import 'package:musicplayer/domain/entities/letra_cancion.dart' as entity;
import 'package:hive/hive.dart';
part 'letra_cancion_model.g.dart';

@HiveType(typeId: 3)
class LetraCancion extends HiveObject {
  @HiveField(0)
  String trackId;

  @HiveField(1)
  String trackName;

  @HiveField(2)
  String artist;

  @HiveField(3)
  String lyrics;

  @HiveField(4)
  String? language;

  @HiveField(5)
  String? source;

  LetraCancion({
    required this.trackId,
    required this.trackName,
    required this.artist,
    required this.lyrics,
    this.language,
    this.source,
  });

  factory LetraCancion.fromEntity(entity.LetraCancion l) => LetraCancion(
    trackId: l.trackId,
    trackName: l.trackName,
    artist: l.artist,
    lyrics: l.lyrics,
    language: l.language,
    source: l.source,
  );

  /// 🔽 Este método es el que te falta
  entity.LetraCancion toEntity() {
    return entity.LetraCancion(
      trackId: trackId,
      trackName: trackName,
      artist: artist,
      lyrics: lyrics,
      language: language,
      source: source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'track_id': trackId,
      'track_name': trackName,
      'artist': artist,
      'lyrics': lyrics,
      'language': language,
      'source': source,
    };
  }
}
