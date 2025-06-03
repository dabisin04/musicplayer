import 'package:musicplayer/domain/entities/configuracion_api.dart';
import 'package:musicplayer/domain/entities/configuracion_usuario.dart';
import 'package:musicplayer/domain/services/configuration_service.dart';
import 'package:musicplayer/domain/repositories/configuracion_repository.dart';

class ConfiguracionRepositoryImpl implements ConfiguracionRepository {
  @override
  Future<ConfiguracionAPI> obtenerApiConfig() async {
    return await ConfigurationService.obtenerApiConfig();
  }

  @override
  Future<void> guardarApiConfig(ConfiguracionAPI config) async {
    await ConfigurationService.guardarApiConfig(config);
  }

  @override
  Future<ConfiguracionUsuario> obtenerConfiguracionUsuario() async {
    return await ConfigurationService.obtenerConfiguracionUsuario();
  }

  @override
  Future<void> guardarConfiguracionUsuario(ConfiguracionUsuario config) async {
    await ConfigurationService.guardarConfiguracionUsuario(config);
  }

  @override
  Future<void> actualizarGeniusToken(String token) async {
    await ConfigurationService.actualizarGeniusToken(token);
  }

  @override
  Future<String?> obtenerTidalApiUrl() async {
    final config = await obtenerApiConfig();
    return config.tidalApiUrl;
  }

  @override
  Future<String?> obtenerGeniusApiUrl() async {
    final config = await obtenerApiConfig();
    return config.geniusApiUrl;
  }
}
