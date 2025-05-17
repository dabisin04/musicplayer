import 'package:equatable/equatable.dart';

abstract class TidalAuthEvent extends Equatable {
  const TidalAuthEvent();
  @override
  List<Object?> get props => [];
}

class IniciarLoginTidal extends TidalAuthEvent {
  final bool forceNew;
  const IniciarLoginTidal({this.forceNew = false});

  @override
  List<Object?> get props => [forceNew];
}

class VerificarLoginTidal extends TidalAuthEvent {
  final String code;
  const VerificarLoginTidal(this.code);

  @override
  List<Object?> get props => [code];
}
