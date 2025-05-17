// ignore_for_file: unused_field, unused_local_variable

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/cancion_repository.dart';
import '../../../domain/repositories/configuracion_repository.dart';
import '../../../domain/entities/cancion.dart';
import 'cancion_event.dart';
import 'cancion_state.dart';

class CancionBloc extends Bloc<CancionEvent, CancionState> {
  final CancionRepository _cancionRepo;
  final ConfiguracionRepository _configRepo;
  final _loadingStates = <String, bool>{};
  final _errorStates = <String, String>{};

  CancionBloc(this._cancionRepo, this._configRepo) : super(CancionInitial()) {
    on<BuscarCanciones>(_onBuscar);
    on<BuscarPorNombre>(_onBuscarNombre);
    on<BuscarPorArtista>(_onBuscarArtista);
    on<BuscarPorAlbum>(_onBuscarAlbum);
    on<ObtenerCancionPorId>(_onObtenerPorId);
    on<BuscarLocalesPorNombre>(_onBuscarLocalesPorNombre);
    on<BuscarLocalesPorArtista>(_onBuscarLocalesPorArtista);
    on<BuscarYTComoFallback>(_onBuscarYTFallback);
    on<ObtenerUrlStream>(_onObtenerUrlStream);
    on<DescargarYCargarCancion>(_onDescargarYCargarCancion);
    on<VerificarDescargada>(_onVerificarDescargada);
    on<ObtenerCancionesLocales>(_onLocales);
    on<EliminarCancionLocal>(_onEliminar);
    on<ObtenerCancionesPorOrigen>(_onPorOrigen);
    on<DescargarCancion>(_onDescargarCancion);
    on<BuscarCancionesLazy>(_onBuscarLazy);
    on<BuscarCancionesFiltradasLazy>(_onBuscarFiltradasLazy);
  }

  void _setLoading(String key, bool value) {
    _loadingStates[key] = value;
    if (value) {
      emit(CancionLoading());
    }
  }

  void _setError(String key, String message) {
    _errorStates[key] = message;
    emit(CancionError(message));
  }

  bool _isLoading(String key) => _loadingStates[key] ?? false;
  String? _getError(String key) => _errorStates[key];

