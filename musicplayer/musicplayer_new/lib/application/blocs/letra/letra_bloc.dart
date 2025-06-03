import 'package:flutter_bloc/flutter_bloc.dart';
import 'letra_event.dart';
import 'letra_state.dart';
import '../../../domain/repositories/letra_repository.dart';

class LetraBloc extends Bloc<LetraEvent, LetraState> {
  final LetraRepository _repo;

  LetraBloc(this._repo) : super(LetraInitial()) {
    on<LoadLetraById>(_onLoadById);
    on<SearchLetraByTitleArtist>(_onSearchByTitleArtist);
    on<LoadLetrasLocales>(_onLoadLocales);
    on<DeleteLetra>(_onDelete);
    on<ClearLetras>(_onClear);
  }

  Future<void> _onLoadById(
    LoadLetraById event,
    Emitter<LetraState> emit,
  ) async {
    emit(LetraLoading());
    try {
      final letra = await _repo.obtenerLetraPorId(event.trackId);
      if (letra != null) {
        emit(LetraLoaded(letra));
      } else {
        emit(const LetraError('No se encontró la letra'));
      }
    } catch (e) {
      emit(LetraError('Error al cargar letra: $e'));
    }
  }

  Future<void> _onSearchByTitleArtist(
    SearchLetraByTitleArtist event,
    Emitter<LetraState> emit,
  ) async {
    emit(LetraLoading());
    try {
      final letra = await _repo.buscarLetraPorNombreYArtista(
        event.title,
        event.artist,
        cancionId: event.cancionId,
      );
      if (letra != null) {
        emit(LetraLoaded(letra));
      } else {
        emit(const LetraError('No se encontró la letra en Genius'));
      }
    } catch (e) {
      emit(LetraError('Error en búsqueda de letra: $e'));
    }
  }

  Future<void> _onLoadLocales(
    LoadLetrasLocales event,
    Emitter<LetraState> emit,
  ) async {
    emit(LetraLoading());
    try {
      final all = await _repo.obtenerTodasLasLetrasLocales();
      emit(LetrasLoaded(all));
    } catch (e) {
      emit(LetraError('Error al cargar letras locales: $e'));
    }
  }

  Future<void> _onDelete(DeleteLetra event, Emitter<LetraState> emit) async {
    try {
      await _repo.borrarLetraPorId(event.trackId);
      emit(LetraDeleted(event.trackId));
    } catch (e) {
      emit(LetraError('Error al borrar letra: $e'));
    }
  }

  Future<void> _onClear(ClearLetras event, Emitter<LetraState> emit) async {
    try {
      await _repo.limpiarLetras();
      emit(LetrasCleared());
    } catch (e) {
      emit(LetraError('Error al limpiar letras: $e'));
    }
  }
}
