import 'package:equatable/equatable.dart';
import '../../../domain/entities/cancion.dart';

abstract class PlaylistEvent extends Equatable {
  const PlaylistEvent();
  @override
  List<Object?> get props => [];
}

/// Carga todas las playlists del usuario
class LoadPlaylists extends PlaylistEvent {}

/// Carga las pistas de una playlist específica
class LoadPlaylistTracks extends PlaylistEvent {
  final String playlistId;
  const LoadPlaylistTracks(this.playlistId);
  @override
  List<Object?> get props => [playlistId];
}

/// Crea una nueva playlist local
class CrearPlaylist extends PlaylistEvent {
  final String nombre;
  final String? descripcion;
  const CrearPlaylist(this.nombre, {this.descripcion});
  @override
  List<Object?> get props => [nombre, descripcion];
}

/// Elimina una playlist local
class EliminarPlaylist extends PlaylistEvent {
  final String playlistId;
  const EliminarPlaylist(this.playlistId);
  @override
  List<Object?> get props => [playlistId];
}

/// Agrega una canción a una playlist local
class AgregarCancionAPlaylist extends PlaylistEvent {
  final String playlistId;
  final Cancion cancion;
  const AgregarCancionAPlaylist(this.playlistId, this.cancion);
  @override
  List<Object?> get props => [playlistId, cancion];
}

/// Elimina una canción de una playlist local
class EliminarCancionDePlaylist extends PlaylistEvent {
  final String playlistId;
  final String trackId;
  const EliminarCancionDePlaylist(this.playlistId, this.trackId);
  @override
  List<Object?> get props => [playlistId, trackId];
}

/// Sincroniza todas las playlists con la API
class SyncPlaylists extends PlaylistEvent {}
