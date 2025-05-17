class ConfiguracionUsuario {
  final String carpetaDescargas;
  final String calidadPreferida;
  final bool mostrarLetra;

  ConfiguracionUsuario({
    required this.carpetaDescargas,
    required this.calidadPreferida,
    required this.mostrarLetra,
  });

  factory ConfiguracionUsuario.fromMap(Map<String, dynamic> map) {
    return ConfiguracionUsuario(
      carpetaDescargas: map['carpetaDescargas'],
      calidadPreferida: map['calidadPreferida'],
      mostrarLetra: map['mostrarLetra'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'carpetaDescargas': carpetaDescargas,
      'calidadPreferida': calidadPreferida,
      'mostrarLetra': mostrarLetra,
    };
  }
}
