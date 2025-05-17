from tidalapi import Session, Config, Quality, Track, Album
import os
from typing import Optional, Dict, Any, List, Set
import aiofiles
import asyncio
from pathlib import Path
import aiohttp
from .models import OutputFormat
import json
from datetime import datetime, timedelta
from fastapi import FastAPI, HTTPException, status, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse, RedirectResponse
from dotenv import load_dotenv
import gzip
from functools import lru_cache
import unicodedata
# Cargar variables de entorno
load_dotenv()

app = FastAPI(title="Tidal API")

# Configuración de CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuración de caché
CACHE_EXPIRATION = timedelta(minutes=30)
response_cache: Dict[str, Dict[str, Any]] = {}

def get_cache_key(endpoint: str, params: Dict[str, Any]) -> str:
    """Genera una clave única para el caché basada en el endpoint y los parámetros."""
    return f"{endpoint}:{json.dumps(params, sort_keys=True)}"

def compress_response(data: Dict[str, Any]) -> bytes:
    """Comprime una respuesta usando gzip."""
    return gzip.compress(json.dumps(data).encode())

def decompress_response(compressed_data: bytes) -> Dict[str, Any]:
    """Descomprime una respuesta usando gzip."""
    return json.loads(gzip.decompress(compressed_data).decode())

def _normalize(text: str) -> str:
    return unicodedata.normalize("NFKD", text).encode("ASCII", "ignore").decode().lower()

from functools import wraps

def cache_response(expiration: timedelta = CACHE_EXPIRATION):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Clave de caché
            params = {k: v for k, v in kwargs.items() if k != 'request'}
            cache_key = get_cache_key(func.__name__, params)

            # Revisar caché
            if cache_key in response_cache:
                cache_entry = response_cache[cache_key]
                if datetime.now() < cache_entry['expires_at']:
                    return decompress_response(cache_entry['data'])

            # Ejecutar función original
            response = await func(*args, **kwargs)

            # Guardar respuesta
            response_cache[cache_key] = {
                'data': compress_response(response),
                'expires_at': datetime.now() + expiration
            }

            return response
        return wrapper
    return decorator


async def cleanup_expired_cache():
    """Limpia las entradas expiradas del caché."""
    while True:
        now = datetime.now()
        expired_keys = [
            key for key, entry in response_cache.items()
            if now >= entry['expires_at']
        ]
        for key in expired_keys:
            del response_cache[key]
        await asyncio.sleep(300)  # Limpiar cada 5 minutos

# Iniciar limpieza de caché
asyncio.create_task(cleanup_expired_cache())

