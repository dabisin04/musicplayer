from fastapi import FastAPI, HTTPException, status, Request, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse, RedirectResponse
import os
from dotenv import load_dotenv
from .tidal_service import tidal_service, cache_response
import aiohttp
from .models import OutputFormat, VerificationUri
from typing import List, Dict, Any, Optional
import asyncio
import json
from datetime import datetime, timedelta
import gzip
from functools import lru_cache
from .config import configure_app

# Cargar variables de entorno
load_dotenv()

app = FastAPI(title="Tidal API")

# Configurar la aplicación
configure_app(app)

# Función para verificar la sesión
async def verify_session():
    if not tidal_service.session.check_login():
        login_link = await tidal_service.get_login_link()
        if not login_link:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Error al obtener link de login"
            )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "message": "Se requiere iniciar sesión",
                "login_url": login_link.get("verification_uri", login_link.get("verification_url"))
            }
        )
    return True

# Rutas de la API
@app.get("/login")
async def redirect_to_tidal_login():
    """Redirigir a la ruta de login de Tidal"""
    return RedirectResponse(url="/tidal/login", status_code=status.HTTP_307_TEMPORARY_REDIRECT)

@app.get("/login/")
async def redirect_to_tidal_login_with_slash():
    """Redirigir a la ruta de login de Tidal"""
    return RedirectResponse(url="/tidal/login", status_code=status.HTTP_307_TEMPORARY_REDIRECT)

@app.get("/tidal/login")
async def get_login_link(force_new: bool = False):
    """Obtener link de login de Tidal. Si force_new es True, se generará un nuevo código incluso si hay uno en caché."""
    result = await tidal_service.get_login_link(force_new=force_new)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error al obtener link de login"
        )
    return result

@app.get("/tidal/login/")
async def get_login_link_with_slash(force_new: bool = False):
    """Redirigir a la ruta sin slash"""
    return RedirectResponse(url=f"/tidal/login?force_new={str(force_new).lower()}", status_code=status.HTTP_307_TEMPORARY_REDIRECT)

@app.post("/tidal/login/verify")
async def verify_login(verification: VerificationUri):
    """Verificar el login con el código de verificación"""
    try:
        print(f"[VERIFY] Intentando verificar login con URI: {verification.get_uri()}")
        success = await tidal_service.process_login(verification.get_uri())
        if success:
            print("[VERIFY] Login verificado exitosamente")
            return {"status": "success", "message": "Login verificado exitosamente"}
        else:
            print("[VERIFY] Error al verificar el login")
            raise HTTPException(status_code=401, detail="Error al verificar el login")
    except Exception as e:
        print(f"[VERIFY] Error inesperado: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/tidal/login/verify/{code}")
@app.get("/tidal/login/verify/{code}")
async def verify_login_code(code: str):
    """Verificar el login con el código de verificación directamente en la URL"""
    try:
        print(f"[VERIFY] Intentando verificar login con código: {code}")
        verification_uri = f"link.tidal.com/{code}"
        success = await tidal_service.process_login(verification_uri)
        if success:
            print("[VERIFY] Login verificado exitosamente")
            return {"status": "success", "message": "Login verificado exitosamente"}
        else:
            print("[VERIFY] Error al verificar el login")
            raise HTTPException(status_code=401, detail="Error al verificar el login")
    except Exception as e:
        print(f"[VERIFY] Error inesperado: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/tidal/login/verify/")
async def verify_login_with_slash(verification: VerificationUri):
    """Redirigir a la ruta sin slash"""
    return RedirectResponse(url="/tidal/login/verify", status_code=status.HTTP_307_TEMPORARY_REDIRECT)

@app.get("/tidal/track/{track_id}")
@cache_response(expiration=timedelta(hours=1))
async def get_track_info(track_id: str, _: bool = Depends(verify_session)):
    """Obtener información de una pista con caché"""
    track_info = await tidal_service.get_track_info(track_id)
    if not track_info:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pista no encontrada"
        )
    return track_info

@app.get("/tidal/track/{track_id}/lyrics")
async def get_track_lyrics(track_id: str):
    lyrics = await tidal_service.get_lyrics(track_id)
    if not lyrics:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Letras no encontradas"
        )
    return lyrics

