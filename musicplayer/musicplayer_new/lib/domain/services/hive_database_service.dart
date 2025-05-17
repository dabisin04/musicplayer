import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'package:musicplayer/domain/models/cancion_model.dart' as model;
import 'package:musicplayer/domain/models/playlist_model.dart' as model;
import 'package:musicplayer/domain/models/mix_model.dart' as model;
import 'package:musicplayer/domain/models/letra_cancion_model.dart' as model;

import 'package:musicplayer/domain/entities/cancion.dart' as entity;
import 'package:musicplayer/domain/entities/playlist.dart' as entity;
import 'package:musicplayer/domain/entities/mix.dart' as entity;
import 'package:musicplayer/domain/entities/letra_cancion.dart' as entity;

class HiveDatabaseService {
  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);

    Hive.registerAdapter(model.CancionAdapter());
    Hive.registerAdapter(model.PlaylistAdapter());
    Hive.registerAdapter(model.MixAdapter());
    Hive.registerAdapter(model.LetraCancionAdapter());

    await Hive.openBox<model.Cancion>('canciones');
    await Hive.openBox<model.Playlist>('playlists');
    await Hive.openBox<model.Mix>('mixes');
    await Hive.openBox<model.LetraCancion>('letras');
  }

  static Future<void> saveCancion(entity.Cancion cancion) async {
    final box = Hive.box<model.Cancion>('canciones');
    await box.put(
      cancion.id ?? cancion.youtubeId,
      model.Cancion.fromEntity(cancion),
    );
  }

  static Future<void> savePlaylist(entity.Playlist playlist) async {
    final box = Hive.box<model.Playlist>('playlists');
    await box.put(playlist.id, model.Playlist.fromEntity(playlist));
  }

  static Future<void> saveMix(entity.Mix mix) async {
    final box = Hive.box<model.Mix>('mixes');
    await box.put(mix.id, model.Mix.fromEntity(mix));
  }

  static Future<void> saveLetra(entity.LetraCancion letra) async {
    final box = Hive.box<model.LetraCancion>('letras');
    await box.put(letra.trackId, model.LetraCancion.fromEntity(letra));
  }

  static Future<File> exportDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final exportPath = File('${dir.path}/export_db.json');

    final canciones =
        Hive.box<model.Cancion>(
          'canciones',
        ).values.map((e) => e.toMap()).toList();
    final playlists =
        Hive.box<model.Playlist>(
          'playlists',
        ).values.map((e) => e.toMap()).toList();
    final mixes =
        Hive.box<model.Mix>('mixes').values.map((e) => e.toMap()).toList();
    final letras =
        Hive.box<model.LetraCancion>(
          'letras',
        ).values.map((e) => e.toMap()).toList();

    final exportData = {
      'canciones': canciones,
      'playlists': playlists,
      'mixes': mixes,
      'letras': letras,
    };

    await exportPath.writeAsString(jsonEncode(exportData));
    return exportPath;
  }
}
