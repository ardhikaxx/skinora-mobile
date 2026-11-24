import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/components/buttons/google_auth_button.dart';
import 'package:skinora_app/components/dialogs/lengkapi_data_diri_dialog.dart';
import 'package:skinora_app/models/user_profile.dart';
import 'package:skinora_app/pages/admin/admin_main_page.dart';
import 'package:skinora_app/pages/auth/login_page.dart';
import 'package:skinora_app/pages/auth/register_page.dart';
import 'package:skinora_app/pages/dokter/dokter_main_page.dart';
import 'package:skinora_app/pages/pengguna/pengguna_main_page.dart';
import 'package:skinora_app/services/auth_service.dart';
import 'package:skinora_app/services/user_service.dart';

class FakeUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;

  FakeUser({
    required this.uid,
    required this.email,
    this.displayName,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserCredential implements UserCredential {
  @override
  final User? user;

  FakeUserCredential({this.user});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AuthService.mockGoogleSignInHandler = null;
    AuthService.mockRegisterHandler = null;
    UserService.setMockCurrentProfile(null);
  });

  tearDown(() {
    AuthService.mockGoogleSignInHandler = null;
    AuthService.mockRegisterHandler = null;
    UserService.setMockCurrentProfile(null);
  });

  group('Validasi Kelengkapan Data Profil Pasien (UserProfile.isPatientProfileComplete)', () {
    test('Mengembalikan true bila nama, telepon, tanggal lahir, gender, dan alamat terisi lengkap', () {
      final profile = UserProfile(
        docId: 'patient_1',
        uid: 'patient_1',
        name: 'Siti Rahma',
        email: 'siti@mail.com',
        phone: '081234567890',
        birthDate: '2000-05-15',
        gender: 'Perempuan',
        address: 'Jl. Merpati No. 45, Bandung',
        role: 'pengguna',
      );

      expect(profile.isPatientProfileComplete, isTrue);
    });

    test('Mengembalikan false bila alamat belum diisi', () {
      final profile = UserProfile(
        docId: 'patient_2',
        uid: 'patient_2',
        name: 'Siti Rahma',
        email: 'siti@mail.com',
        phone: '081234567890',
        birthDate: '2000-05-15',
        gender: 'Perempuan',
        address: '',
        role: 'pengguna',
      );

      expect(profile.isPatientProfileComplete, isFalse);
    });

    test('Mengembalikan false bila tanggal lahir atau jenis kelamin belum diisi', () {
      final profile = UserProfile(
        docId: 'patient_3',
        uid: 'patient_3',
        name: 'Andi',
        email: 'andi@mail.com',
        phone: '081234567890',
        birthDate: '',
        gender: '',
        address: 'Jl. Mawar 10',
        role: 'pengguna',
      );

      expect(profile.isPatientProfileComplete, isFalse);
    });
  });

  group('Tampilan Komponen Google Auth & Modal Template', () {
    testWidgets('LoginPage menampilkan tombol "Masuk dengan Google" dan divider', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('atau masuk dengan'), findsOneWidget);
      expect(find.text('Masuk dengan Google'), findsOneWidget);
      expect(find.byType(GoogleAuthButton), findsOneWidget);
    });

    testWidgets('RegisterPage menampilkan tombol "Daftar dengan Google" dan divider', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('atau daftar dengan'), findsOneWidget);
      expect(find.text('Daftar dengan Google'), findsOneWidget);
      expect(find.byType(GoogleAuthButton), findsOneWidget);
    });

    testWidgets('LengkapiDataDiriDialog memvalidasi form dan menyimpan data lengkap', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final initialProfile = UserProfile(
        docId: 'user_incomplete',
        uid: 'user_incomplete',
        name: 'Budi Santoso',
        email: 'budi@gmail.com',
        phone: '',
        birthDate: '',
        gender: 'Laki-laki',
        address: '',
        role: 'pengguna',
      );
      UserService.setMockCurrentProfile(initialProfile);

      UserProfile? savedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      savedResult = await LengkapiDataDiriDialog.show(
                        context,
                        profile: initialProfile,
                      );
                    },
                    child: const Text('Buka Modal'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buka modal
      await tester.tap(find.text('Buka Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Lengkapi Data Diri'), findsOneWidget);
      expect(find.text('budi@gmail.com'), findsOneWidget);

      // Coba klik "Simpan & Lanjutkan" saat data masih kosong -> validasi error
      final simpanBtn = find.text('Simpan & Lanjutkan');
      await tester.ensureVisible(simpanBtn);
      await tester.tap(simpanBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Nomor telepon tidak valid'), findsOneWidget);

      // Isi nomor telepon
      await tester.enterText(
        find.widgetWithText(TextField, '081234567890'),
        '081298765432',
      );

      // Isi tanggal lahir manual ke controller
      final birthDateField = find.widgetWithText(TextField, 'Pilih Tanggal Lahir (YYYY-MM-DD)');
      await tester.enterText(birthDateField, '1998-04-12');

      // Isi alamat
      await tester.enterText(
        find.widgetWithText(TextField, 'Jl. Melati No. 123, Kelurahan, Kota...'),
        'Jl. Gatot Subroto No. 88, Jakarta Selatan',
      );

      await tester.pumpAndSettle();

      // Simpan
      await tester.tap(simpanBtn);
      await tester.pumpAndSettle();

      // Dialog tertutup dan menghasilkan profil yang lengkap
      expect(find.byType(LengkapiDataDiriDialog), findsNothing);
      expect(savedResult, isNotNull);
      expect(savedResult!.phone, '081298765432');
      expect(savedResult!.birthDate, '1998-04-12');
      expect(savedResult!.address, 'Jl. Gatot Subroto No. 88, Jakarta Selatan');
      expect(savedResult!.isPatientProfileComplete, isTrue);
    });
  });

  group('Pembedaan Role pada Login dengan Google (LoginPage)', () {
    testWidgets('Role Admin langsung diarahkan ke AdminMainPage', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final adminProfile = UserProfile(
        docId: 'admin_uid',
        uid: 'admin_uid',
        name: 'Admin Utama',
        email: 'admin@skinora.com',
        role: 'admin',
        status: 'aktif',
      );
      UserService.setMockCurrentProfile(adminProfile);

      AuthService.mockGoogleSignInHandler = () async {
        return FakeUserCredential(
          user: FakeUser(
            uid: 'admin_uid',
            email: 'admin@skinora.com',
            displayName: 'Admin Utama',
          ),
        );
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      final googleBtn = find.text('Masuk dengan Google');
      await tester.ensureVisible(googleBtn);
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AdminMainPage), findsOneWidget);
    });

    testWidgets('Role Dokter terverifikasi diarahkan ke DokterMainPage', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final dokterProfile = UserProfile(
        docId: 'dokter_uid',
        uid: 'dokter_uid',
        name: 'dr. Sarah Sp.KK',
        email: 'sarah@skinora.com',
        role: 'dokter',
        status: 'terverifikasi',
      );
      UserService.setMockCurrentProfile(dokterProfile);

      AuthService.mockGoogleSignInHandler = () async {
        return FakeUserCredential(
          user: FakeUser(
            uid: 'dokter_uid',
            email: 'sarah@skinora.com',
            displayName: 'dr. Sarah Sp.KK',
          ),
        );
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      final googleBtn = find.text('Masuk dengan Google');
      await tester.ensureVisible(googleBtn);
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      expect(find.byType(DokterMainPage), findsOneWidget);
    });

    testWidgets('Role Dokter yang masih "menunggu" ditolak masuk dan menampilkan dialog peringatan', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final dokterPending = UserProfile(
        docId: 'dokter_pending_uid',
        uid: 'dokter_pending_uid',
        name: 'dr. Budi Calon',
        email: 'budi.calon@skinora.com',
        role: 'dokter',
        status: 'menunggu',
      );
      UserService.setMockCurrentProfile(dokterPending);

      AuthService.mockGoogleSignInHandler = () async {
        return FakeUserCredential(
          user: FakeUser(
            uid: 'dokter_pending_uid',
            email: 'budi.calon@skinora.com',
            displayName: 'dr. Budi Calon',
          ),
        );
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      final googleBtn = find.text('Masuk dengan Google');
      await tester.ensureVisible(googleBtn);
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      expect(find.text('Menunggu Verifikasi'), findsOneWidget);
      expect(find.textContaining('masih dalam proses verifikasi'), findsOneWidget);
      expect(find.byType(DokterMainPage), findsNothing);
    });

    testWidgets('Role Pengguna dengan data lengkap langsung masuk ke PenggunaMainPage', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final penggunaComplete = UserProfile(
        docId: 'user_complete_uid',
        uid: 'user_complete_uid',
        name: 'Rina Astuti',
        email: 'rina@gmail.com',
        phone: '081234567890',
        birthDate: '1999-01-20',
        gender: 'Perempuan',
        address: 'Jl. Surya Kencana No. 12',
        role: 'pengguna',
        status: 'aktif',
      );
      UserService.setMockCurrentProfile(penggunaComplete);

      AuthService.mockGoogleSignInHandler = () async {
        return FakeUserCredential(
          user: FakeUser(
            uid: 'user_complete_uid',
            email: 'rina@gmail.com',
            displayName: 'Rina Astuti',
          ),
        );
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      final googleBtn = find.text('Masuk dengan Google');
      await tester.ensureVisible(googleBtn);
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      expect(find.byType(PenggunaMainPage), findsOneWidget);
    });

    testWidgets('Role Pengguna dengan data belum lengkap memicu modal template data diri', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final penggunaIncomplete = UserProfile(
        docId: 'user_inc_uid',
        uid: 'user_inc_uid',
        name: 'Doni Pratama',
        email: 'doni@gmail.com',
        phone: '',
        birthDate: '',
        gender: '',
        address: '',
        role: 'pengguna',
        status: 'aktif',
      );
      UserService.setMockCurrentProfile(penggunaIncomplete);

      AuthService.mockGoogleSignInHandler = () async {
        return FakeUserCredential(
          user: FakeUser(
            uid: 'user_inc_uid',
            email: 'doni@gmail.com',
            displayName: 'Doni Pratama',
          ),
        );
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      final googleBtn = find.text('Masuk dengan Google');
      await tester.ensureVisible(googleBtn);
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      // Modal template wajib muncul
      expect(find.byType(LengkapiDataDiriDialog), findsOneWidget);
      expect(find.text('Lengkapi Data Diri'), findsOneWidget);
      expect(find.byType(PenggunaMainPage), findsNothing);
    });
  });

  group('Register dengan Google & Register Manual (RegisterPage)', () {
    testWidgets('Register Google hanya untuk pengguna: Dokter/Admin ditolak register', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final existingDokter = UserProfile(
        docId: 'dr_existing',
        uid: 'dr_existing',
        name: 'dr. Andi Sp.KK',
        email: 'andi.dokter@gmail.com',
        role: 'dokter',
        status: 'terverifikasi',
      );
      UserService.setMockCurrentProfile(existingDokter);

      AuthService.mockGoogleSignInHandler = () async {
        return FakeUserCredential(
          user: FakeUser(
            uid: 'dr_existing',
            email: 'andi.dokter@gmail.com',
            displayName: 'dr. Andi Sp.KK',
          ),
        );
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterPage(),
        ),
      );
      await tester.pumpAndSettle();

      final googleRegBtn = find.text('Daftar dengan Google');
      await tester.ensureVisible(googleRegBtn);
      await tester.tap(googleRegBtn);
      await tester.pumpAndSettle();

      expect(find.text('Akun Khusus'), findsOneWidget);
      expect(find.textContaining('Email ini terdaftar sebagai dokter'), findsOneWidget);
      expect(find.byType(PenggunaMainPage), findsNothing);
    });

    testWidgets('Register Google untuk pengguna baru memicu modal template lengkapi data diri', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final newGoogleUser = UserProfile(
        docId: 'new_patient_uid',
        uid: 'new_patient_uid',
        name: 'Nadia Putri',
        email: 'nadia@gmail.com',
        phone: '',
        birthDate: '',
        gender: '',
        address: '',
        role: 'pengguna',
        status: 'aktif',
      );
      UserService.setMockCurrentProfile(newGoogleUser);

      AuthService.mockGoogleSignInHandler = () async {
        return FakeUserCredential(
          user: FakeUser(
            uid: 'new_patient_uid',
            email: 'nadia@gmail.com',
            displayName: 'Nadia Putri',
          ),
        );
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterPage(),
        ),
      );
      await tester.pumpAndSettle();

      final googleRegBtn = find.text('Daftar dengan Google');
      await tester.ensureVisible(googleRegBtn);
      await tester.tap(googleRegBtn);
      await tester.pumpAndSettle();

      // Modal template kelengkapan data diri muncul
      expect(find.byType(LengkapiDataDiriDialog), findsOneWidget);
      expect(find.text('nadia@gmail.com'), findsOneWidget);
    });

    testWidgets('Register manual untuk pasien memicu modal template jika profil belum lengkap', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Akun hasil registrasi manual: role pengguna tapi address belum diisi
      final manualRegistered = UserProfile(
        docId: 'manual_uid_1',
        uid: 'manual_uid_1',
        name: 'Indah Kusuma',
        email: 'indah@gmail.com',
        phone: '081233445566',
        birthDate: '2001-08-10',
        gender: 'Perempuan',
        address: '', // belum lengkap
        role: 'pengguna',
        status: 'aktif',
      );
      UserService.setMockCurrentProfile(manualRegistered);

      AuthService.mockRegisterHandler = ({
        required name,
        required email,
        required phone,
        required password,
        birthDate,
        gender,
      }) async {
        return FakeUserCredential(
          user: FakeUser(
            uid: 'manual_uid_1',
            email: email,
            displayName: name,
          ),
        );
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Isi form manual
      await tester.enterText(
        find.widgetWithText(TextField, 'Nama Anda'),
        'Indah Kusuma',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'contoh@email.com'),
        'indah@gmail.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '081234567890'),
        '081233445566',
      );
      // Birth date
      final birthDateField = find.widgetWithText(TextField, 'Pilih Tanggal Lahir (YYYY-MM-DD)');
      await tester.enterText(birthDateField, '2001-08-10');

      // Password
      await tester.enterText(
        find.widgetWithText(TextField, 'Minimal 4 karakter'),
        'pass1234',
      );

      final daftarBtn = find.text('Daftar');
      await tester.ensureVisible(daftarBtn);
      await tester.tap(daftarBtn);
      await tester.pumpAndSettle();

      // Modal template wajib muncul untuk melengkapi alamat
      expect(find.byType(LengkapiDataDiriDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(LengkapiDataDiriDialog),
          matching: find.text('indah@gmail.com'),
        ),
        findsOneWidget,
      );
    });
  });
}
