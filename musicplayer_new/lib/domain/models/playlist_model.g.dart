// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaylistAdapter extends TypeAdapter<Playlist> {
  @override
  final int typeId = 1;

  @override
  Playlist read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Playlist(
      id: fields[0] as String,
      nombre: fields[1] as String,
      descripcion: fields[2] as String?,
      creador: fields[3] as String?,
      numeroCanciones: fields[4] as int,
      duracion: fields[5] as int,
      fechaCreacion: fields[6] as DateTime?,
      origen: fields[7] as String,
      canciones: (fields[8] as List).cast<model.Cancion>(),
      coverUrl: fields[9] as String?,
      squareCoverUrl: fields[10] as String?,
      ultimaActualizacion: fields[11] as DateTime?,
      esPropia: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Playlist obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.descripcion)
      ..writeByte(3)
      ..write(obj.creador)
      ..writeByte(4)
      ..write(obj.numeroCanciones)
      ..writeByte(5)
      ..write(obj.duracion)
      ..writeByte(6)
      ..write(obj.fechaCreacion)
      ..writeByte(7)
      ..write(obj.origen)
      ..writeByte(8)
      ..write(obj.canciones)
      ..writeByte(9)
      ..write(obj.coverUrl)
      ..writeByte(10)
      ..write(obj.squareCoverUrl)
      ..writeByte(11)
      ..write(obj.ultimaActualizacion)
      ..writeByte(12)
      ..write(obj.esPropia);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
