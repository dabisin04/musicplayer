// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mix_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MixAdapter extends TypeAdapter<Mix> {
  @override
  final int typeId = 2;

  @override
  Mix read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Mix(
      id: fields[0] as String,
      titulo: fields[1] as String,
      subtitulo: fields[2] as String,
      portadaUrl: fields[3] as String?,
      cantidadPistas: fields[4] as int,
      tracks: (fields[5] as List?)?.cast<model.Cancion>(),
    );
  }

  @override
  void write(BinaryWriter writer, Mix obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titulo)
      ..writeByte(2)
      ..write(obj.subtitulo)
      ..writeByte(3)
      ..write(obj.portadaUrl)
      ..writeByte(4)
      ..write(obj.cantidadPistas)
      ..writeByte(5)
      ..write(obj.tracks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MixAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
