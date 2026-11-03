import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/models/admin_account_model.dart';
import 'package:skinora_app/models/admin_user_model.dart';
import 'package:skinora_app/pages/admin/detail_admin_page.dart';
import 'package:skinora_app/pages/admin/manajemen_admin_page.dart';
import 'package:skinora_app/pages/admin/tambah_admin_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyAdmins = [
    AdminAccountModel(
      id: 'admin_1',
      name: 'Admin Utama',
      email: 'admin.utama@skinora.id',
      phone: '081234567890',
      address: 'Jl. Merdeka No. 1, Jakarta',
      birthDate: '1990-01-01',
      gender: 'Laki-laki',
      status: UserStatus.aktif,
      registered: true,
    ),
    AdminAccountModel(
      id: 'admin_2',
      name: 'Admin Operasional',
      email: 'ops@skinora.id',
      phone: '089876543210',
      address: 'Jl. Sudirman No. 10, Bandung',
      birthDate: '1995-05-15',
      gender: 'Perempuan',
      status: UserStatus.ditangguhkan,
      registered: true,
    ),
    AdminAccountModel(
      id: 'admin_3',
      name: 'Admin Baru Undangan',
      email: 'invite@skinora.id',
      phone: '081122334455',
      address: 'Jl. Diponegoro No. 5, Surabaya',
      birthDate: '1992-10-20',
      gender: 'Laki-laki',
      status: UserStatus.aktif,
      registered: false,
    ),
  ];

  group('ManajemenAdminPage UI & Interactions', () {
    testWidgets('menampilkan daftar admin, pencarian, dan badge',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ManajemenAdminPage(
            initialAdmins: dummyAdmins,
          ),
        ),
      );

      // Verifikasi header
      expect(find.text('Manajemen Admin'), findsOneWidget);
      expect(find.text('Baru'), findsOneWidget);

      // Verifikasi item admin ditampilkan
      expect(find.text('Admin Utama'), findsOneWidget);
      expect(find.text('admin.utama@skinora.id'), findsOneWidget);
      expect(find.text('Admin Operasional'), findsOneWidget);
      expect(find.text('Admin Baru Undangan'), findsOneWidget);

      // Verifikasi status badge
      expect(find.text('Aktif'), findsOneWidget);
      expect(find.text('Ditangguhkan'), findsOneWidget);
      expect(find.text('Undangan'), findsOneWidget);

      // Uji pencarian
      await tester.enterText(
          find.byType(TextField), 'ops@skinora.id');
      await tester.pump();

      expect(find.text('Admin Operasional'), findsOneWidget);
      expect(find.text('Admin Utama'), findsNothing);
      expect(find.text('Admin Baru Undangan'), findsNothing);

      // Uji pencarian tidak ada hasil
      await tester.enterText(find.byType(TextField), 'xyz123tidakada');
      await tester.pump();

      expect(find.text('Admin tidak ditemukan'), findsOneWidget);
    });

    testWidgets('menampilkan empty state jika belum ada data admin',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ManajemenAdminPage(
            initialAdmins: [],
          ),
        ),
      );

      expect(find.text('Belum ada data admin'), findsOneWidget);
      expect(find.text('Tambah Admin'), findsOneWidget);
    });
  });

  group('TambahAdminPage Form & Validation', () {
    testWidgets('validasi form: nama, email, dan password wajib diisi dengan format benar', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: TambahAdminPage(),
        ),
      );

      expect(find.text('Tambah Admin Baru'), findsOneWidget);
      expect(find.text('Simpan Admin'), findsOneWidget);

      // Verifikasi label dengan tanda bintang
      expect(find.text('Nama Lengkap *'), findsOneWidget);
      expect(find.text('Email Admin *'), findsOneWidget);
      expect(find.text('Password Admin *'), findsOneWidget);

      // 1. Coba submit saat semua kosong -> gagal di nama
      await tester.ensureVisible(find.text('Simpan Admin'));
      await tester.tap(find.text('Simpan Admin'));
      await tester.pump();

      expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);

      // 2. Isi nama saja, email kosong -> gagal di email
      await tester.enterText(find.byType(TextField).at(0), 'Admin Tester');
      await tester.tap(find.text('Simpan Admin'));
      await tester.pump();

      expect(find.text('Email valid wajib diisi'), findsOneWidget);

      // 3. Isi email valid, password kosong -> gagal di password wajib
      await tester.enterText(find.byType(TextField).at(1), 'admin@skinora.id');
      await tester.tap(find.text('Simpan Admin'));
      await tester.pump();

      expect(find.text('Password wajib diisi'), findsOneWidget);

      // 4. Isi password kurang dari 6 karakter -> gagal minimal 6 karakter
      await tester.enterText(find.byType(TextField).at(2), '12345');
      await tester.tap(find.text('Simpan Admin'));
      await tester.pump();

      expect(find.text('Password minimal 6 karakter'), findsOneWidget);
    });

    testWidgets('berhasil submit form tambah admin', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      AdminAccountModel? createdAdmin;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    createdAdmin = await Navigator.push<AdminAccountModel>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TambahAdminPage(),
                      ),
                    );
                  },
                  child: const Text('Buka Tambah'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buka Tambah'));
      await tester.pumpAndSettle();

      // Isi form
      await tester.enterText(find.byType(TextField).at(0), 'Budi Santoso');
      await tester.enterText(
          find.byType(TextField).at(1), 'budi.admin@skinora.id');
      await tester.enterText(find.byType(TextField).at(2), 'adminSecret123');
      await tester.enterText(find.byType(TextField).at(3), '0812345678');
      await tester.enterText(
          find.byType(TextField).at(4), 'Jl. Merdeka No. 45');

      await tester.ensureVisible(find.text('Simpan Admin'));
      await tester.tap(find.text('Simpan Admin'));
      await tester.pumpAndSettle();

      expect(createdAdmin, isNotNull);
      expect(createdAdmin!.name, 'Budi Santoso');
      expect(createdAdmin!.email, 'budi.admin@skinora.id');
      expect(createdAdmin!.password, 'adminSecret123');
      expect(createdAdmin!.phone, '0812345678');
      expect(createdAdmin!.address, 'Jl. Merdeka No. 45');
      expect(createdAdmin!.status, UserStatus.aktif);
    });
  });

  group('DetailAdminPage UI & Actions', () {
    testWidgets('menampilkan detail admin aktif dan dialog penangguhan',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final targetAdmin = dummyAdmins[0];

      await tester.pumpWidget(
        MaterialApp(
          home: DetailAdminPage(
            admin: targetAdmin,
          ),
        ),
      );

      expect(find.text('Detail Admin'), findsOneWidget);
      expect(find.text('Admin Utama'), findsOneWidget);
      expect(find.text('admin.utama@skinora.id'), findsWidgets);
      expect(find.text('Administrator'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);
      expect(find.text('081234567890'), findsOneWidget);
      expect(find.text('Jl. Merdeka No. 1, Jakarta'), findsOneWidget);

      // Verifikasi tombol Tangguhkan
      expect(find.text('Tangguhkan Admin'), findsOneWidget);
      await tester.ensureVisible(find.text('Tangguhkan Admin'));
      await tester.tap(find.text('Tangguhkan Admin'));
      await tester.pumpAndSettle();

      // Verifikasi dialog konfirmasi muncul
      expect(find.text('Apakah Anda yakin ingin menangguhkan admin ini? Akses administrator ke sistem akan dibekukan sementara.'),
          findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Batal dialog
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Tangguhkan Admin'), findsOneWidget);
    });

    testWidgets('menampilkan tombol aktifkan kembali untuk admin ditangguhkan',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final suspendedAdmin = dummyAdmins[1];

      await tester.pumpWidget(
        MaterialApp(
          home: DetailAdminPage(
            admin: suspendedAdmin,
          ),
        ),
      );

      expect(find.text('Admin Operasional'), findsOneWidget);
      expect(find.text('Ditangguhkan'), findsOneWidget);
      expect(find.text('Aktifkan Kembali Admin'), findsOneWidget);

      await tester.ensureVisible(find.text('Aktifkan Kembali Admin'));
      await tester.tap(find.text('Aktifkan Kembali Admin'));
      await tester.pumpAndSettle();

      expect(find.text('Apakah Anda yakin ingin mengaktifkan kembali akun admin ini? Hak akses ke panel admin akan dipulihkan.'),
          findsOneWidget);
    });
  });
}
