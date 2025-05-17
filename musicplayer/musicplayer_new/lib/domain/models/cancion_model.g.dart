// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancion_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CancionAdapter extends TypeAdapter<Cancion> {
  @override
  final int typeId = 0;

  @override
  Cancion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Cancion(
      id: fields[0] as int?,
      youtubeId: fields[1] as String?,
      name: fields[2] as String,
      artist: fields[3] as String,
      album: fields[4] as String,
      duration: fields[5] as int,
      quality: fields[6] as String?,
      url: fields[7] as String?,
      streamUrl: fields[8] as String?,
      coverUrl: fields[9] as String?,
      lyrics: fields[10] as String?,
      lyricsLanguage: fields[11] as String?,
      origen: fields[12] as String,
      localPath: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Cancion obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.youtubeId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.artist)
      ..writeByte(4)
      ..write(obj.album)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.quality)
      ..writeByte(7)
      ..write(obj.url)
      ..writeByte(8)
      ..write(obj.streamUrl)
      ..writeByte(9)
      ..write(obj.coverUrl)
      ..writeByte(10)
      ..write(obj.lyrics)
      ..writeByte(11)
      ..write(obj.lyricsLanguage)
      ..writeByte(12)
      ..write(obj.origen)
      ..writeByte(13)
      ..write(obj.localPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CancionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
