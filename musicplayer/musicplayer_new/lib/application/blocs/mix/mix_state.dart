import 'package:equatable/equatable.dart';
import 'package:musicplayer/domain/entities/mix.dart';
import 'package:musicplayer/domain/entities/cancion.dart';

abstract class MixState extends Equatable {
  const MixState();
  @override
  List<Object?> get props => [];
}

/// Estado inicial, sin datos cargados
class MixInitial extends MixState {}

/// Indicando que se está cargando información
class MixLoading extends MixState {}

/// Lista de mixes cargada
class MixesLoaded extends MixState {
  final List<Mix> mixes;
  const MixesLoaded(this.mixes);
  @override
  List<Object?> get props => [mixes];
}

/// Información detallada de un mix cargada
class MixInfoLoaded extends MixState {
  final Mix mix;
  const MixInfoLoaded(this.mix);
  @override
  List<Object?> get props => [mix];
}

/// Pistas de un mix cargadas
class MixTracksLoaded extends MixState {
  final String mixId;
  final List<Cancion> tracks;
  const MixTracksLoaded(this.mixId, this.tracks);
  @override
  List<Object?> get props => [mixId, tracks];
}

/// Error genérico al interactuar con mixes
class MixError extends MixState {
  final String message;
  const MixError(this.message);
  @override
  List<Object?> get props => [message];
}
