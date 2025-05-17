// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:musicplayer/application/blocs/auth/auth_bloc.dart';
import 'package:musicplayer/application/blocs/auth/auth_event.dart';
import 'package:musicplayer/application/blocs/auth/auth_state.dart';
import 'package:musicplayer/application/blocs/configuration/configuration_bloc.dart';
import 'package:musicplayer/application/blocs/configuration/configuration_event.dart';
import 'package:musicplayer/application/blocs/configuration/configuration_state.dart';
import 'package:musicplayer/domain/entities/configuracion_api.dart';
import 'package:musicplayer/domain/entities/configuracion_usuario.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  late TextEditingController _tidalUrlController;
  late TextEditingController _geniusUrlController;
  late TextEditingController _geniusTokenController;
  late TextEditingController _downloadsFolderController;
  String? _lastVerificationCode;
  String _preferredQuality = 'HI_RES_LOSSLESS';
  bool _showLyrics = true;

  @override
  void initState() {
    super.initState();
    _tidalUrlController = TextEditingController();
    _geniusUrlController = TextEditingController();
    _geniusTokenController = TextEditingController();
    _downloadsFolderController = TextEditingController();

    // Carga inicial de configuraciones
    context.read<ConfiguracionBloc>().add(LoadUserConfig());
    context.read<ConfiguracionBloc>().add(LoadApiConfig());
  }

  @override
  void dispose() {
    _tidalUrlController.dispose();
    _geniusUrlController.dispose();
    _geniusTokenController.dispose();
    _downloadsFolderController.dispose();
    super.dispose();
  }

  void _saveUserConfig() {
    final userCfg = ConfiguracionUsuario(
      carpetaDescargas: _downloadsFolderController.text,
      calidadPreferida: _preferredQuality,
      mostrarLetra: _showLyrics,
    );
    context.read<ConfiguracionBloc>().add(UpdateUserConfig(userCfg));
  }

  void _saveApiConfig() {
    final apiCfg = ConfiguracionAPI(
      tidalApiUrl: _tidalUrlController.text,
      geniusApiUrl: _geniusUrlController.text,
      geniusAccessToken: _geniusTokenController.text,
    );
    context.read<ConfiguracionBloc>().add(UpdateApiConfig(apiCfg));
  }

  void _startTidalLogin() {
    context.read<TidalAuthBloc>().add(IniciarLoginTidal(forceNew: false));
  }

  void _verifyTidalLogin() {
    if (_lastVerificationCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay código de verificación disponible'),
        ),
      );
      return;
    }
    context.read<TidalAuthBloc>().add(
      VerificarLoginTidal(_lastVerificationCode!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<ConfiguracionBloc, ConfiguracionState>(
        listener: (context, state) {
          if (state is ApiConfigLoaded) {
            // Antes: state.apiConfig → Ahora: state.config
            _tidalUrlController.text = state.config.tidalApiUrl ?? '';
            _geniusUrlController.text = state.config.geniusApiUrl ?? '';
            _geniusTokenController.text = state.config.geniusAccessToken ?? '';
          }
          if (state is UserConfigLoaded) {
            // Antes: state.userConfig → Ahora: state.config
            _downloadsFolderController.text = state.config.carpetaDescargas;
            _preferredQuality = state.config.calidadPreferida;
            _showLyrics = state.config.mostrarLetra;
          }
          if (state is ConfiguracionError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is ApiConfigUpdated || state is UserConfigUpdated) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Guardado')));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ——— Configuración de usuario ———
              const Text(
                'Configuración de usuario',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _downloadsFolderController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Carpeta descargas',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _showLyrics,
                onChanged: (v) => setState(() => _showLyrics = v),
                title: const Text(
                  'Mostrar letras',
                  style: TextStyle(color: Colors.white),
                ),
                activeColor: Colors.white,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _preferredQuality,
                decoration: const InputDecoration(
                  labelText: 'Calidad preferida',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Baja')),
                  DropdownMenuItem(value: 'HIGH', child: Text('Alta')),
                  DropdownMenuItem(value: 'LOSSLESS', child: Text('Lossless')),
                  DropdownMenuItem(
                    value: 'HI_RES_LOSSLESS',
                    child: Text('Hi-Res Lossless'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _preferredQuality = v);
                },
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _saveUserConfig,
                icon: const Icon(Icons.save),
                label: const Text('Guardar configuración usuario'),
              ),
              const Divider(color: Colors.grey, height: 32),

              // ——— Configuración de API ———
              const Text(
                'Configuración de API',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tidalUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Tidal API URL',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _geniusUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Genius API URL',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _geniusTokenController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Genius Access Token',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _saveApiConfig,
                icon: const Icon(Icons.save),
                label: const Text('Guardar configuración API'),
              ),
              const Divider(color: Colors.grey, height: 32),

              // ——— Autenticación Tidal ———
              const Text(
                'Autenticación Tidal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              BlocConsumer<TidalAuthBloc, TidalAuthState>(
                listener: (context, state) {
                  if (state is TidalAuthError) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                  if (state is TidalAuthSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Login exitoso')),
                    );
                  }
                  if (state is TidalAuthPending) {
                    _lastVerificationCode =
                        state.verificationCode; // GUARDAR CÓDIGO
                  }
                },

                builder: (context, state) {
                  final List<Widget> children = [];
                  if (state is TidalAuthPending) {
                    // Asegura que el enlace tenga https://
                    String uri = state.verificationUri;
                    if (!uri.startsWith('http')) {
                      uri = 'https://' + uri;
                    }
                    children.addAll([
                      Text(
                        'Código: ${state.verificationCode}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap:
                            () => launchUrl(
                              Uri.parse(uri),
                              mode: LaunchMode.externalApplication,
                            ),
                        child: Text(
                          uri,
                          style: const TextStyle(
                            color: Colors.lightBlueAccent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ]);
                  }
                  // Botones siempre visibles
                  children.add(
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _startTidalLogin,
                          child: const Text('Iniciar sesión en Tidal'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _verifyTidalLogin,
                          child: const Text('Verificar'),
                        ),
                      ],
                    ),
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
