// ignore_for_file: unused_local_variable, depend_on_referenced_packages, deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'package:musicplayer/domain/entities/cancion.dart';
import 'package:musicplayer/domain/models/cancion_model.dart' as model;
import 'package:musicplayer/domain/repositories/cancion_repository.dart';
import 'package:musicplayer/domain/repositories/configuracion_repository.dart';
import 'package:musicplayer/domain/services/hive_database_service.dart';

/// Modo de búsqueda interno
enum SearchMode { general, name, artist }

/// Repositorio de canciones que combina Tidal, YouTube y almacenamiento local
class CancionRepositoryImpl implements CancionRepository {
  final ConfiguracionRepository _configRepo;
  final YoutubeExplode _yt = YoutubeExplode();
  final Map<String, List<Cancion>> _searchCache = {};
  static const _cacheExpiration = Duration(minutes: 30);
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, String> _compressedCache =
      {}; // Nuevo caché para respuestas comprimidas

  CancionRepositoryImpl(this._configRepo) {
    print('[INIT] CancionRepositoryImpl inicializado');
    _initializeCache();
  }

  void _initializeCache() {
    // Limpiar caché expirado al iniciar
    final now = DateTime.now();
    _cacheTimestamps.removeWhere(
      (key, timestamp) => now.difference(timestamp) > _cacheExpiration,
    );
    _searchCache.removeWhere((key, _) => !_cacheTimestamps.containsKey(key));
  }

  String _compressResponse(List<Cancion> canciones) {
    return jsonEncode(
      canciones.map((c) => model.Cancion.fromEntity(c).toMap()).toList(),
    );
  }

  List<Cancion> _decompressResponse(String compressed) {
    final List<dynamic> decoded = jsonDecode(compressed);
    return decoded
        .map((json) => model.Cancion.fromJson(json).toEntity())
        .toList();
  }

  Future<List<Cancion>> _getFromCache(String query, SearchMode mode) async {
    final cacheKey = '${query}_${mode.name}';
    final timestamp = _cacheTimestamps[cacheKey];

    if (timestamp != null &&
        DateTime.now().difference(timestamp) < _cacheExpiration) {
      if (_compressedCache.containsKey(cacheKey)) {
        print('[CACHE] Usando respuesta comprimida en caché para $cacheKey');
        return _decompressResponse(_compressedCache[cacheKey]!);
      }
    }
    return [];
  }

  void _saveToCache(String query, SearchMode mode, List<Cancion> results) {
    final cacheKey = '${query}_${mode.name}';
    _cacheTimestamps[cacheKey] = DateTime.now();
    _compressedCache[cacheKey] = _compressResponse(results);
    print('[CACHE] Guardando respuesta comprimida en caché para $cacheKey');
  }

  /*─────────────────────────── HELPERS ───────────────────────────*/

  /// Selecciona la mejor carátula disponible para un video de YouTube
  Future<String> _bestYoutubeCover(String videoId) async {
    print('[YOUTUBE] _bestYoutubeCover iniciado con videoId=$videoId');
    const resolutions = [
      'maxresdefault.jpg',
      'hqdefault.jpg',
      'mqdefault.jpg',
      'default.jpg',
    ];
    for (final res in resolutions) {
      final url = 'https://img.youtube.com/vi/$videoId/$res';
      print('[YOUTUBE] Probando carátula: $url');
      final head = await http.head(Uri.parse(url));
      print('[YOUTUBE] Estado HTTP: ${head.statusCode}');
      if (head.statusCode == 200) {
        print('[YOUTUBE] Carátula encontrada: $url');
        return url;
      }
    }
    final fallback = 'https://img.youtube.com/vi/$videoId/default.jpg';
    print('[YOUTUBE] Usando carátula por defecto: $fallback');
    return fallback;
  }

  Future<String> _saveBytes(List<int> bytes, String filename) async {
    print(
      '[SAVE] _saveBytes iniciado con filename=$filename, bytes=${bytes.length}',
    );
    final dir = await getApplicationDocumentsDirectory();
    print('[SAVE] Directorio de documentos: ${dir.path}');
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    print('[SAVE] Archivo guardado en: ${file.path}');
    return file.path;
  }

