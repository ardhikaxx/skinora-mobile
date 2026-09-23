import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skinora_app/pages/pengguna/pengguna_main_page.dart';
import 'package:skinora_app/pages/pengguna/profil_pengguna_page.dart';
import 'package:skinora_app/pages/pengguna/edit_profil_pengguna_page.dart';
import 'package:skinora_app/pages/pengguna/pengaturan_pengguna_page.dart';
import 'package:skinora_app/pages/pengguna/tentang_pengguna_page.dart';
import 'package:skinora_app/pages/pengguna/riwayat_aktivitas_pengguna_page.dart';
import 'package:skinora_app/pages/pengguna/profil_dokter_page.dart';
import 'package:skinora_app/pages/pengguna/skin_daily_page.dart';
import 'package:skinora_app/pages/pengguna/riwayat_skin_daily_page.dart';
import 'package:skinora_app/pages/pengguna/insight_kulit_pengguna_page.dart';
import 'package:skinora_app/pages/pengguna/skincare_page.dart';
import 'package:skinora_app/pages/pengguna/riwayat_skincare_page.dart';
import 'package:skinora_app/pages/admin/profil_admin_page.dart';
import 'package:skinora_app/pages/admin/edit_profil_admin_page.dart';
import 'package:skinora_app/pages/admin/pengaturan_admin_page.dart';
import 'package:skinora_app/pages/admin/tentang_admin_page.dart';
import 'package:skinora_app/pages/admin/riwayat_aktivitas_admin_page.dart';
import 'package:skinora_app/pages/admin/manajemen_edukasi_page.dart';
import 'package:skinora_app/pages/admin/tambah_artikel_page.dart';
import 'package:skinora_app/pages/admin/edit_artikel_page.dart';
import 'package:skinora_app/models/admin_article_model.dart';
import 'package:skinora_app/pages/admin/master_spesialisasi_page.dart';
import 'package:skinora_app/pages/admin/tambah_spesialisasi_page.dart';
import 'package:skinora_app/pages/admin/edit_spesialisasi_page.dart';
import 'package:skinora_app/pages/admin/manajemen_dokter_page.dart';
import 'package:skinora_app/pages/admin/tambah_dokter_page.dart';
import 'package:skinora_app/pages/admin/detail_dokter_page.dart';
import 'package:skinora_app/models/admin_doctor_model.dart';
import 'package:skinora_app/pages/admin/manajemen_pengguna_page.dart';
import 'package:skinora_app/pages/admin/tambah_pengguna_page.dart';
import 'package:skinora_app/pages/admin/detail_pengguna_page.dart';
import 'package:skinora_app/models/admin_user_model.dart';
import 'package:skinora_app/pages/dokter/profil_dokter_page.dart' as dokter;
import 'package:skinora_app/pages/dokter/patient_insight_page.dart';
import 'package:skinora_app/pages/dokter/detail_patient_insight_page.dart';
import 'package:skinora_app/pages/dokter/jadwal_page.dart';
import 'package:skinora_app/pages/dokter/chat_konsultasi_page.dart';
import 'package:skinora_app/pages/dokter/ruang_chat_dokter_page.dart';
import 'package:skinora_app/pages/dokter/riwayat_konsultasi_page.dart';
import 'package:skinora_app/pages/dokter/detail_riwayat_konsultasi_page.dart';
import 'package:skinora_app/pages/dokter/edit_profil_dokter_page.dart';
import 'package:skinora_app/pages/dokter/tentang_dokter_page.dart';
import 'package:skinora_app/pages/dokter/riwayat_aktivitas_dokter_page.dart';
import 'package:skinora_app/pages/dokter/pengaturan_dokter_page.dart' as dokter_settings;
import 'package:skinora_app/pages/dokter/dokter_main_page.dart';