@app.get("/tidal/track/{track_id}/download-info")
async def get_track_download_info(track_id: str, cover_size: int = 1280):
    """Obtiene la información necesaria para descargar una pista
    
    Args:
        track_id: ID de la pista
        cover_size: Tamaño de la portada (80, 160, 320, 640, 1280). Por defecto 1280.
    """
    try:
        track = tidal_service.session.track(track_id)
        stream_url = await tidal_service.get_stream_url(track_id)
        lyrics = await tidal_service.get_lyrics(track_id)
        cover_url = await tidal_service.get_album_cover_url(track, size=cover_size)
        
        if not stream_url:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No se pudo obtener la URL de descarga"
            )
            
        return {
            "id": track.id,
            "name": track.name,
            "artist": track.artist.name,
            "album": track.album.name,
            "duration": track.duration,
            "stream_url": stream_url,
            "cover_url": cover_url,
            "lyrics": lyrics.get("lyrics") if lyrics else None,
            "lyrics_language": lyrics.get("language") if lyrics else None
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al obtener información de descarga: {str(e)}"
        )

@app.get("/tidal/stream/{track_id}")
async def stream_track(track_id: str):
    try:
        track = tidal_service.session.track(track_id)
        stream_url = await tidal_service.get_stream_url(track_id)
        lyrics = await tidal_service.get_lyrics(track_id)
        
        if not stream_url:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pista no encontrada o no disponible para streaming"
            )

        async def stream_generator():
            async with aiohttp.ClientSession() as session:
                async with session.get(stream_url) as response:
                    async for chunk in response.content.iter_chunked(8192):
                        yield chunk

        return StreamingResponse(
            stream_generator(),
            media_type="audio/mpeg",
            headers={
                "Content-Disposition": f'attachment; filename="{track_id}.mp3"',
                "X-Track-Name": track.name,
                "X-Artist-Name": track.artist.name,
                "X-Album-Name": track.album.name,
                "X-Lyrics": lyrics.get("lyrics") if lyrics else "",
                "X-Lyrics-Language": lyrics.get("language") if lyrics else ""
            }
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al obtener stream: {str(e)}"
        )

@app.get("/tidal/download/{track_id}")
async def download_track(track_id: str, output_path: str, format: OutputFormat = OutputFormat.flac):
    success = await tidal_service.download_track(track_id, output_path, format)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error al descargar la pista"
        )
    return {"message": "Pista descargada exitosamente", "path": f"{output_path}.{format}"}

@app.get("/tidal/search")
@cache_response(expiration=timedelta(minutes=30))
async def search_tracks(
    query: str = Query(..., description="Término de búsqueda"),
    limit: int = Query(10, ge=1, le=100, description="Número máximo de resultados")
):
    """Buscar canciones por nombre con caché"""
    try:
        print(f"[API] Búsqueda recibida - query: {query}, limit: {limit}")
        tracks = await tidal_service.search_tracks(query, limit)
        if not tracks:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No se encontraron canciones"
            )
        return {
            "query": query,
            "total_results": len(tracks),
            "tracks": tracks
        }
    except Exception as e:
        print(f"[API] Error en búsqueda: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al realizar la búsqueda: {str(e)}"
        )

@app.get("/tidal/search/")
async def search_tracks_with_slash(query: str, limit: int = 10):
    """Redirigir a la ruta sin slash"""
    return RedirectResponse(url=f"/tidal/search?query={query}&limit={limit}", status_code=status.HTTP_307_TEMPORARY_REDIRECT)

@app.get("/tidal/search/artist")
async def search_tracks_by_artist(title: str, artist: str, limit: int = 10):
    """Buscar canciones por título y artista"""
    tracks = await tidal_service.search_tracks_by_artist(title, artist, limit)
    if not tracks:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No se encontraron canciones"
        )
    return {
        "title": title,
        "artist": artist,
        "total_results": len(tracks),
        "tracks": tracks
    }

@app.get("/tidal/search/artist/")
async def search_tracks_by_artist_with_slash(title: str, artist: str, limit: int = 10):
    """Redirigir a la ruta sin slash"""
    return RedirectResponse(
        url=f"/tidal/search/artist?title={title}&artist={artist}&limit={limit}",
        status_code=status.HTTP_307_TEMPORARY_REDIRECT
    )

@app.get("/tidal/playlist/{playlist_id}")
async def get_playlist_info(playlist_id: str):
    playlist_info = await tidal_service.get_playlist_info(playlist_id)
    if not playlist_info:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Playlist no encontrada"
        )
    return playlist_info