  List<OrigenCancion> _priority(String quality) {
    print('[CONFIG] Determinando prioridad para calidad=$quality');
    switch (quality) {
      case 'LOW':
      case 'HIGH':
        print('[CONFIG] Orden: tidal, local, youtube');
        return [
          OrigenCancion.tidal,
          OrigenCancion.local,
          OrigenCancion.youtube,
        ];
      default: // LOSSLESS | HI_RES_LOSSLESS
        print('[CONFIG] Orden: local, tidal, youtube');
        return [
          OrigenCancion.local,
          OrigenCancion.tidal,
          OrigenCancion.youtube,
        ];
    }
  }

  /*─────────────── ID/URL PARSING ───────────────*/

  String? _tidalIdFromUrl(String url) {
    print('[TIDAL] _tidalIdFromUrl parsing url=$url');
    final uri = Uri.tryParse(url);
    if (uri == null) {
      print('[TIDAL] URL inválida');
      return null;
    }
    final idx = uri.pathSegments.indexOf('track');
    final id =
        (idx != -1 && idx + 1 < uri.pathSegments.length)
            ? uri.pathSegments[idx + 1]
            : null;
    print('[TIDAL] ID extraído: $id');
    return id;
  }

  String? _youtubeIdFromUrl(String url) {
    print('[YOUTUBE] _youtubeIdFromUrl parsing url=$url');
    final uri = Uri.tryParse(url);
    if (uri == null) {
      print('[YOUTUBE] URL inválida');
      return null;
    }
    if (uri.host.contains('youtu')) {
      final id = uri.queryParameters['v'] ?? uri.pathSegments.last;
      print('[YOUTUBE] ID extraído: $id');
      return id;
    }
    print('[YOUTUBE] No es URL de YouTube');
    return null;
  }

  /*─────────────────────── TIDAL ───────────────────────*/

  Future<List<Cancion>> _tidalSearch(String q, {int limit = 10}) async {
    print('[TIDAL] _tidalSearch iniciado con query="$q", limit=$limit');
    final api = await _configRepo.obtenerTidalApiUrl();
    print('[TIDAL] URL base API Tidal: $api');
    if (api == null) return [];
    final url =
        '$api/tidal/search?query=${Uri.encodeComponent(q)}&limit=$limit';
    print('[TIDAL] GET $url');
    final res = await http.get(Uri.parse(url));
    print('[TIDAL] Estado HTTP: ${res.statusCode}');
    if (res.statusCode != 200) return [];
    final tracks =
        (jsonDecode(res.body)['tracks'] as List)
            .map((e) => Cancion.fromMap(e, origen: OrigenCancion.tidal))
            .toList();
    print('[TIDAL] Canciones encontradas: ${tracks.length}');
    for (final t in tracks) {
      print('[TIDAL] Guardando en Hive: ${t.name}');
      await HiveDatabaseService.saveCancion(t);
    }
    return tracks;
  }

  Future<List<Cancion>> _tidalAlbum(String albumName) async {
    print('[TIDAL] _tidalAlbum iniciado con albumName="$albumName"');
    final api = await _configRepo.obtenerTidalApiUrl();
    if (api == null) return [];
    final searchUrl =
        '$api/tidal/search/albums?query=${Uri.encodeComponent(albumName)}';
    print('[TIDAL] GET $searchUrl');
    final res = await http.get(Uri.parse(searchUrl));
    print('[TIDAL] Estado HTTP: ${res.statusCode}');
    if (res.statusCode != 200) return [];
    final albums = jsonDecode(res.body)['albums'] as List;
    final out = <Cancion>[];
    print('[TIDAL] Álbumes encontrados: ${albums.length}');
    for (final alb in albums) {
      final albUrl = '$api/tidal/album/${alb['id']}';
      print('[TIDAL] GET $albUrl');
      final albRes = await http.get(Uri.parse(albUrl));
      print('[TIDAL] Estado HTTP álbum: ${albRes.statusCode}');
      if (albRes.statusCode != 200) continue;
      final tracks = (jsonDecode(albRes.body)['tracks'] as List?) ?? [];
      print('[TIDAL] Pistas en álbum: ${tracks.length}');
      for (final tr in tracks) {
        final c = Cancion.fromMap(tr, origen: OrigenCancion.tidal);
        print('[TIDAL] Guardando pista: ${c.name}');
        await HiveDatabaseService.saveCancion(c);
        out.add(c);
      }
    }
    return out;
  }

