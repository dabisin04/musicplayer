import 'package:equatable/equatable.dart';
import 'package:musicplayer/domain/entities/configuracion_api.dart';
import 'package:musicplayer/domain/entities/configuracion_usuario.dart';

abstract class ConfiguracionEvent extends Equatable {
  const ConfiguracionEvent();
  @override
  List<Object?> get props => [];
}

class LoadApiConfig extends ConfiguracionEvent {}

class UpdateApiConfig extends ConfiguracionEvent {
  final ConfiguracionAPI apiConfig;
  const UpdateApiConfig(this.apiConfig);
  @override
  List<Object?> get props => [apiConfig];
}

class LoadUserConfig extends ConfiguracionEvent {}

class UpdateUserConfig extends ConfiguracionEvent {
  final ConfiguracionUsuario userConfig;
  const UpdateUserConfig(this.userConfig);
  @override
  List<Object?> get props => [userConfig];
}

class UpdateGeniusToken extends ConfiguracionEvent {
  final String token;
  const UpdateGeniusToken(this.token);
  @override
  List<Object?> get props => [token];
}
