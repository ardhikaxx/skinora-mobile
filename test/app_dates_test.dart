import 'package:cloud_firestore/cloud_firestore.dart';
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

    test('toWib bersifat idempoten dan tidak menambah offset ganda', () {
      final utc = DateTime.utc(2026, 8, 28, 5, 30, 0); // 05:30 UTC -> 12:30 WIB
      final wib1 = AppDates.toWib(utc);
      final wib2 = AppDates.toWib(wib1);
      final wib3 = AppDates.toWib(wib2);
      expect(wib1.hour, 12);
      expect(wib1.minute, 30);
      expect(wib2.hour, 12);
      expect(wib2.minute, 30);
      expect(wib3.hour, 12);
      expect(wib3.minute, 30);
    });

    test('nowWib diformat dengan hmWib, hmsWib, dan fullDisplayWib tidak bergeser ganda', () {
      final now = AppDates.nowWib();
      final expectedHour = now.hour.toString().padLeft(2, '0');
      final expectedMinute = now.minute.toString().padLeft(2, '0');
      final expectedPrefix = '$expectedHour.$expectedMinute';

      expect(AppDates.hmWib(now), startsWith(expectedPrefix));
      expect(AppDates.hmsWib(now), startsWith(expectedPrefix));
      expect(AppDates.fullDisplayWib(now), contains(expectedPrefix));
      expect(AppDates.formatChatTimeWib(now), startsWith(expectedPrefix));
    });

    test('greetingWib mengembalikan salam tanpa tanda koma di akhir', () {
      final greeting = AppDates.greetingWib();
      expect(greeting.endsWith(','), isFalse);
      expect(
        greeting == 'Selamat pagi' ||
            greeting == 'Selamat siang' ||
            greeting == 'Selamat sore' ||
            greeting == 'Selamat malam',
        isTrue,
      );
    });

    test('timeOfDayWib mengembalikan jam dan menit sesuai waktu WIB', () {
      final tod = AppDates.timeOfDayWib();
      final now = AppDates.nowWib();
      expect(tod.hour, now.hour);
      expect(tod.minute, now.minute);
    });

    test('isPastSlot mendeteksi slot lampau dan slot aktif/akan datang dengan benar', () {
      final now = AppDates.nowWib();
      final yesterday = AppDates.iso(now.subtract(const Duration(days: 1)));
      final tomorrow = AppDates.iso(now.add(const Duration(days: 1)));

      // Kemarin pasti lampau
      expect(AppDates.isPastSlot(dateIso: yesterday, timeEnd: '10.00'), isTrue);

      // Besok pasti belum lampau
      expect(AppDates.isPastSlot(dateIso: tomorrow, timeEnd: '10.00'), isFalse);

      // String gabungan "2026-08-28 • 09:00 - 09:30"
      expect(
        AppDates.isPastSlot(dateIso: '2026-08-28 • 09:00 - 09:30'),
        isTrue,
      );

      // Tanggal lampau spesifik
      expect(AppDates.isPastSlot(dateIso: '2020-01-01', timeEnd: '12.00'), isTrue);

      // Tanggal masa depan spesifik
      expect(AppDates.isPastSlot(dateIso: '2030-01-01', timeEnd: '12.00'), isFalse);
    });

    test('formatChatTimeWib memformat string jam dan Timestamp dengan benar', () {
      final now = AppDates.nowWib();
      final expectedHmWib = AppDates.hmWib(now);
      expect(AppDates.formatChatTimeWib(now), equals(expectedHmWib));
      expect(AppDates.formatChatTimeWib(null, now), equals(expectedHmWib));
      expect(AppDates.formatChatTimeWib('09:01'), equals('09.01 WIB'));
      expect(AppDates.formatChatTimeWib('09.01 WIB'), equals('09.01 WIB'));

      final ts = Timestamp.now();
      expect(AppDates.formatChatTimeWib(ts), equals(expectedHmWib));

      final tsUtc = Timestamp.fromDate(DateTime.utc(2026, 9, 30, 0, 29, 0));
      expect(AppDates.formatChatTimeWib(tsUtc), equals('07.29 WIB'));
    });

    test('tryParseDisplay menangani nama bulan pendek dan panjang', () {
      final sepLong = AppDates.tryParseDisplay('Rabu, 30 September 2026');
      expect(sepLong, isNotNull);
      expect(sepLong!.month, 9);
      expect(sepLong.day, 30);

      final sepShort = AppDates.tryParseDisplay('30 Sep 2026');
      expect(sepShort, isNotNull);
      expect(sepShort!.month, 9);
      expect(sepShort.day, 30);
    });

    test('isConsultationExpired mendeteksi sesi kadaluarsa dari berbagai format', () {
      final now = AppDates.nowWib();
      final todayIso = AppDates.iso(now);
      final pastHour = (now.hour - 1).clamp(0, 23).toString().padLeft(2, '0');
      final pastSlot = '$pastHour.00 - $pastHour.15 WIB';

      expect(
        AppDates.isConsultationExpired(dateIso: todayIso, timeEnd: pastSlot),
        isTrue,
      );

      final futureHour = (now.hour + 2).clamp(0, 23).toString().padLeft(2, '0');
      final futureSlot = '$futureHour.00 - $futureHour.15 WIB';

      expect(
        AppDates.isConsultationExpired(dateIso: todayIso, timeEnd: futureSlot),
        isFalse,
      );
    });

    test('formatSkinCheckDateWib memformat Timestamp, ISO, millis, dan display WIB dengan akurat', () {
      // 1. String yang sudah dalam format WIB lengkap dipertahankan langsung tanpa pergeseran
      const displayOriginal = 'Selasa, 29 September 2026 • 20.30 WIB';
      expect(
        AppDates.formatSkinCheckDateWib(null, fallbackDisplay: displayOriginal),
        equals(displayOriginal),
      );

      // 2. Firestore Timestamp jam 13:30 UTC -> harus tetap 20:30 WIB di tanggal 29 September (tidak lompat ke 30 Sep)
      final tsUtc = Timestamp.fromDate(DateTime.utc(2026, 9, 29, 13, 30, 0));
      expect(
        AppDates.formatSkinCheckDateWib(tsUtc),
        equals('Selasa, 29 September 2026 • 20.30 WIB'),
      );

      // 3. String ISO UTC -> 20:30 WIB di tanggal 29 September
      expect(
        AppDates.formatSkinCheckDateWib('2026-09-29T13:30:00Z'),
        equals('Selasa, 29 September 2026 • 20.30 WIB'),
      );

      // 4. Epoch millis UTC -> 20:30 WIB di tanggal 29 September
      final millis = DateTime.utc(2026, 9, 29, 13, 30, 0).millisecondsSinceEpoch;
      expect(
        AppDates.formatSkinCheckDateWib(millis),
        equals('Selasa, 29 September 2026 • 20.30 WIB'),
      );

      // 5. Fallback doc map dengan createdDisplay
      final docMap = {
        'createdDisplay': 'Rabu, 30 September 2026 • 08.20 WIB',
        'createdIso': '2026-09-30',
        'createdAt': tsUtc,
      };
      expect(
        AppDates.formatSkinCheckDateWib(null, doc: docMap),
        equals('Rabu, 30 September 2026 • 08.20 WIB'),
      );

      // 6. Tanggal ISO saja tanpa jam
      expect(
        AppDates.formatSkinCheckDateWib(null, fallbackDisplay: '2026-08-28'),
        contains('Jumat, 28 Agustus 2026'),
      );
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

    testWidgets('RealtimeWibBadge menampilkan jam WIB aktual tanpa pergeseran ganda', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealtimeWibBadge(
              style: RealtimeWibStyle.minimal,
              showDate: false,
              includeSeconds: false,
            ),
          ),
        ),
      );

      await tester.pump();
      final now = AppDates.nowWib();
      final expectedTime = AppDates.hmWib(now);
      expect(find.text(expectedTime), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
