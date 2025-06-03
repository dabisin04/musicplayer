import 'package:musicplayer/domain/entities/letra_cancion.dart';

abstract class LetraRepository {
  Future<LetraCancion?> obtenerLetraPorId(String trackId);
  Future<LetraCancion?> buscarLetraPorNombreYArtista(
    String title,
    String artist, {
    String? cancionId,
  });
  Future<LetraCancion?> obtenerLetraLocalPorId(String trackId);
  Future<List<LetraCancion>> obtenerTodasLasLetrasLocales();
  Future<void> borrarLetraPorId(String trackId);
  Future<void> limpiarLetras();
}
