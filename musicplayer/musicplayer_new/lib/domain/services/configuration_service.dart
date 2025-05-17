import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../entities/configuracion_api.dart';
import '../entities/configuracion_usuario.dart';

class ConfigurationService {
  static const _apiConfigKey = 'config_api';
  static const _usuarioConfigKey = 'config_usuario';

  static Future<void> guardarApiConfig(ConfiguracionAPI config) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_apiConfigKey, jsonEncode(config.toMap()));
  }

  static Future<ConfiguracionAPI> obtenerApiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_apiConfigKey);
    if (json == null) return ConfiguracionAPI(); // Valores por defecto
    return ConfiguracionAPI.fromMap(jsonDecode(json));
  }

  static Future<void> actualizarGeniusToken(String token) async {
    final current = await obtenerApiConfig();
    final updated = current.copyWith(geniusAccessToken: token);
    await guardarApiConfig(updated);
  }

  static Future<void> guardarConfiguracionUsuario(
    ConfiguracionUsuario config,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_usuarioConfigKey, jsonEncode(config.toMap()));
  }

  static Future<ConfiguracionUsuario> obtenerConfiguracionUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_usuarioConfigKey);
    if (json == null) {
      return ConfiguracionUsuario(
        carpetaDescargas: '/downloads',
        calidadPreferida: 'HI_RES_LOSSLESS',
        mostrarLetra: true,
      );
    }
    return ConfiguracionUsuario.fromMap(jsonDecode(json));
  }
}
