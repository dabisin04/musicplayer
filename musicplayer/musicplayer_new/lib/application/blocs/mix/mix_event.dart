import 'package:equatable/equatable.dart';

abstract class MixEvent extends Equatable {
  const MixEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar la lista de mixes disponibles
typedef LoadMixes = _LoadMixes;

class _LoadMixes extends MixEvent {}

/// Cargar información de un mix específico
class LoadMixInfo extends MixEvent {
  final String mixId;
  const LoadMixInfo(this.mixId);

  @override
  List<Object?> get props => [mixId];
}

/// Cargar pistas de un mix específico
class LoadMixTracks extends MixEvent {
  final String mixId;
  const LoadMixTracks(this.mixId);

  @override
  List<Object?> get props => [mixId];
}
