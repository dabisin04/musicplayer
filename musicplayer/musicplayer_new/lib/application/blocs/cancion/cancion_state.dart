import 'package:equatable/equatable.dart';
import '../../../domain/entities/cancion.dart';

abstract class CancionState extends Equatable {
  const CancionState();
  @override
  List<Object?> get props => [];
}

class CancionInitial extends CancionState {}

class CancionLoading extends CancionState {}

// Estados existentes
class CancionesCargadas extends CancionState {
  final List<Cancion> canciones;
  const CancionesCargadas(this.canciones);
  @override
  List<Object?> get props => [canciones];
}

class CancionEncontrada extends CancionState {
  final Cancion cancion;
  const CancionEncontrada(this.cancion);
  @override
  List<Object?> get props => [cancion];
}

class CancionError extends CancionState {
  final String mensaje;
  const CancionError(this.mensaje);
  @override
  List<Object?> get props => [mensaje];
}

// ————————————— Nuevos estados —————————————

class LocalesPorNombreCargadas extends CancionState {
  final List<Cancion> canciones;
  const LocalesPorNombreCargadas(this.canciones);
  @override
  List<Object?> get props => [canciones];
}

class LocalesPorArtistaCargadas extends CancionState {
  final List<Cancion> canciones;
  const LocalesPorArtistaCargadas(this.canciones);
  @override
  List<Object?> get props => [canciones];
}

class CancionesYTFallbackCargadas extends CancionState {
  final List<Cancion> canciones;
  const CancionesYTFallbackCargadas(this.canciones);
  @override
  List<Object?> get props => [canciones];
}

class UrlStreamObtenida extends CancionState {
  final String url;
  const UrlStreamObtenida(this.url);
  @override
  List<Object?> get props => [url];
}

class CancionDescargada extends CancionState {
  final Cancion cancion;
  const CancionDescargada(this.cancion);
  @override
  List<Object?> get props => [cancion];
}

class DescargaVerificada extends CancionState {
  final bool descargada;
  const DescargaVerificada(this.descargada);
  @override
  List<Object?> get props => [descargada];
}

class CancionesFiltradasLazyCargadas extends CancionState {
  final List<Cancion> canciones;
  const CancionesFiltradasLazyCargadas(this.canciones);

  @override
  List<Object?> get props => [canciones];
}
