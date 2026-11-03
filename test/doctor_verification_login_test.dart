import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/models/admin_doctor_model.dart';
import 'package:skinora_app/models/user_profile.dart';
import 'package:skinora_app/pages/admin/detail_dokter_page.dart';
import 'package:skinora_app/pages/auth/register_dokter_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Role Dokter - Verifikasi & Hak Akses canLogin', () {
    test('Dokter berstatus menunggu TIDAK BISA login (canLogin == false)', () {
      final doctorMenunggu = UserProfile(
        uid: 'doc_123',
        docId: 'doc_123',
        name: 'dr. Andi',
        email: 'andi@skinora.com',
        role: 'dokter',
        status: 'menunggu',
      );
      expect(doctorMenunggu.canLogin, isFalse);
    });

    test('Dokter berstatus ditolak TIDAK BISA login (canLogin == false)', () {
      final doctorDitolak = UserProfile(
        uid: 'doc_456',
        docId: 'doc_456',
        name: 'dr. Budi',
        email: 'budi@skinora.com',
        role: 'dokter',
        status: 'ditolak',
      );
      expect(doctorDitolak.canLogin, isFalse);
    });

    test('Dokter berstatus ditangguhkan TIDAK BISA login (canLogin == false)', () {
      final doctorDitangguhkan = UserProfile(
        uid: 'doc_789',
        docId: 'doc_789',
        name: 'dr. Citra',
        email: 'citra@skinora.com',
        role: 'dokter',
        status: 'ditangguhkan',
      );
      expect(doctorDitangguhkan.canLogin, isFalse);
    });

    test('Dokter yang sudah diverifikasi admin BISA login (canLogin == true)', () {
      final doctorTerverifikasi = UserProfile(
        uid: 'doc_verified',
        docId: 'doc_verified',
        name: 'dr. Dian, Sp.D.V.E.',
        email: 'dian@skinora.com',
        role: 'dokter',
        status: 'terverifikasi',
      );
      expect(doctorTerverifikasi.canLogin, isTrue);

      final doctorAktif = UserProfile(
        uid: 'doc_aktif',
        docId: 'doc_aktif',
        name: 'dr. Dian, Sp.D.V.E.',
        email: 'dian@skinora.com',
        role: 'dokter',
        status: 'aktif',
      );
      expect(doctorAktif.canLogin, isTrue);
    });

    test('Pengguna dan Admin biasa tetap mengikuti aturan aktif / ditangguhkan', () {
      final userAktif = UserProfile(
        uid: 'usr_1',
        docId: 'usr_1',
        name: 'User Satu',
        email: 'user@skinora.com',
        role: 'pengguna',
        status: 'aktif',
      );
      expect(userAktif.canLogin, isTrue);

      final userDitangguhkan = UserProfile(
        uid: 'usr_2',
        docId: 'usr_2',
        name: 'User Dua',
        email: 'user2@skinora.com',
        role: 'pengguna',
        status: 'ditangguhkan',
      );
      expect(userDitangguhkan.canLogin, isFalse);

      final adminAktif = UserProfile(
        uid: 'adm_1',
        docId: 'adm_1',
        name: 'Admin Utama',
        email: 'admin@skinora.com',
        role: 'admin',
        status: 'aktif',
      );
      expect(adminAktif.canLogin, isTrue);
    });
  });

  group('Alur Verifikasi Dokter oleh Admin di DetailDokterPage', () {
    testWidgets('Admin memverifikasi dokter berstatus Menunggu menjadi Terverifikasi',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final doctor = AdminDoctorModel(
        id: 'doc_pending_1',
        name: 'dr. Rina Puspita, Sp.KK',
        email: 'rina@skinora.com',
        phone: '081234567899',
        specialization: 'Estetika',
        experience: '5 tahun',
        str: 'STR-99998888',
        bio: 'Dokter estetika kulit',
        status: DoctorStatus.menunggu,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DetailDokterPage(doctor: doctor),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan status awal Menunggu dan tombol Verifikasi muncul
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Verifikasi'), findsOneWidget);
      expect(find.text('Tolak'), findsOneWidget);

      // Admin klik Verifikasi
      await tester.tap(find.text('Verifikasi'));
      await tester.pumpAndSettle();

      expect(find.text('Verifikasi Dokter'), findsOneWidget);

      // Konfirmasi verifikasi
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verifikasi').last);
      await tester.pumpAndSettle();

      // Muncul dialog sukses dan status berubah ke Terverifikasi
      expect(find.text('dr. Rina Puspita, Sp.KK telah diverifikasi'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Terverifikasi'), findsOneWidget);
    });
  });

  group('RegisterDokterPage - Pesan Verifikasi', () {
    testWidgets('RegisterDokterPage menginformasikan bahwa pendaftaran butuh verifikasi admin',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterDokterPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verifikasi Medis Skinora'), findsOneWidget);
      expect(find.text('Pendaftaran Dokter'), findsOneWidget);
    });
  });
}
