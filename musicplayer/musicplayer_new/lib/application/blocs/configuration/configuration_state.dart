import 'package:equatable/equatable.dart';
import 'package:musicplayer/domain/entities/configuracion_api.dart';
import 'package:musicplayer/domain/entities/configuracion_usuario.dart';

abstract class ConfiguracionState extends Equatable {
  const ConfiguracionState();
  @override
  List<Object?> get props => [];
}

class ConfiguracionInitial extends ConfiguracionState {}

class ConfiguracionLoading extends ConfiguracionState {}

class ApiConfigLoaded extends ConfiguracionState {
  final ConfiguracionAPI config;
  const ApiConfigLoaded(this.config);
  @override
  List<Object?> get props => [config];
}

class UserConfigLoaded extends ConfiguracionState {
  final ConfiguracionUsuario config;
  const UserConfigLoaded(this.config);
  @override
  List<Object?> get props => [config];
}

class ApiConfigUpdated extends ConfiguracionState {
  final ConfiguracionAPI config;
  const ApiConfigUpdated(this.config);
  @override
  List<Object?> get props => [config];
}

class UserConfigUpdated extends ConfiguracionState {
  final ConfiguracionUsuario config;
  const UserConfigUpdated(this.config);
  @override
  List<Object?> get props => [config];
}

class ConfiguracionError extends ConfiguracionState {
  final String message;
  const ConfiguracionError(this.message);
  @override
  List<Object?> get props => [message];
}