  Future<List<Cancion>> _tidalArtist(String title, String artist) async {
    print('[TIDAL] _tidalArtist iniciado con title="$title", artist="$artist"');
    final api = await _configRepo.obtenerTidalApiUrl();
    if (api == null) return [];
    final uri =
        '$api/tidal/search/artist?title=${Uri.encodeComponent(title)}&artist=${Uri.encodeComponent(artist)}';
    print('[TIDAL] GET $uri');
    final res = await http.get(Uri.parse(uri));
    print('[TIDAL] Estado HTTP: ${res.statusCode}');
    if (res.statusCode != 200) return [];
    final tracks =
        (jsonDecode(res.body)['tracks'] as List)
            .map((e) => Cancion.fromMap(e, origen: OrigenCancion.tidal))
            .toList();
    print('[TIDAL] Pistas por artista encontradas: ${tracks.length}');
    for (final t in tracks) {
      print('[TIDAL] Guardando: ${t.name}');
      await HiveDatabaseService.saveCancion(t);
    }
    return tracks;
  }

  Future<Cancion?> _tidalTrackById(String id) async {
    print('[TIDAL] _tidalTrackById iniciado con id=$id');
    final api = await _configRepo.obtenerTidalApiUrl();
    if (api == null) return null;
    final url = '$api/tidal/track/$id';
    print('[TIDAL] GET $url');
    final res = await http.get(Uri.parse(url));
    print('[TIDAL] Estado HTTP: ${res.statusCode}');
    if (res.statusCode != 200) return null;
    final c = Cancion.fromMap(
      jsonDecode(res.body),
      origen: OrigenCancion.tidal,
    );
    print('[TIDAL] Canción obtenida: ${c.name}');
    await HiveDatabaseService.saveCancion(c);
    return c;
  }

  Future<String?> _tidalStreamUrl(String id) async {
    print('[TIDAL] _tidalStreamUrl iniciado con id=$id');
    final api = await _configRepo.obtenerTidalApiUrl();
    if (api == null) return null;
    final url = '$api/tidal/track/$id/download-info';
    print('[TIDAL] GET $url');
    final res = await http.get(Uri.parse(url));
    print('[TIDAL] Estado HTTP: ${res.statusCode}');
    if (res.statusCode != 200) return null;
    final streamUrl = jsonDecode(res.body)['stream_url'];
    print('[TIDAL] Stream URL: $streamUrl');
    return streamUrl;
  }

  /*─────────────────────── YOUTUBE ───────────────────────*/

  /// Búsqueda optimizada en YouTube: stream + top 10 + portada homogénea
  Future<List<Cancion>> _youtubeSearch(String q) async {
    print('[YOUTUBE] _youtubeSearch iniciado con query="$q" (max 10)');

    // Espera el resultado completo y corta a 10
    final result = await _yt.search.getVideos(q);
    final videos = result.take(10).toList();

    print('[YOUTUBE] Videos obtenidos (max 10): ${videos.length}');

    // Definimos las resoluciones en orden preferido
    const resolutions = [
      'maxresdefault.jpg',
      'hqdefault.jpg',
      'mqdefault.jpg',
      'default.jpg',
    ];

    // Descubrimos la primera resolución válida
    String chosenRes = resolutions.last;
    for (final v in videos) {
      for (final res in resolutions) {
        final url = 'https://img.youtube.com/vi/${v.id.value}/$res';
        final head = await http.head(Uri.parse(url));
        if (head.statusCode == 200) {
          chosenRes = res;
          print('[YOUTUBE] Calidad de portada elegida: $chosenRes');
          break;
        }
      }
      if (chosenRes != resolutions.last) break;
    }

    // Construimos entidades Cancion
    final out = <Cancion>[];
    for (final v in videos) {
      final coverUrl = 'https://img.youtube.com/vi/${v.id.value}/$chosenRes';
      final c = Cancion(
        youtubeId: v.id.value,
        name: v.title,
        artist: v.author,
        album: '',
        duration: v.duration?.inSeconds ?? 0,
        streamUrl: 'https://www.youtube.com/watch?v=${v.id.value}',
        coverUrl: coverUrl,
        origen: OrigenCancion.youtube,
      );
      await HiveDatabaseService.saveCancion(c);
      out.add(c);
    }

    return out;
  }

