import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skinora_app/pages/dokter/chat_konsultasi_page.dart';
import 'package:skinora_app/pages/pengguna/menunggu_konfirmasi_page.dart';
import 'package:skinora_app/pages/pengguna/profil_dokter_page.dart';
import 'package:skinora_app/services/schedule_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Alur Booking Konsultasi Pasien Sebelum Jam Sesi Dimulai', () {
    testWidgets('Pasien dapat memilih slot konsultasi di jam 15.30 sebelum jam 15.30 dan muncul dialog konfirmasi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Siapkan dokter dengan slot jam 15.30
      final doctor = DoctorProfileDetailModel(
        id: 'doc_1',
        name: 'dr. Sarah Sp.KK',
        specialization: 'Spesialis Kulit & Kelamin',
        experience: '5 Tahun',
        bio: 'Dokter spesialis kulit dan kelamin.',
        schedules: const [
          DoctorScheduleModel(
            dayDate: 'SENIN, 3 NOVEMBER 2026',
            timeSlots: ['15.30 - 16.00'],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilDokterPenggunaPage(
            doctorId: doctor.id,
            doctorName: doctor.name,
            specialization: doctor.specialization,
            initialDoctor: doctor,
            initialSlots: const [
              SlotRecord(
                id: 'slot_1530',
                doctorId: 'doc_1',
                date: 'SENIN, 3 NOVEMBER 2026',
                time: '15.30 - 16.00',
                timeStart: '15.30',
                timeEnd: '16.00',
                quota: 2,
                bookedCount: 0,
                isBooked: false,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan slot 15.30 - 16.00 tampil di profil dokter
      expect(find.text('15.30 - 16.00'), findsOneWidget);

      // Pasien mengetap slot 15.30 - 16.00
      await tester.tap(find.text('15.30 - 16.00'));
      await tester.pump(); // trigger dialog

      // Muncul dialog menunggu konfirmasi dokter (tidak diblokir oleh "Belum Waktunya Konsultasi")
      expect(find.text('Menunggu Konfirmasi Dokter...'), findsOneWidget);
      expect(find.text('Belum Waktunya Konsultasi'), findsNothing);

      // Tunggu delay navigasi dialog
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Pasien diarahkan ke halaman awal Menunggu Verifikasi Dokter
      expect(find.text('Menunggu Verifikasi Dokter'), findsWidgets);
    });
  });

  group('Halaman Menunggu Verifikasi Pasien & Masuk Ruang Chat Setelah Diverifikasi', () {
    testWidgets('Tampil status menunggu verifikasi dan berubah jadi Masuk Ruang Chat saat terverifikasi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MenungguKonfirmasiPage(
            doctorId: 'doc_1',
            doctorName: 'dr. Sarah Sp.KK',
            specialization: 'Spesialis Kulit',
            dateTime: 'Senin, 3 November 2026 • 15.30 WIB',
            scheduleDate: 'Senin, 3 November 2026',
            scheduleTime: '15.30 - 16.00',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi tampilan awal status Menunggu Verifikasi
      expect(find.text('Menunggu Verifikasi Dokter'), findsWidgets);
      expect(find.text('Menunggu Verifikasi'), findsOneWidget);
      expect(find.text('Masuk Ruang Chat'), findsNothing);
    });
  });

  group('Alur Verifikasi Dokter di ChatKonsultasiPage', () {
    testWidgets('Tombol Verifikasi Sekarang berubah menjadi Mulai Konsultasi, dan tetap Masuk Ruang Chat saat keluar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final consultationItem = ConsultationItemModel(
        id: 'c_test_1',
        patientName: 'Budi Santoso',
        dateTime: 'Senin, 3 November 2026 • 15.30 - 16.00',
        status: 'Menunggu Verifikasi',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatKonsultasiPage(
            initialConsultations: [consultationItem],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Sebelum diverifikasi, tombol bertuliskan "Verifikasi Sekarang"
      expect(find.text('Menunggu Verifikasi'), findsOneWidget);
      expect(find.text('Verifikasi Sekarang'), findsOneWidget);
      expect(find.text('Mulai Konsultasi'), findsNothing);

      // 2. Dokter klik "Verifikasi Sekarang"
      await tester.tap(find.text('Verifikasi Sekarang'));
      await tester.pumpAndSettle();

      // Status berubah menjadi "Terjadwal" dan tombol berubah menjadi "Mulai Konsultasi"
      expect(find.text('Terjadwal'), findsOneWidget);
      expect(find.text('Mulai Konsultasi'), findsOneWidget);
      expect(find.text('Verifikasi Sekarang'), findsNothing);

      // 3. Dokter klik "Mulai Konsultasi" -> masuk ke RuangChatDokterPage
      await tester.tap(find.text('Mulai Konsultasi'));
      await tester.pumpAndSettle();

      // Di dalam RuangChatDokterPage
      expect(find.text('Budi Santoso'), findsOneWidget);

      // 4. Dokter keluar dari ruang konsultasi (tap back button) saat sesi berlangsung
      await tester.tap(find.byIcon(LucideIcons.chevronLeft).first);
      await tester.pumpAndSettle();

      // Kembali ke halaman konsultasi dokter: status adalah Berlangsung dan tombol tetap "Masuk Ruang Chat"
      expect(find.text('Berlangsung'), findsOneWidget);
      expect(find.text('Masuk Ruang Chat'), findsOneWidget);
    });
  });
}
