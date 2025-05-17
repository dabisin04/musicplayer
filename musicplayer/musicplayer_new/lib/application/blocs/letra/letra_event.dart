import 'package:equatable/equatable.dart';

abstract class LetraEvent extends Equatable {
  const LetraEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar una letra (busca local y luego remota)
class LoadLetraById extends LetraEvent {
  final String trackId;
  const LoadLetraById(this.trackId);

  @override
  List<Object?> get props => [trackId];
}

/// Buscar letra por título y artista (fallback Genius)
class SearchLetraByTitleArtist extends LetraEvent {
  final String title;
  final String artist;
  final String? cancionId; // opcional para cache

  const SearchLetraByTitleArtist(this.title, this.artist, {this.cancionId});

  @override
  List<Object?> get props => [title, artist, cancionId];
}

/// Cargar todas las letras almacenadas localmente
class LoadLetrasLocales extends LetraEvent {}

/// Borrar una letra concreta de la cache local
class DeleteLetra extends LetraEvent {
  final String trackId;
  const DeleteLetra(this.trackId);

  @override
  List<Object?> get props => [trackId];
}

/// Limpiar todas las letras locales
class ClearLetras extends LetraEvent {}
