import 'package:equatable/equatable.dart';

abstract class TidalAuthState extends Equatable {
  const TidalAuthState();
  @override
  List<Object?> get props => [];
}

class TidalAuthInitial extends TidalAuthState {}

class TidalAuthLoading extends TidalAuthState {}

class TidalAuthPending extends TidalAuthState {
  final String verificationUri;
  final String verificationCode;

  const TidalAuthPending({
    required this.verificationUri,
    required this.verificationCode,
  });

  @override
  List<Object?> get props => [verificationUri, verificationCode];
}

class TidalAuthSuccess extends TidalAuthState {}

class TidalAuthError extends TidalAuthState {
  final String message;
  const TidalAuthError(this.message);

  @override
  List<Object?> get props => [message];
}
