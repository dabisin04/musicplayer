import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:musicplayer/domain/repositories/configuracion_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TidalAuthService {
  final ConfiguracionRepository _configRepo;
  static const _tidalLoginKey = 'tidal_login_success';

  TidalAuthService(this._configRepo);

  Future<String?> _baseUrl() async {
    return await _configRepo.obtenerTidalApiUrl();
  }

  Future<Map<String, dynamic>?> obtenerLinkLogin({
    bool forceNew = false,
  }) async {
    final url = await _baseUrl();
    if (url == null) return null;

    // Si no es forceNew, primero verificamos si hay un login exitoso
    if (!forceNew) {
      final isLoggedIn = await isLoginExitoso();
      if (isLoggedIn) {
        print('[TidalAuthService] Usuario ya está logueado');
        return null;
      }
    }

    final uri = Uri.parse('$url/tidal/login?force_new=$forceNew');
    print('[TidalAuthService] GET: ' + uri.toString());
    final res = await http.get(uri);
    print('[TidalAuthService] Status Code: ${res.statusCode}');
    print('[TidalAuthService] Response Body: ${res.body}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      print('[TidalAuthService] Decoded Data: $data');

      // Si el estado es pending y no hay código, forzamos un nuevo login
      if (data['status'] == 'pending' &&
          !data.containsKey('verification_code')) {
        print(
          '[TidalAuthService] Estado pending sin código, forzando nuevo login',
        );
        return await obtenerLinkLogin(forceNew: true);
      }

      // Verificar que los campos requeridos estén presentes
      if (!data.containsKey('verification_uri') ||
          !data.containsKey('verification_code')) {
        print(
          '[TidalAuthService] Error: Respuesta inválida - Faltan campos requeridos',
        );
        print(
          '[TidalAuthService] verification_uri: ${data['verification_uri']}',
        );
        print(
          '[TidalAuthService] verification_code: ${data['verification_code']}',
        );
        return null;
      }

      return data;
    }
    return null;
  }

  Future<bool> verificarLogin(String code) async {
    final url = await _baseUrl();
    if (url == null) return false;

    final uri = Uri.parse('$url/tidal/login/verify/$code');
    print('[TidalAuthService] GET: ' + uri.toString());
    final res = await http.get(uri);
    final success = res.statusCode == 200;

    if (success) {
      await _guardarLoginExitoso();
    }
    return success;
  }

  Future<bool> verificarLoginConObjeto(String verificationUrl) async {
    final url = await _baseUrl();
    if (url == null) return false;

    final uri = Uri.parse('$url/tidal/login/verify');
    final body = jsonEncode({'verification_url': verificationUrl});
    print('[TidalAuthService] POST: ' + uri.toString());
    print('[TidalAuthService] BODY: ' + body);
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    final success = res.statusCode == 200;

    if (success) {
      await _guardarLoginExitoso();
    }
    return success;
  }

  Future<void> _guardarLoginExitoso() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tidalLoginKey, true);
  }

  Future<bool> isLoginExitoso() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tidalLoginKey) ?? false;
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tidalLoginKey);
  }
}
