import 'package:flutter_bloc/flutter_bloc.dart';
import 'configuration_event.dart';
import 'configuration_state.dart';
import 'package:musicplayer/domain/repositories/configuracion_repository.dart';

class ConfiguracionBloc extends Bloc<ConfiguracionEvent, ConfiguracionState> {
  final ConfiguracionRepository _repo;

  ConfiguracionBloc(this._repo) : super(ConfiguracionInitial()) {
    on<LoadApiConfig>(_onLoadApiConfig);
    on<LoadUserConfig>(_onLoadUserConfig);
    on<UpdateApiConfig>(_onUpdateApiConfig);
    on<UpdateUserConfig>(_onUpdateUserConfig);
    on<UpdateGeniusToken>(_onUpdateGeniusToken);
  }

  Future<void> _onLoadApiConfig(
    LoadApiConfig event,
    Emitter<ConfiguracionState> emit,
  ) async {
    emit(ConfiguracionLoading());
    try {
      final cfg = await _repo.obtenerApiConfig();
      emit(ApiConfigLoaded(cfg));
    } catch (e) {
      emit(ConfiguracionError('Error loading API config: $e'));
    }
  }

  Future<void> _onLoadUserConfig(
    LoadUserConfig event,
    Emitter<ConfiguracionState> emit,
  ) async {
    emit(ConfiguracionLoading());
    try {
      final cfg = await _repo.obtenerConfiguracionUsuario();
      emit(UserConfigLoaded(cfg));
    } catch (e) {
      emit(ConfiguracionError('Error loading user config: $e'));
    }
  }

  Future<void> _onUpdateApiConfig(
    UpdateApiConfig event,
    Emitter<ConfiguracionState> emit,
  ) async {
    emit(ConfiguracionLoading());
    try {
      await _repo.guardarApiConfig(event.apiConfig);
      emit(ApiConfigUpdated(event.apiConfig));
    } catch (e) {
      emit(ConfiguracionError('Error updating API config: $e'));
    }
  }

  Future<void> _onUpdateUserConfig(
    UpdateUserConfig event,
    Emitter<ConfiguracionState> emit,
  ) async {
    emit(ConfiguracionLoading());
    try {
      await _repo.guardarConfiguracionUsuario(event.userConfig);
      emit(UserConfigUpdated(event.userConfig));
    } catch (e) {
      emit(ConfiguracionError('Error updating user config: $e'));
    }
  }

  Future<void> _onUpdateGeniusToken(
    UpdateGeniusToken event,
    Emitter<ConfiguracionState> emit,
  ) async {
    emit(ConfiguracionLoading());
    try {
      await _repo.actualizarGeniusToken(event.token);
      final cfg = await _repo.obtenerApiConfig();
      emit(ApiConfigUpdated(cfg));
    } catch (e) {
      emit(ConfiguracionError('Error updating Genius token: $e'));
    }
  }
}
