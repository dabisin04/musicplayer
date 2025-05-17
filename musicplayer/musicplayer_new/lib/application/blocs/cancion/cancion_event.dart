// ignore_for_file: depend_on_referenced_packages

import 'package:equatable/equatable.dart';
import '../../../domain/entities/cancion.dart';

abstract class CancionEvent extends Equatable {
  const CancionEvent();
  @override
  List<Object?> get props => [];
}

class BuscarCanciones extends CancionEvent {
  final String query;
  const BuscarCanciones(this.query);
  @override
  List<Object?> get props => [query];
}

class BuscarPorNombre extends CancionEvent {
  final String nombre;
  final int limit;
  const BuscarPorNombre(this.nombre, {this.limit = 10});
  @override
  List<Object?> get props => [nombre, limit];
}

class BuscarPorArtista extends CancionEvent {
  final String artista;
  final int limit;
  const BuscarPorArtista(this.artista, {this.limit = 10});
  @override
  List<Object?> get props => [artista, limit];
}

class BuscarPorAlbum extends CancionEvent {
  final String album;
  final int limit;
  const BuscarPorAlbum(this.album, {this.limit = 10});
  @override
  List<Object?> get props => [album, limit];
}

class ObtenerCancionPorId extends CancionEvent {
  final String id;
  const ObtenerCancionPorId(this.id);
  @override
  List<Object?> get props => [id];
}

class ObtenerCancionesLocales extends CancionEvent {}

class EliminarCancionLocal extends CancionEvent {
  final String cancionId;
  const EliminarCancionLocal(this.cancionId);
  @override
  List<Object?> get props => [cancionId];
}

class ObtenerCancionesPorOrigen extends CancionEvent {
  final String origen;
  const ObtenerCancionesPorOrigen(this.origen);
  @override
  List<Object?> get props => [origen];
}

// ————————————— Nuevos eventos —————————————

class BuscarLocalesPorNombre extends CancionEvent {
  final String nombre;
  const BuscarLocalesPorNombre(this.nombre);
  @override
  List<Object?> get props => [nombre];
}

class BuscarLocalesPorArtista extends CancionEvent {
  final String artista;
  const BuscarLocalesPorArtista(this.artista);
  @override
  List<Object?> get props => [artista];
}

class BuscarYTComoFallback extends CancionEvent {
  final String query;
  const BuscarYTComoFallback(this.query);
  @override
  List<Object?> get props => [query];
}

class ObtenerUrlStream extends CancionEvent {
  final String trackId;
  const ObtenerUrlStream(this.trackId);
  @override
  List<Object?> get props => [trackId];
}

class DescargarYCargarCancion extends CancionEvent {
  final Cancion cancion;
  const DescargarYCargarCancion(this.cancion);
  @override
  List<Object?> get props => [cancion];
}

class VerificarDescargada extends CancionEvent {
  final String cancionId;
  const VerificarDescargada(this.cancionId);
  @override
  List<Object?> get props => [cancionId];
}

class DescargarCancion extends CancionEvent {
  final Cancion cancion;
  const DescargarCancion(this.cancion);

  @override
  List<Object?> get props => [cancion];
}

class BuscarCancionesLazy extends CancionEvent {
  final String query;
  const BuscarCancionesLazy(this.query);

  @override
  List<Object?> get props => [query];
}

class BuscarCancionesFiltradasLazy extends CancionEvent {
  final String query;
  final List<OrigenCancion> origenesSeleccionados;
  final int limit;

  const BuscarCancionesFiltradasLazy(
    this.query,
    this.origenesSeleccionados, {
    this.limit = 10,
  });

  @override
  List<Object?> get props => [query, origenesSeleccionados, limit];
}
