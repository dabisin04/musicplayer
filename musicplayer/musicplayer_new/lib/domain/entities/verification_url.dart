class VerificationUri {
  final String verificationUrl;

  VerificationUri({required this.verificationUrl});

  Map<String, dynamic> toJson() => {'verification_url': verificationUrl};
}
