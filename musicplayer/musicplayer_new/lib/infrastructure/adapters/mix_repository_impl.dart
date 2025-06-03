// ignore_for_file: unused_import, depend_on_referenced_packages

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:musicplayer/domain/entities/mix.dart';
import 'package:musicplayer/domain/entities/cancion.dart';
import 'package:musicplayer/domain/models/mix_model.dart' as model;
import 'package:musicplayer/domain/models/cancion_model.dart' as model_c;
import 'package:musicplayer/domain/repositories/mix_repository.dart';
import 'package:musicplayer/domain/repositories/configuracion_repository.dart';
import 'package:musicplayer/domain/services/hive_database_service.dart';

/// Implementación que consulta la API FastAPI de Tidal y cachea en Hive
class MixRepositoryImpl implements MixRepository {
  final ConfiguracionRepository _configRepo;

  MixRepositoryImpl(this._configRepo);

  Future<String?> _baseUrl() => _configRepo.obtenerTidalApiUrl();

  @override
  Future<List<Mix>> obtenerMixes() async {
    final url = await _baseUrl();
    if (url == null) return [];
    final res = await http.get(Uri.parse('$url/tidal/mixes'));
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body)['mixes'] as List;
    final mixes = data.map((e) => Mix.fromMap(e)).toList();

    // Guardar en Hive
    final box = await Hive.openBox<model.Mix>('mixes');
    for (final m in mixes) {
      await box.put(m.id, model.Mix.fromEntity(m));
    }
    return mixes;
  }

  @override
  Future<Mix?> obtenerInfoMix(String mixId) async {
    // intenta cache
    final box = await Hive.openBox<model.Mix>('mixes');
    final cached = box.get(mixId);
    if (cached != null) return cached.toEntity();

    final url = await _baseUrl();
    if (url == null) return null;
    final res = await http.get(Uri.parse('$url/tidal/mix/$mixId'));
    if (res.statusCode != 200) return null;
    final mix = Mix.fromMap(jsonDecode(res.body));
    await HiveDatabaseService.saveMix(mix);
    return mix;
  }

  @override
  Future<List<Cancion>> obtenerCancionesDeMix(String mixId) async {
    final url = await _baseUrl();
    if (url == null) return [];
    final res = await http.get(Uri.parse('$url/tidal/mix/$mixId/tracks'));
    if (res.statusCode != 200) return [];
    final tracks =
        (jsonDecode(res.body)['tracks'] as List)
            .map((e) => Cancion.fromMap(e, origen: OrigenCancion.tidal))
            .toList();

    // Guardar canciones en Hive
    for (final c in tracks) {
      await HiveDatabaseService.saveCancion(c);
    }
    return tracks;
  }
}