class TidalService:
    def __init__(self):
        self.session = Session()
        self.config = Config()
        self.quality = Quality.hi_res_lossless
        self.link_login = None
        self.config_file = Path(os.path.expanduser("~")) / ".tidal_session.json"
        self.login_cache_file = Path(os.path.expanduser("~")) / ".tidal_login_cache.json"
        # Limpiar caché al iniciar
        self.clear_login_cache()
        # Inicializar sesión
        self.initialize_session()
        
    def initialize_session(self):
        """Inicializar la sesión de Tidal"""
        try:
            print("[INIT] Inicializando sesión de Tidal")
            # Limpiar sesión actual
            self.session = Session()
            
            # Intentar cargar sesión guardada
            if self.load_session():
                print("[INIT] Sesión cargada exitosamente")
                return True
                
            print("[INIT] No se pudo cargar sesión existente")
            return False
        except Exception as e:
            print(f"[INIT] Error al inicializar sesión: {str(e)}")
            return False

    def clear_login_cache(self):
        """Limpiar el caché de login"""
        try:
            print("[CACHE] Limpiando caché de login al iniciar")
            if self.login_cache_file.exists():
                os.remove(self.login_cache_file)
                print("[CACHE] Caché de login eliminado")
        except Exception as e:
            print(f"[CACHE] Error al limpiar caché de login: {str(e)}")
        
    def load_session(self):
        """Cargar la sesión guardada si existe"""
        try:
            print(f"[SESSION] Intentando cargar sesión desde: {self.config_file}")
            if not self.config_file.exists():
                print("[SESSION] No se encontró archivo de sesión")
                return False
            
            print("[SESSION] Archivo de sesión encontrado")
            with open(self.config_file, 'r') as f:
                session_data = json.load(f)
            print(f"[SESSION] Datos de sesión cargados: {list(session_data.keys())}")
            
            if not all(key in session_data for key in ['access_token', 'refresh_token', 'token_type']):
                print("[SESSION] Datos de sesión incompletos")
                return False
            
            try:
                print("[SESSION] Intentando cargar sesión OAuth")
                self.session.load_oauth_session(
                    session_data['access_token'],
                    session_data['refresh_token'],
                    session_data['token_type']
                )
                
                # Verificar si la sesión es válida
                if self.session.check_login():
                    print("[SESSION] Sesión cargada exitosamente")
                    return True
                else:
                    print("[SESSION] Sesión expirada, intentando refrescar")
                    try:
                        self.session.refresh_access_token()
                        if self.session.check_login():
                            print("[SESSION] Sesión refrescada exitosamente")
                            self.save_session()
                            return True
                    except Exception as e:
                        print(f"[SESSION] Error al refrescar la sesión: {str(e)}")
                    self.clear_session()
            except Exception as e:
                print(f"[SESSION] Error al cargar la sesión OAuth: {str(e)}")
                self.clear_session()
            
            return False
        except Exception as e:
            print(f"[SESSION] Error general al cargar la sesión: {str(e)}")
            return False

    def load_login_cache(self) -> Optional[Dict[str, Any]]:
        """Cargar el caché de login si existe"""
        try:
            if self.login_cache_file.exists():
                with open(self.login_cache_file, 'r') as f:
                    cache_data = json.load(f)
                    # Verificar si el caché no ha expirado
                    if 'expires_at' in cache_data and datetime.fromisoformat(cache_data['expires_at']) > datetime.now():
                        return cache_data
            return None
        except Exception as e:
            print(f"[CACHE] Error al cargar caché de login: {str(e)}")
            return None

    def save_login_cache(self, login_data: Dict[str, Any]):
        """Guardar el caché de login"""
        try:
            cache_data = {
                'verification_uri': login_data['verification_uri'],
                'expires_at': (datetime.now() + timedelta(seconds=login_data['expires_in'])).isoformat(),
                'created_at': datetime.now().isoformat()
            }
            with open(self.login_cache_file, 'w') as f:
                json.dump(cache_data, f, indent=4)
            print("[CACHE] Caché de login guardado exitosamente")
        except Exception as e:
            print(f"[CACHE] Error al guardar caché de login: {str(e)}")

    def clear_session(self):
        """Limpiar la sesión actual y el archivo de sesión"""
        try:
            print("[SESSION] Iniciando limpieza de sesión")
            # Primero limpiamos la sesión actual
            self.session = Session()
            print("[SESSION] Sesión actual limpiada")
            
            # Limpiar caché de login
            self.clear_login_cache()
            
            # Intentamos eliminar el archivo de sesión
            try:
                if self.config_file.exists():
                    print(f"[SESSION] Intentando eliminar archivo: {self.config_file}")
                    os.remove(self.config_file)
                    print("[SESSION] Archivo eliminado exitosamente")
            except PermissionError:
                print("[SESSION] Error de permisos al eliminar archivo, intentando sobrescribir")
                # Si el archivo está en uso, intentamos sobrescribirlo con una sesión vacía
                try:
                    with open(self.config_file, 'w') as f:
                        json.dump({}, f, indent=4)
                    print("[SESSION] Archivo sobrescrito exitosamente")
                except Exception as e:
                    print(f"[SESSION] Error al sobrescribir archivo: {str(e)}")
            except Exception as e:
                print(f"[SESSION] Error al eliminar archivo: {str(e)}")
                
            print("[SESSION] Limpieza de sesión completada")
        except Exception as e:
            print(f"[SESSION] Error general al limpiar sesión: {str(e)}")
        
    def save_session(self):
        """Guardar los datos de la sesión actual"""
        try:
            print("[SESSION] Intentando guardar sesión")
            
            # Verificar si hay una sesión activa
            if not self.session.check_login():
                print("[SESSION] No hay una sesión activa para guardar")
                return False

            # Verificar que los tokens existan y no estén vacíos
            required_tokens = ['access_token', 'refresh_token', 'token_type']
            for token in required_tokens:
                if not hasattr(self.session, token):
                    print(f"[SESSION] Falta token: {token}")
                    return False
                if not getattr(self.session, token):
                    print(f"[SESSION] Token vacío: {token}")
                    return False

            # Obtener los tokens
            session_data = {
                'access_token': self.session.access_token,
                'refresh_token': self.session.refresh_token,
                'token_type': self.session.token_type,
                'last_updated': str(datetime.now())
            }
            
            print(f"[SESSION] Tokens obtenidos: {list(session_data.keys())}")
            
            # Asegurarse de que el directorio existe
            self.config_file.parent.mkdir(parents=True, exist_ok=True)
            
            # Intentar guardar directamente en el archivo final
            try:
                with open(self.config_file, 'w') as f:
                    json.dump(session_data, f, indent=4)
                print("[SESSION] Sesión guardada exitosamente en:", self.config_file)
                return True
            except Exception as e:
                print(f"[SESSION] Error al guardar directamente: {str(e)}")
                
                # Si falla, intentar con un archivo temporal con nombre único
                try:
                    import uuid
                    temp_file = self.config_file.with_suffix(f'.{uuid.uuid4()}.tmp')
                    with open(temp_file, 'w') as f:
                        json.dump(session_data, f, indent=4)
                    
                    # Intentar mover el archivo temporal
                    try:
                        if self.config_file.exists():
                            os.remove(self.config_file)
                        os.rename(temp_file, self.config_file)
                        print("[SESSION] Sesión guardada exitosamente usando archivo temporal")
                        return True
                    except Exception as e:
                        print(f"[SESSION] Error al mover archivo temporal: {str(e)}")
                        if temp_file.exists():
                            os.remove(temp_file)
                        return False
                except Exception as e:
                    print(f"[SESSION] Error al usar archivo temporal: {str(e)}")
                    return False
                
        except Exception as e:
            print(f"[SESSION] Error al guardar la sesión: {str(e)}")
            return False

    async def get_playlist_info(self, playlist_id: str) -> Optional[Dict[str, Any]]:
        """Obtener información de una playlist"""
        try:
            playlist = self.session.playlist(playlist_id)
            
            # Obtener la portada de la playlist
            cover_url = None
            if hasattr(playlist, 'image'):
                try:
                    cover_url = playlist.image(dimensions=1500)  # Usar la máxima resolución disponible
                except ValueError:
                    try:
                        cover_url = playlist.image(dimensions=640)  # Intentar con resolución media
                    except ValueError:
                        cover_url = playlist.image(dimensions=320)  # Usar resolución mínima
            
            return {
                "id": playlist.id,
                "name": playlist.name,
                "description": playlist.description,
                "creator": playlist.creator.name,
                "number_of_tracks": playlist.num_tracks,
                "duration": playlist.duration,
                "created": playlist.created,
                "cover_url": cover_url
            }
        except Exception as e:
            print(f"Error al obtener información de la playlist: {str(e)}")
            return None

    async def get_playlist_tracks(self, playlist_id: str) -> List[Dict[str, Any]]:
        """Obtener todas las pistas de una playlist"""
        try:
            playlist = self.session.playlist(playlist_id)
            tracks = []
            for track in playlist.tracks():
                # Obtener la portada del álbum
                cover_url = await self.get_album_cover_url(track, size=1280)
                
                tracks.append({
                    "id": track.id,
                    "name": track.name,
                    "artist": track.artist.name,
                    "album": track.album.name,
                    "duration": track.duration,
                    "cover_url": cover_url
                })
            return tracks
        except Exception as e:
            print(f"Error al obtener pistas de la playlist: {str(e)}")
            return []

    async def download_playlist(self, playlist_id: str, output_dir: str, format: OutputFormat = OutputFormat.flac) -> Dict[str, Any]:
        """Descargar todas las pistas de una playlist"""
        try:
            # Obtener información de la playlist
            playlist = self.session.playlist(playlist_id)
            playlist_dir = Path(output_dir) / playlist.name
            playlist_dir.mkdir(parents=True, exist_ok=True)

            # Descargar cada pista
            results = {
                "success": [],
                "failed": []
            }

            for track in playlist.tracks():
                try:
                    # Crear nombre de archivo seguro
                    safe_name = f"{track.name} - {track.artist.name}".replace("/", "_").replace("\\", "_")
                    output_path = playlist_dir / f"{safe_name}.{format}"
                    
                    # Descargar la pista
                    success = await self.download_track(track.id, str(output_path), format)
                    
                    if success:
                        results["success"].append({
                            "id": track.id,
                            "name": track.name,
                            "artist": track.artist.name,
                            "path": str(output_path)
                        })
                    else:
                        results["failed"].append({
                            "id": track.id,
                            "name": track.name,
                            "artist": track.artist.name
                        })
                except Exception as e:
                    print(f"Error al descargar pista {track.name}: {str(e)}")
                    results["failed"].append({
                        "id": track.id,
                        "name": track.name,
                        "artist": track.artist.name,
                        "error": str(e)
                    })

            return {
                "playlist_name": playlist.name,
                "total_tracks": len(playlist.tracks()),
                "successful_downloads": len(results["success"]),
                "failed_downloads": len(results["failed"]),
                "results": results
            }
        except Exception as e:
            print(f"Error al descargar playlist: {str(e)}")
            return {
                "error": str(e),
                "successful_downloads": 0,
                "failed_downloads": 0,
                "results": {"success": [], "failed": []}
            }
        
    async def get_login_link(self, force_new: bool = False) -> Optional[Dict[str, Any]]:
        try:
            # Primero verificar si hay una sesión activa
            if self.session.check_login():
                return {"status": "success", "message": "Ya estás autenticado"}
            
            # Verificar si hay un caché de login válido y no se está forzando uno nuevo
            if not force_new:
                cached_login = self.load_login_cache()
                if cached_login:
                    print("[LOGIN] Usando link de login en caché")
                    return {
                        "status": "pending",
                        "verification_uri": cached_login['verification_uri'],
                        "expires_in": int((datetime.fromisoformat(cached_login['expires_at']) - datetime.now()).total_seconds()),
                        "from_cache": True
                    }
            
            # Si no hay caché o se está forzando uno nuevo, obtener nuevo link de login
            print("[LOGIN] Generando nuevo link de login")
            self.link_login = self.session.get_link_login()
            
            # Obtener el código de verificación del link
            verification_code = None
            if hasattr(self.link_login, 'verification_code'):
                verification_code = self.link_login.verification_code
            elif hasattr(self.link_login, 'user_code'):
                verification_code = self.link_login.user_code
            
            # Calcular tiempo de expiración (5 minutos)
            expires_in = 300
            
            login_data = {
                "status": "pending",
                "verification_uri": self.link_login.verification_uri_complete,
                "expires_in": expires_in,
                "verification_code": verification_code,
                "created_at": datetime.now().isoformat()
            }
            
            print(f"[LOGIN] Código de verificación: {verification_code}")
            print(f"[LOGIN] URI completa: {self.link_login.verification_uri_complete}")
            print(f"[LOGIN] Tiempo de expiración: {expires_in} segundos")
            
            # Guardar en caché
            self.save_login_cache(login_data)
            return login_data
            
        except Exception as e:
            print(f"[LOGIN] Error al obtener link de login: {str(e)}")
            return None

    async def process_login(self, verification_uri: str) -> bool:
        try:
            print(f"[LOGIN] Iniciando proceso de login con URI: {verification_uri}")
            
            # Verificar si hay un caché de login válido
            cached_login = self.load_login_cache()
            if not cached_login:
                print("[LOGIN] No hay caché de login válido")
                return False
            
            # Verificar si el código ha expirado
            created_at = datetime.fromisoformat(cached_login['created_at'])
            if (datetime.now() - created_at).total_seconds() > 300:  # 5 minutos
                print("[LOGIN] Código de verificación expirado")
                return False
            
            # Procesar el login
            try:
                print("[LOGIN] Procesando login con Tidal")
                if not self.link_login:
                    print("[LOGIN] No hay objeto link_login disponible")
                    return False
                
                # Intentar procesar el login con reintentos
                max_retries = 3
                retry_count = 0
                last_error = None
                
                while retry_count < max_retries:
                    try:
                        print(f"[LOGIN] Intento {retry_count + 1} de {max_retries}")
                        
                        # Verificar si el usuario ha confirmado el login
                        try:
                            print("[LOGIN] Procesando link_login...")
                            self.session.process_link_login(self.link_login, until_expiry=False)
                            print("[LOGIN] Link login procesado exitosamente")
                            
                            # Verificar si el login fue exitoso
                            if self.session.check_login():
                                print("[LOGIN] Login verificado exitosamente")
                                
                                # Guardar la sesión
                                if self.save_session():
                                    print("[LOGIN] Sesión guardada exitosamente")
                                    # Limpiar el caché de login
                                    self.clear_login_cache()
                                    return True
                                else:
                                    print("[LOGIN] Error al guardar la sesión")
                                    return False
                            else:
                                print("[LOGIN] Login no verificado, esperando confirmación")
                                last_error = "Esperando confirmación del usuario"
                                retry_count += 1
                                await asyncio.sleep(2)  # Esperar 2 segundos entre intentos
                                continue
                                
                        except Exception as e:
                            error_msg = str(e)
                            print(f"[LOGIN] Error en intento {retry_count + 1}: {error_msg}")
                            
                            if "You took too long to log in" in error_msg:
                                print("[LOGIN] Tiempo de espera agotado")
                                return False
                            elif "User code expired" in error_msg:
                                print("[LOGIN] Código expirado")
                                return False
                            else:
                                last_error = error_msg
                                retry_count += 1
                                await asyncio.sleep(2)
                                continue
                                
                    except Exception as e:
                        print(f"[LOGIN] Error general en intento {retry_count + 1}: {str(e)}")
                        last_error = str(e)
                        retry_count += 1
                        await asyncio.sleep(2)
                        continue
                
                print(f"[LOGIN] Error después de {max_retries} intentos: {last_error}")
                return False
                
            except Exception as e:
                print(f"[LOGIN] Error al procesar login con Tidal: {str(e)}")
                return False
                
        except Exception as e:
            print(f"[LOGIN] Error general al procesar login: {str(e)}")
            return False

    async def get_track_info(self, track_id: str) -> Optional[Dict[str, Any]]:
        try:
            print(f"[TRACK] Obteniendo información para track ID: {track_id}")
            track = self.session.track(track_id)
            
            # Obtener la URL de la portada
            cover_url = await self.get_album_cover_url(track)
            
            track_info = {
                "id": track.id,
                "name": track.name,
                "artist": track.artist.name,
                "album": track.album.name,
                "duration": track.duration,
                "quality": str(self.quality),
                "url": f"https://tidal.com/track/{track.id}",
                "cover_url": cover_url if cover_url else None
            }
            
            print(f"[TRACK] Información obtenida exitosamente para: {track.name}")
            return track_info
        except Exception as e:
            print(f"[TRACK] Error al obtener información de la pista: {str(e)}")
            return None

    async def get_stream_url(self, track_id: str) -> Optional[str]:
        try:
            print(f"[STREAM] Obteniendo URL de streaming para track ID: {track_id}")
            track = self.session.track(track_id)
            
            # Lista de calidades en orden descendente
            qualities = [
                Quality.hi_res_lossless,
                Quality.high_lossless,
                Quality.low_320k,
                Quality.low_96k
            ]
            
            # Probar cada calidad
            for quality in qualities:
                try:
                    print(f"[STREAM] Probando calidad: {quality}")
                    self.session.audio_quality = quality
                    stream = track.get_stream()
                    stream_manifest = stream.get_stream_manifest()
                    urls = stream_manifest.get_urls()
                    print(f"[STREAM] URLs disponibles para {quality}: {len(urls)}")
                    
                    # Buscar la URL en formato FLAC
                    flac_url = None
                    for url in urls:
                        if url.endswith('.flac'):
                            flac_url = url
                            print(f"[STREAM] URL FLAC encontrada con calidad {quality}: {flac_url}")
                            return flac_url
                    
                    # Si no se encuentra FLAC pero hay URLs, usar la primera
                    if urls:
                        print(f"[STREAM] No se encontró FLAC con calidad {quality}, usando primera URL disponible")
                        return urls[0]
                        
                except Exception as e:
                    print(f"[STREAM] Error al probar calidad {quality}: {str(e)}")
                    continue
            
            print("[STREAM] No se pudo obtener URL de streaming con ninguna calidad")
            return None
            
        except Exception as e:
            print(f"[STREAM] Error al obtener URL de streaming: {str(e)}")
            return None

    async def download_track(self, track_id: str, output_path: str, format: OutputFormat = OutputFormat.flac) -> bool:
        try:
            # Asegurar que la extensión sea la especificada
            output_path = str(Path(output_path).with_suffix(f'.{format}'))
            
            # Crear directorio si no existe
            Path(output_path).parent.mkdir(parents=True, exist_ok=True)
            
            # Obtener la pista y su stream
            track = self.session.track(track_id)
            stream = track.get_stream()
            stream_manifest = stream.get_stream_manifest()
            stream_url = stream_manifest.get_urls()[0]
            
            # Descargar el archivo
            async with aiohttp.ClientSession() as session:
                async with session.get(stream_url) as response:
                    async with aiofiles.open(output_path, 'wb') as f:
                        await f.write(await response.read())
            
            return True
        except Exception as e:
            print(f"Error al descargar la pista: {str(e)}")
            return False

    async def get_lyrics(self, track_id: str) -> Optional[Dict[str, Any]]:
        """Obtener las letras de una canción"""
        try:
            print(f"[LYRICS] Obteniendo letras para track ID: {track_id}")
            track = self.session.track(track_id)
            lyrics = track.lyrics()
            
            if not lyrics:
                print("[LYRICS] No se encontraron letras")
                return None
                
            # Obtener los atributos disponibles
            lyrics_data = {
                "track_id": track_id,
                "track_name": track.name,
                "artist": track.artist.name,
                "lyrics": lyrics.text if hasattr(lyrics, 'text') else None
            }
            
            # Añadir atributos opcionales si están disponibles
            if hasattr(lyrics, 'source'):
                lyrics_data["source"] = lyrics.source
            if hasattr(lyrics, 'language'):
                lyrics_data["language"] = lyrics.language
            if hasattr(lyrics, 'rights'):
                lyrics_data["rights"] = lyrics.rights
                
            print(f"[LYRICS] Letras obtenidas exitosamente para: {track.name}")
            return lyrics_data
            
        except Exception as e:
            print(f"[LYRICS] Error al obtener letras: {str(e)}")
            import traceback
            print(f"[LYRICS] Traceback: {traceback.format_exc()}")
            return None

    async def get_album_cover_url(self, track, size: int = 1280) -> Optional[str]:
        """Obtener la URL de la portada del álbum en el tamaño especificado
        
        Args:
            track: Objeto Track de Tidal
            size: Tamaño de la imagen (80, 160, 320, 640, 1280). Por defecto 1280.
            
        Returns:
            URL de la portada del álbum o None si no se encuentra
        """
        try:
            print(f"[COVER] Intentando obtener portada para track: {track.name}")
            
            # Validar el tamaño
            valid_sizes = [80, 160, 320, 640, 1280]
            if size not in valid_sizes:
                print(f"[COVER] Tamaño inválido {size}, usando 1280")
                size = 1280
            
            # Intentar obtener la URL del álbum
            album = self.session.album(track.album.id)
            print(f"[COVER] Álbum encontrado: {album.name}")
            
            # Intentar obtener la URL de la portada en el tamaño especificado
            try:
                cover_url = album.image(dimensions=size)
                print(f"[COVER] URL encontrada en album.image() con tamaño {size}: {cover_url}")
                return cover_url
            except Exception as e:
                print(f"[COVER] Error al obtener album.image(): {str(e)}")
                return None
                
        except Exception as e:
            print(f"[COVER] Error al obtener URL de la portada: {str(e)}")
            return None

    async def search_tracks(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Buscar canciones por nombre"""
        try:
            
            norm_query = _normalize(query)
            print(f"[SEARCH] Buscando tracks con query='{query}', limit={limit}")
            
            # Validar parámetros
            if not query or not isinstance(query, str):
                print("[SEARCH] Query inválida")
                return []
                
            if not isinstance(limit, int) or limit < 1:
                print("[SEARCH] Límite inválido, usando valor por defecto")
                limit = 10
                
            if not self.session.check_login():
                print("[SEARCH] Sesión no válida")
                return []

            # Realizar la búsqueda
            search_results = self.session.search(norm_query, models=[Track], limit=limit)
            print(f"[SEARCH] Resultados recibidos: {type(search_results)}")
            
            if not search_results:
                print("[SEARCH] No se encontraron resultados")
                return []
            
            # Obtener las pistas de los resultados
            tracks = []
            track_list = []
            
            # Manejar diferentes formatos de respuesta
            if isinstance(search_results, dict):
                if 'tracks' in search_results:
                    track_list = search_results['tracks']
                elif 'items' in search_results:
                    track_list = search_results['items']
            elif hasattr(search_results, 'tracks'):
                track_list = search_results.tracks
            elif hasattr(search_results, 'items'):
                track_list = search_results.items
            
            print(f"[SEARCH] Número de pistas encontradas: {len(track_list)}")
            
            for track in track_list:
                try:
                    # Obtener la URL de la portada
                    cover_url = await self.get_album_cover_url(track)
                    
                    track_info = {
                        'id': track.id,
                        'name': track.name,
                        'artist': track.artist.name,
                        'album': track.album.name,
                        'duration': track.duration,
                        'quality': str(self.quality),
                        'url': f"https://tidal.com/track/{track.id}",
                        'stream_url': None,  # Se obtiene al solicitar
                        'cover_url': cover_url,
                        'lyrics': None,  # Se obtiene al solicitar
                        'lyrics_language': None,  # Se obtiene al solicitar
                    }
                    tracks.append(track_info)
                    print(f"[SEARCH] Procesada pista: {track.name} - {track.artist.name}")
                except Exception as e:
                    print(f"[SEARCH] Error al procesar track: {str(e)}")
                    continue

            print(f"[SEARCH] Encontrados {len(tracks)} tracks")
            return tracks
        except Exception as e:
            print(f"[SEARCH] Error en búsqueda: {str(e)}")
            return []

    async def search_tracks_by_artist(self, title: str, artist: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Buscar canciones por título y artista"""
        try:
            print(f"[SEARCH] Buscando canciones con título: {title} y artista: {artist}")
            if not self.session.check_login():
                print("[SEARCH] No hay sesión activa")
                return []
                
            # Primero buscamos por título
            search_results = self.session.search(title, models=[Track], limit=limit*2)  # Buscamos más resultados para filtrar
            print(f"[SEARCH] Resultados recibidos: {type(search_results)}")
            
            if not search_results:
                print("[SEARCH] No se encontraron resultados")
                return []
            
            # Obtener las pistas de los resultados
            tracks = []
            if hasattr(search_results, 'tracks'):
                track_list = search_results.tracks
            else:
                track_list = search_results.get('tracks', []) if isinstance(search_results, dict) else []
            
            print(f"[SEARCH] Número de pistas encontradas antes de filtrar: {len(track_list)}")
            
            # Normalizar los términos de búsqueda
            title = title.lower().strip()
            artist = artist.lower().strip()
            
            # Filtrar por artista y título
            for track in track_list:
                try:
                    track_name = track.name.lower()
                    artist_name = track.artist.name.lower()
                    
                    # Verificar coincidencia exacta o muy cercana
                    title_match = title in track_name or track_name in title
                    artist_match = artist in artist_name or artist_name in artist
                    
                    if title_match and artist_match:
                        # Obtener la URL de la portada
                        cover_url = await self.get_album_cover_url(track)
                        
                        track_info = {
                            "id": track.id,
                            "name": track.name,
                            "artist": track.artist.name,
                            "album": track.album.name,
                            "duration": track.duration,
                            "quality": str(self.quality),
                            "url": f"https://tidal.com/track/{track.id}",
                            "cover_url": cover_url
                        }
                        tracks.append(track_info)
                        print(f"[SEARCH] Procesada pista: {track.name} - {track.artist.name}")
                        
                        if len(tracks) >= limit:
                            break
                except Exception as e:
                    print(f"[SEARCH] Error al procesar track {getattr(track, 'id', 'unknown')}: {str(e)}")
                    continue
            
            print(f"[SEARCH] Se encontraron {len(tracks)} canciones después de filtrar por artista y título")
            return tracks
        except Exception as e:
            print(f"[SEARCH] Error al buscar canciones: {str(e)}")
            import traceback
            print(f"[SEARCH] Traceback: {traceback.format_exc()}")
            return []

    async def get_mixes(self) -> List[Dict[str, Any]]:
        """Obtener los mixes disponibles para el usuario"""
        try:
            print("[MIXES] Obteniendo mixes disponibles")
            if not self.session.check_login():
                print("[MIXES] No hay sesión activa")
                return []
            
            # Obtener los mixes
            mixes = self.session.mixes()
            print(f"[MIXES] Número de mixes encontrados: {len(mixes)}")
            
            # Procesar cada mix
            mixes_info = []
            for mix in mixes:
                try:
                    # Obtener la portada del mix
                    cover_url = None
                    if hasattr(mix, 'image'):
                        try:
                            cover_url = mix.image(dimensions=1500)  # Usar la máxima resolución disponible
                        except ValueError:
                            try:
                                cover_url = mix.image(dimensions=640)  # Intentar con resolución media
                            except ValueError:
                                cover_url = mix.image(dimensions=320)  # Usar resolución mínima
                    
                    # Obtener el número de pistas usando items()
                    number_of_tracks = len(mix.items()) if hasattr(mix, 'items') else 0
                    
                    mix_info = {
                        "id": mix.id,
                        "title": mix.title,
                        "subtitle": mix.sub_title,  # Usar sub_title en lugar de subtitle
                        "cover_url": cover_url,
                        "number_of_tracks": number_of_tracks
                    }
                    mixes_info.append(mix_info)
                    print(f"[MIXES] Procesado mix: {mix.title}")
                except Exception as e:
                    print(f"[MIXES] Error al procesar mix {getattr(mix, 'id', 'unknown')}: {str(e)}")
                    continue
            
            return mixes_info
        except Exception as e:
            print(f"[MIXES] Error al obtener mixes: {str(e)}")
            return []

    async def get_mix_tracks(self, mix_id: str) -> List[Dict[str, Any]]:
        """Obtener las pistas de un mix específico"""
        try:
            print(f"[MIXES] Obteniendo pistas para mix ID: {mix_id}")
            if not self.session.check_login():
                print("[MIXES] No hay sesión activa")
                return []
            
            # Obtener el mix
            mix = self.session.mix(mix_id)
            if not mix:
                print(f"[MIXES] Mix no encontrado: {mix_id}")
                return []
            
            # Obtener las pistas usando items()
            tracks = []
            for item in mix.items():
                try:
                    # Verificar si el item es una pista
                    if not isinstance(item, Track):
                        continue
                        
                    # Obtener la portada del álbum
                    cover_url = await self.get_album_cover_url(item, size=1280)
                    
                    track_info = {
                        "id": item.id,
                        "name": item.name,
                        "artist": item.artist.name,
                        "album": item.album.name,
                        "duration": item.duration,
                        "cover_url": cover_url
                    }
                    tracks.append(track_info)
                    print(f"[MIXES] Procesada pista: {item.name} - {item.artist.name}")
                except Exception as e:
                    print(f"[MIXES] Error al procesar track {getattr(item, 'id', 'unknown')}: {str(e)}")
                    continue
            
            return tracks
        except Exception as e:
            print(f"[MIXES] Error al obtener pistas del mix: {str(e)}")
            return []

    async def get_mix_info(self, mix_id: str) -> Optional[Dict[str, Any]]:
        """Obtener información detallada de un mix"""
        try:
            print(f"[MIXES] Obteniendo información para mix ID: {mix_id}")
            if not self.session.check_login():
                print("[MIXES] No hay sesión activa")
                return None
            
            # Obtener el mix
            mix = self.session.mix(mix_id)
            if not mix:
                print(f"[MIXES] Mix no encontrado: {mix_id}")
                return None
            
            # Obtener la portada del mix
            cover_url = None
            if hasattr(mix, 'image'):
                try:
                    cover_url = mix.image(dimensions=1500)  # Usar la máxima resolución disponible
                except ValueError:
                    try:
                        cover_url = mix.image(dimensions=640)  # Intentar con resolución media
                    except ValueError:
                        cover_url = mix.image(dimensions=320)  # Usar resolución mínima
            
            # Obtener las pistas
            tracks = await self.get_mix_tracks(mix_id)
            
            mix_info = {
                "id": mix.id,
                "title": mix.title,
                "subtitle": mix.sub_title,  # Usar sub_title en lugar de subtitle
                "cover_url": cover_url,
                "number_of_tracks": len(tracks),
                "tracks": tracks
            }
            
            return mix_info
        except Exception as e:
            print(f"[MIXES] Error al obtener información del mix: {str(e)}")
            return None

    async def get_album_info(self, album_id: str) -> Optional[Dict[str, Any]]:
        """Obtener información detallada de un álbum"""
        try:
            print(f"[ALBUM] Obteniendo información para álbum ID: {album_id}")
            if not self.session.check_login():
                print("[ALBUM] No hay sesión activa")
                return None
            
            # Obtener el álbum
            album = self.session.album(album_id)
            if not album:
                print(f"[ALBUM] Álbum no encontrado: {album_id}")
                return None
            
            # Obtener la portada del álbum
            cover_url = None
            try:
                cover_url = album.image(dimensions=1280)
            except Exception as e:
                print(f"[ALBUM] Error al obtener portada: {str(e)}")
            
            # Obtener las pistas del álbum
            tracks = []
            for track in album.tracks():
                try:
                    # Obtener la portada para cada pista
                    track_cover_url = cover_url  # Usar la portada del álbum por defecto
                    try:
                        track_cover_url = await self.get_album_cover_url(track)
                    except Exception as e:
                        print(f"[ALBUM] Error al obtener portada de pista: {str(e)}")
                    
                    track_info = {
                        "id": track.id,
                        "name": track.name,
                        "artist": track.artist.name,
                        "duration": track.duration,
                        "track_number": track.track_num,
                        "volume_number": track.volume_num,
                        "explicit": track.explicit,
                        "cover_url": track_cover_url
                    }
                    tracks.append(track_info)
                    print(f"[ALBUM] Procesada pista: {track.name}")
                except Exception as e:
                    print(f"[ALBUM] Error al procesar track {getattr(track, 'id', 'unknown')}: {str(e)}")
                    continue
            
            album_info = {
                "id": album.id,
                "name": album.name,
                "artist": album.artist.name,
                "cover_url": cover_url,
                "release_date": album.release_date.isoformat() if album.release_date else None,
                "number_of_tracks": len(tracks),
                "duration": album.duration,
                "tracks": tracks
            }
            
            return album_info
        except Exception as e:
            print(f"[ALBUM] Error al obtener información del álbum: {str(e)}")
            return None

    async def search_albums(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Buscar álbumes por nombre"""
        try:
            print(f"[SEARCH] Buscando álbumes con query: {query}")
            if not self.session.check_login():
                print("[SEARCH] No hay sesión activa")
                return []
                
            # Normalizar la query
            norm_query = _normalize(query)
            search_results = self.session.search(norm_query, models=[Album], limit=limit)
            print(f"[SEARCH] Resultados recibidos: {type(search_results)}")
            
            # Verificar si hay resultados
            if not search_results:
                print("[SEARCH] No se encontraron resultados")
                return []
            
            # Obtener los álbumes de los resultados
            albums = []
            if hasattr(search_results, 'albums'):
                album_list = search_results.albums
            else:
                album_list = search_results.get('albums', []) if isinstance(search_results, dict) else []
            
            print(f"[SEARCH] Número de álbumes encontrados: {len(album_list)}")
            
            for album in album_list:
                try:
                    # Obtener la URL de la portada
                    cover_url = None
                    try:
                        cover_url = album.image(dimensions=1280)
                    except Exception as e:
                        print(f"[SEARCH] Error al obtener portada: {str(e)}")
                    
                    album_info = {
                        "id": album.id,
                        "name": album.name,
                        "artist": album.artist.name,
                        "cover_url": cover_url,
                        "release_date": album.release_date.isoformat() if album.release_date else None,
                        "number_of_tracks": album.num_tracks,
                        "duration": album.duration
                    }
                    albums.append(album_info)
                    print(f"[SEARCH] Procesado álbum: {album.name} - {album.artist.name}")
                except Exception as e:
                    print(f"[SEARCH] Error al procesar álbum {getattr(album, 'id', 'unknown')}: {str(e)}")
                    continue
            
            print(f"[SEARCH] Se encontraron {len(albums)} álbumes")
            return albums
        except Exception as e:
            print(f"[SEARCH] Error al buscar álbumes: {str(e)}")
            import traceback
            print(f"[SEARCH] Traceback: {traceback.format_exc()}")
            return []

    async def search_albums_by_artist(self, title: str, artist: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Buscar álbumes por título y artista"""
        try:
            print(f"[SEARCH] Buscando álbumes con título: {title} y artista: {artist}")
            if not self.session.check_login():
                print("[SEARCH] No hay sesión activa")
                return []
                
            # Primero buscamos por título
            search_results = self.session.search(title, models=[Album], limit=limit*2)
            print(f"[SEARCH] Resultados recibidos: {type(search_results)}")
            
            if not search_results:
                print("[SEARCH] No se encontraron resultados")
                return []
            
            # Obtener los álbumes de los resultados
            albums = []
            if hasattr(search_results, 'albums'):
                album_list = search_results.albums
            else:
                album_list = search_results.get('albums', []) if isinstance(search_results, dict) else []
            
            print(f"[SEARCH] Número de álbumes encontrados antes de filtrar: {len(album_list)}")
            
            # Normalizar los términos de búsqueda
            title = title.lower().strip()
            artist = artist.lower().strip()
            
            # Filtrar por artista y título
            for album in album_list:
                try:
                    album_name = album.name.lower()
                    artist_name = album.artist.name.lower()
                    
                    # Verificar coincidencia exacta o muy cercana
                    title_match = title in album_name or album_name in title
                    artist_match = artist in artist_name or artist_name in artist
                    
                    if title_match and artist_match:
                        # Obtener la URL de la portada
                        cover_url = None
                        try:
                            cover_url = album.image(dimensions=1280)
                        except Exception as e:
                            print(f"[SEARCH] Error al obtener portada: {str(e)}")
                        
                        album_info = {
                            "id": album.id,
                            "name": album.name,
                            "artist": album.artist.name,
                            "cover_url": cover_url,
                            "release_date": album.release_date.isoformat() if album.release_date else None,
                            "number_of_tracks": album.num_tracks,
                            "duration": album.duration
                        }
                        albums.append(album_info)
                        print(f"[SEARCH] Procesado álbum: {album.name} - {album.artist.name}")
                        
                        if len(albums) >= limit:
                            break
                except Exception as e:
                    print(f"[SEARCH] Error al procesar álbum {getattr(album, 'id', 'unknown')}: {str(e)}")
                    continue
            
            print(f"[SEARCH] Se encontraron {len(albums)} álbumes después de filtrar por artista y título")
            return albums
        except Exception as e:
            print(f"[SEARCH] Error al buscar álbumes: {str(e)}")
            import traceback
            print(f"[SEARCH] Traceback: {traceback.format_exc()}")
            return []

    async def get_user_playlists(self) -> List[Dict[str, Any]]:
        """
        Devuelve todas las playlists del usuario (propias y seguidas),
        sin duplicados y con el flag `is_own` correctamente asignado.
        """
        try:
            print("[PLAYLISTS] Obteniendo playlists del usuario")
            if not self.session.check_login():
                print("[PLAYLISTS] No hay sesión activa")
                return []

            playlists_info: List[Dict[str, Any]] = []
            seen_ids: Set[str] = set()

            def build_info(pl, is_own: bool) -> Dict[str, Any]:
                # Intentar obtener la mejor calidad disponible
                cover_url = None
                square_cover_url = None
                try:
                    # Intentar con la máxima calidad primero
                    for size in [1500, 1280, 1080, 960, 640, 320]:
                        try:
                            cover_url = pl.image(dimensions=size)
                            if cover_url:
                                break
                        except:
                            continue

                    # Para la versión cuadrada, usar un tamaño más pequeño
                    for size in [640, 320, 160, 80]:
                        try:
                            square_cover_url = pl.image(dimensions=size)
                            if square_cover_url:
                                break
                        except:
                            continue

                except Exception as e:
                    print(f"[PLAYLISTS] Error al obtener imágenes: {e}")

                return {
                    "id": pl.id,
                    "name": pl.name,
                    "description": pl.description or "",
                    "creator": "me" if is_own else (pl.creator.name if pl.creator else "user"),
                    "number_of_tracks": pl.num_tracks,
                    "duration": pl.duration,
                    "cover_url": cover_url,
                    "square_cover_url": square_cover_url,
                    "created": pl.created.isoformat() if pl.created else None,
                    "last_updated": pl.last_updated.isoformat() if pl.last_updated else None,
                    "is_own": is_own
                }

            # Playlists creadas por el usuario
            print("[PLAYLISTS] Obteniendo playlists propias")
            for pl in self.session.user.playlists():
                if pl.id in seen_ids:
                    continue
                seen_ids.add(pl.id)
                playlists_info.append(build_info(pl, True))
                print(f"[PLAYLISTS] Procesada playlist propia: {pl.name}")

            # Playlists seguidas/favoritas
            print("[PLAYLISTS] Obteniendo playlists seguidas")
            for pl in self.session.user.favorites.playlists():
                if pl.id in seen_ids:
                    continue

                is_own = (
                    pl.creator
                    and getattr(pl.creator, "id", None) == self.session.user.id
                )
                if is_own:
                    continue

                seen_ids.add(pl.id)
                playlists_info.append(build_info(pl, False))
                print(f"[PLAYLISTS] Procesada playlist seguida: {pl.name}")

            return playlists_info

        except Exception as e:
            print(f"[PLAYLISTS] Error al obtener playlists del usuario: {e}")
            return []

    def check_session(self) -> bool:
        """Verificar si hay una sesión activa"""
        try:
            return self.session.check_login()
        except Exception:
            return False

# Instancia global del servicio
tidal_service = TidalService() 