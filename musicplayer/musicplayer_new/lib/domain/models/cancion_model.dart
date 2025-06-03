import 'package:hive/hive.dart';
import 'package:musicplayer/domain/entities/cancion.dart' as entity;
part 'cancion_model.g.dart';

@HiveType(typeId: 0)
class Cancion extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String? youtubeId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String artist;

  @HiveField(4)
  String album;

  @HiveField(5)
  int duration;

  @HiveField(6)
  String? quality;

  @HiveField(7)
  String? url;

  @HiveField(8)
  String? streamUrl;

  @HiveField(9)
  String? coverUrl;

  @HiveField(10)
  String? lyrics;

  @HiveField(11)
  String? lyricsLanguage;

  @HiveField(12)
  String origen;

  @HiveField(13)
  String? localPath;

  Cancion({
    this.id,
    this.youtubeId,
    required this.name,
    required this.artist,
    required this.album,
    required this.duration,
    this.quality,
    this.url,
    this.streamUrl,
    this.coverUrl,
    this.lyrics,
    this.lyricsLanguage,
    required this.origen,
    this.localPath,
  });

  factory Cancion.fromEntity(entity.Cancion c) => Cancion(
    id: c.id,
    youtubeId: c.youtubeId,
    name: c.name,
    artist: c.artist,
    album: c.album,
    duration: c.duration,
    quality: c.quality,
    url: c.url,
    streamUrl: c.streamUrl,
    coverUrl: c.coverUrl,
    lyrics: c.lyrics,
    lyricsLanguage: c.lyricsLanguage,
    origen: c.origen.name,
    localPath: c.localPath,
  );

  entity.Cancion toEntity() {
    return entity.Cancion(
      id: id,
      youtubeId: youtubeId,
      name: name,
      artist: artist,
      album: album,
      duration: duration,
      quality: quality,
      url: url,
      streamUrl: streamUrl,
      coverUrl: coverUrl,
      lyrics: lyrics,
      lyricsLanguage: lyricsLanguage,
      origen: entity.OrigenCancion.values.firstWhere(
        (e) => e.name == origen,
        orElse: () => entity.OrigenCancion.local,
      ),
      localPath: localPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'youtube_id': youtubeId,
      'name': name,
      'artist': artist,
      'album': album,
      'duration': duration,
      'quality': quality,
      'url': url,
      'stream_url': streamUrl,
      'cover_url': coverUrl,
      'lyrics': lyrics,
      'lyrics_language': lyricsLanguage,
      'origen': origen,
      'local_path': localPath,
    };
  }

  factory Cancion.fromJson(Map<String, dynamic> json) => Cancion(
    id: json['id'],
    youtubeId: json['youtube_id'],
    name: json['name'],
    artist: json['artist'],
    album: json['album'],
    duration: json['duration'],
    quality: json['quality'],
    url: json['url'],
    streamUrl: json['stream_url'],
    coverUrl: json['cover_url'],
    lyrics: json['lyrics'],
    lyricsLanguage: json['lyrics_language'],
    origen: json['origen'],
    localPath: json['local_path'],
  );
}
