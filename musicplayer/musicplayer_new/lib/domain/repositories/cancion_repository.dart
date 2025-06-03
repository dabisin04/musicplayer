import '../entities/cancion.dart';

abstract class CancionRepository {
  Future<List<Cancion>> buscarCanciones(String query);
  Future<List<Cancion>> buscarPorArtista(String artista);
  Future<List<Cancion>> buscarPorAlbum(String album);
  Future<List<Cancion>> buscarPorNombre(String nombre);
  Future<List<Cancion>> buscarLocalesPorNombre(String nombre);
  Future<List<Cancion>> buscarLocalesPorArtista(String artista);
  Future<Cancion?> obtenerCancionPorId(String id);
  Future<List<Cancion>> buscarYTComoFallback(String query);
  Future<String?> obtenerUrlStream(String trackId);
  Future<String?> descargarCancion(Cancion cancion);
  Future<List<Cancion>> obtenerCancionesLocales();
  Future<void> eliminarCancionLocal(String cancionId);
  Future<bool> estaDescargada(String cancionId);
  Future<List<Cancion>> obtenerPorOrigen(OrigenCancion origen);
  Stream<List<Cancion>> buscarCancionesLazy(String q);
  Stream<List<Cancion>> buscarCancionesFiltradasLazy(
    String query,
    List<String> origenes,
  );
}
