import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:musicplayer/domain/services/verification_service.dart';

class TidalAuthBloc extends Bloc<TidalAuthEvent, TidalAuthState> {
  final TidalAuthService tidalAuthService;

  TidalAuthBloc(this.tidalAuthService) : super(TidalAuthInitial()) {
    on<IniciarLoginTidal>(_onIniciarLogin);
    on<VerificarLoginTidal>(_onVerificarLogin);
  }

  Future<void> _onIniciarLogin(
    IniciarLoginTidal event,
    Emitter<TidalAuthState> emit,
  ) async {
    emit(TidalAuthLoading());
    try {
      final result = await tidalAuthService.obtenerLinkLogin(
        forceNew: event.forceNew,
      );

      if (result == null) {
        if (event.forceNew) {
          emit(const TidalAuthError('No se pudo obtener el link de login'));
        } else {
          // Si no es forceNew y result es null, intentamos con forceNew
          final newResult = await tidalAuthService.obtenerLinkLogin(
            forceNew: true,
          );
          if (newResult == null) {
            emit(const TidalAuthError('No se pudo obtener el link de login'));
            return;
          }
          final uri = newResult['verification_uri']?.toString();
          final code = newResult['verification_code']?.toString();
          if (uri == null || uri.isEmpty || code == null || code.isEmpty) {
            emit(const TidalAuthError('Respuesta inválida del servidor'));
            return;
          }
          emit(TidalAuthPending(verificationUri: uri, verificationCode: code));
        }
        return;
      }

      final uri = result['verification_uri']?.toString();
      final code = result['verification_code']?.toString();

      if (uri == null || uri.isEmpty || code == null || code.isEmpty) {
        print('[TidalAuthBloc] Error: URI o código inválidos');
        print('[TidalAuthBloc] URI: $uri');
        print('[TidalAuthBloc] Code: $code');
        emit(
          const TidalAuthError(
            'Respuesta inválida del servidor: falta verification_uri o verification_code',
          ),
        );
        return;
      }

      emit(TidalAuthPending(verificationUri: uri, verificationCode: code));
    } catch (e) {
      print('[TidalAuthBloc] Error en _onIniciarLogin: $e');
      emit(TidalAuthError('Error: $e'));
    }
  }

  Future<void> _onVerificarLogin(
    VerificarLoginTidal event,
    Emitter<TidalAuthState> emit,
  ) async {
    emit(TidalAuthLoading());
    try {
      final ok = await tidalAuthService.verificarLogin(event.code);
      emit(
        ok ? TidalAuthSuccess() : const TidalAuthError('Verificación fallida'),
      );
    } catch (e) {
      emit(TidalAuthError('Error: $e'));
    }
  }
}
