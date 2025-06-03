// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:musicplayer/domain/entities/letra_cancion.dart' as entity;
import 'package:musicplayer/domain/entities/cancion.dart';
import 'package:musicplayer/domain/models/letra_cancion_model.dart' as model;
import 'package:musicplayer/domain/repositories/letra_repository.dart';
import 'package:musicplayer/domain/repositories/configuracion_repository.dart';
import 'package:musicplayer/domain/services/hive_database_service.dart';

class LetraRepositoryImpl implements LetraRepository {
  final ConfiguracionRepository configuracionRepository;

  LetraRepositoryImpl(this.configuracionRepository);

  @override
  Future<entity.LetraCancion?> obtenerLetraPorId(String trackId) async {
    final letraLocal = await obtenerLetraLocalPorId(trackId);
    if (letraLocal != null) return letraLocal;

    final tidalApiUrl = await configuracionRepository.obtenerTidalApiUrl();
    if (tidalApiUrl == null) return null;

    // 1. Intentar con Tidal directamente
    try {
      final tidalLyricsUri = Uri.parse(
        '$tidalApiUrl/tidal/track/$trackId/lyrics',
      );
      final tidalRes = await http.get(tidalLyricsUri);

      if (tidalRes.statusCode == 200) {
        final json = jsonDecode(tidalRes.body);
        final letra = entity.LetraCancion(
          trackId: trackId,
          trackName: json['track_name'] ?? json['name'] ?? '',
          artist: json['artist'] ?? '',
          lyrics: json['lyrics'] ?? '',
          language: json['language'] ?? json['lyrics_language'],
          source: 'Tidal',
        );
        await HiveDatabaseService.saveLetra(letra);
        return letra;
      }
    } catch (_) {}

    // 2. Obtener info de canción (para fallback)
    Cancion? cancion;
    try {
      final uri = Uri.parse('$tidalApiUrl/tidal/track/$trackId');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final json = Map<String, dynamic>.from(jsonDecode(res.body));
        cancion = Cancion.fromMap(json, origen: OrigenCancion.tidal);
      }
    } catch (_) {}

    if (cancion == null) return null;

    return await buscarLetraPorNombreYArtista(
      cancion.name,
      cancion.artist,
      cancionId: trackId,
    );
  }

  @override
  Future<entity.LetraCancion?> buscarLetraPorNombreYArtista(
    String title,
    String artist, {
    String? cancionId,
  }) async {
    final geniusApiUrl = await configuracionRepository.obtenerGeniusApiUrl();
    if (geniusApiUrl == null) return null;

    try {
      final uri = Uri.parse(
        '$geniusApiUrl/lyrics?title=${Uri.encodeComponent(title)}&artist=${Uri.encodeComponent(artist)}',
      );
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);

        if (json['error'] != null || json['lyrics'] == null) return null;

        final letra = entity.LetraCancion(
          trackId: cancionId ?? '',
          trackName: title,
          artist: artist,
          lyrics: json['lyrics'],
          language: json['language'],
          source: 'Genius',
        );
        await HiveDatabaseService.saveLetra(letra);
        return letra;
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<entity.LetraCancion?> obtenerLetraLocalPorId(String trackId) async {
    final box = await Hive.openBox<model.LetraCancion>('letras');
    final cached = box.get(trackId);
    return cached?.toEntity();
  }

  @override
  Future<List<entity.LetraCancion>> obtenerTodasLasLetrasLocales() async {
    final box = await Hive.openBox<model.LetraCancion>('letras');
    return box.values.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> borrarLetraPorId(String trackId) async {
    final box = await Hive.openBox<model.LetraCancion>('letras');
    await box.delete(trackId);
  }

  @override
  Future<void> limpiarLetras() async {
    final box = await Hive.openBox<model.LetraCancion>('letras');
    await box.clear();
  }
}