  Future<Cancion?> _youtubeById(String id) async {
    print('[YOUTUBE] _youtubeById iniciado con id=$id');
    try {
      final v = await _yt.videos.get(id);
      print('[YOUTUBE] Video obtenido: ${v.title}');
      final c = Cancion(
        youtubeId: v.id.value,
        name: v.title,
        artist: v.author,
        album: '',
        duration: v.duration?.inSeconds ?? 0,
        streamUrl: 'https://www.youtube.com/watch?v=${v.id.value}',
        coverUrl: await _bestYoutubeCover(v.id.value),
        origen: OrigenCancion.youtube,
      );
      await HiveDatabaseService.saveCancion(c);
      return c;
    } catch (e) {
      print('[YOUTUBE] Error al obtener video: $e');
      return null;
    }
  }

  /*─────────────────────── LOCAL ───────────────────────*/

  Future<List<Cancion>> _localSearch(String q, bool byArtist) async {
    print('[LOCAL] _localSearch iniciado con query="$q", byArtist=$byArtist');
    final box = await Hive.openBox<model.Cancion>('canciones');
    final indexBox = await Hive.openBox('search_indices');
    print('[LOCAL] Box abierto, registros actuales: ${box.length}');

    // Normalizar la consulta
    final query = q.toLowerCase().trim();

    // Crear índices si no existen
    if (!indexBox.containsKey('_index_name')) {
      final nameIndex = <String, List<String>>{};
      final artistIndex = <String, List<String>>{};

      for (final key in box.keys) {
        if (key is String && !key.startsWith('_')) {
          final cancion = box.get(key);
          if (cancion != null) {
            // Índice por nombre
            final words = cancion.name.toLowerCase().split(' ');
            for (final word in words) {
              if (word.isNotEmpty) {
                nameIndex.putIfAbsent(word, () => []).add(key);
              }
            }

            // Índice por artista
            final artistWords = cancion.artist.toLowerCase().split(' ');
            for (final word in artistWords) {
              if (word.isNotEmpty) {
                artistIndex.putIfAbsent(word, () => []).add(key);
              }
            }
          }
        }
      }

      await indexBox.put('_index_name', nameIndex);
      await indexBox.put('_index_artist', artistIndex);
    }

    // Obtener índices
    final nameIndex = indexBox.get('_index_name') as Map<String, List<String>>?;
    final artistIndex =
        indexBox.get('_index_artist') as Map<String, List<String>>?;

    if (nameIndex == null || artistIndex == null) {
      // Fallback a búsqueda lineal si no hay índices
      final results =
          box.values
              .where(
                (c) =>
                    byArtist
                        ? c.artist.toLowerCase().contains(query)
                        : c.name.toLowerCase().contains(query),
              )
              .map((c) => c.toEntity())
              .toList();
      print('[LOCAL] Coincidencias encontradas (fallback): ${results.length}');
      return results;
    }

    // Búsqueda usando índices
    final Set<String> matchingKeys = {};
    final queryWords = query.split(' ');

    for (final word in queryWords) {
      if (word.isNotEmpty) {
        if (byArtist) {
          final artistMatches = artistIndex[word] ?? [];
          matchingKeys.addAll(artistMatches);
        } else {
          final nameMatches = nameIndex[word] ?? [];
          matchingKeys.addAll(nameMatches);
        }
      }
    }

    final results =
        matchingKeys
            .map((key) => box.get(key))
            .where((c) => c != null)
            .map((c) => c!.toEntity())
            .toList();

    print('[LOCAL] Coincidencias encontradas (índices): ${results.length}');
    return results;
  }

