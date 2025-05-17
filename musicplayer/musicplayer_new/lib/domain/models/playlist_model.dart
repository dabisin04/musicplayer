import 'package:hive/hive.dart';
import 'package:musicplayer/domain/entities/playlist.dart' as entity_p;
import 'package:musicplayer/domain/models/cancion_model.dart' as model;

part 'playlist_model.g.dart';

@HiveType(typeId: 1)
class Playlist extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nombre;

  @HiveField(2)
  String? descripcion;

  @HiveField(3)
  String? creador;

  @HiveField(4)
  int numeroCanciones;

  @HiveField(5)
  int duracion;

  @HiveField(6)
  DateTime? fechaCreacion;

  @HiveField(7)
  String origen;

  @HiveField(8)
  List<model.Cancion> canciones;

  @HiveField(9)
  String? coverUrl;

  @HiveField(10)
  String? squareCoverUrl;

  @HiveField(11)
  DateTime? ultimaActualizacion;

  @HiveField(12)
  bool esPropia;

  Playlist({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.creador,
    required this.numeroCanciones,
    required this.duracion,
    this.fechaCreacion,
    required this.origen,
    this.canciones = const [],
    this.coverUrl,
    this.squareCoverUrl,
    this.ultimaActualizacion,
    this.esPropia = false,
  });

  factory Playlist.fromEntity(entity_p.Playlist p) => Playlist(
    id: p.id,
    nombre: p.nombre,
    descripcion: p.descripcion,
    creador: p.creador,
    numeroCanciones: p.numeroCanciones,
    duracion: p.duracion,
    fechaCreacion: p.fechaCreacion,
    origen: p.origen.name,
    canciones: p.canciones.map((c) => model.Cancion.fromEntity(c)).toList(),
    coverUrl: p.coverUrl,
    squareCoverUrl: p.squareCoverUrl,
    ultimaActualizacion: p.ultimaActualizacion,
    esPropia: p.esPropia,
  );

  entity_p.Playlist toEntity() => entity_p.Playlist(
    id: id,
    nombre: nombre,
    descripcion: descripcion,
    creador: creador,
    numeroCanciones: numeroCanciones,
    duracion: duracion,
    fechaCreacion: fechaCreacion,
    origen: entity_p.OrigenPlaylist.values.firstWhere(
      (e) => e.name == origen,
      orElse: () => entity_p.OrigenPlaylist.tidal,
    ),
    canciones: canciones.map((c) => c.toEntity()).toList(),
    coverUrl: coverUrl,
    squareCoverUrl: squareCoverUrl,
    ultimaActualizacion: ultimaActualizacion,
    esPropia: esPropia,
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': nombre,
      'description': descripcion,
      'creator': creador,
      'number_of_tracks': numeroCanciones,
      'duration': duracion,
      'created': fechaCreacion?.toIso8601String(),
      'last_updated': ultimaActualizacion?.toIso8601String(),
      'cover_url': coverUrl,
      'square_cover_url': squareCoverUrl,
      'is_own': esPropia,
      'origen': origen,
      'tracks': canciones.map((c) => c.toMap()).toList(),
    };
  }
}
