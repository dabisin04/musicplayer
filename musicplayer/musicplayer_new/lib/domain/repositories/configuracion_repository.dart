import '../entities/configuracion_api.dart';
import '../entities/configuracion_usuario.dart';

abstract class ConfiguracionRepository {
  Future<ConfiguracionAPI> obtenerApiConfig();
  Future<void> guardarApiConfig(ConfiguracionAPI config);
  Future<ConfiguracionUsuario> obtenerConfiguracionUsuario();
  Future<void> guardarConfiguracionUsuario(ConfiguracionUsuario config);
  Future<void> actualizarGeniusToken(String token);
  Future<String?> obtenerTidalApiUrl();
  Future<String?> obtenerGeniusApiUrl();
}