  Future<List<Cancion>> _localByOrigen(OrigenCancion origen) async {
    print('[LOCAL] _localByOrigen iniciado con origen=$origen');
    final box = await Hive.openBox<model.Cancion>('canciones');
    final results =
        box.values
            .where((e) => e.origen == origen.name)
            .map((e) => e.toEntity())
            .toList();
    print(
      '[LOCAL] Canciones locales por origen (${origen.name}): ${results.length}',
    );
    return results;
  }

  /*─────────────────────── PUBLIC API IMPLEMENTATION ───────────────────────*/

  @override
  Future<List<Cancion>> buscarCanciones(String query, {int limit = 10}) =>
      _aggregatedSearch(query, SearchMode.general, limit: limit);

  @override
  Future<List<Cancion>> buscarPorNombre(String nombre, {int limit = 10}) =>
      _aggregatedSearch(nombre, SearchMode.name, limit: limit);

  @override
  Future<List<Cancion>> buscarPorArtista(String artista, {int limit = 10}) =>
      _aggregatedSearch(artista, SearchMode.artist, limit: limit);

  @override
  Future<List<Cancion>> buscarPorAlbum(String album) {
    print('[API] buscarPorAlbum iniciado con album="$album"');
    return _tidalAlbum(album);
  }

  @override
  Future<List<Cancion>> buscarLocalesPorNombre(String nombre) {
    print('[API] buscarLocalesPorNombre iniciado con nombre="$nombre"');
    return _localSearch(nombre, false);
  }

  @override
  Future<List<Cancion>> buscarLocalesPorArtista(String artista) {
    print('[API] buscarLocalesPorArtista iniciado con artista="$artista"');
    return _localSearch(artista, true);
  }

  @override
  Future<List<Cancion>> buscarYTComoFallback(String query) {
    print('[API] buscarYTComoFallback iniciado con query="$query"');
    return _youtubeSearch(query);
  }

  Future<List<Cancion>> _aggregatedSearch(
    String q,
    SearchMode mode, {
    int limit = 10,
  }) async {
    print(
      '[SEARCH] _aggregatedSearch iniciado con q="$q", mode=$mode, limit=$limit',
    );

    // Intentar obtener de caché primero
    final cachedResults = await _getFromCache(q, mode);
    if (cachedResults.isNotEmpty) {
      return cachedResults;
    }

    final config = await _configRepo.obtenerConfiguracionUsuario();
    print('[SEARCH] Configuración usuario obtenida');
    final order = _priority(config.calidadPreferida);
    print('[SEARCH] Orden de orígenes: $order');
    final out = <Cancion>[];

    for (final origen in order) {
      print('[SEARCH] Intentando origen: $origen');
      try {
        switch (origen) {
          case OrigenCancion.tidal:
            final list =
                (mode == SearchMode.artist)
                    ? await _tidalArtist(q, q)
                    : await _tidalSearch(q, limit: limit);
            out.addAll(list);
            break;
          case OrigenCancion.local:
            final list = await _localSearch(q, mode == SearchMode.artist);
            out.addAll(list);
            break;
          case OrigenCancion.youtube:
            final list = await _youtubeSearch(q);
            out.addAll(list);
            break;
        }
        print('[SEARCH] Resultados acumulados: ${out.length}');
      } catch (e) {
        print('[SEARCH] Error con origen $origen: $e');
        continue;
      }
    }

    // Guardar en caché
    _saveToCache(q, mode, out);
    return out;
  }

  @override
  Stream<List<Cancion>> buscarCancionesLazy(String q) async* {
    print('[LAZY] Iniciando búsqueda lazy para "$q"');
    final config = await _configRepo.obtenerConfiguracionUsuario();
    final order = _priority(config.calidadPreferida);
    final List<Cancion> acumulado = [];
    final Set<String> idsProcesados = {}; // Para evitar duplicados

    for (final origen in order) {
      try {
        List<Cancion> listaParcial;
        switch (origen) {
          case OrigenCancion.tidal:
            listaParcial = await _tidalSearch(q);
            break;
          case OrigenCancion.local:
            listaParcial = await _localSearch(q, false);
            break;
          case OrigenCancion.youtube:
            listaParcial = await _youtubeSearch(q);
            break;
        }

        // Filtrar duplicados
        final nuevasCanciones =
            listaParcial.where((c) {
              final id = c.id?.toString() ?? c.youtubeId ?? '';
              if (idsProcesados.contains(id)) return false;
              idsProcesados.add(id);
              return true;
            }).toList();

        acumulado.addAll(nuevasCanciones);
        print('[LAZY] Emitiendo ${acumulado.length} resultados tras $origen');
        yield List<Cancion>.from(acumulado);
      } catch (e) {
        print('[LAZY] Error en $origen: $e');
      }
    }
  }

