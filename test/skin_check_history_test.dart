import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/pages/pengguna/riwayat_skin_check_page.dart';
import 'package:skinora_app/pages/pengguna/skin_check_result_page.dart';
import 'package:skinora_app/services/skin_service.dart';
import 'package:skinora_app/utils/app_dates.dart';

void main() {
  group('Riwayat Skin Check Realtime & WIB Format Tests', () {
    testWidgets('RiwayatSkinCheckPage menampilkan format tanggal dan jam WIB Indonesia', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RiwayatSkinCheckPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan halaman render dan menampilkan teks WIB pada card riwayat
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.textContaining('WIB'), findsWidgets);
      expect(find.text('Kombinasi'), findsWidgets);
      expect(find.text('Normal'), findsWidgets);
    });

    testWidgets('Menyimpan Skin Check baru secara realtime muncul di RiwayatSkinCheckPage', (tester) async {
      final specificTime = DateTime.utc(2026, 9, 30, 7, 45, 0); // 14.45 WIB
      final customDisplay = AppDates.fullDisplayWib(specificTime);

      await SkinService.saveSkinCheck(
        uid: 'test_user_wib',
        name: 'Tester WIB',
        answers: {
          'age': '24',
          'gender': 'Wanita',
        },
        resultSkinType: 'Berminyak',
        resultSensitivity: 'Sangat Sensitif',
        resultAcneRisk: 'Rentan',
        createdDisplay: customDisplay,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: RiwayatSkinCheckPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Card baru langsung muncul di riwayat dengan jam dan tanggal yang sama persis
      expect(find.text('Berminyak'), findsWidgets);
      expect(find.text(customDisplay), findsOneWidget);

      // Tap card riwayat membuka SkinCheckResultPage dengan createdDisplay yang cocok persis
      await tester.tap(find.text('Berminyak').first);
      await tester.pumpAndSettle();

      expect(find.byType(SkinCheckResultPage), findsOneWidget);
      expect(find.text(customDisplay), findsOneWidget);
      expect(find.text('Berminyak'), findsWidgets);
    });

    test('formatSkinCheckDateWib tidak melompat keesokan harinya untuk Timestamp malam hari WIB', () {
      // Misal skin check diambil tanggal 29 September 2026 jam 21.45 WIB (14.45 UTC)
      final tsNight = Timestamp.fromDate(DateTime.utc(2026, 9, 29, 14, 45, 0));
      final formatted = AppDates.formatSkinCheckDateWib(tsNight);

      // Harus tetap 29 September 2026, jam 21.45 WIB (TIDAK melompat ke 30 September)
      expect(formatted, equals('Selasa, 29 September 2026 • 21.45 WIB'));
      expect(formatted, contains('29 September 2026'));
      expect(formatted, contains('21.45 WIB'));
      expect(formatted.contains('30 September'), isFalse);
    });
  });
}
