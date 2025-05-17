// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:musicplayer/domain/entities/playlist.dart' as entity_p;
import 'package:musicplayer/domain/entities/cancion.dart' as entity_c;
import 'package:musicplayer/domain/models/cancion_model.dart' as model;
import 'package:musicplayer/domain/models/playlist_model.dart' as model;
import 'package:musicplayer/domain/repositories/playlist_repository.dart';
import 'package:musicplayer/domain/repositories/configuracion_repository.dart';
import 'package:musicplayer/domain/services/hive_database_service.dart';

/// Implementación de [PlaylistRepository] integrando la API FastAPI de Tidal
/// y cache en Hive.
class PlaylistRepositoryImpl implements PlaylistRepository {
  final ConfiguracionRepository _configRepo;

  PlaylistRepositoryImpl(this._configRepo);

  Future<String?> _baseUrl() => _configRepo.obtenerTidalApiUrl();

  /*────────────────────── LISTA DE PLAYLISTS ──────────────────────*/

  @override
  Future<List<entity_p.Playlist>> obtenerPlaylists() async {
    final url = await _baseUrl();
    if (url == null) return [];

    final box = await Hive.openBox<model.Playlist>('playlists');
    await box.clear(); // Limpia todas las playlists locales

    try {
      final res = await http.get(Uri.parse('$url/tidal/user/playlists'));
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body)['playlists'] as List;
      final playlists = data.map((e) => entity_p.Playlist.fromMap(e)).toList();

      for (final playlist in playlists) {
        await HiveDatabaseService.savePlaylist(playlist);
        final tracks = await obtenerCancionesDePlaylist(playlist.id);
        playlist.setCanciones = tracks;
        playlist.setNumeroCanciones = tracks.length;
        playlist.setDuracion = tracks.fold(0, (sum, c) => sum + c.duration);
        await HiveDatabaseService.savePlaylist(playlist); // actualiza
      }

      return playlists;
    } catch (e) {
      print('[PlaylistRepositoryImpl] Error al obtener playlists: $e');
      return [];
    }
  }

  /*───────────────── PISTAS DE UNA PLAYLIST ─────────────────*/

  @override
  Future<List<entity_c.Cancion>> obtenerCancionesDePlaylist(
    String playlistId,
  ) async {
    final url = await _baseUrl();
    if (url == null) return [];

    try {
      final res = await http.get(
        Uri.parse('$url/tidal/playlist/$playlistId/tracks'),
      );
      if (res.statusCode != 200) return [];

      final dynamic decoded = jsonDecode(res.body);
      List<dynamic> tracksJson;
      if (decoded is List) {
        tracksJson = decoded;
      } else if (decoded is Map && decoded.containsKey('tracks')) {
        tracksJson = decoded['tracks'] as List;
      } else {
        tracksJson = [];
      }

      final tracks =
          tracksJson
              .map(
                (e) => entity_c.Cancion.fromMap(
                  e,
                  origen: entity_c.OrigenCancion.tidal,
                ),
              )
              .toList();

      for (final c in tracks) {
        await HiveDatabaseService.saveCancion(c);
      }

      final box = await Hive.openBox<model.Playlist>('playlists');
      final cached = box.get(playlistId);
      if (cached != null) {
        cached.canciones =
            tracks.map((c) => model.Cancion.fromEntity(c)).toList();
        await box.put(playlistId, cached);
      }

      return tracks;
    } catch (e) {
      print(
        '[PlaylistRepositoryImpl] Error al obtener canciones de playlist: $e',
      );
      return [];
    }
  }

  /*─────────────── GESTIÓN DE PLAYLISTS LOCALES ───────────────*/

  @override
  Future<entity_p.Playlist> crearPlaylist(
    String nombre, {
    String? descripcion,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final nueva = entity_p.Playlist(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      creador: 'local',
      numeroCanciones: 0,
      duracion: 0,
      fechaCreacion: DateTime.now(),
      origen: entity_p.OrigenPlaylist.local,
      canciones: [],
    );
    await HiveDatabaseService.savePlaylist(nueva);
    return nueva;
  }

  @override
  Future<void> eliminarPlaylist(String playlistId) async {
    final box = await Hive.openBox<model.Playlist>('playlists');
    await box.delete(playlistId);
  }

  @override
  Future<void> agregarCancionAPlaylist(
    String playlistId,
    entity_c.Cancion cancion,
  ) async {
    final box = await Hive.openBox<model.Playlist>('playlists');
    final p = box.get(playlistId);
    if (p == null) return;

    p.canciones.add(model.Cancion.fromEntity(cancion));
    p.numeroCanciones = p.canciones.length;
    p.duracion += cancion.duration;

    await box.put(playlistId, p);
  }

  @override
  Future<void> eliminarCancionDePlaylist(
    String playlistId,
    String trackId,
  ) async {
    final box = await Hive.openBox<model.Playlist>('playlists');
    final p = box.get(playlistId);
    if (p == null) return;

    p.canciones.removeWhere((c) => c.id == trackId || c.youtubeId == trackId);
    p.numeroCanciones = p.canciones.length;
    p.duracion = p.canciones.fold(0, (sum, c) => sum + c.duration);

    await box.put(playlistId, p);
  }

  /*────────────────────── SYNC TOTAL ──────────────────────*/

  @override
  Future<void> syncPlaylistsAndTracks() async {
    final playlists = await obtenerPlaylists();
    for (final p in playlists) {
      await obtenerCancionesDePlaylist(p.id);
    }
  }
}
