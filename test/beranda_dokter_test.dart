import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/components/realtime_wib_badge.dart';
import 'package:skinora_app/pages/dokter/beranda_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BerandaDokterPage Statistik Card Tests', () {
    testWidgets('Card Statistik Hari Ini hanya menampilkan judul tanpa penanda waktu dan tanggal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: BerandaDokterPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan teks "STATISTIK HARI INI" tampil
      expect(find.text('STATISTIK HARI INI'), findsOneWidget);

      // Memastikan tidak ada penanda waktu dan tanggal (RealtimeWibBadge) di card statistik
      expect(find.byType(RealtimeWibBadge), findsNothing);

      // Memastikan statistik hari ini tetap tampil
      expect(find.text('Hari Ini'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
    });
  });
}
