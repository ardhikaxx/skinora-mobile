import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/admin_user_model.dart';
import '../models/satusehat_models.dart';
import '../models/user_profile.dart';
import 'satusehat_config.dart';
import 'user_service.dart';

/// Layanan integrasi API SATUSEHAT Kemenkes (mode Sandbox / Production)
/// untuk autentikasi OAuth2, Master Wilayah, pencarian, dan pendaftaran
/// resource FHIR R4 `Patient`.
class SatuSehatService {
  SatuSehatService._();

  static const Duration _timeout = Duration(seconds: 20);

  static http.Client? _clientOverride;
  static String? _cachedToken;
  static DateTime? _tokenExpiresAt;
  static String? _cachedTokenKey;

  /// Inject custom `http.Client` untuk unit test tanpa jaringan nyata.
  static void setHttpClientForTest(http.Client? client) {
    _clientOverride = client;
    clearTokenCache();
  }

  /// Hapus cache token OAuth2 di memori.
  static void clearTokenCache() {
    _cachedToken = null;
    _tokenExpiresAt = null;
    _cachedTokenKey = null;
  }

  static http.Client _client() => _clientOverride ?? http.Client();

  static void _closeIfOwned(http.Client client) {
    if (!identical(client, _clientOverride)) {
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // OAuth2 Client Credentials
  // ---------------------------------------------------------------------------

  /// Mendapatkan `access_token` OAuth2 (`client_credentials`).
  /// Token di-cache hingga 60 detik sebelum kedaluwarsa.
  static Future<String> getAccessToken({bool forceRefresh = false}) async {
    final cfg = SatuSehatConfig.current;
    if (!cfg.isConfigured) {
      throw const SatuSehatException(
        'Kredensial SATUSEHAT belum lengkap (Organization ID / Client ID / Client Secret).',
      );
    }

    final tokenKey = '${cfg.host}|${cfg.clientId}';
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedToken != null &&
        _cachedTokenKey == tokenKey &&
        _tokenExpiresAt != null &&
        now.isBefore(_tokenExpiresAt!)) {
      return _cachedToken!;
    }

    final uri = Uri.parse('${cfg.authBaseUrl}/accesstoken').replace(
      queryParameters: const {'grant_type': 'client_credentials'},
    );

    final client = _client();
    try {
      final res = await client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'client_id': cfg.clientId,
              'client_secret': cfg.clientSecret,
            },
          )
          .timeout(_timeout);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw SatuSehatException(
          'Autentikasi SATUSEHAT gagal (${res.statusCode}): ${_extractErrorMessage(res.body)}',
          statusCode: res.statusCode,
          rawBody: res.body,
        );
      }

      final json = _decodeJsonMap(res.body);
      final token = (json['access_token'] as String?)?.trim() ?? '';
      if (token.isEmpty) {
        throw SatuSehatException(
          'Respon autentikasi SATUSEHAT tidak mengandung access_token.',
          statusCode: res.statusCode,
          rawBody: res.body,
        );
      }

      final expiresRaw = json['expires_in'];
      final expiresSec = expiresRaw is int
          ? expiresRaw
          : int.tryParse(expiresRaw?.toString() ?? '') ?? 3600;
      final safeTtl = expiresSec > 120 ? expiresSec - 60 : expiresSec;

