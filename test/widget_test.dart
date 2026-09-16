import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/pages/pengguna/pengguna_main_page.dart';
import 'package:skinora_app/pages/pengguna/profil_pengguna_page.dart';
import 'package:skinora_app/pages/pengguna/edit_profil_pengguna_page.dart';
import 'package:skinora_app/pages/pengguna/pengaturan_pengguna_page.dart';
import 'package:skinora_app/pages/pengguna/tentang_pengguna_page.dart';
import 'package:skinora_app/pages/pengguna/riwayat_aktivitas_pengguna_page.dart';
import 'package:skinora_app/pages/pengguna/profil_dokter_page.dart';
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
}
