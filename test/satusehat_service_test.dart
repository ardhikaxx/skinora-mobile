import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:skinora_app/models/admin_user_model.dart';
import 'package:skinora_app/models/satusehat_models.dart';
import 'package:skinora_app/models/user_profile.dart';
import 'package:skinora_app/pages/admin/detail_pengguna_page.dart';
import 'package:skinora_app/pages/admin/manajemen_pengguna_page.dart';
import 'package:skinora_app/pages/admin/pengaturan_admin_page.dart';
import 'package:skinora_app/pages/common/satusehat_patient_sync_page.dart';
import 'package:skinora_app/pages/pengguna/profil_pengguna_page.dart';
import 'package:skinora_app/services/satusehat_config.dart';
import 'package:skinora_app/services/satusehat_service.dart';
import 'package:skinora_app/services/user_service.dart';

SatuSehatPatientInput _validInput({String nik = '3171012345678902'}) {
  return SatuSehatPatientInput(
    nik: nik,
    name: 'Siti Rahmawati',
    phone: '081234567890',
    email: 'siti@example.com',
    gender: 'Perempuan',
    birthDate: '1995-05-15',
    addressLine: 'Jl. Merdeka No. 10',
    provinceCode: '31',
    provinceName: 'DKI Jakarta',
    cityCode: '3171',
    cityName: 'Kota Adm. Jakarta Pusat',
    districtCode: '317101',
    districtName: 'Gambir',
    villageCode: '3171011001',
    villageName: 'Gambir',
    postalCode: '10110',
    maritalStatusCode: 'S',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SatuSehatConfig.setOverride(null);
    SatuSehatService.setHttpClientForTest(null);
    UserService.setMockCurrentProfile(null);
  });

  tearDown(() {
    SatuSehatConfig.setOverride(null);
    SatuSehatService.setHttpClientForTest(null);
    UserService.setMockCurrentProfile(null);
  });

  group('SatuSehatConfig', () {
    test('Default konfigurasi menggunakan mode Sandbox dengan kredensial yang diberikan', () {
      final cfg = SatuSehatConfig.current;
      expect(cfg.isSandbox, isTrue);
      expect(cfg.host, 'api-satusehat-stg.dto.kemkes.go.id');
      expect(cfg.organizationId, '77fd9d28-df0f-4d94-b730-159fffaf1e94');
      expect(cfg.clientId, 'b5hAzjWQk7DGaBeAdod91MSG8JoaoXwo62jQ6lhdLYHunoez');
      expect(cfg.clientSecret, isNotEmpty);
      expect(cfg.isConfigured, isTrue);
    });
  });

  group('SatuSehatService Validasi & Payload FHIR R4', () {
    test('validatePatientInput menolak NIK tidak 16 digit dan kode wilayah kosong', () {
      const invalid = SatuSehatPatientInput(
        nik: '12345',
        name: '',
        phone: '0812',
        gender: '',
        birthDate: '15-05-1995',
        addressLine: 'Jl',
        provinceCode: '',
        cityCode: '',
        districtCode: '',
        villageCode: '',
      );

      final errors = SatuSehatService.validatePatientInput(invalid);
      expect(errors.length, 7);
      expect(errors.first, contains('16 digit'));
    });

    test('buildFhirPatientPayload menghasilkan struktur FHIR R4 Patient valid', () {
      final payload = SatuSehatService.buildFhirPatientPayload(_validInput());
      expect(payload['resourceType'], 'Patient');
      expect(payload['gender'], 'female');
      expect(payload['birthDate'], '1995-05-15');
      expect(payload['identifier'][0]['system'], 'https://fhir.kemkes.go.id/id/nik');
      expect(payload['identifier'][0]['value'], '3171012345678902');
      final address = (payload['address'] as List).first as Map<String, dynamic>;
      final ext = (address['extension'] as List).first as Map<String, dynamic>;
      expect(
        ext['url'],
        'https://fhir.kemkes.go.id/r4/StructureDefinition/administrativeCode',
      );
      final subExt = ext['extension'] as List;
      expect(subExt.length, 4);
    });
  });

  group('SatuSehatService OAuth2, Masterdata, & Patient Sync', () {
    test('getAccessToken melakukan cache token sampai forceRefresh', () async {
      var authCalls = 0;
      SatuSehatService.setHttpClientForTest(MockClient((req) async {
        if (req.url.path.endsWith('/accesstoken')) {
          authCalls++;
          return http.Response(
            jsonEncode({
              'access_token': 'tok_$authCalls',
              'expires_in': '14399',
              'token_type': 'BearerToken',
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      }));

      final t1 = await SatuSehatService.getAccessToken();
      final t2 = await SatuSehatService.getAccessToken();
      final t3 = await SatuSehatService.getAccessToken(forceRefresh: true);

      expect(t1, 'tok_1');
      expect(t2, 'tok_1');
      expect(t3, 'tok_2');
      expect(authCalls, 2);
    });

    test('verifyConnection membaca data Organization Sandbox', () async {
      SatuSehatService.setHttpClientForTest(MockClient((req) async {
        if (req.url.path.endsWith('/accesstoken')) {
          return http.Response(
            jsonEncode({'access_token': 'tok_org', 'expires_in': '3600'}),
            200,
          );
        }
        if (req.url.path.endsWith('/Organization/77fd9d28-df0f-4d94-b730-159fffaf1e94')) {
          return http.Response(
            jsonEncode({
              'resourceType': 'Organization',
              'id': '77fd9d28-df0f-4d94-b730-159fffaf1e94',
              'name': 'STAGING Skinora Clinic',
              'active': true,
              'telecom': [
                {'system': 'phone', 'value': '+6285933648537'},
                {'system': 'email', 'value': 'test@skinora.id'},
              ],
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      }));

      final org = await SatuSehatService.verifyConnection();
      expect(org.id, '77fd9d28-df0f-4d94-b730-159fffaf1e94');
      expect(org.name, 'STAGING Skinora Clinic');
      expect(org.active, isTrue);
    });

    test('syncPatient mengirim POST /Patient jika NIK belum ditemukan dan mengembalikan IHS Number', () async {
      var postedBody = <String, dynamic>{};
      SatuSehatService.setHttpClientForTest(MockClient((req) async {
        if (req.url.path.endsWith('/accesstoken')) {
          return http.Response(
            jsonEncode({'access_token': 'tok_post', 'expires_in': '3600'}),
            200,
          );
        }
        if (req.method == 'GET' && req.url.path.endsWith('/Patient')) {
          return http.Response(
            jsonEncode({
              'resourceType': 'Bundle',
              'type': 'searchset',
              'total': 0,
              'entry': [],
            }),
            200,
          );
        }
        if (req.method == 'POST' && req.url.path.endsWith('/Patient')) {
          postedBody = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'resourceType': 'Patient',
              'id': 'P20396488167',
              'identifier': [
                {
                  'system': 'https://fhir.kemkes.go.id/id/nik',
                  'value': '3171012345678902',
                },
                {
                  'system': 'https://fhir.kemkes.go.id/id/ihs-number',
                  'value': 'P20396488167',
                },
              ],
              'active': true,
            }),
            201,
          );
        }
        return http.Response('Unexpected', 500);
      }));

      final result = await SatuSehatService.syncPatient(_validInput());
      expect(result.success, isTrue);
      expect(result.isCreated, isTrue);
      expect(result.ihsNumber, 'P20396488167');
      expect(postedBody['resourceType'], 'Patient');
      expect(postedBody['gender'], 'female');
    });

    test('syncPatient langsung mencocokkan jika NIK sudah ada pada GET /Patient', () async {
      var postCalled = false;
      SatuSehatService.setHttpClientForTest(MockClient((req) async {
        if (req.url.path.endsWith('/accesstoken')) {
          return http.Response(
            jsonEncode({'access_token': 'tok_match', 'expires_in': '3600'}),
            200,
          );
        }
        if (req.method == 'GET' && req.url.path.endsWith('/Patient')) {
          return http.Response(
            jsonEncode({
              'resourceType': 'Bundle',
              'type': 'searchset',
              'total': 1,
              'entry': [
                {
                  'resource': {
                    'resourceType': 'Patient',
                    'id': 'P02478375538',
                    'identifier': [
                      {
                        'system': 'https://fhir.kemkes.go.id/id/ihs-number',
                        'value': 'P02478375538',
                      },
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }
        if (req.method == 'POST') {
          postCalled = true;
        }
        return http.Response('Unexpected', 500);
      }));

      final result = await SatuSehatService.syncPatient(_validInput());
      expect(result.success, isTrue);
      expect(result.isMatched, isTrue);
      expect(result.ihsNumber, 'P02478375538');
      expect(postCalled, isFalse);
    });

    test('syncPatient mengekstrak IHS Number jika POST mengembalikan 400 Patient existing', () async {
      SatuSehatService.setHttpClientForTest(MockClient((req) async {
        if (req.url.path.endsWith('/accesstoken')) {
          return http.Response(
            jsonEncode({'access_token': 'tok_400', 'expires_in': '3600'}),
            200,
          );
        }
        if (req.method == 'GET' && req.url.path.endsWith('/Patient')) {
          return http.Response(
            jsonEncode({'resourceType': 'Bundle', 'total': 0}),
            200,
          );
        }
        if (req.method == 'POST' && req.url.path.endsWith('/Patient')) {
          return http.Response(
            jsonEncode({
              'resourceType': 'Patient',
              'id': 'P20396488167',
              'identifier': [
                {
                  'system': 'https://fhir.kemkes.go.id/id/ihs-number',
                  'value': 'P20396488167',
                },
              ],
            }),
            400,
          );
        }
        return http.Response('Unexpected', 500);
      }));

      final result = await SatuSehatService.syncPatient(_validInput());
      expect(result.success, isTrue);
      expect(result.isMatched, isTrue);
      expect(result.ihsNumber, 'P20396488167');
    });

    test('syncPatient melempar SatuSehatException terstruktur untuk OperationOutcome error', () async {
      SatuSehatService.setHttpClientForTest(MockClient((req) async {
        if (req.url.path.endsWith('/accesstoken')) {
          return http.Response(
            jsonEncode({'access_token': 'tok_err', 'expires_in': '3600'}),
            200,
          );
        }
        if (req.method == 'GET' && req.url.path.endsWith('/Patient')) {
          return http.Response(
            jsonEncode({'resourceType': 'Bundle', 'total': 0}),
            200,
          );
        }
        if (req.method == 'POST' && req.url.path.endsWith('/Patient')) {
          return http.Response(
            jsonEncode({
              'resourceType': 'OperationOutcome',
              'issue': [
                {
                  'severity': 'error',
                  'details': {'text': 'Element not found: Patient.address'},
                },
              ],
            }),
            400,
          );
        }
        return http.Response('Unexpected', 500);
      }));

      expect(
        () => SatuSehatService.syncPatient(_validInput()),
        throwsA(
          isA<SatuSehatException>().having(
            (e) => e.message,
            'message',
            contains('Element not found: Patient.address'),
          ),
        ),
      );
    });

    test('syncAndPersistUserProfile menyimpan ihsNumber dan status ke UserService', () async {
      final profile = UserProfile(
        uid: 'u_satusehat_1',
        docId: 'u_satusehat_1',
        name: 'Siti Rahmawati',
        email: 'siti@example.com',
        phone: '081234567890',
        address: 'Jl. Merdeka No. 10',
        birthDate: '1995-05-15',
        gender: 'Perempuan',
        nik: '3171012345678902',
        provinceCode: '31',
        cityCode: '3171',
        districtCode: '317101',
        villageCode: '3171011001',
      );
      UserService.setMockCurrentProfile(profile);

      SatuSehatService.setHttpClientForTest(MockClient((req) async {
        if (req.url.path.endsWith('/accesstoken')) {
          return http.Response(
            jsonEncode({'access_token': 'tok_persist', 'expires_in': '3600'}),
            200,
          );
        }
        if (req.method == 'GET' && req.url.path.endsWith('/Patient')) {
          return http.Response(
            jsonEncode({'resourceType': 'Bundle', 'total': 0}),
            200,
          );
        }
        if (req.method == 'POST' && req.url.path.endsWith('/Patient')) {
          return http.Response(
            jsonEncode({
              'resourceType': 'Patient',
              'id': 'P9988776655',
            }),
            201,
          );
        }
        return http.Response('Unexpected', 500);
      }));

      final res = await SatuSehatService.syncAndPersistUserProfile(profile);
      expect(res.ihsNumber, 'P9988776655');

      final reloaded = await UserService.loadByUid('u_satusehat_1');
      expect(reloaded, isNotNull);
      expect(reloaded!.ihsNumber, 'P9988776655');
      expect(reloaded.satuSehatStatus, 'terhubung');
    });
  });

  group('UI Integrasi SATUSEHAT', () {
    testWidgets('SatuSehatPatientSyncPage dapat tes koneksi dan kirim data pasien ke SATUSEHAT', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SatuSehatService.setHttpClientForTest(MockClient((req) async {
        if (req.url.path.endsWith('/accesstoken')) {
          return http.Response(
            jsonEncode({'access_token': 'tok_ui', 'expires_in': '3600'}),
            200,
          );
        }
        if (req.url.path.contains('/masterdata/v1/provinces')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'code': '31', 'parent_code': '', 'bps_code': '31', 'name': 'DKI Jakarta'},
              ],
            }),
            200,
          );
        }
        if (req.url.path.contains('/masterdata/v1/cities')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'code': '3171', 'parent_code': '31', 'bps_code': '3173', 'name': 'Kota Adm. Jakarta Pusat'},
              ],
            }),
            200,
          );
        }
        if (req.url.path.contains('/masterdata/v1/districts')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'code': '317101', 'parent_code': '3171', 'bps_code': '3173080', 'name': 'Gambir'},
              ],
            }),
            200,
          );
        }
        if (req.url.path.contains('/masterdata/v1/sub-districts')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'code': '3171011001', 'parent_code': '317101', 'bps_code': '3173080003', 'name': 'Gambir'},
              ],
            }),
            200,
          );
        }
        if (req.url.path.endsWith('/Organization/77fd9d28-df0f-4d94-b730-159fffaf1e94')) {
          return http.Response(
            jsonEncode({
              'resourceType': 'Organization',
              'id': '77fd9d28-df0f-4d94-b730-159fffaf1e94',
              'name': 'STAGING Skinora',
              'active': true,
            }),
            200,
          );
        }
        if (req.method == 'GET' && req.url.path.endsWith('/Patient')) {
          return http.Response(
            jsonEncode({'resourceType': 'Bundle', 'total': 0}),
            200,
          );
        }
        if (req.method == 'POST' && req.url.path.endsWith('/Patient')) {
          return http.Response(
            jsonEncode({'resourceType': 'Patient', 'id': 'P1234567890'}),
            201,
          );
        }
        return http.Response('Not found', 404);
      }));

      final profile = UserProfile(
        uid: 'ui_user_1',
        docId: 'ui_user_1',
        name: 'Ayu Lestari',
        email: 'ayu@skinora.id',
        phone: '081234567890',
        address: 'Jl. Medan Merdeka Selatan No. 5',
        birthDate: '1997-08-17',
        gender: 'Perempuan',
      );
      UserService.setMockCurrentProfile(profile);

      await tester.pumpWidget(
        MaterialApp(
          home: SatuSehatPatientSyncPage.forPatient(profile),
        ),
      );
      await tester.pumpAndSettle();

      // Tes Koneksi Sandbox
      await tester.tap(find.text('Tes Koneksi'));
      await tester.pumpAndSettle();
      expect(
        find.text('Koneksi aktif: STAGING Skinora (Status: Aktif)'),
        findsOneWidget,
      );

      // Isi NIK 16 digit
      await tester.enterText(
        find.widgetWithText(TextField, '3171012345678902'),
        '3171011708970001',
      );

      // Isi contoh wilayah Jakarta (Sandbox)
      final presetChip = find.text('Isi Wilayah Contoh Jakarta (Sandbox)');
      await tester.ensureVisible(presetChip);
      await tester.tap(presetChip);
      await tester.pumpAndSettle();

      // Kirim pasien ke SATUSEHAT
      final sendBtn = find.text('Kirim Pasien ke SATUSEHAT');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(find.text('Pasien Terdaftar di SATUSEHAT'), findsOneWidget);
      expect(find.textContaining('P1234567890'), findsWidgets);
    });

    testWidgets('ProfilPenggunaPage, DetailPenggunaPage, dan PengaturanAdminPage menampilkan entry SATUSEHAT', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ProfilPenggunaPage()));
      await tester.pumpAndSettle();
      expect(find.text('Integrasi SATUSEHAT'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: DetailPenggunaPage(
            user: AdminUserModel(
              id: '1',
              name: 'Pasien Demo',
              email: 'pasien@demo.com',
              phone: '081234567890',
              address: 'Jakarta',
              birthDate: '1999-01-01',
              gender: 'Perempuan',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sinkronkan ke SATUSEHAT'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: PengaturanAdminPage()));
      await tester.pumpAndSettle();
      expect(find.text('SATUSEHAT Sandbox (Data Pasien)'), findsOneWidget);
    });

    testWidgets('ManajemenPenggunaPage menampilkan badge dan filter pasien terintegrasi SATUSEHAT', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final users = [
        AdminUserModel(
          id: 'u1',
          name: 'Pasien Terhubung',
          email: 'terhubung@skinora.id',
          phone: '081234567890',
          address: 'Jakarta',
          birthDate: '1995-05-15',
          gender: 'Perempuan',
          nik: '3171012611260099',
          ihsNumber: 'P20396488189',
          satuSehatStatus: 'terhubung',
        ),
        AdminUserModel(
          id: 'u2',
          name: 'Pasien Belum Sinkron',
          email: 'belum@skinora.id',
          phone: '081234567891',
          address: 'Bandung',
          birthDate: '1998-01-20',
          gender: 'Laki-laki',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ManajemenPenggunaPage(initialUsers: users),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Semua (2)'), findsOneWidget);
      expect(find.text('Terintegrasi SATUSEHAT (1)'), findsOneWidget);
      expect(find.text('Belum SATUSEHAT (1)'), findsOneWidget);
      expect(find.text('SATUSEHAT • P20396488189'), findsOneWidget);

      // Filter hanya yang terintegrasi SATUSEHAT
      await tester.tap(find.text('Terintegrasi SATUSEHAT (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Pasien Terhubung'), findsOneWidget);
      expect(find.text('Pasien Belum Sinkron'), findsNothing);

      // Filter hanya yang belum SATUSEHAT
      await tester.tap(find.text('Belum SATUSEHAT (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Pasien Terhubung'), findsNothing);
      expect(find.text('Pasien Belum Sinkron'), findsOneWidget);
    });
  });
}
