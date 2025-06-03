class AudioMetadata {
  final int bitrate; // en kbps
  final int sampleRate; // en Hz
  final String codec; // formato del codec (mp3, aac, flac, etc)
  final int channels; // número de canales (1=mono, 2=stereo)
  final int? bitDepth; // profundidad de bits (16, 24, etc)
  final String? quality; // calidad (low, medium, high, lossless, etc)

  const AudioMetadata({
    required this.bitrate,
    required this.sampleRate,
    required this.codec,
    required this.channels,
    this.bitDepth,
    this.quality,
  });

  AudioMetadata copyWith({
    int? bitrate,
    int? sampleRate,
    String? codec,
    int? channels,
    int? bitDepth,
    String? quality,
  }) => AudioMetadata(
    bitrate: bitrate ?? this.bitrate,
    sampleRate: sampleRate ?? this.sampleRate,
    codec: codec ?? this.codec,
    channels: channels ?? this.channels,
    bitDepth: bitDepth ?? this.bitDepth,
    quality: quality ?? this.quality,
  );

  Map<String, dynamic> toMap() => {
    'bitrate': bitrate,
    'sampleRate': sampleRate,
    'codec': codec,
    'channels': channels,
    'bitDepth': bitDepth,
    'quality': quality,
  };

  static AudioMetadata fromMap(Map<String, dynamic> map) => AudioMetadata(
    bitrate: map['bitrate'] as int,
    sampleRate: map['sampleRate'] as int,
    codec: map['codec'] as String,
    channels: map['channels'] as int,
    bitDepth: map['bitDepth'] as int?,
    quality: map['quality'] as String?,
  );
}
