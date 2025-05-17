import 'package:equatable/equatable.dart';
import '../../../domain/entities/letra_cancion.dart';

abstract class LetraState extends Equatable {
  const LetraState();

  @override
  List<Object?> get props => [];
}

class LetraInitial extends LetraState {}

class LetraLoading extends LetraState {}

/// Estado con una única letra cargada
class LetraLoaded extends LetraState {
  final LetraCancion letra;
  const LetraLoaded(this.letra);

  @override
  List<Object?> get props => [letra];
}

/// Estado con todas las letras locales
class LetrasLoaded extends LetraState {
  final List<LetraCancion> letras;
  const LetrasLoaded(this.letras);

  @override
  List<Object?> get props => [letras];
}

/// Confirmación de borrado local
class LetraDeleted extends LetraState {
  final String trackId;
  const LetraDeleted(this.trackId);

  @override
  List<Object?> get props => [trackId];
}

/// Confirmación de limpieza total
class LetrasCleared extends LetraState {}

class LetraError extends LetraState {
  final String message;
  const LetraError(this.message);

  @override
  List<Object?> get props => [message];
}
