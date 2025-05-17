enum OrigenCancion { tidal, youtube, local }

class Cancion {
  final int? id; // Para Tidal
  final String? youtubeId; // Para YouTube
  final String name;
  final String artist;
  final String album;
  final int duration;
  final String? quality;
  final String? url;
  final String? streamUrl;
  final String? coverUrl;
  final String? lyrics;
  final String? lyricsLanguage;
  final OrigenCancion origen;
  final String? localPath; // Nuevo campo para ruta local

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

  factory Cancion.fromMap(
    Map<String, dynamic> map, {
    OrigenCancion origen = OrigenCancion.tidal,
  }) {
    return Cancion(
      id: map['id'] is int ? map['id'] : null,
      youtubeId: map['youtube_id'],
      name: map['name'],
      artist: map['artist'],
      album: map['album'] ?? '',
      duration: map['duration'],
      quality: map['quality'],
      url: map['url'],
      streamUrl: map['stream_url'],
      coverUrl: map['cover_url'],
      lyrics: map['lyrics'],
      lyricsLanguage: map['lyrics_language'],
      localPath: map['local_path'],
      origen: origen,
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
      'local_path': localPath,
      'origen': origen.name,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory Cancion.fromJson(Map<String, dynamic> json) => Cancion.fromMap(json);

  Cancion copyWith({
    int? id,
    String? youtubeId,
    String? name,
    String? artist,
    String? album,
    int? duration,
    String? quality,
    String? url,
    String? streamUrl,
    String? coverUrl,
    String? lyrics,
    String? lyricsLanguage,
    OrigenCancion? origen,
    String? localPath,
  }) {
    return Cancion(
      id: id ?? this.id,
      youtubeId: youtubeId ?? this.youtubeId,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      quality: quality ?? this.quality,
      url: url ?? this.url,
      streamUrl: streamUrl ?? this.streamUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      lyrics: lyrics ?? this.lyrics,
      lyricsLanguage: lyricsLanguage ?? this.lyricsLanguage,
      origen: origen ?? this.origen,
      localPath: localPath ?? this.localPath,
    );
  }
}