void main() {
  testWidgets('Test ProfilPenggunaPage directly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilPenggunaPage(),
      ),
    );
    expect(find.text('Profil'), findsOneWidget);
  });

  testWidgets('Test PenggunaMainPage navigate to Profil tab', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PenggunaMainPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Profil tab on PenggunaNavBottom
    final profilNav = find.text('Profil');
    expect(profilNav, findsWidgets);
    await tester.tap(profilNav.last);
    await tester.pumpAndSettle();
  });

  testWidgets('Test Beranda quick menu navigate to Profil', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PenggunaMainPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Profil in quick menu on Beranda
    final profilQuick = find.text('Profil').first;
    await tester.tap(profilQuick);
    await tester.pumpAndSettle();
  });

  testWidgets('Test EditProfilPenggunaPage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EditProfilPenggunaPage(),
      ),
    );
    expect(find.text('Edit Profil'), findsOneWidget);
  });

  testWidgets('Test PengaturanPenggunaPage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PengaturanPenggunaPage(),
      ),
    );
    expect(find.text('Pengaturan'), findsOneWidget);
  });

  testWidgets('Test TentangPenggunaPage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TentangPenggunaPage(),
      ),
    );
    expect(find.text('Tentang'), findsOneWidget);
  });

  testWidgets('Test RiwayatAktivitasPenggunaPage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RiwayatAktivitasPenggunaPage(),
      ),
    );
    expect(find.text('Riwayat Aktivitas'), findsOneWidget);
  });

  testWidgets('Test ProfilDokterPenggunaPage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilDokterPenggunaPage(),
      ),
    );
    expect(find.text('Profil Dokter'), findsOneWidget);
  });

  testWidgets('Test ProfilAdminPage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilAdminPage(),
      ),
    );
    expect(find.text('Profil Admin'), findsOneWidget);
  });

  testWidgets('Test Dokter ProfilDokterPage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: dokter.ProfilDokterPage(),
      ),
    );
    expect(find.text('Profil Dokter'), findsOneWidget);
  });

  testWidgets('Test Dokter RiwayatKonsultasiPage directly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RiwayatKonsultasiPage(showBottomNav: true),
      ),
    );
    expect(find.text('Riwayat Konsultasi'), findsOneWidget);
  });

  testWidgets('Test SkinDailyPage and interactions', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: SkinDailyPage(),
      ),
    );
    expect(find.text('Skin Daily'), findsOneWidget);
    expect(find.text('PROGRESS'), findsOneWidget);
    expect(find.text('TANGGAL'), findsOneWidget);
    expect(find.text('LOKASI GEJALA'), findsOneWidget);
    expect(find.text('GEJALA KULIT'), findsOneWidget);
    expect(find.text('KEBIASAAN HARIAN'), findsOneWidget);
    expect(find.text('JAM TIDUR'), findsOneWidget);
    expect(find.text('AIR (GELAS)'), findsOneWidget);
    expect(find.text('MAKANAN'), findsOneWidget);
    expect(find.text('AKTIVITAS'), findsOneWidget);
    expect(find.text('SKINCARE ROUTINE'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);

    // Tap a location checkbox
    await tester.tap(find.text('T-Zone'));
    await tester.pumpAndSettle();

    // Tap a symptom chip
    await tester.tap(find.text('Jerawat'));
    await tester.pumpAndSettle();

    // Tap Simpan
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
  });

  testWidgets('Test RiwayatSkinDailyPage', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RiwayatSkinDailyPage(),
      ),
    );
    expect(find.text('Riwayat Skin Daily'), findsOneWidget);
    expect(find.text('Jumat, 28 Agustus 2026'), findsOneWidget);
    expect(find.text('Baik'), findsWidgets);
    expect(find.text('LOKASI GEJALA'), findsOneWidget);
    expect(find.text('TIDUR'), findsOneWidget);
    expect(find.text('AIR'), findsOneWidget);

    // Tap a card to collapse it
    await tester.tap(find.text('Jumat, 28 Agustus 2026'));
    await tester.pumpAndSettle();

    // Tap another card to expand it
    await tester.tap(find.text('Rabu, 26 Agustus 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Mie goreng, telur, jus jeruk'), findsOneWidget);
  });

  testWidgets('Test InsightKulitPenggunaPage and navigation from SkinDailyPage', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: InsightKulitPenggunaPage(),
      ),
    );
    expect(find.text('Insight Kulit'), findsOneWidget);
    expect(find.text('RINGKASAN KONDISI'), findsOneWidget);
    expect(find.text('POLA HIDUP'), findsOneWidget);
    expect(find.text('RIWAYAT 7 HARI'), findsOneWidget);
    expect(find.text('4'), findsWidgets);
    expect(find.text('Baik'), findsWidgets);
    expect(find.text('Sedang'), findsWidgets);
    expect(find.text('Buruk'), findsWidgets);
    expect(find.text('Rata-rata Air/Hari'), findsOneWidget);
    expect(find.text('Skincare Lengkap'), findsOneWidget);
  });

  testWidgets('Test SkincarePage and interactions', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: SkincarePage(),
      ),
    );
    expect(find.text('Skincare Routine'), findsOneWidget);
    expect(find.text('TANGGAL'), findsOneWidget);
    expect(find.text('Morning Routine'), findsOneWidget);
    expect(find.text('Night Routine'), findsOneWidget);
    expect(find.text('Simpan Pagi'), findsOneWidget);
    expect(find.text('Simpan Malam'), findsOneWidget);

    // Tap a checkbox
    await tester.tap(find.text('Cleanser').first);
    await tester.pumpAndSettle();

    // Tap Simpan Pagi
    await tester.tap(find.text('Simpan Pagi'));
    await tester.pumpAndSettle();
  });

  testWidgets('Test RiwayatSkincarePage and card expansion', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RiwayatSkincarePage(),
      ),
    );
    expect(find.text('Riwayat Skincare'), findsOneWidget);
    expect(find.text('Jumat, 28 Agustus 2026'), findsOneWidget);
    expect(find.text('PAGI'), findsOneWidget);
    expect(find.text('MALAM'), findsOneWidget);
    expect(find.text('Sunscreen'), findsOneWidget);

    // Tap a card to collapse it
    await tester.tap(find.text('Jumat, 28 Agustus 2026'));
    await tester.pumpAndSettle();

    // Tap another card to expand it
    await tester.tap(find.text('Kamis, 27 Agustus 2026'));
    await tester.pumpAndSettle();
    expect(find.text('PAGI'), findsOneWidget);
  });

  testWidgets('Test TambahSpesialisasiPage UI and validation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TambahSpesialisasiPage(),
      ),
    );
    expect(find.text('Spesialisasi Baru'), findsOneWidget);
    expect(find.text('NAMA SPESIALISASI'), findsOneWidget);
    expect(find.text('Tambah Spesialisasi'), findsOneWidget);

    // Try submit without entering text (shows SnackBar)
    await tester.tap(find.text('Tambah Spesialisasi'));
    await tester.pumpAndSettle();
    expect(find.text('Nama spesialisasi tidak boleh kosong'), findsOneWidget);

    // Enter text
    await tester.enterText(find.byType(TextField), 'Dermatologi Anak');
    await tester.pumpAndSettle();
    expect(find.text('Dermatologi Anak'), findsOneWidget);
  });

  testWidgets('Test EditSpesialisasiPage UI and interaction', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EditSpesialisasiPage(initialName: 'Jerawat'),
      ),
    );
    expect(find.text('Edit Spesialisasi'), findsOneWidget);
    expect(find.text('NAMA SPESIALISASI'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsOneWidget);
    expect(find.text('Jerawat'), findsOneWidget);

    // Edit text
    await tester.enterText(find.byType(TextField), 'Jerawat Kronis');
    await tester.pumpAndSettle();
    expect(find.text('Jerawat Kronis'), findsOneWidget);
  });

  testWidgets('Test MasterSpesialisasiPage flow: Add, Edit, Toggle, Delete with Dialogs', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MasterSpesialisasiPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Master Spesialisasi'), findsOneWidget);
    expect(find.text('+ Tambah Spesialisasi'), findsOneWidget);
    expect(find.text('Jerawat'), findsOneWidget);

    // 1. Test Add Specialization Flow
    await tester.tap(find.text('+ Tambah Spesialisasi'));
    await tester.pumpAndSettle();

    // Now on TambahSpesialisasiPage
    expect(find.text('Spesialisasi Baru'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Bedah Kulit');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Spesialisasi'));
    await tester.pumpAndSettle();

    // Returned to MasterSpesialisasiPage with success dialog
    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Spesialisasi baru berhasil ditambahkan'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Bedah Kulit'), findsOneWidget);

    // 2. Test Edit Specialization Flow (first Edit button)
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();

    // Now on EditSpesialisasiPage
    expect(find.text('Edit Spesialisasi'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Jerawat & Komedo');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    // Returned with success dialog
    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Spesialisasi berhasil diperbarui'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Jerawat & Komedo'), findsOneWidget);

    // 3. Test Toggle (Nonaktifkan) Flow
    await tester.tap(find.text('Nonaktifkan').first);
    await tester.pumpAndSettle();

    // Confirm dialog shown
    expect(find.text('Nonaktifkan Spesialisasi'), findsOneWidget);
    expect(find.text('Nonaktifkan "Jerawat & Komedo"?'), findsOneWidget);
    // Tap confirm button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Nonaktifkan'));
    await tester.pumpAndSettle();

    // Success dialog shown
    expect(find.text('Status spesialisasi diubah ke inactive'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // 4. Test Delete Flow
    await tester.tap(find.text('Hapus').first);
    await tester.pumpAndSettle();

    // Delete confirm dialog shown
    expect(find.text('Hapus Spesialisasi'), findsOneWidget);
    expect(find.text('Hapus "Jerawat & Komedo" secara permanen?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
    await tester.pumpAndSettle();

    // Delete success dialog shown
    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Spesialisasi "Jerawat & Komedo" berhasil dihapus'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Jerawat & Komedo'), findsNothing);
  });

  testWidgets('Test ManajemenDokterPage search and filter chips', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ManajemenDokterPage(showBottomNav: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manajemen Dokter'), findsOneWidget);
    expect(find.text('Baru'), findsOneWidget);
    expect(find.text('dr. Anita Dewi, Sp.KK'), findsOneWidget);
    expect(find.text('dr. Sari Wulandari, Sp.KK'), findsOneWidget);

    // Filter chip: Pending
    await tester.tap(find.text('Pending'));
    await tester.pumpAndSettle();

    expect(find.text('dr. Sari Wulandari, Sp.KK'), findsOneWidget);
    expect(find.text('dr. Anita Dewi, Sp.KK'), findsNothing);

    // Filter chip: Semua
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();
    expect(find.text('dr. Anita Dewi, Sp.KK'), findsOneWidget);

    // Search: Anita
    await tester.enterText(find.byType(TextField).first, 'Anita');
    await tester.pumpAndSettle();
    expect(find.text('dr. Anita Dewi, Sp.KK'), findsOneWidget);
    expect(find.text('dr. Andi Pratama, Sp.KK'), findsNothing);
  });

  testWidgets('Test TambahDokterPage validation and submit', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: TambahDokterPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tambah Dokter'), findsWidgets);
    expect(find.text('NAMA LENGKAP'), findsOneWidget);
    expect(find.text('EMAIL'), findsOneWidget);

    // Submit empty -> validation error
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tambah Dokter'));
    await tester.pumpAndSettle();
    expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);

    // Fill name
    await tester.enterText(find.byType(TextField).at(0), 'dr. Budi Santoso, Sp.KK');
    await tester.pumpAndSettle();

    // Submit without email
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tambah Dokter'));
    await tester.pumpAndSettle();
    expect(find.text('Email wajib diisi'), findsOneWidget);

    // Fill email
    await tester.enterText(find.byType(TextField).at(1), 'budi@demo.com');
    await tester.pumpAndSettle();
  });

  testWidgets('Test DetailDokterPage for Terverifikasi doctor (Tangguhkan & Aktifkan Kembali)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final doctor = AdminDoctorModel(
      id: '1',
      name: 'dr. Anita Dewi, Sp.KK',
      email: 'anita@demo.com',
      phone: '081234567800',
      specialization: 'Estetika Kulit',
      experience: '8 tahun',
      str: 'STR-2018-12345',
      bio: 'Dokter spesialis kulit.',
      status: DoctorStatus.terverifikasi,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DetailDokterPage(doctor: doctor),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Dokter'), findsOneWidget);
    expect(find.text('dr. Anita Dewi, Sp.KK'), findsOneWidget);
    expect(find.text('Terverifikasi'), findsOneWidget);
    expect(find.text('Tangguhkan'), findsOneWidget);

    // Tap Tangguhkan -> confirm dialog
    await tester.tap(find.text('Tangguhkan'));
    await tester.pumpAndSettle();

    expect(find.text('Tangguhkan Dokter'), findsOneWidget);
    expect(find.text('Apakah Anda yakin ingin menangguhkan dokter ini?'), findsOneWidget);

    // Confirm Tangguhkan
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tangguhkan').last);
    await tester.pumpAndSettle();

    // Success dialog
    expect(find.text('dr. Anita Dewi, Sp.KK telah ditangguhkan'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Now status is Ditangguhkan, button is Aktifkan Kembali
    expect(find.text('Ditangguhkan'), findsOneWidget);
    expect(find.text('Aktifkan Kembali'), findsOneWidget);

    // Tap Aktifkan Kembali
    await tester.tap(find.text('Aktifkan Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('dr. Anita Dewi, Sp.KK telah diaktifkan kembali'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Terverifikasi'), findsOneWidget);
    expect(find.text('Tangguhkan'), findsOneWidget);
  });

  testWidgets('Test DetailDokterPage for Menunggu doctor (Verifikasi)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final doctor = AdminDoctorModel(
      id: '3',
      name: 'dr. Sari Wulandari, Sp.KK',
      email: 'sari@demo.com',
      phone: '081234567802',
      specialization: 'Alergi',
      experience: '3 tahun',
      str: 'STR-2022-12347',
      bio: 'Dokter spesialis kulit alergi.',
      status: DoctorStatus.menunggu,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DetailDokterPage(doctor: doctor),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Dokter'), findsOneWidget);
    expect(find.text('dr. Sari Wulandari, Sp.KK'), findsOneWidget);
    expect(find.text('Menunggu'), findsOneWidget);
    expect(find.text('Verifikasi'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);

    // Tap Verifikasi
    await tester.tap(find.text('Verifikasi'));
    await tester.pumpAndSettle();

    expect(find.text('Verifikasi Dokter'), findsOneWidget);
    expect(find.text('Apakah Anda yakin ingin memverifikasi dokter ini?'), findsOneWidget);

    // Confirm Verifikasi (dialog button)
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verifikasi').last);
    await tester.pumpAndSettle();

    expect(find.text('dr. Sari Wulandari, Sp.KK telah diverifikasi'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Terverifikasi'), findsOneWidget);
    expect(find.text('Tangguhkan'), findsOneWidget);
  });

  testWidgets('Test DetailDokterPage for Menunggu doctor (Tolak)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final doctor = AdminDoctorModel(
      id: '4',
      name: 'dr. Sari Wulandari, Sp.KK',
      email: 'sari@demo.com',
      phone: '081234567802',
      specialization: 'Alergi',
      experience: '3 tahun',
      str: 'STR-2022-12347',
      bio: 'Dokter spesialis kulit alergi.',
      status: DoctorStatus.menunggu,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DetailDokterPage(doctor: doctor),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Dokter'), findsOneWidget);
    expect(find.text('dr. Sari Wulandari, Sp.KK'), findsOneWidget);
    expect(find.text('Menunggu'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);

    // Tap Tolak
    await tester.tap(find.text('Tolak'));
    await tester.pumpAndSettle();

    expect(find.text('Tolak Dokter'), findsOneWidget);
    expect(find.text('Apakah Anda yakin ingin menolak dokter ini?'), findsOneWidget);

    // Confirm Tolak (dialog button)
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tolak').last);
    await tester.pumpAndSettle();

    expect(find.text('dr. Sari Wulandari, Sp.KK telah ditolak'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Now status is Ditolak, no action button
    expect(find.text('Ditolak'), findsOneWidget);
    expect(find.text('Verifikasi'), findsNothing);
    expect(find.text('Tolak'), findsNothing);
  });

  testWidgets('Test ManajemenPenggunaPage rendering and search', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ManajemenPenggunaPage(showBottomNav: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manajemen Pengguna'), findsOneWidget);
    expect(find.text('Baru'), findsOneWidget);
    expect(find.text('Leonita Yulyta Agustin'), findsOneWidget);
    expect(find.text('Annida Tri Aulia'), findsOneWidget);

    // Search for "Leonita"
    await tester.enterText(find.byType(TextField).first, 'Leonita');
    await tester.pumpAndSettle();
    expect(find.text('Leonita Yulyta Agustin'), findsOneWidget);
    expect(find.text('Annida Tri Aulia'), findsNothing);
  });

  testWidgets('Test TambahPenggunaPage validation and submit', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: TambahPenggunaPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tambah Pengguna'), findsWidgets);
    expect(find.text('NAMA LENGKAP'), findsOneWidget);
    expect(find.text('EMAIL'), findsOneWidget);

    // Empty submit
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tambah Pengguna'));
    await tester.pumpAndSettle();
    expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);

    // Fill name
    await tester.enterText(find.byType(TextField).at(0), 'Dewi Sartika');
    await tester.pumpAndSettle();

    // Submit without email
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tambah Pengguna'));
    await tester.pumpAndSettle();
    expect(find.text('Email wajib diisi'), findsOneWidget);

    // Fill email
    await tester.enterText(find.byType(TextField).at(1), 'dewi@demo.com');
    await tester.pumpAndSettle();
  });

  testWidgets('Test DetailPenggunaPage Tangguhkan and Aktifkan Kembali', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final user = AdminUserModel(
      id: '1',
      name: 'Leonita Yulyta Agustin',
      email: 'leonita@demo.com',
      phone: '081234567890',
      address: 'Jl. Sudirman No. 123, Jakarta',
      birthDate: '1995-06-15',
      gender: 'Perempuan',
      status: UserStatus.aktif,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DetailPenggunaPage(user: user),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Pengguna'), findsOneWidget);
    expect(find.text('Leonita Yulyta Agustin'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Tangguhkan'), findsOneWidget);

    // Tap Tangguhkan -> confirm dialog
    await tester.tap(find.text('Tangguhkan'));
    await tester.pumpAndSettle();

    expect(find.text('Tangguhkan Pengguna'), findsOneWidget);
    expect(find.text('Apakah Anda yakin ingin menangguhkan pengguna ini?'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);

    // Cancel dialog
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Tangguhkan Pengguna'), findsNothing);
  });

  testWidgets('Test ManajemenPenggunaPage flow to DetailPenggunaPage and suspension', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ManajemenPenggunaPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Leonita Yulyta Agustin'), findsOneWidget);
    expect(find.text('Ditangguhkan'), findsNothing);

    // Tap on Leonita Yulyta Agustin
    await tester.tap(find.text('Leonita Yulyta Agustin'));
    await tester.pumpAndSettle();

    // Now on DetailPenggunaPage
    expect(find.text('Detail Pengguna'), findsOneWidget);
    expect(find.text('Tangguhkan'), findsOneWidget);

    // Tap Tangguhkan
    await tester.tap(find.text('Tangguhkan'));
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('Tangguhkan Pengguna'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tangguhkan').last);
    await tester.pumpAndSettle();

    // Returned to ManajemenPenggunaPage with success dialog (Screen 5)
    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Leonita Yulyta Agustin telah ditangguhkan'), findsOneWidget);

    // Tap OK on success dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Now shows Ditangguhkan badge (Screen 6)
    expect(find.text('Ditangguhkan'), findsOneWidget);
  });

  testWidgets('Test EditProfilAdminPage UI and update', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: EditProfilAdminPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('NAMA'), findsOneWidget);
    expect(find.text('TELEPON'), findsOneWidget);
    expect(find.text('ALAMAT'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);

    final nameField = find.byType(TextField).first;
    await tester.enterText(nameField, 'Super Admin');
    await tester.pumpAndSettle();

    expect(find.text('SA'), findsOneWidget);

    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
  });

  testWidgets('Test PengaturanAdminPage UI and toggle', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PengaturanAdminPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('NOTIFIKASI'), findsOneWidget);
    expect(find.text('Aktifkan Notifikasi'), findsOneWidget);

    // Toggle switch
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Tap Simpan Pengaturan
    await tester.tap(find.text('Simpan Pengaturan'));
    await tester.pumpAndSettle();

    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Pengaturan admin berhasil disimpan'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('Test TentangAdminPage UI', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: TentangAdminPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tentang'), findsOneWidget);
    expect(find.text('Skinora'), findsOneWidget);
    expect(find.text('VERSI 1.0.0'), findsOneWidget);
    expect(
      find.text('Skinora adalah aplikasi perawatan kulit cerdas yang membantu Anda memahami kondisi kulit, memantau rutinitas sehari-hari, dan berkonsultasi dengan dokter spesialis kulit.'),
      findsOneWidget,
    );
    expect(find.text('Dikembangkan oleh Tim Skinora'), findsOneWidget);
    expect(find.text('© 2026 Skinora'), findsOneWidget);
  });

  testWidgets('Test RiwayatAktivitasAdminPage UI', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RiwayatAktivitasAdminPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Aktivitas'), findsOneWidget);
    expect(find.text('Login admin berhasil'), findsOneWidget);
    expect(find.text('2026-08-27 07:55'), findsOneWidget);
    expect(find.text('Memverifikasi dr. Anita Dewi'), findsOneWidget);
    expect(find.text('2026-08-15 10:00'), findsOneWidget);
    expect(find.text('Mempublikasikan artikel:\nMengenal Tipe Kulit'), findsOneWidget);
    expect(find.text('2026-08-01 12:00'), findsOneWidget);
  });

  testWidgets('Test ProfilAdminPage subpage navigations and logout dialog', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilAdminPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profil Admin'), findsOneWidget);
    expect(find.text('Admin Skinora'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
    expect(find.text('RINGKASAN PLATFORM'), findsOneWidget);

    // 1. Test Logout Dialog
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Apakah Anda yakin ingin keluar?'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    // Tap Batal
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Apakah Anda yakin ingin keluar?'), findsNothing);

    // 2. Test navigate to Edit Profil
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profil'), findsOneWidget);
    final nameField = find.widgetWithText(TextField, 'Admin Skinora');
    await tester.enterText(nameField, 'Admin Utama');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    // Success dialog shown on ProfilAdminPage
    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Profil admin berhasil diperbarui'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Admin Utama'), findsOneWidget);

    // 3. Test navigate to Pengaturan
    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    expect(find.text('Aktifkan Notifikasi'), findsOneWidget);
    // Back
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();

    // 4. Test navigate to Tentang Aplikasi
    await tester.tap(find.text('Tentang Aplikasi'));
    await tester.pumpAndSettle();
    expect(find.text('VERSI 1.0.0'), findsOneWidget);
    // Back
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();

    // 5. Test navigate to Riwayat Aktivitas
    await tester.tap(find.text('Riwayat Aktivitas'));
    await tester.pumpAndSettle();
    expect(find.text('Login admin berhasil'), findsOneWidget);
    // Back
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();
  });

  testWidgets('Test ManajemenEdukasiPage search and filter chips', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ManajemenEdukasiPage(showBottomNav: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manajemen Konten Edukasi'), findsOneWidget);
    expect(find.text('+ Baru'), findsOneWidget);
    expect(find.text('Mengenal Tipe Kulit Wajah Anda'), findsOneWidget);
    expect(find.text('Draft: Treatment Laser Terbaru'), findsOneWidget);

    // Search
    final searchField = find.widgetWithText(TextField, 'Cari artikel...');
    await tester.enterText(searchField, 'Jerawat');
    await tester.pumpAndSettle();

    expect(find.text('Cara Mengatasi Jerawat Secara'), findsOneWidget);
    expect(find.text('Mengenal Tipe Kulit Wajah Anda'), findsNothing);

    // Clear search
    await tester.enterText(searchField, '');
    await tester.pumpAndSettle();

    // Filter "Diterbitkan"
    await tester.tap(find.text('Diterbitkan').first);
    await tester.pumpAndSettle();
    expect(find.text('Mengenal Tipe Kulit Wajah Anda'), findsOneWidget);
    expect(find.text('Draft: Treatment Laser Terbaru'), findsNothing);

    // Filter "Draf"
    await tester.tap(find.text('Draf').first);
    await tester.pumpAndSettle();
    expect(find.text('Mengenal Tipe Kulit Wajah Anda'), findsNothing);
    expect(find.text('Draft: Treatment Laser Terbaru'), findsOneWidget);

    // Filter "Semua"
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();
    expect(find.text('Mengenal Tipe Kulit Wajah Anda'), findsOneWidget);
    expect(find.text('Draft: Treatment Laser Terbaru'), findsOneWidget);
  });

  testWidgets('Test ManajemenEdukasiPage toggle status Tolak Terbit and Terbitkan', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ManajemenEdukasiPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap "Tolak Terbit" on the first article
    final tolakTerbitBtn = find.text('Tolak Terbit').first;
    await tester.tap(tolakTerbitBtn);
    await tester.pumpAndSettle();

    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Artikel dialihkan ke draf'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Now it shows "Terbitkan"
    final terbitkanBtn = find.text('Terbitkan').first;
    await tester.tap(terbitkanBtn);
    await tester.pumpAndSettle();

    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Artikel berhasil diterbitkan'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('Test ManajemenEdukasiPage delete dialog Batal and Hapus', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ManajemenEdukasiPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mengenal Tipe Kulit Wajah Anda'), findsOneWidget);

    // Tap "Hapus" on the first article
    final hapusBtn = find.text('Hapus').first;
    await tester.tap(hapusBtn);
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('Hapus Artikel'), findsOneWidget);
    expect(find.text('Apakah Anda yakin ingin menghapus "Mengenal Tipe Kulit Wajah Anda"?'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);

    // Tap Batal
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Mengenal Tipe Kulit Wajah Anda'), findsOneWidget);

    // Tap Hapus again
    await tester.tap(find.text('Hapus').first);
    await tester.pumpAndSettle();

    // Tap Hapus in dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus').last);
    await tester.pumpAndSettle();

    // Success dialog
    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Artikel berhasil dihapus'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Mengenal Tipe Kulit Wajah Anda'), findsNothing);
  });

  testWidgets('Test TambahArtikelPage UI, validation and submit', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: TambahArtikelPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Artikel Baru'), findsOneWidget);
    expect(find.text('JUDUL'), findsOneWidget);
    expect(find.text('KATEGORI'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);
    expect(find.text('KONTEN'), findsOneWidget);
    expect(find.text('Buat Artikel'), findsOneWidget);

    // Submit without input -> snackbar
    await tester.tap(find.text('Buat Artikel'));
    await tester.pumpAndSettle();
    expect(find.text('Judul artikel tidak boleh kosong'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Enter title
    final titleField = find.widgetWithText(TextField, 'Judul artikel...');
    await tester.enterText(titleField, 'Tips Merawat Kulit Kering');
    await tester.pumpAndSettle();

    // Submit without category -> snackbar
    await tester.tap(find.text('Buat Artikel'));
    await tester.pumpAndSettle();
    expect(find.text('Kategori artikel tidak boleh kosong'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Enter category
    final catField = find.widgetWithText(TextField, 'Kategori artikel...');
    await tester.enterText(catField, 'Perawatan');
    await tester.pumpAndSettle();

    // Toggle status to Diterbitkan
    await tester.tap(find.widgetWithText(ElevatedButton, 'Diterbitkan'));
    await tester.pumpAndSettle();

    // Enter content
    final contentField = find.widgetWithText(TextField, 'Tulis konten artikel...');
    await tester.enterText(contentField, 'Gunakan pelembab secara teratur.');
    await tester.pumpAndSettle();

    // Submit
    await tester.tap(find.text('Buat Artikel'));
    await tester.pumpAndSettle();
  });

  testWidgets('Test EditArtikelPage UI and save', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final article = AdminArticleModel(
      id: '1',
      title: 'Mengenal Tipe Kulit Wajah Anda',
      category: 'Kulit Dasar',
      date: '2026-08-01',
      content: 'Pelajari cara mengenali tipe kulit.',
      status: ArticleStatus.diterbitkan,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EditArtikelPage(article: article),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Artikel'), findsOneWidget);
    expect(find.text('Mengenal Tipe Kulit Wajah Anda'), findsOneWidget);
    expect(find.text('Kulit Dasar'), findsOneWidget);

    // Edit title
    final titleField = find.widgetWithText(TextField, 'Mengenal Tipe Kulit Wajah Anda');
    await tester.enterText(titleField, 'Mengenal Tipe Kulit Wajah Kita');
    await tester.pumpAndSettle();

    // Toggle status to Draf
    await tester.tap(find.widgetWithText(ElevatedButton, 'Draf'));
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
  });

  testWidgets('Test ManajemenEdukasiPage full flow to TambahArtikel and EditArtikel', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ManajemenEdukasiPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap "+ Baru"
    await tester.tap(find.text('+ Baru'));
    await tester.pumpAndSettle();

    // Now on TambahArtikelPage
    expect(find.text('Artikel Baru'), findsOneWidget);
    final titleField = find.widgetWithText(TextField, 'Judul artikel...');
    await tester.enterText(titleField, 'Artikel Baru Eksperimen');
    final catField = find.widgetWithText(TextField, 'Kategori artikel...');
    await tester.enterText(catField, 'Tips');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buat Artikel'));
    await tester.pumpAndSettle();

    // Returned to ManajemenEdukasiPage with success dialog
    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Artikel baru berhasil ditambahkan'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Artikel Baru Eksperimen'), findsOneWidget);

    // Tap "Edit" on the new article
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();

    // Now on EditArtikelPage
    expect(find.text('Edit Artikel'), findsOneWidget);
    final editTitleField = find.widgetWithText(TextField, 'Artikel Baru Eksperimen');
    await tester.enterText(editTitleField, 'Artikel Baru Diedit');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    // Returned with success dialog
    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Artikel berhasil diperbarui'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Artikel Baru Diedit'), findsOneWidget);
  });

  testWidgets('Test DetailPatientInsightPage UI and switch patient', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: DetailPatientInsightPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Patient Insight'), findsOneWidget);
    expect(find.text('Leonita Yulyta Agustin'), findsOneWidget);
    expect(find.text('3 konsultasi'), findsOneWidget);
    expect(find.text('Ganti'), findsOneWidget);

    // Section 1: Ringkasan Insight
    expect(find.text('RINGKASAN INSIGHT'), findsOneWidget);
    expect(find.text('KONDISI KULIT TERATAS'), findsOneWidget);
    expect(find.text('Berminyak'), findsWidgets);
    expect(find.text('6.6'), findsWidgets);
    expect(find.text('Gelas/Hari'), findsOneWidget);
    expect(find.text('57%'), findsWidgets);
    expect(find.text('Skincare'), findsWidgets);
    expect(find.text('INSIGHT'), findsOneWidget);

    // Section 2: Skin Check
    expect(find.text('SKIN CHECK'), findsOneWidget);
    expect(find.text('2026-08-28'), findsWidgets);
    expect(find.text('Kombinasi'), findsOneWidget);
    expect(find.text('Sensitif'), findsOneWidget);

    // Section 3: Skin Daily
    expect(find.text('SKIN DAILY'), findsOneWidget);
    expect(find.text('Letak Gejala: Hidung, Dahi'), findsOneWidget);
    expect(find.text('Pagi ✓'), findsWidgets);

    // Section 4: Skincare Routine
    expect(find.text('SKINCARE ROUTINE'), findsOneWidget);
    expect(find.text('PAGI'), findsWidgets);
    expect(find.text('MALAM'), findsWidgets);

    // Tap "Ganti" button
    await tester.tap(find.text('Ganti'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Pasien'), findsOneWidget);
    expect(find.text('Annida Tri Aulia'), findsOneWidget);

    // Select Annida
    await tester.tap(find.text('Annida Tri Aulia'));
    await tester.pumpAndSettle();

    // Now header shows Annida
    expect(find.text('Annida Tri Aulia'), findsOneWidget);
  });

  testWidgets('Test PatientInsightPage navigation to DetailPatientInsightPage', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PatientInsightPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PILIH PASIEN'), findsOneWidget);
    expect(find.text('Leonita Yulyta Agustin'), findsOneWidget);

    // Tap on Leonita Yulyta Agustin
    await tester.tap(find.text('Leonita Yulyta Agustin'));
    await tester.pumpAndSettle();

    // Navigated to DetailPatientInsightPage
    expect(find.text('RINGKASAN INSIGHT'), findsOneWidget);
    expect(find.text('KONDISI KULIT TERATAS'), findsOneWidget);
    expect(find.text('Ganti'), findsOneWidget);

    // Back to PatientInsightPage
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();

    expect(find.text('PILIH PASIEN'), findsOneWidget);
  });

  testWidgets('Test JadwalDokterPage availability toggle, form add slot, and delete confirmation dialog', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: JadwalDokterPage(showBottomNav: true),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial State
    expect(find.text('Jadwal'), findsWidgets);
    expect(find.text('Status Ketersediaan'), findsOneWidget);
    expect(find.text('Sibuk'), findsOneWidget);
    expect(find.text('Tambah Slot Baru'), findsOneWidget);
    expect(find.text('Slot Baru'), findsNothing);

    // 2. Toggle availability: Sibuk -> Siap
    await tester.tap(find.text('Sibuk'));
    await tester.pumpAndSettle();
    expect(find.text('Siap'), findsOneWidget);
    expect(find.text('Sibuk'), findsNothing);

    // Toggle back: Siap -> Sibuk
    await tester.tap(find.text('Siap'));
    await tester.pumpAndSettle();
    expect(find.text('Sibuk'), findsOneWidget);
    expect(find.text('Siap'), findsNothing);

    // 3. Open Form: "Tambah Slot Baru" -> "Tutup Form"
    await tester.tap(find.text('Tambah Slot Baru'));
    await tester.pumpAndSettle();

    expect(find.text('Tutup Form'), findsOneWidget);
    expect(find.text('Slot Baru'), findsOneWidget);
    expect(find.text('TANGGAL'), findsOneWidget);
    expect(find.text('JAM MULAI'), findsOneWidget);
    expect(find.text('JAM SELESAI'), findsOneWidget);
    expect(find.text('Simpan Slot'), findsOneWidget);

    // Close form again using Tutup Form
    await tester.tap(find.text('Tutup Form'));
    await tester.pumpAndSettle();
    expect(find.text('Slot Baru'), findsNothing);
    expect(find.text('Tambah Slot Baru'), findsOneWidget);

    // Open form again to add slot
    await tester.tap(find.text('Tambah Slot Baru'));
    await tester.pumpAndSettle();

    // Enter start and end time
    final startField = find.widgetWithText(TextField, '09:00');
    final endField = find.widgetWithText(TextField, '09:30');
    await tester.enterText(startField, '15:30');
    await tester.enterText(endField, '16:00');
    await tester.pumpAndSettle();

    // Tap "Simpan Slot"
    await tester.tap(find.text('Simpan Slot'));
    await tester.pumpAndSettle();

    // Form is closed and new slot appears
    expect(find.text('Slot Baru'), findsNothing);
    expect(find.text('15:30 - 16:00'), findsOneWidget);

    // 4. Delete slot with confirmation dialog: First test "Batal"
    final newSlotContainer = find.ancestor(
      of: find.text('15:30 - 16:00'),
      matching: find.byWidgetPredicate(
        (widget) => widget is Container && widget.child is Row,
      ),
    );
    final hapusButton = find.descendant(
      of: newSlotContainer,
      matching: find.text('Hapus'),
    );
    expect(hapusButton, findsOneWidget);
    await tester.tap(hapusButton);
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Hapus Slot?'), findsOneWidget);
    expect(find.text('Slot ini akan dihapus dari jadwal Anda.'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Ya, Hapus'), findsOneWidget);

    // Tap Batal
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    // Dialog dismissed and slot still exists
    expect(find.text('Hapus Slot?'), findsNothing);
    expect(find.text('15:30 - 16:00'), findsOneWidget);

    // Tap Hapus again and confirm with "Ya, Hapus"
    await tester.tap(hapusButton);
    await tester.pumpAndSettle();

    expect(find.text('Hapus Slot?'), findsOneWidget);
    await tester.tap(find.text('Ya, Hapus'));
    await tester.pumpAndSettle();

    // Success dialog appears
    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Slot berhasil dihapus'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    // Tap OK
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Dialog dismissed and slot removed
    expect(find.text('Berhasil'), findsNothing);
    expect(find.text('15:30 - 16:00'), findsNothing);
  });

  testWidgets('Test RuangChatDokterPage UI, message sending, and finish confirmation cancel', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RuangChatDokterPage(
          patientName: 'Leonita Yulyta Agustin',
          showBottomNav: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Leonita Yulyta Agustin'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Selamat pagi, Leonita. Ada yang bisa saya bantu hari ini?'), findsOneWidget);
    expect(find.text('Baik Dok, terima kasih banyak atas penjelasannya!'), findsOneWidget);

    // Send a message
    final inputField = find.widgetWithText(TextField, 'Ketik pesan...');
    await tester.enterText(inputField, 'Semoga lekas sembuh dan pulih ya!');
    await tester.pumpAndSettle();

    // Tap send button
    final sendBtn = find.byIcon(LucideIcons.send);
    await tester.tap(sendBtn);
    await tester.pumpAndSettle();

    expect(find.text('Semoga lekas sembuh dan pulih ya!'), findsOneWidget);

    // Tap "Selesai" button
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    expect(find.text('Selesaikan Konsultasi?'), findsOneWidget);
    expect(find.text('Konsultasi akan ditandai selesai.'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Ya, Selesai'), findsOneWidget);

    // Tap "Batal"
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Selesaikan Konsultasi?'), findsNothing);
    expect(find.text('Leonita Yulyta Agustin'), findsOneWidget);
  });

  testWidgets('Test ChatKonsultasiPage flow to RuangChatDokterPage, complete consultation, and show Berhasil dialog', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ChatKonsultasiPage(showBottomNav: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Konsultasi'), findsOneWidget);
    expect(find.text('Leonita Yulyta Agustin'), findsWidgets);
    expect(find.text('Mulai Konsultasi'), findsWidgets);
    expect(find.text('Masuk Ruang Chat'), findsOneWidget);

    // Tap "Mulai Konsultasi" on the first card (Leonita)
    await tester.tap(find.text('Mulai Konsultasi').first);
    await tester.pumpAndSettle();

    // Now in RuangChatDokterPage
    expect(find.text('Leonita Yulyta Agustin'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);

    // Tap "Selesai"
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    expect(find.text('Selesaikan Konsultasi?'), findsOneWidget);

    // Confirm with "Ya, Selesai"
    await tester.tap(find.text('Ya, Selesai'));
    await tester.pumpAndSettle();

    // Popped back to ChatKonsultasiPage and Success Dialog appears (Screen 4)
    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Konsultasi telah diselesaikan'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    // Tap "OK" -> Automatically navigates to RiwayatKonsultasiPage!
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Berhasil'), findsNothing);

    // Now on RiwayatKonsultasiPage
    expect(find.text('Riwayat Konsultasi'), findsOneWidget);
    // Leonita 09:00 - 09:30 is now present in Riwayat Konsultasi!
    expect(find.text('2026-08-28 • 09:00 - 09:30'), findsOneWidget);

    // Pop back to ChatKonsultasiPage
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();

    // Back on ChatKonsultasiPage: Leonita 09:00 - 09:30 has been removed from active list!
    expect(find.text('Konsultasi'), findsOneWidget);
    expect(find.text('2026-08-28 • 09:00 - 09:30'), findsNothing);
    // Annida 09:30 - 10:00 is now at the top
    expect(find.text('2026-08-28 • 09:30 - 10:00'), findsOneWidget);
  });

  testWidgets('Test DokterMainPage consultation completion switches to Riwayat tab automatically', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterMainPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on Chat tab (index 2)
    final chatTab = find.text('Chat');
    expect(chatTab, findsWidgets);
    await tester.tap(chatTab.first);
    await tester.pumpAndSettle();

    // Now on ChatKonsultasiPage
    expect(find.text('Konsultasi'), findsOneWidget);

    // Tap on "Masuk Ruang Chat" or "Mulai Konsultasi"
    final actionBtn = find.text('Masuk Ruang Chat');
    expect(actionBtn, findsOneWidget);
    await tester.tap(actionBtn);
    await tester.pumpAndSettle();

    // Now in RuangChatDokterPage
    expect(find.text('Selesai'), findsOneWidget);
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    // Tap "Ya, Selesai"
    await tester.tap(find.text('Ya, Selesai'));
    await tester.pumpAndSettle();

    // Success dialog shown
    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Konsultasi telah diselesaikan'), findsOneWidget);

    // Tap "OK" -> Switches to Riwayat tab
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Now on Riwayat tab!
    expect(find.text('Riwayat Konsultasi'), findsOneWidget);
  });

  testWidgets('Test DetailRiwayatKonsultasiPage UI and chat history directly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: DetailRiwayatKonsultasiPage(showBottomNav: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Riwayat'), findsOneWidget);
    expect(find.text('Leonita Yulyta Agustin'), findsOneWidget);
    expect(find.text('2026-08-15 • 09:00 - 09:30'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('RIWAYAT CHAT'), findsOneWidget);
    expect(find.text('Belum ada riwayat chat'), findsNothing);
    expect(find.text('Dok, saya mau tanya soal perawatan kulit setelah operasi kecil'), findsOneWidget);
    expect(find.text('Tentu, operasi apa yang sudah dilakukan?'), findsOneWidget);
    expect(find.text('Operasi kecil untuk angkat tahi lalat di pipi kanan'), findsOneWidget);
    expect(find.text('Baik, hindari paparan matahari langsung selama 2 minggu. Gunakan krim antibiotik yang sudah saya resepkan.'), findsOneWidget);
  });

  testWidgets('Test RiwayatKonsultasiPage tap card navigates to DetailRiwayatKonsultasiPage', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RiwayatKonsultasiPage(showBottomNav: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Konsultasi'), findsOneWidget);
    expect(find.text('2026-08-15 • 09:00 - 09:30'), findsOneWidget);

    // Tap on Leonita Yulyta Agustin card
    await tester.tap(find.text('2026-08-15 • 09:00 - 09:30'));
    await tester.pumpAndSettle();

    // Now on DetailRiwayatKonsultasiPage
    expect(find.text('Detail Riwayat'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);
    expect(find.text('RIWAYAT CHAT'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();

    // Returned to RiwayatKonsultasiPage
    expect(find.text('Riwayat Konsultasi'), findsOneWidget);
  });

  testWidgets('Test EditProfilDokterPage UI and update', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: EditProfilDokterPage(showBottomNav: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('DA'), findsOneWidget);
    expect(find.text('NAMA'), findsOneWidget);
    expect(find.text('SPESIALISASI'), findsOneWidget);
    expect(find.text('PENGALAMAN'), findsOneWidget);
    expect(find.text('TELEPON'), findsOneWidget);
    expect(find.text('ALAMAT'), findsOneWidget);
    expect(find.text('BIO'), findsOneWidget);

    final nameField = find.byType(TextField).first;
    await tester.enterText(nameField, 'dr. Budi Santoso, Sp.KK');
    await tester.pumpAndSettle();

    // Initials should update to DB
    expect(find.text('DB'), findsOneWidget);

    // Revert back
    await tester.enterText(nameField, 'dr. Anita Dewi, Sp.KK');
    await tester.pumpAndSettle();
    expect(find.text('DA'), findsOneWidget);

    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
  });

  testWidgets('Test Dokter PengaturanDokterPage UI, toggle and save', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: dokter_settings.PengaturanDokterPage(showBottomNav: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('NOTIFIKASI'), findsOneWidget);
    expect(find.text('Aktifkan Notifikasi'), findsOneWidget);

    await tester.tap(find.text('Simpan Pengaturan'));
    await tester.pumpAndSettle();

    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Pengaturan dokter berhasil disimpan'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('Test TentangDokterPage UI', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: TentangDokterPage(showBottomNav: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tentang'), findsOneWidget);
    expect(find.text('Skinora'), findsOneWidget);
    expect(find.text('VERSI 1.0.0'), findsOneWidget);
    expect(find.text('Dikembangkan oleh Tim Skinora'), findsOneWidget);
    expect(find.text('© 2026 Skinora'), findsOneWidget);
  });

  testWidgets('Test RiwayatAktivitasDokterPage UI', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RiwayatAktivitasDokterPage(showBottomNav: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Aktivitas'), findsOneWidget);
    expect(find.text('Konsultasi selesai dengan Annida Tri Aulia'), findsOneWidget);
    expect(find.text('2026-08-29 10:30'), findsOneWidget);
    expect(find.text('Login berhasil'), findsOneWidget);
    expect(find.text('2026-08-29 08:00'), findsOneWidget);
  });

  testWidgets('Test ProfilDokterPage full navigation and logout dialog', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: dokter.ProfilDokterPage(showBottomNav: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profil Dokter'), findsOneWidget);
    expect(find.text('dr. Anita Dewi, Sp.KK'), findsOneWidget);
    expect(find.text('DA'), findsOneWidget);
    expect(find.text('RINGKASAN PRAKTIK'), findsOneWidget);
    expect(find.text('Konsultasi'), findsOneWidget);
    expect(find.text('Pasien'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('INFORMASI'), findsOneWidget);
    expect(find.text('081234567800'), findsOneWidget);

    // 1. Test Logout Dialog
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Apakah Anda yakin ingin keluar?'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Apakah Anda yakin ingin keluar?'), findsNothing);

    // 2. Test navigate to Edit Profil
    await tester.tap(find.text('Edit Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profil'), findsOneWidget);
    // Back
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();

    // 3. Test navigate to Pengaturan
    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    expect(find.text('Aktifkan Notifikasi'), findsOneWidget);
    // Back
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();

    // 4. Test navigate to Tentang Aplikasi
    await tester.tap(find.text('Tentang Aplikasi'));
    await tester.pumpAndSettle();
    expect(find.text('VERSI 1.0.0'), findsOneWidget);
    // Back
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();

    // 5. Test navigate to Riwayat Aktivitas
    await tester.tap(find.text('Riwayat Aktivitas'));
    await tester.pumpAndSettle();
    expect(find.text('Konsultasi selesai dengan Annida Tri Aulia'), findsOneWidget);
    // Back
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();
  });
}






