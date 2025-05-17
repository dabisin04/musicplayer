import 'package:equatable/equatable.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/cancion.dart';

abstract class PlaylistState extends Equatable {
  const PlaylistState();
  @override
  List<Object?> get props => [];
}

/// Estado inicial
class PlaylistInitial extends PlaylistState {}

/// Cargando datos de playlists o pistas
class PlaylistLoading extends PlaylistState {}

/// Playlists cargadas exitosamente
class PlaylistsLoaded extends PlaylistState {
  final List<Playlist> playlists;
  const PlaylistsLoaded(this.playlists);
  @override
  List<Object?> get props => [playlists];
}

/// Pistas de una playlist cargadas exitosamente
class PlaylistTracksLoaded extends PlaylistState {
  final String playlistId;
  final List<Cancion> tracks;
  const PlaylistTracksLoaded(this.playlistId, this.tracks);
  @override
  List<Object?> get props => [playlistId, tracks];
}

class PlaylistError extends PlaylistState {
  final String message;
  const PlaylistError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Playlist creada exitosamente
class PlaylistCreada extends PlaylistState {
  final Playlist playlist;
  const PlaylistCreada(this.playlist);
  @override
  List<Object?> get props => [playlist];
}

/// Playlist eliminada exitosamente
class PlaylistEliminada extends PlaylistState {
  final String playlistId;
  const PlaylistEliminada(this.playlistId);
  @override
  List<Object?> get props => [playlistId];
}

/// Canción agregada exitosamente
class CancionAgregada extends PlaylistState {
  final String playlistId;
  const CancionAgregada(this.playlistId);
  @override
  List<Object?> get props => [playlistId];
}

/// Canción eliminada exitosamente
class CancionEliminada extends PlaylistState {
  final String playlistId;
  const CancionEliminada(this.playlistId);
  @override
  List<Object?> get props => [playlistId];
}

/// Sincronización completada
class PlaylistsSincronizadas extends PlaylistState {
  final List<Playlist> playlists;
  const PlaylistsSincronizadas(this.playlists);
  @override
  List<Object?> get props => [playlists];
}
