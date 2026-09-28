import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/components/realtime_wib_badge.dart';
import 'package:skinora_app/utils/app_dates.dart';

void main() {
  group('AppDates Format Tanggal dan Waktu WIB', () {
    test('toWib mengonversi UTC ke UTC+7 dengan tepat', () {
      final utc = DateTime.utc(2026, 8, 28, 5, 30, 0); // 05:30 UTC
      final wib = AppDates.toWib(utc);
      expect(wib.hour, 12);
      expect(wib.minute, 30);
    });

    test('hmWib dan hmsWib menambahkan suffix WIB dengan benar', () {
      final dt = DateTime.utc(2026, 8, 28, 2, 15, 45); // 09:15:45 WIB
      expect(AppDates.hmWib(dt), '09.15 WIB');
      expect(AppDates.hmsWib(dt), '09.15.45 WIB');
    });

    test('dateTimeWib menghasilkan format tanggal pendek dengan jam WIB', () {
      final dt = DateTime.utc(2026, 8, 28, 2, 15, 0); // 28 Agu 2026, 09.15 WIB
      expect(AppDates.dateTimeWib(dt), '28 Agu 2026, 09.15 WIB');
      expect(AppDates.dateTimeWib(dt, includeSeconds: true), '28 Agu 2026, 09.15.00 WIB');
    });

    test('fullDisplayWib menyertakan hari, tanggal penuh, dan jam WIB', () {
      final dt = DateTime.utc(2026, 8, 28, 7, 0, 0); // 28 Agustus 2026 adalah hari Jumat, 14.00 WIB
      expect(
        AppDates.fullDisplayWib(dt),
        'Jumat, 28 Agustus 2026 • 14.00 WIB',
      );
    });

    test('relativeWib memberikan teks relatif yang akurat', () {
      final now = DateTime.now();
      expect(AppDates.relativeWib(now), 'Baru saja');

      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      expect(AppDates.relativeWib(fiveMinutesAgo), '5 menit yang lalu');
    });

    test('formatTimestampWib menerima String ISO, DateTime, dan int epoch', () {
      final dt = DateTime.utc(2026, 8, 28, 2, 15, 0);
      expect(AppDates.formatTimestampWib(dt), '28 Agu 2026, 09.15 WIB');
      expect(AppDates.formatTimestampWib(dt.millisecondsSinceEpoch), '28 Agu 2026, 09.15 WIB');
      expect(AppDates.formatTimestampWib(dt.toIso8601String()), '28 Agu 2026, 09.15 WIB');
      expect(AppDates.formatTimestampWib(null), '');
    });

    test('formatRange dengan withWib menyertakan suffix WIB', () {
      expect(AppDates.formatRange('09:00 - 09:30', withWib: true), '09.00 - 09.30 WIB');
      expect(AppDates.formatRange('09:00', withWib: true), '09.00 WIB');
    });

    test('realtimeWibStream memancarkan waktu WIB', () async {
      final stream = AppDates.realtimeWibStream(interval: const Duration(milliseconds: 50));
      final emitted = await stream.first;
      expect(emitted, isNotNull);
    });
  });

  group('RealtimeWibBadge Widget', () {
    testWidgets('menampilkan pill realtime badge dengan benar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RealtimeWibBadge(
                style: RealtimeWibStyle.pill,
                includeSeconds: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(RealtimeWibBadge), findsOneWidget);
      expect(find.textContaining('WIB'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('menampilkan minimal dan card realtime badge tanpa error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RealtimeWibBadge(style: RealtimeWibStyle.minimal),
                RealtimeWibBadge(style: RealtimeWibStyle.card),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(RealtimeWibBadge), findsNWidgets(2));
      expect(find.textContaining('WIB'), findsNWidgets(2));

      await tester.pumpWidget(const SizedBox());
    });
  });
}
