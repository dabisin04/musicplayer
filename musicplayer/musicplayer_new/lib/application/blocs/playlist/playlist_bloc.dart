import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicplayer/domain/repositories/playlist_repository.dart';
import 'playlist_event.dart';
import 'playlist_state.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  final PlaylistRepository _repo;

  PlaylistBloc(this._repo) : super(PlaylistInitial()) {
    on<LoadPlaylists>(_onLoadPlaylists);
    on<LoadPlaylistTracks>(_onLoadPlaylistTracks);
    on<CrearPlaylist>(_onCrearPlaylist);
    on<EliminarPlaylist>(_onEliminarPlaylist);
    on<AgregarCancionAPlaylist>(_onAgregarCancionAPlaylist);
    on<EliminarCancionDePlaylist>(_onEliminarCancionDePlaylist);
    on<SyncPlaylists>(_onSyncPlaylists);
  }

  Future<void> _onLoadPlaylists(
    LoadPlaylists event,
    Emitter<PlaylistState> emit,
  ) async {
    emit(PlaylistLoading());
    try {
      final playlists = await _repo.obtenerPlaylists();
      emit(PlaylistsLoaded(playlists));
    } catch (e) {
      emit(PlaylistError('Error al cargar playlists: $e'));
    }
  }

  Future<void> _onLoadPlaylistTracks(
    LoadPlaylistTracks event,
    Emitter<PlaylistState> emit,
  ) async {
    emit(PlaylistLoading());
    try {
      final tracks = await _repo.obtenerCancionesDePlaylist(event.playlistId);
      emit(PlaylistTracksLoaded(event.playlistId, tracks));
    } catch (e) {
      emit(PlaylistError('Error al cargar pistas: $e'));
    }
  }

  Future<void> _onCrearPlaylist(
    CrearPlaylist event,
    Emitter<PlaylistState> emit,
  ) async {
    emit(PlaylistLoading());
    try {
      final nueva = await _repo.crearPlaylist(
        event.nombre,
        descripcion: event.descripcion,
      );
      emit(PlaylistCreada(nueva));

      final playlists = await _repo.obtenerPlaylists();
      emit(PlaylistsLoaded(playlists));
    } catch (e) {
      emit(PlaylistError('Error al crear playlist: $e'));
    }
  }

  Future<void> _onEliminarPlaylist(
    EliminarPlaylist event,
    Emitter<PlaylistState> emit,
  ) async {
    emit(PlaylistLoading());
    try {
      await _repo.eliminarPlaylist(event.playlistId);
      emit(PlaylistEliminada(event.playlistId));

      final playlists = await _repo.obtenerPlaylists();
      emit(PlaylistsLoaded(playlists));
    } catch (e) {
      emit(PlaylistError('Error al eliminar playlist: $e'));
    }
  }

  Future<void> _onAgregarCancionAPlaylist(
    AgregarCancionAPlaylist event,
    Emitter<PlaylistState> emit,
  ) async {
    emit(PlaylistLoading());
    try {
      await _repo.agregarCancionAPlaylist(event.playlistId, event.cancion);
      emit(CancionAgregada(event.playlistId));

      final tracks = await _repo.obtenerCancionesDePlaylist(event.playlistId);
      emit(PlaylistTracksLoaded(event.playlistId, tracks));
    } catch (e) {
      emit(PlaylistError('Error al agregar canción: $e'));
    }
  }

  Future<void> _onEliminarCancionDePlaylist(
    EliminarCancionDePlaylist event,
    Emitter<PlaylistState> emit,
  ) async {
    emit(PlaylistLoading());
    try {
      await _repo.eliminarCancionDePlaylist(event.playlistId, event.trackId);
      emit(CancionEliminada(event.playlistId));

      final tracks = await _repo.obtenerCancionesDePlaylist(event.playlistId);
      emit(PlaylistTracksLoaded(event.playlistId, tracks));
    } catch (e) {
      emit(PlaylistError('Error al eliminar canción: $e'));
    }
  }

  Future<void> _onSyncPlaylists(
    SyncPlaylists event,
    Emitter<PlaylistState> emit,
  ) async {
    emit(PlaylistLoading());
    try {
      await _repo.syncPlaylistsAndTracks();
      final playlists = await _repo.obtenerPlaylists();
      emit(PlaylistsSincronizadas(playlists));
      emit(PlaylistsLoaded(playlists));
    } catch (e) {
      emit(PlaylistError('Error al sincronizar playlists: $e'));
    }
  }
}
