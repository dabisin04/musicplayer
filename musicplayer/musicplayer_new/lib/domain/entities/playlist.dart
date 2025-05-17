import 'package:musicplayer/domain/entities/cancion.dart';

enum OrigenPlaylist { tidal, youtube, local }

class Playlist {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? creador;
  int numeroCanciones;
  int duracion;
  final DateTime? fechaCreacion;
  final DateTime? ultimaActualizacion;
  final OrigenPlaylist origen;
  final String? coverUrl;
  final String? squareCoverUrl;
  final bool esPropia;
  List<Cancion> canciones;

  Playlist({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.creador,
    required this.numeroCanciones,
    required this.duracion,
    this.fechaCreacion,
    this.ultimaActualizacion,
    required this.origen,
    this.coverUrl,
    this.squareCoverUrl,
    this.esPropia = false,
    List<Cancion>? canciones,
  }) : canciones = canciones ?? [];

  // Setters
  set setCanciones(List<Cancion> value) => canciones = value;
  set setNumeroCanciones(int value) => numeroCanciones = value;
  set setDuracion(int value) => duracion = value;

  factory Playlist.fromMap(
    Map<String, dynamic> map, {
    OrigenPlaylist origen = OrigenPlaylist.tidal,
  }) {
    return Playlist(
      id: map['id'],
      nombre: map['name'],
      descripcion: map['description'],
      creador: map['creator'],
      numeroCanciones:
          map['number_of_tracks'] ?? (map['tracks'] as List?)?.length ?? 0,
      duracion: map['duration'] ?? 0,
      fechaCreacion:
          map['created'] != null ? DateTime.tryParse(map['created']) : null,
      ultimaActualizacion:
          map['last_updated'] != null
              ? DateTime.tryParse(map['last_updated'])
              : null,
      coverUrl: map['cover_url'],
      squareCoverUrl: map['square_cover_url'],
      esPropia: map['is_own'] ?? false,
      origen: origen,
    );
  }

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
      'origen': origen.name,
      'tracks': canciones.map((c) => c.toMap()).toList(),
    };
  }
}
