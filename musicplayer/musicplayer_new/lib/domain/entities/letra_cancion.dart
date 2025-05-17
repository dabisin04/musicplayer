class LetraCancion {
  final String trackId; // Puede ser el ID de Tidal o el videoId de YouTube
  final String trackName;
  final String artist;
  final String lyrics;
  final String? language;
  final String? source; // Puede indicar si viene de Genius, Tidal u otro

  LetraCancion({
    required this.trackId,
    required this.trackName,
    required this.artist,
    required this.lyrics,
    this.language,
    this.source,
  });

  factory LetraCancion.fromMap(Map<String, dynamic> map) {
    return LetraCancion(
      trackId: map['track_id'] ?? map['id'] ?? '',
      trackName: map['track_name'] ?? map['name'] ?? '',
      artist: map['artist'] ?? '',
      lyrics: map['lyrics'] ?? '',
      language: map['language'] ?? map['lyrics_language'],
      source: map['source'] ?? 'desconocido',
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
