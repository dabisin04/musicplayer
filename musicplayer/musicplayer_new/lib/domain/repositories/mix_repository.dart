import '../entities/cancion.dart';
import '../entities/mix.dart';

abstract class MixRepository {
  Future<List<Mix>> obtenerMixes();
  Future<Mix?> obtenerInfoMix(String mixId);
  Future<List<Cancion>> obtenerCancionesDeMix(String mixId);
}
