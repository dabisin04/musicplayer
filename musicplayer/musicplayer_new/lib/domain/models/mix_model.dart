import 'package:hive/hive.dart';
import 'package:musicplayer/domain/models/cancion_model.dart' as model;
import 'package:musicplayer/domain/entities/mix.dart' as entity;
part 'mix_model.g.dart';

@HiveType(typeId: 2)
class Mix extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String titulo;

  @HiveField(2)
  String subtitulo;

  @HiveField(3)
  String? portadaUrl;

  @HiveField(4)
  int cantidadPistas;

  @HiveField(5)
  List<model.Cancion>? tracks;

  Mix({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    this.portadaUrl,
    required this.cantidadPistas,
    this.tracks,
  });

  factory Mix.fromEntity(entity.Mix m) => Mix(
    id: m.id,
    titulo: m.titulo,
    subtitulo: m.subtitulo,
    portadaUrl: m.portadaUrl,
    cantidadPistas: m.cantidadPistas,
    tracks: m.tracks?.map((e) => model.Cancion.fromEntity(e)).toList(),
  );

  entity.Mix toEntity() => entity.Mix(
    id: id,
    titulo: titulo,
    subtitulo: subtitulo,
    portadaUrl: portadaUrl,
    cantidadPistas: cantidadPistas,
    tracks: tracks?.map((t) => t.toEntity()).toList(),
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': titulo,
      'subtitle': subtitulo,
      'cover_url': portadaUrl,
      'number_of_tracks': cantidadPistas,
      'tracks': tracks?.map((t) => t.toMap()).toList(),
    };
  }
}