@app.get("/tidal/playlist/{playlist_id}/tracks")
async def get_playlist_tracks(playlist_id: str):
    tracks = await tidal_service.get_playlist_tracks(playlist_id)
    if not tracks:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No se encontraron pistas en la playlist"
        )
    return tracks

@app.get("/tidal/playlist/{playlist_id}/download-info")
async def get_playlist_download_info(playlist_id: str):
    """Obtiene la información necesaria para descargar cada pista de la playlist"""
    try:
        playlist = tidal_service.session.playlist(playlist_id)
        tracks_info = []
        
        for track in playlist.tracks():
            stream_url = await tidal_service.get_stream_url(track.id)
            if stream_url:
                tracks_info.append({
                    "id": track.id,
                    "name": track.name,
                    "artist": track.artist.name,
                    "album": track.album.name,
                    "stream_url": stream_url,
                    "duration": track.duration
                })
        
        return {
            "playlist_name": playlist.name,
            "total_tracks": len(tracks_info),
            "tracks": tracks_info
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al obtener información de descarga: {str(e)}"
        )

@app.get("/tidal/mixes")
async def get_mixes():
    """Obtener todos los mixes disponibles"""
    mixes = await tidal_service.get_mixes()
    if not mixes:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No se encontraron mixes"
        )
    return {
        "total_mixes": len(mixes),
        "mixes": mixes
    }

@app.get("/tidal/mix/{mix_id}")
async def get_mix_info(mix_id: str):
    """Obtener información detallada de un mix específico"""
    mix_info = await tidal_service.get_mix_info(mix_id)
    if not mix_info:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mix no encontrado"
        )
    return mix_info

@app.get("/tidal/mix/{mix_id}/tracks")
async def get_mix_tracks(mix_id: str):
    """Obtener las pistas de un mix específico"""
    tracks = await tidal_service.get_mix_tracks(mix_id)
    if not tracks:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No se encontraron pistas en el mix"
        )
    return {
        "mix_id": mix_id,
        "total_tracks": len(tracks),
        "tracks": tracks
    }

@app.get("/tidal/album/{album_id}")
async def get_album_info(album_id: str):
    """Obtener información detallada de un álbum"""
    album_info = await tidal_service.get_album_info(album_id)
    if not album_info:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Álbum no encontrado"
        )
    return album_info

@app.get("/tidal/search/albums")
async def search_albums(query: str, limit: int = 10):
    """Buscar álbumes por nombre"""
    albums = await tidal_service.search_albums(query, limit)
    if not albums:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No se encontraron álbumes"
        )
    return {
        "query": query,
        "total_results": len(albums),
        "albums": albums
    }

@app.get("/tidal/search/albums/")
async def search_albums_with_slash(query: str, limit: int = 10):
    """Redirigir a la ruta sin slash"""
    return RedirectResponse(url=f"/tidal/search/albums?query={query}&limit={limit}", status_code=status.HTTP_307_TEMPORARY_REDIRECT)

@app.get("/tidal/search/albums/artist")
async def search_albums_by_artist(title: str, artist: str, limit: int = 10):
    """Buscar álbumes por título y artista"""
    albums = await tidal_service.search_albums_by_artist(title, artist, limit)
    if not albums:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No se encontraron álbumes"
        )
    return {
        "title": title,
        "artist": artist,
        "total_results": len(albums),
        "albums": albums
    }

@app.get("/tidal/search/albums/artist/")
async def search_albums_by_artist_with_slash(title: str, artist: str, limit: int = 10):
    """Redirigir a la ruta sin slash"""
    return RedirectResponse(
        url=f"/tidal/search/albums/artist?title={title}&artist={artist}&limit={limit}",
        status_code=status.HTTP_307_TEMPORARY_REDIRECT
    )

@app.get("/tidal/user/playlists")
async def get_user_playlists():
    """Obtener todas las playlists del usuario"""
    playlists = await tidal_service.get_user_playlists()
    if not playlists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No se encontraron playlists"
        )
    return {
        "total_playlists": len(playlists),
        "playlists": playlists
    }

@app.get("/tidal/user/playlists/")
async def get_user_playlists_with_slash():
    """Redirigir a la ruta sin slash"""
    return RedirectResponse(url="/tidal/user/playlists", status_code=status.HTTP_307_TEMPORARY_REDIRECT) 