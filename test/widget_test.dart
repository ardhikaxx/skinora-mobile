import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:skinora_app/pages/dokter/profil_dokter_page.dart' as dokter;

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
}
