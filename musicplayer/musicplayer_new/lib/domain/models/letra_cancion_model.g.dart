// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'letra_cancion_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LetraCancionAdapter extends TypeAdapter<LetraCancion> {
  @override
  final int typeId = 3;

  @override
  LetraCancion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LetraCancion(
      trackId: fields[0] as String,
      trackName: fields[1] as String,
      artist: fields[2] as String,
      lyrics: fields[3] as String,
      language: fields[4] as String?,
      source: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LetraCancion obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.trackId)
      ..writeByte(1)
      ..write(obj.trackName)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.lyrics)
      ..writeByte(4)
      ..write(obj.language)
      ..writeByte(5)
      ..write(obj.source);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LetraCancionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
