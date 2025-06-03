class ConfiguracionAPI {
  final String? tidalVerificationUrl;
  final DateTime? tidalCreatedAt;
  final int? tidalExpiresIn;
  final bool tidalAuthenticated;

  final String? geniusAccessToken;
  final bool geniusAuthenticated;

  final String? tidalApiUrl;
  final String? geniusApiUrl;

  ConfiguracionAPI({
    this.tidalVerificationUrl,
    this.tidalCreatedAt,
    this.tidalExpiresIn,
    this.tidalAuthenticated = false,
    this.geniusAccessToken,
    this.geniusAuthenticated = false,
    this.tidalApiUrl,
    this.geniusApiUrl,
  });

  factory ConfiguracionAPI.fromMap(Map<String, dynamic> map) {
    return ConfiguracionAPI(
      tidalVerificationUrl: map['tidalVerificationUrl'],
      tidalCreatedAt:
          map['tidalCreatedAt'] != null
              ? DateTime.tryParse(map['tidalCreatedAt'])
              : null,
      tidalExpiresIn: map['tidalExpiresIn'],
      tidalAuthenticated: map['tidalAuthenticated'] ?? false,
      geniusAccessToken: map['geniusAccessToken'],
      geniusAuthenticated: map['geniusAuthenticated'] ?? false,
      tidalApiUrl: map['tidalApiUrl'],
      geniusApiUrl: map['geniusApiUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tidalVerificationUrl': tidalVerificationUrl,
      'tidalCreatedAt': tidalCreatedAt?.toIso8601String(),
      'tidalExpiresIn': tidalExpiresIn,
      'tidalAuthenticated': tidalAuthenticated,
      'geniusAccessToken': geniusAccessToken,
      'geniusAuthenticated': geniusAuthenticated,
      'tidalApiUrl': tidalApiUrl,
      'geniusApiUrl': geniusApiUrl,
    };
  }

  ConfiguracionAPI copyWith({
    String? tidalVerificationUrl,
    DateTime? tidalCreatedAt,
    int? tidalExpiresIn,
    bool? tidalAuthenticated,
    String? geniusAccessToken,
    bool? geniusAuthenticated,
    String? tidalApiUrl,
    String? geniusApiUrl,
  }) {
    return ConfiguracionAPI(
      tidalVerificationUrl: tidalVerificationUrl ?? this.tidalVerificationUrl,
      tidalCreatedAt: tidalCreatedAt ?? this.tidalCreatedAt,
      tidalExpiresIn: tidalExpiresIn ?? this.tidalExpiresIn,
      tidalAuthenticated: tidalAuthenticated ?? this.tidalAuthenticated,
      geniusAccessToken: geniusAccessToken ?? this.geniusAccessToken,
      geniusAuthenticated: geniusAuthenticated ?? this.geniusAuthenticated,
      tidalApiUrl: tidalApiUrl ?? this.tidalApiUrl,
      geniusApiUrl: geniusApiUrl ?? this.geniusApiUrl,
    );
  }
}