      _cachedToken = token;
      _cachedTokenKey = tokenKey;
      _tokenExpiresAt = DateTime.now().add(Duration(seconds: safeTtl));
      return token;
    } on SatuSehatException {
      rethrow;
    } catch (e) {
      throw SatuSehatException('Gagal menghubungi server OAuth2 SATUSEHAT: $e');
    } finally {
      _closeIfOwned(client);
    }
  }

  /// Verifikasi koneksi Sandbox + validasi Organization ID ke SATUSEHAT.
  static Future<SatuSehatOrganizationInfo> verifyConnection() async {
    final cfg = SatuSehatConfig.current;
    final token = await getAccessToken(forceRefresh: true);
    final uri = Uri.parse('${cfg.fhirBaseUrl}/Organization/${cfg.organizationId}');

    final client = _client();
    try {
      final res = await client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw SatuSehatException(
          'Gagal membaca Organization SATUSEHAT (${res.statusCode}): ${_extractErrorMessage(res.body)}',
          statusCode: res.statusCode,
          rawBody: res.body,
        );
      }

      final json = _decodeJsonMap(res.body);
      String phone = '';
      String email = '';
      final telecoms = json['telecom'];
      if (telecoms is List) {
        for (final item in telecoms) {
          if (item is Map<String, dynamic>) {
            if (item['system'] == 'phone' && phone.isEmpty) {
              phone = (item['value'] as String?) ?? '';
            } else if (item['system'] == 'email' && email.isEmpty) {
              email = (item['value'] as String?) ?? '';
            }
          }
        }
      }

      return SatuSehatOrganizationInfo(
        id: (json['id'] as String?) ?? cfg.organizationId,
        name: (json['name'] as String?) ?? '-',
        active: (json['active'] as bool?) ?? false,
        phone: phone,
        email: email,
      );
    } on SatuSehatException {
      rethrow;
    } catch (e) {
      throw SatuSehatException('Gagal memverifikasi koneksi SATUSEHAT: $e');
    } finally {
      _closeIfOwned(client);
    }
  }

  // ---------------------------------------------------------------------------
  // Master Wilayah Administratif (/masterdata/v1)
  // ---------------------------------------------------------------------------

  static Future<List<SatuSehatRegionItem>> fetchProvinces() async {
    final cfg = SatuSehatConfig.current;
    return _fetchRegions('${cfg.masterDataBaseUrl}/provinces');
  }

  static Future<List<SatuSehatRegionItem>> fetchCities(String provinceCode) async {
    final clean = provinceCode.trim();
    if (clean.isEmpty) return const [];
    final cfg = SatuSehatConfig.current;
    return _fetchRegions(
      '${cfg.masterDataBaseUrl}/cities?province_codes=${Uri.encodeQueryComponent(clean)}',
    );
  }

  static Future<List<SatuSehatRegionItem>> fetchDistricts(String cityCode) async {
    final clean = cityCode.trim();
    if (clean.isEmpty) return const [];
    final cfg = SatuSehatConfig.current;
    return _fetchRegions(
      '${cfg.masterDataBaseUrl}/districts?city_codes=${Uri.encodeQueryComponent(clean)}',
    );
  }

  static Future<List<SatuSehatRegionItem>> fetchVillages(String districtCode) async {
    final clean = districtCode.trim();
    if (clean.isEmpty) return const [];
    final cfg = SatuSehatConfig.current;
    return _fetchRegions(
      '${cfg.masterDataBaseUrl}/sub-districts?district_codes=${Uri.encodeQueryComponent(clean)}',
    );
  }

  static Future<List<SatuSehatRegionItem>> _fetchRegions(String url) async {
    final token = await getAccessToken();
    final client = _client();
    try {
      final res = await client
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (res.statusCode == 401) {
        final refreshed = await getAccessToken(forceRefresh: true);
        final retry = await client
            .get(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $refreshed',
                'Accept': 'application/json',
              },
            )
            .timeout(_timeout);
        if (retry.statusCode < 200 || retry.statusCode >= 300) {
          throw SatuSehatException(
            'Gagal memuat master wilayah (${retry.statusCode}).',
            statusCode: retry.statusCode,
            rawBody: retry.body,
          );
        }
        return _parseRegionsResponse(retry.body);
      }

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw SatuSehatException(
          'Gagal memuat master wilayah (${res.statusCode}): ${_extractErrorMessage(res.body)}',
          statusCode: res.statusCode,
          rawBody: res.body,
        );
      }

      return _parseRegionsResponse(res.body);
    } on SatuSehatException {
      rethrow;
    } catch (e) {
      throw SatuSehatException('Gagal mengambil data wilayah SATUSEHAT: $e');
    } finally {
      _closeIfOwned(client);
    }
  }

  static List<SatuSehatRegionItem> _parseRegionsResponse(String body) {
    final json = _decodeJsonMap(body);
    final data = json['data'];
    if (data is! List) return const [];
    final items = data
        .whereType<Map<String, dynamic>>()
        .map(SatuSehatRegionItem.fromJson)
        .where((e) => e.code.isNotEmpty && e.name.isNotEmpty)
        .toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  // ---------------------------------------------------------------------------
  // Validasi & Builder Payload FHIR R4 Patient
  // ---------------------------------------------------------------------------

  /// Mapping jenis kelamin aplikasi ke kode gender FHIR R4 (`male` | `female`).
  static String mapGenderToFhir(String gender) {
    final g = gender.trim().toLowerCase();
    if (g == 'laki-laki' || g == 'male' || g == 'l' || g == 'pria') {
      return 'male';
    }
    if (g == 'perempuan' || g == 'female' || g == 'p' || g == 'wanita') {
      return 'female';
    }
    return '';
  }

  /// Validasi field wajib pasien sebelum dikirim ke SATUSEHAT.
  static List<String> validatePatientInput(SatuSehatPatientInput input) {
    final errors = <String>[];
    if (!RegExp(r'^\d{16}$').hasMatch(input.nik.trim())) {
      errors.add('NIK wajib diisi tepat 16 digit angka.');
    }
    if (input.name.trim().isEmpty) {
      errors.add('Nama lengkap pasien wajib diisi.');
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(input.birthDate.trim()) ||
        DateTime.tryParse(input.birthDate.trim()) == null) {
      errors.add('Tanggal lahir wajib berformat YYYY-MM-DD.');
    }
    if (mapGenderToFhir(input.gender).isEmpty) {
      errors.add('Jenis kelamin wajib dipilih (Laki-laki atau Perempuan).');
    }
    if (input.phone.trim().length < 8) {
      errors.add('Nomor telepon pasien wajib minimal 8 digit.');
    }
    if (input.addressLine.trim().length < 3) {
      errors.add('Alamat lengkap pasien wajib diisi.');
    }
    if (input.provinceCode.trim().isEmpty ||
        input.cityCode.trim().isEmpty ||
        input.districtCode.trim().isEmpty ||
        input.villageCode.trim().isEmpty) {
      errors.add(
        'Kode wilayah administratif (Provinsi, Kota/Kabupaten, Kecamatan, dan Kelurahan/Desa) wajib lengkap untuk SATUSEHAT.',
      );
    }
    return errors;
  }

  /// Menyusun payload JSON FHIR R4 `Patient` sesuai profil Kemenkes SATUSEHAT.
  static Map<String, dynamic> buildFhirPatientPayload(
    SatuSehatPatientInput input,
  ) {
    final marital = SatuSehatMaritalStatus.byCode(input.maritalStatusCode);
    final fhirGender = mapGenderToFhir(input.gender);

    final telecom = <Map<String, dynamic>>[
      {
        'system': 'phone',
        'value': input.phone.trim(),
        'use': 'mobile',
      },
      if (input.email.trim().isNotEmpty)
        {
          'system': 'email',
          'value': input.email.trim(),
          'use': 'home',
        },
    ];

    final addressEntry = <String, dynamic>{
      'use': 'home',
      'line': [input.addressLine.trim()],
      if (input.cityName.trim().isNotEmpty) 'city': input.cityName.trim(),
      if (input.postalCode.trim().isNotEmpty)
        'postalCode': input.postalCode.trim(),
      'country': 'ID',
      'extension': [
        {
          'url':
              'https://fhir.kemkes.go.id/r4/StructureDefinition/administrativeCode',
          'extension': [
            {'url': 'province', 'valueCode': input.provinceCode.trim()},
            {'url': 'city', 'valueCode': input.cityCode.trim()},
            {'url': 'district', 'valueCode': input.districtCode.trim()},
            {'url': 'village', 'valueCode': input.villageCode.trim()},
          ],
        },
      ],
    };

    return {
      'resourceType': 'Patient',
      'meta': {
        'profile': [
          'https://fhir.kemkes.go.id/r4/StructureDefinition/Patient',
        ],
      },
      'identifier': [
        {
          'use': 'official',
          'system': 'https://fhir.kemkes.go.id/id/nik',
          'value': input.nik.trim(),
        },
      ],
      'active': true,
      'name': [
        {
          'use': 'official',
          'text': input.name.trim(),
        },
      ],
      'telecom': telecom,
      'gender': fhirGender,
      'birthDate': input.birthDate.trim(),
      'deceasedBoolean': false,
      'address': [addressEntry],
      'maritalStatus': {
        'coding': [
          {
            'system':
                'http://terminology.hl7.org/CodeSystem/v3-MaritalStatus',
            'code': marital.code,
            'display': marital.display,
          },
        ],
        'text': marital.display,
      },
      'multipleBirthInteger': 0,
      'communication': [
        {
          'language': {
            'coding': [
              {
                'system': 'urn:ietf:bcp:47',
                'code': 'id-ID',
                'display': 'Indonesian',
              },
            ],
            'text': 'Indonesian',
          },
          'preferred': true,
        },
      ],
    };
  }

  /// Mengambil IHS Number dari object FHIR `Patient`.
  static String extractIhsNumber(Map<String, dynamic> patientResource) {
    final identifiers = patientResource['identifier'];
    if (identifiers is List) {
      for (final item in identifiers) {
        if (item is Map<String, dynamic>) {
          final sys = (item['system'] as String?) ?? '';
          if (sys == 'https://fhir.kemkes.go.id/id/ihs-number' ||
              sys == 'https://fhir.kemkes.go.id/id/patient-ihs-number') {
            final val = (item['value'] as String?)?.trim() ?? '';
            if (val.isNotEmpty) return val;
          }
        }
      }
    }
    return (patientResource['id'] as String?)?.trim() ?? '';
  }

  static SatuSehatPatientRecord _recordFromPatientJson(
    Map<String, dynamic> resource,
  ) {
    final ihs = extractIhsNumber(resource);
    String name = '';
    final names = resource['name'];
    if (names is List && names.isNotEmpty && names.first is Map) {
      name = ((names.first as Map)['text'] as String?)?.trim() ?? '';
    }
    String nikMasked = '';
    final identifiers = resource['identifier'];
    if (identifiers is List) {
      for (final item in identifiers) {
        if (item is Map && item['system'] == 'https://fhir.kemkes.go.id/id/nik') {
          nikMasked = (item['value'] as String?)?.trim() ?? '';
          break;
        }
      }
    }
    return SatuSehatPatientRecord(
      ihsNumber: ihs,
      name: name,
      gender: (resource['gender'] as String?) ?? '',
      birthDate: (resource['birthDate'] as String?) ?? '',
      nikMasked: nikMasked,
      active: (resource['active'] as bool?) ?? true,
      rawJson: resource,
    );
  }

  // ---------------------------------------------------------------------------
  // Search & Create Patient (FHIR R4)
  // ---------------------------------------------------------------------------

  /// Cari pasien berdasarkan NIK (`GET /Patient?identifier=https://fhir.kemkes.go.id/id/nik|{nik}`).
  static Future<SatuSehatPatientRecord?> searchPatientByNik(String nik) async {
    final cleanNik = nik.trim();
    if (cleanNik.isEmpty) return null;

    final cfg = SatuSehatConfig.current;
    final token = await getAccessToken();
    final uri = Uri.parse('${cfg.fhirBaseUrl}/Patient').replace(
      queryParameters: {
        'identifier': 'https://fhir.kemkes.go.id/id/nik|$cleanNik',
      },
    );

    final client = _client();
    try {
      final res = await client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw SatuSehatException(
          'Pencarian pasien berdasarkan NIK gagal (${res.statusCode}): ${_extractErrorMessage(res.body)}',
          statusCode: res.statusCode,
          rawBody: res.body,
        );
      }

      final bundle = _decodeJsonMap(res.body);
      final entries = bundle['entry'];
      if (entries is List && entries.isNotEmpty) {
        for (final entry in entries) {
          if (entry is Map<String, dynamic>) {
            final resource = entry['resource'];
            if (resource is Map<String, dynamic> &&
                resource['resourceType'] == 'Patient') {
              final record = _recordFromPatientJson(resource);
              if (record.ihsNumber.isNotEmpty) return record;
            }
          }
        }
      }
      return null;
    } on SatuSehatException {
      rethrow;
    } catch (e) {
      throw SatuSehatException('Gagal mencari pasien di SATUSEHAT: $e');
    } finally {
      _closeIfOwned(client);
    }
  }

  /// Ambil data pasien langsung dengan IHS Number (`GET /Patient/{ihsNumber}`).
  static Future<SatuSehatPatientRecord?> getPatientByIhs(String ihsNumber) async {
    final clean = ihsNumber.trim();
    if (clean.isEmpty) return null;

    final cfg = SatuSehatConfig.current;
    final token = await getAccessToken();
    final uri = Uri.parse('${cfg.fhirBaseUrl}/Patient/$clean');

    final client = _client();
    try {
      final res = await client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (res.statusCode == 404) return null;
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw SatuSehatException(
          'Gagal membaca pasien SATUSEHAT (${res.statusCode}): ${_extractErrorMessage(res.body)}',
          statusCode: res.statusCode,
          rawBody: res.body,
        );
      }

      final json = _decodeJsonMap(res.body);
      if (json['resourceType'] != 'Patient') return null;
      return _recordFromPatientJson(json);
    } on SatuSehatException {
      rethrow;
    } catch (e) {
      throw SatuSehatException('Gagal mengambil data pasien dari SATUSEHAT: $e');
    } finally {
      _closeIfOwned(client);
    }
  }

  /// Cari pasien berdasarkan nama, tanggal lahir, dan jenis kelamin.
  static Future<List<SatuSehatPatientRecord>> searchPatientByDemographics({
    required String name,
    required String birthDate,
    required String gender,
  }) async {
    final cfg = SatuSehatConfig.current;
    final token = await getAccessToken();
    final fhirGender = mapGenderToFhir(gender);
    final query = <String, String>{
      if (name.trim().isNotEmpty) 'name': name.trim(),
      if (birthDate.trim().isNotEmpty) 'birthdate': birthDate.trim(),
      if (fhirGender.isNotEmpty) 'gender': fhirGender,
    };
    final uri = Uri.parse('${cfg.fhirBaseUrl}/Patient').replace(
      queryParameters: query,
    );

    final client = _client();
    try {
      final res = await client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw SatuSehatException(
          'Pencarian demografi pasien gagal (${res.statusCode}): ${_extractErrorMessage(res.body)}',
          statusCode: res.statusCode,
          rawBody: res.body,
        );
      }

      final bundle = _decodeJsonMap(res.body);
      final entries = bundle['entry'];
      if (entries is! List) return const [];
      return entries
          .whereType<Map<String, dynamic>>()
          .map((e) => e['resource'])
          .whereType<Map<String, dynamic>>()
          .where((r) => r['resourceType'] == 'Patient')
          .map(_recordFromPatientJson)
          .where((r) => r.ihsNumber.isNotEmpty)
          .toList();
    } on SatuSehatException {
      rethrow;
    } catch (e) {
      throw SatuSehatException('Gagal mencari pasien di SATUSEHAT: $e');
    } finally {
      _closeIfOwned(client);
    }
  }

  /// Mengirim atau mencocokkan data pasien ke SATUSEHAT (`GET` by NIK -> `POST /Patient`).
  ///
  /// 1. Validasi data pasien & kode wilayah.
  /// 2. Cek apakah NIK sudah terdaftar di SATUSEHAT via `GET /Patient`.
  /// 3. Jika belum terdaftar, kirim `POST /Patient` untuk membuat data baru dan
  ///    memperoleh IHS Number.
  /// 4. Jika `POST` mengembalikan HTTP 400 dengan resource `Patient` (NIK sudah
  ///    pernah didaftarkan), IHS Number tetap diekstrak sebagai `matched`.
  static Future<SatuSehatPatientSyncResult> syncPatient(
    SatuSehatPatientInput input,
  ) async {
    final errors = validatePatientInput(input);
    if (errors.isNotEmpty) {
      throw SatuSehatException(errors.first);
    }

    final payload = buildFhirPatientPayload(input);
    final nowIso = DateTime.now().toUtc().toIso8601String();

    // Tahap 1: Cari dulu berdasarkan NIK agar idempoten.
    final existing = await searchPatientByNik(input.nik);
    if (existing != null && existing.ihsNumber.isNotEmpty) {
      return SatuSehatPatientSyncResult(
        success: true,
        action: 'matched',
        ihsNumber: existing.ihsNumber,
        message:
            'Pasien ditemukan di SATUSEHAT dengan IHS Number ${existing.ihsNumber}.',
        syncedAtIso: nowIso,
        requestPayload: payload,
        responseJson: existing.rawJson,
      );
    }

    // Tahap 2: Belum ada -> kirim POST /Patient
    final cfg = SatuSehatConfig.current;
    final token = await getAccessToken();
    final uri = Uri.parse('${cfg.fhirBaseUrl}/Patient');

    final client = _client();
    try {
      final res = await client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      final parsedBody = _tryDecodeJsonMap(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300 && parsedBody != null) {
        final ihs = extractIhsNumber(parsedBody);
        if (ihs.isEmpty) {
          throw SatuSehatException(
            'SATUSEHAT tidak mengembalikan IHS Number pasien.',
            statusCode: res.statusCode,
            rawBody: res.body,
          );
        }
        return SatuSehatPatientSyncResult(
          success: true,
          action: 'created',
          ihsNumber: ihs,
          message:
              'Data pasien berhasil dikirim ke SATUSEHAT (IHS Number: $ihs).',
          syncedAtIso: nowIso,
          requestPayload: payload,
          responseJson: parsedBody,
        );
      }

      // SATUSEHAT Staging mengembalikan HTTP 400 dengan body Patient existing
      // apabila NIK yang di-POST ternyata sudah terdaftar.
      if (res.statusCode == 400 &&
          parsedBody != null &&
          parsedBody['resourceType'] == 'Patient') {
        final ihs = extractIhsNumber(parsedBody);
        if (ihs.isNotEmpty) {
          return SatuSehatPatientSyncResult(
            success: true,
            action: 'matched',
            ihsNumber: ihs,
            message:
                'NIK sudah terdaftar di SATUSEHAT (IHS Number: $ihs).',
            syncedAtIso: nowIso,
            requestPayload: payload,
            responseJson: parsedBody,
          );
        }
      }

      throw SatuSehatException(
        'Gagal mengirim data pasien ke SATUSEHAT (${res.statusCode}): ${_extractErrorMessage(res.body)}',
        statusCode: res.statusCode,
        rawBody: res.body,
      );
    } on SatuSehatException {
      rethrow;
    } catch (e) {
      throw SatuSehatException('Gagal mengirim data pasien ke SATUSEHAT: $e');
    } finally {
      _closeIfOwned(client);
    }
  }

  // ---------------------------------------------------------------------------
  // Integrasi langsung dengan UserService (Skinora Firestore / Mock)
  // ---------------------------------------------------------------------------

  /// Sinkronkan [UserProfile] ke SATUSEHAT lalu simpan IHS Number & metadata
  /// ke Firestore `users/{uid}` (atau mock profile saat pengujian).
  static Future<SatuSehatPatientSyncResult> syncAndPersistUserProfile(
    UserProfile profile, {
    SatuSehatPatientInput? inputOverride,
  }) {
    final input = inputOverride ?? SatuSehatPatientInput.fromUserProfile(profile);
    final docId = profile.uid.isNotEmpty ? profile.uid : profile.docId;
    return _syncAndPersist(
      docId: docId,
      registered: profile.registered,
      input: input,
    );
  }

  /// Sinkronkan [AdminUserModel] ke SATUSEHAT lalu simpan IHS Number & status.
  static Future<SatuSehatPatientSyncResult> syncAndPersistAdminUser(
    AdminUserModel user, {
    SatuSehatPatientInput? inputOverride,
  }) {
    final input = inputOverride ?? SatuSehatPatientInput.fromAdminUser(user);
    return _syncAndPersist(
      docId: user.backendId,
      registered: user.registered,
      input: input,
    );
  }

  static Future<SatuSehatPatientSyncResult> _syncAndPersist({
    required String docId,
    required bool registered,
    required SatuSehatPatientInput input,
  }) async {
    try {
      final result = await syncPatient(input);
      if (docId.isNotEmpty) {
        await UserService.saveUserSatuSehatData(
          docId,
          registered: registered,
          fields: {
            'name': input.name,
            'phone': input.phone,
            'address': input.addressLine,
            'birthDate': input.birthDate,
            'gender': input.gender,
            'nik': input.nik,
            'provinceCode': input.provinceCode,
            'provinceName': input.provinceName,
            'cityCode': input.cityCode,
            'cityName': input.cityName,
            'districtCode': input.districtCode,
            'districtName': input.districtName,
            'villageCode': input.villageCode,
            'villageName': input.villageName,
            'postalCode': input.postalCode,
            'maritalStatusCode': input.maritalStatusCode,
            'ihsNumber': result.ihsNumber,
            'satuSehatStatus': 'terhubung',
            'satuSehatSyncedAt': result.syncedAtIso,
            'satuSehatLastError': '',
          },
        );
      }
      return result;
    } catch (e) {
      if (docId.isNotEmpty) {
        await UserService.saveUserSatuSehatData(
          docId,
          registered: registered,
          fields: {
            'satuSehatStatus': 'gagal',
            'satuSehatLastError': e.toString(),
          },
        ).catchError((_) {});
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers JSON & Error Parsing
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _decodeJsonMap(String body) {
    final parsed = _tryDecodeJsonMap(body);
    if (parsed == null) {
      throw SatuSehatException(
        'Respon SATUSEHAT bukan JSON valid.',
        rawBody: body,
      );
    }
    return parsed;
  }

  static Map<String, dynamic>? _tryDecodeJsonMap(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _extractErrorMessage(String body) {
    final json = _tryDecodeJsonMap(body);
    if (json == null) {
      return body.trim().isEmpty ? 'Tidak ada keterangan error.' : body.trim();
    }
    if (json['resourceType'] == 'OperationOutcome') {
      final issues = json['issue'];
      if (issues is List && issues.isNotEmpty) {
        final messages = <String>[];
        for (final issue in issues) {
          if (issue is Map<String, dynamic>) {
            final details = issue['details'];
            final diagnostics = issue['diagnostics'];
            String? text;
            if (details is Map<String, dynamic>) {
              text = details['text'] as String?;
            }
            text ??= diagnostics as String?;
            if (text != null && text.trim().isNotEmpty) {
              messages.add(text.trim());
            }
          }
        }
        if (messages.isNotEmpty) return messages.join('; ');
      }
    }
    final errDesc = json['error_description'] ?? json['message'] ?? json['fault'];
    if (errDesc != null) return errDesc.toString();
    return body.trim();
  }
}