  @override
  Stream<List<Cancion>> buscarCancionesFiltradasLazy(
    String query,
    List<String> origenes,
  ) async* {
    print('[LAZY+FILTRO] Búsqueda lazy con filtros: $origenes para "$query"');
    final List<Cancion> acumulado = [];
    final Set<String> idsProcesados = {}; // Para evitar duplicados

    for (final origenStr in origenes) {
      final origen = OrigenCancion.values.firstWhere(
        (e) => e.name == origenStr,
        orElse: () => OrigenCancion.local,
      );

      try {
        List<Cancion> listaParcial = [];
        switch (origen) {
          case OrigenCancion.tidal:
            listaParcial = await _tidalSearch(query);
            break;
          case OrigenCancion.youtube:
            listaParcial = await _youtubeSearch(query);
            break;
          case OrigenCancion.local:
            listaParcial = await _localSearch(query, false);
            break;
        }

        // Filtrar duplicados
        final nuevasCanciones =
            listaParcial.where((c) {
              final id = c.id?.toString() ?? c.youtubeId ?? '';
              if (idsProcesados.contains(id)) return false;
              idsProcesados.add(id);
              return true;
            }).toList();

        acumulado.addAll(nuevasCanciones);
        print(
          '[LAZY+FILTRO] Emitiendo ${acumulado.length} acumuladas tras $origenStr',
        );
        yield List<Cancion>.from(acumulado);
      } catch (e) {
        print('[LAZY+FILTRO] Error en $origenStr: $e');
      }
    }
  }

  /*────────── BY ID OR LINK ─────────*/

  @override
  Future<Cancion?> obtenerCancionPorId(String input) async {
    print('[API] obtenerCancionPorId iniciado con input="$input"');
    // Detect link or raw id automatically
    final tidalId =
        _tidalIdFromUrl(input) ??
        (RegExp(r'^[0-9]{6,}$').hasMatch(input) ? input : null);
    if (tidalId != null) {
      print('[API] ID Tidal detectado: $tidalId');
      final localBox = await Hive.openBox<model.Cancion>('canciones');
      final cached = localBox.get(tidalId);
      if (cached != null) {
        print('[API] Canción encontrada en caché Tidal: ${cached.name}');
        return cached.toEntity();
      }
      return await _tidalTrackById(tidalId);
    }

    final ytId =
        _youtubeIdFromUrl(input) ??
        (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(input) ? input : null);
    if (ytId != null) {
      print('[API] ID YouTube detectado: $ytId');
      final localBox = await Hive.openBox<model.Cancion>('canciones');
      final cached = localBox.values.firstWhere(
        (c) => c.youtubeId == ytId,
        orElse:
            () => model.Cancion(
              name: '',
              artist: '',
              album: '',
              duration: 0,
              origen: OrigenCancion.youtube.name,
            ),
      );
      if (cached.youtubeId != null) {
        print('[API] Canción encontrada en caché YouTube: ${cached.name}');
        return cached.toEntity();
      }
      return await _youtubeById(ytId);
    }

    print('[API] No se pudo interpretar input: $input');
    return null;
  }

  /*────────── STREAM URL ─────────*/

  @override
  Future<String?> obtenerUrlStream(String trackId) async {
    print('[API] obtenerUrlStream iniciado con trackId=$trackId');
    final box = await Hive.openBox<model.Cancion>('canciones');
    final local = box.get(trackId);
    if (local != null && local.streamUrl != null) {
      print('[API] Stream URL desde caché: ${local.streamUrl}');
      return local.streamUrl;
    }
    print('[API] Obteniendo Stream URL de Tidal');
    return _tidalStreamUrl(trackId);
  }

  /*────────── DOWNLOAD ─────────*/