  Future<void> _onBuscar(
    BuscarCanciones event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('buscar')) return;
    _setLoading('buscar', true);
    try {
      final config = await _configRepo.obtenerConfiguracionUsuario();
      final canciones = await _cancionRepo.buscarCanciones(event.query);
      emit(CancionesCargadas(canciones));
    } catch (e) {
      _setError('buscar', "Error al buscar canciones: $e");
    } finally {
      _setLoading('buscar', false);
    }
  }

  Future<void> _onBuscarNombre(
    BuscarPorNombre event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('buscar_nombre')) return;
    _setLoading('buscar_nombre', true);
    try {
      final canciones = await _cancionRepo.buscarPorNombre(event.nombre);
      emit(CancionesCargadas(canciones));
    } catch (e) {
      _setError('buscar_nombre', "Error al buscar por nombre");
    } finally {
      _setLoading('buscar_nombre', false);
    }
  }

  Future<void> _onBuscarArtista(
    BuscarPorArtista event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('buscar_artista')) return;
    _setLoading('buscar_artista', true);
    try {
      final canciones = await _cancionRepo.buscarPorArtista(event.artista);
      emit(CancionesCargadas(canciones));
    } catch (e) {
      _setError('buscar_artista', "Error al buscar por artista");
    } finally {
      _setLoading('buscar_artista', false);
    }
  }

  Future<void> _onBuscarAlbum(
    BuscarPorAlbum event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('buscar_album')) return;
    _setLoading('buscar_album', true);
    try {
      final canciones = await _cancionRepo.buscarPorAlbum(event.album);
      emit(CancionesCargadas(canciones));
    } catch (e) {
      _setError('buscar_album', "Error al buscar por álbum");
    } finally {
      _setLoading('buscar_album', false);
    }
  }

  Future<void> _onObtenerPorId(
    ObtenerCancionPorId event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('obtener_por_id')) return;
    _setLoading('obtener_por_id', true);
    try {
      final cancion = await _cancionRepo.obtenerCancionPorId(event.id);
      if (cancion != null) {
        emit(CancionEncontrada(cancion));
      } else {
        emit(const CancionError("Canción no encontrada"));
      }
    } catch (e) {
      _setError('obtener_por_id', "Error al obtener canción por ID");
    } finally {
      _setLoading('obtener_por_id', false);
    }
  }

  Future<void> _onLocales(
    ObtenerCancionesLocales event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('locales')) return;
    _setLoading('locales', true);
    try {
      final canciones = await _cancionRepo.obtenerCancionesLocales();
      emit(CancionesCargadas(canciones));
    } catch (e) {
      _setError('locales', "Error al obtener canciones locales");
    } finally {
      _setLoading('locales', false);
    }
  }

  Future<void> _onEliminar(
    EliminarCancionLocal event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('eliminar')) return;
    _setLoading('eliminar', true);
    try {
      await _cancionRepo.eliminarCancionLocal(event.cancionId);
      // opcional: emitir un estado tras eliminar
    } catch (e) {
      _setError('eliminar', "Error al eliminar canción local");
    } finally {
      _setLoading('eliminar', false);
    }
  }

  Future<void> _onPorOrigen(
    ObtenerCancionesPorOrigen event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('por_origen')) return;
    _setLoading('por_origen', true);
    try {
      final origenEnum = OrigenCancion.values.firstWhere(
        (o) => o.name == event.origen,
        orElse: () => OrigenCancion.local,
      );
      final canciones = await _cancionRepo.obtenerPorOrigen(origenEnum);
      emit(CancionesCargadas(canciones));
    } catch (e) {
      _setError('por_origen', "Error al filtrar por origen");
    } finally {
      _setLoading('por_origen', false);
    }
  }

  Future<void> _onBuscarLocalesPorNombre(
    BuscarLocalesPorNombre event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('buscar_locales_nombre')) return;
    _setLoading('buscar_locales_nombre', true);
    try {
      final list = await _cancionRepo.buscarLocalesPorNombre(event.nombre);
      emit(LocalesPorNombreCargadas(list));
    } catch (e) {
      _setError(
        'buscar_locales_nombre',
        'Error al buscar locales por nombre: $e',
      );
    } finally {
      _setLoading('buscar_locales_nombre', false);
    }
  }

  Future<void> _onBuscarLocalesPorArtista(
    BuscarLocalesPorArtista event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('buscar_locales_artista')) return;
    _setLoading('buscar_locales_artista', true);
    try {
      final list = await _cancionRepo.buscarLocalesPorArtista(event.artista);
      emit(LocalesPorArtistaCargadas(list));
    } catch (e) {
      _setError(
        'buscar_locales_artista',
        'Error al buscar locales por artista: $e',
      );
    } finally {
      _setLoading('buscar_locales_artista', false);
    }
  }

  Future<void> _onBuscarYTFallback(
    BuscarYTComoFallback event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('buscar_yt_fallback')) return;
    _setLoading('buscar_yt_fallback', true);
    try {
      final list = await _cancionRepo.buscarYTComoFallback(event.query);
      emit(CancionesYTFallbackCargadas(list));
    } catch (e) {
      _setError('buscar_yt_fallback', 'Error al buscar YouTube fallback: $e');
    } finally {
      _setLoading('buscar_yt_fallback', false);
    }
  }

  Future<void> _onObtenerUrlStream(
    ObtenerUrlStream event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('obtener_url_stream')) return;
    _setLoading('obtener_url_stream', true);
    try {
      final url = await _cancionRepo.obtenerUrlStream(event.trackId);
      if (url != null) {
        emit(UrlStreamObtenida(url));
      } else {
        emit(const CancionError('No se obtuvo stream URL'));
      }
    } catch (e) {
      _setError('obtener_url_stream', 'Error al obtener stream URL: $e');
    } finally {
      _setLoading('obtener_url_stream', false);
    }
  }

  Future<void> _onDescargarYCargarCancion(
    DescargarYCargarCancion event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('descargar_y_cargar')) return;
    _setLoading('descargar_y_cargar', true);
    try {
      final path = await _cancionRepo.descargarCancion(event.cancion);
      if (path != null) {
        final descargada = event.cancion.copyWith(localPath: path);
        emit(CancionDescargada(descargada));
      } else {
        emit(const CancionError('No se pudo descargar la canción'));
      }
    } catch (e) {
      _setError('descargar_y_cargar', 'Error al descargar: $e');
    } finally {
      _setLoading('descargar_y_cargar', false);
    }
  }

  Future<void> _onVerificarDescargada(
    VerificarDescargada event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('verificar_descarga')) return;
    _setLoading('verificar_descarga', true);
    try {
      final ok = await _cancionRepo.estaDescargada(event.cancionId);
      emit(DescargaVerificada(ok));
    } catch (e) {
      _setError('verificar_descarga', 'Error al verificar descarga: $e');
    } finally {
      _setLoading('verificar_descarga', false);
    }
  }

  Future<void> _onDescargarCancion(
    DescargarCancion event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('descargar_cancion')) return;
    _setLoading('descargar_cancion', true);
    try {
      final path = await _cancionRepo.descargarCancion(event.cancion);
      if (path != null) {
        final descargada = event.cancion.copyWith(localPath: path);
        emit(CancionDescargada(descargada));
      } else {
        emit(const CancionError('No se pudo descargar la canción'));
      }
    } catch (e) {
      _setError('descargar_cancion', 'Error al descargar: $e');
    } finally {
      _setLoading('descargar_cancion', false);
    }
  }

  Future<void> _onBuscarLazy(
    BuscarCancionesLazy event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('buscar_lazy')) return;
    _setLoading('buscar_lazy', true);
    try {
      await for (final parcial in _cancionRepo.buscarCancionesLazy(
        event.query,
      )) {
        emit(CancionesCargadas(parcial));
      }
    } catch (e) {
      _setError('buscar_lazy', "Error al buscar canciones: $e");
    } finally {
      _setLoading('buscar_lazy', false);
    }
  }

  Future<void> _onBuscarFiltradasLazy(
    BuscarCancionesFiltradasLazy event,
    Emitter<CancionState> emit,
  ) async {
    if (_isLoading('buscar_filtradas_lazy')) return;
    _setLoading('buscar_filtradas_lazy', true);
    try {
      await for (final parcial in _cancionRepo.buscarCancionesFiltradasLazy(
        event.query,
        event.origenesSeleccionados.map((e) => e.name).toList(),
      )) {
        emit(CancionesFiltradasLazyCargadas(parcial));
      }
    } catch (e) {
      _setError('buscar_filtradas_lazy', "Error en búsqueda filtrada: $e");
    } finally {
      _setLoading('buscar_filtradas_lazy', false);
    }
  }
}
