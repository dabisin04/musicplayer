import '../entities/cancion.dart';
import '../entities/playlist.dart';

abstract class PlaylistRepository {
  Future<List<Playlist>> obtenerPlaylists();
  Future<List<Cancion>> obtenerCancionesDePlaylist(String playlistId);
  Future<Playlist> crearPlaylist(String nombre, {String? descripcion});
  Future<void> eliminarPlaylist(String playlistId);
  Future<void> agregarCancionAPlaylist(String playlistId, Cancion cancion);
  Future<void> eliminarCancionDePlaylist(String playlistId, String trackId);
  Future<void> syncPlaylistsAndTracks();
}
