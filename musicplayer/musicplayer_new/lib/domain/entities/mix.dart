import 'cancion.dart'; // Asegúrate de importar la clase Cancion

class Mix {
  final String id;
  final String titulo;
  final String subtitulo;
  final String? portadaUrl;
  final int cantidadPistas;
  final List<Cancion>? tracks;

  Mix({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    this.portadaUrl,
    required this.cantidadPistas,
    this.tracks,
  });

  factory Mix.fromMap(Map<String, dynamic> map) {
    return Mix(
      id: map['id'],
      titulo: map['title'],
      subtitulo: map['subtitle'],
      portadaUrl: map['cover_url'],
      cantidadPistas: map['number_of_tracks'],
      tracks:
          map['tracks'] != null
              ? List<Cancion>.from(map['tracks'].map((t) => Cancion.fromMap(t)))
              : null,
    );
  }

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
