import 'package:flutter_bloc/flutter_bloc.dart';
import 'mix_event.dart';
import 'mix_state.dart';
import 'package:musicplayer/domain/repositories/mix_repository.dart';

class MixBloc extends Bloc<MixEvent, MixState> {
  final MixRepository mixRepository;

  MixBloc(this.mixRepository) : super(MixInitial()) {
    on<LoadMixes>(_onLoadMixes);
    on<LoadMixInfo>(_onLoadMixInfo);
    on<LoadMixTracks>(_onLoadMixTracks);
  }

  Future<void> _onLoadMixes(LoadMixes event, Emitter<MixState> emit) async {
    emit(MixLoading());
    try {
      final mixes = await mixRepository.obtenerMixes();
      emit(MixesLoaded(mixes));
    } catch (e) {
      emit(MixError('Error al cargar mixes: \$e'));
    }
  }

  Future<void> _onLoadMixInfo(LoadMixInfo event, Emitter<MixState> emit) async {
    emit(MixLoading());
    try {
      final mix = await mixRepository.obtenerInfoMix(event.mixId);
      if (mix != null) {
        emit(MixInfoLoaded(mix));
      } else {
        emit(MixError('Mix no encontrado'));
      }
    } catch (e) {
      emit(MixError('Error al obtener información del mix: \$e'));
    }
  }

  Future<void> _onLoadMixTracks(
    LoadMixTracks event,
    Emitter<MixState> emit,
  ) async {
    emit(MixLoading());
    try {
      final tracks = await mixRepository.obtenerCancionesDeMix(event.mixId);
      emit(MixTracksLoaded(event.mixId, tracks));
    } catch (e) {
      emit(MixError('Error al cargar pistas del mix: \$e'));
    }
  }
}
