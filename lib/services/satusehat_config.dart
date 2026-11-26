/// Mode environment SATUSEHAT Kemenkes RI.
enum SatuSehatEnvironment {
  sandbox,
  production,
}

/// Konfigurasi kredensial dan endpoint SATUSEHAT.
///
/// Secara default memakai mode **Sandbox / Staging** agar integrasi dapat
/// langsung diuji terhadap `api-satusehat-stg.dto.kemkes.go.id`.
/// Untuk production, gunakan `--dart-define=SATUSEHAT_ENV=production` dan
/// pindahkan `clientSecret` ke backend proxy / Cloud Functions.
class SatuSehatConfig {
  final SatuSehatEnvironment environment;
  final String organizationId;
  final String clientId;
  final String clientSecret;

  const SatuSehatConfig({
    required this.environment,
    required this.organizationId,
    required this.clientId,
    required this.clientSecret,
  });

  static const String _envDefine = String.fromEnvironment(
    'SATUSEHAT_ENV',
    defaultValue: 'sandbox',
  );
  static const String _orgDefine = String.fromEnvironment(
    'SATUSEHAT_ORG_ID',
    defaultValue: '00e3b782-a631-43ab-9187-1971043abdd6',
  );
  static const String _clientIdDefine = String.fromEnvironment(
    'SATUSEHAT_CLIENT_ID',
    defaultValue: 'pKIu76lAgU9AqniYTFeBtIgPPvAcGzgOy2pLQpNG6wvVDKC3',
  );
  static const String _clientSecretDefine = String.fromEnvironment(
    'SATUSEHAT_CLIENT_SECRET',
    defaultValue: 'GmgwZGMJbUOnLY35r0xIgibFr6yG5uGk59KYATAc5w2GhwUltw939aQ32hBtP82F',
  );

  static SatuSehatConfig? _override;

  /// Konfigurasi aktif saat ini (override bila diset, atau bawaan Sandbox).
  static SatuSehatConfig get current {
    if (_override != null) return _override!;
    final env = _envDefine.trim().toLowerCase() == 'production'
        ? SatuSehatEnvironment.production
        : SatuSehatEnvironment.sandbox;
    return SatuSehatConfig(
      environment: env,
      organizationId: _orgDefine.trim(),
      clientId: _clientIdDefine.trim(),
      clientSecret: _clientSecretDefine.trim(),
    );
  }

  /// Override konfigurasi saat runtime atau unit test.
  static void setOverride(SatuSehatConfig? config) {
    _override = config;
  }

  bool get isSandbox => environment == SatuSehatEnvironment.sandbox;

  String get environmentLabel =>
      isSandbox ? 'Sandbox (Staging)' : 'Production';

  String get host => isSandbox
      ? 'api-satusehat-stg.dto.kemkes.go.id'
      : 'api-satusehat.kemkes.go.id';

  String get authBaseUrl => 'https://$host/oauth2/v1';
  String get fhirBaseUrl => 'https://$host/fhir-r4/v1';
  String get masterDataBaseUrl => 'https://$host/masterdata/v1';

  bool get isConfigured =>
      organizationId.isNotEmpty &&
      clientId.isNotEmpty &&
      clientSecret.isNotEmpty;
}