  @override
  Future<String?> descargarCancion(Cancion cancion) async {
    print('[DOWNLOAD] descargarCancion iniciado para ${cancion.name}');

    if (cancion.localPath != null) {
      print('[DOWNLOAD] Ya existe localPath: ${cancion.localPath}');
      return cancion.localPath;
    }

    final configUser = await _configRepo.obtenerConfiguracionUsuario();
    final downloadsDir =
        Directory(
          configUser.carpetaDescargas.isNotEmpty
              ? configUser.carpetaDescargas
              : (await getApplicationDocumentsDirectory()).path,
        ).path;

    print('[DOWNLOAD] Descargas dir: $downloadsDir');

    try {
      final client = http.Client();

      // ──────────── YouTube ────────────
      if (cancion.origen == OrigenCancion.youtube &&
          cancion.streamUrl != null) {
        print('[DOWNLOAD] Descargando desde YouTube URL=${cancion.streamUrl}');
        final request = http.Request('GET', Uri.parse(cancion.streamUrl!));
        final response = await client
            .send(request)
            .timeout(const Duration(seconds: 60));
        final bytes = await response.stream.toBytes();

        print('[DOWNLOAD] Estado HTTP: ${response.statusCode}');
        if (response.statusCode == 200) {
          final filePath = await _saveBytes(
            bytes,
            '${cancion.name}-${cancion.artist}.mp3',
          );
          final updated = cancion.copyWith(localPath: filePath);
          await HiveDatabaseService.saveCancion(updated);
          print('[DOWNLOAD] ← Path en entidad: ${updated.localPath}');
          return filePath;
        }
      }

      // ──────────── Tidal ────────────
      if (cancion.origen == OrigenCancion.tidal && cancion.id != null) {
        print('[DOWNLOAD] Descargando desde Tidal ID=${cancion.id}');
        final stream = await _tidalStreamUrl(cancion.id!.toString());
        if (stream != null) {
          print('[DOWNLOAD] Stream obtenido: $stream');
          final request = http.Request('GET', Uri.parse(stream));
          final response = await client
              .send(request)
              .timeout(const Duration(seconds: 60));
          final bytes = await response.stream.toBytes();

          print('[DOWNLOAD] Estado HTTP: ${response.statusCode}');
          if (response.statusCode == 200) {
            final filePath = await _saveBytes(
              bytes,
              '${cancion.name}-${cancion.artist}.flac',
            );
            final updated = cancion.copyWith(localPath: filePath);
            await HiveDatabaseService.saveCancion(updated);
            print('[DOWNLOAD] ← Path en entidad: ${updated.localPath}');
            return filePath;
          }
        }
      }
    } catch (e) {
      print('[DOWNLOAD] Error durante descarga: $e');
    }

    print('[DOWNLOAD] No se pudo descargar la canción');
    return null;
  }

  /*────────── LOCAL MANAGEMENT ─────────*/

  @override
  Future<List<Cancion>> obtenerCancionesLocales() async {
    print('[LOCAL] obtenerCancionesLocales iniciado');
    final box = await Hive.openBox<model.Cancion>('canciones');
    final list = box.values.map((e) => e.toEntity()).toList();
    print('[LOCAL] Total canciones locales: ${list.length}');
    return list;
  }

  @override
  Future<void> eliminarCancionLocal(String cancionId) async {
    print('[LOCAL] eliminarCancionLocal iniciado con cancionId=$cancionId');
    final box = await Hive.openBox<model.Cancion>('canciones');
    await box.delete(cancionId);
    print('[LOCAL] Canción eliminada del box: $cancionId');
  }

  @override
  Future<bool> estaDescargada(String cancionId) async {
    print('[LOCAL] estaDescargada iniciado con cancionId=$cancionId');
    final box = await Hive.openBox<model.Cancion>('canciones');
    final c = box.get(cancionId);
    final exists =
        c != null && c.localPath != null && File(c.localPath!).existsSync();
    print('[LOCAL] Descargada? $exists');
    return exists;
  }

  @override
  Future<List<Cancion>> obtenerPorOrigen(OrigenCancion origen) {
    print('[LOCAL] obtenerPorOrigen iniciado con origen=$origen');
    return _localByOrigen(origen);
  }
}
