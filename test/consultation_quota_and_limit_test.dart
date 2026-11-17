import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/models/doctor_practice_settings.dart';
import 'package:skinora_app/pages/dokter/jadwal_page.dart';
import 'package:skinora_app/pages/pengguna/profil_dokter_page.dart';
import 'package:skinora_app/services/consultation_service.dart';
import 'package:skinora_app/services/schedule_service.dart';
import 'package:skinora_app/utils/app_dates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DoctorPracticeSettings & TimeRangeSession Unit Tests', () {
    test('generateSessions 25 menit konsultasi + 5 menit jeda (13.00 - 15.00)', () {
      const settings = DoctorPracticeSettings(
        practiceStartTime: '13.00',
        practiceEndTime: '15.00',
        sessionDurationMinutes: 25,
        breakDurationMinutes: 5,
        quotaPerSession: 1,
      );

      final sessions = settings.generateSessions();
      expect(sessions.length, 4);
      expect(sessions[0].displayRange, '13.00 - 13.25');
      expect(sessions[0].quota, 1);
      expect(sessions[1].displayRange, '13.30 - 13.55');
      expect(sessions[1].quota, 1);
      expect(sessions[2].displayRange, '14.00 - 14.25');
      expect(sessions[2].quota, 1);
      expect(sessions[3].displayRange, '14.30 - 14.55');
      expect(sessions[3].quota, 1);
    });

    test('generateSessions menghasilkan pembagian sesi yang akurat tanpa jeda', () {
      const settings = DoctorPracticeSettings(
        practiceStartTime: '09.00',
        practiceEndTime: '10.00',
        sessionDurationMinutes: 15,
        breakDurationMinutes: 0,
        quotaPerSession: 2,
        dailyPatientLimit: 10,
        autoClose: true,
      );

      final sessions = settings.generateSessions();
      expect(sessions.length, 4);
      expect(sessions[0].displayRange, '09.00 - 09.15');
      expect(sessions[0].quota, 2);
      expect(sessions[1].displayRange, '09.15 - 09.30');
      expect(sessions[2].displayRange, '09.30 - 09.45');
      expect(sessions[3].displayRange, '09.45 - 10.00');
    });

    test('generateSessions dengan durasi 30 menit tanpa jeda', () {
      const settings = DoctorPracticeSettings(
        practiceStartTime: '09.00',
        practiceEndTime: '11.00',
        sessionDurationMinutes: 30,
        breakDurationMinutes: 0,
        quotaPerSession: 3,
      );

      final sessions = settings.generateSessions();
      expect(sessions.length, 4);
      expect(sessions[0].displayRange, '09.00 - 09.30');
      expect(sessions[0].quota, 3);
      expect(sessions[1].displayRange, '09.30 - 10.00');
      expect(sessions[2].displayRange, '10.00 - 10.30');
      expect(sessions[3].displayRange, '10.30 - 11.00');
    });

    test('Serialization toMap dan fromMap konsisten', () {
      const original = DoctorPracticeSettings(
        practiceStartTime: '08.30',
        practiceEndTime: '14.00',
        sessionDurationMinutes: 20,
        breakDurationMinutes: 5,
        quotaPerSession: 1,
        dailyPatientLimit: 15,
        autoClose: true,
      );

      final map = original.toMap();
      final fromMap = DoctorPracticeSettings.fromMap(map);

      expect(fromMap.practiceStartTime, '08.30');
      expect(fromMap.practiceEndTime, '14.00');
      expect(fromMap.sessionDurationMinutes, 20);
      expect(fromMap.breakDurationMinutes, 5);
      expect(fromMap.quotaPerSession, 1);
      expect(fromMap.dailyPatientLimit, 15);
      expect(fromMap.autoClose, true);
    });
  });

  group('SlotRecord Quota & Fullness Unit Tests', () {
    test('remainingQuota dan isFull saat slot kosong', () {
      const slot = SlotRecord(
        id: 'slot_1',
        doctorId: 'doc_1',
        date: 'Senin, 3 November 2026',
        time: '09.00 - 09.15',
        quota: 2,
        bookedCount: 0,
        isBooked: false,
      );

      expect(slot.remainingQuota, 2);
      expect(slot.isFull, false);
      expect(ScheduleService.availabilityOf(slot), isNot(SlotAvailability.booked));
    });

    test('remainingQuota dan isFull saat terisi sebagian', () {
      const slot = SlotRecord(
        id: 'slot_2',
        doctorId: 'doc_1',
        date: 'Senin, 3 November 2026',
        time: '09.15 - 09.30',
        quota: 2,
        bookedCount: 1,
        isBooked: false,
        patientIds: ['user_1'],
        patientNames: ['Pasien A'],
      );

      expect(slot.remainingQuota, 1);
      expect(slot.isFull, false);
    });

    test('remainingQuota dan isFull saat kuota terpenuhi (penuh)', () {
      const slot = SlotRecord(
        id: 'slot_3',
        doctorId: 'doc_1',
        date: 'Senin, 3 November 2026',
        time: '09.30 - 09.45',
        quota: 2,
        bookedCount: 2,
        isBooked: true,
        patientIds: ['user_1', 'user_2'],
        patientNames: ['Pasien A', 'Pasien B'],
      );

      expect(slot.remainingQuota, 0);
      expect(slot.isFull, true);
      expect(ScheduleService.availabilityOf(slot), SlotAvailability.booked);
    });
  });

  group('JadwalDokterPage Slot Baru & Quota UI Tests', () {
    testWidgets('Card Jadwal & Kuota Praktik tidak ada, hanya tombol Tambah Slot Baru', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: JadwalDokterPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jadwal & Kuota Praktik'), findsNothing);
      expect(find.text('Atur Jam & Kuota'), findsNothing);
      expect(find.text('Terapkan Sesi'), findsNothing);
      expect(find.text('Tambah Slot Baru'), findsOneWidget);
    });

    testWidgets('Buka form Tambah Slot Baru dan otomatis mengisi jam selesai saat jam mulai diisi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: JadwalDokterPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Buka form Slot Baru
      await tester.tap(find.text('Tambah Slot Baru'));
      await tester.pumpAndSettle();

      expect(find.text('Slot Baru'), findsOneWidget);
      expect(find.text('JAM MULAI'), findsOneWidget);
      expect(find.text('JAM SELESAI'), findsOneWidget);
      expect(find.text('LIMIT PASIEN (KUOTA PER SESI)'), findsOneWidget);

      // Cari input jam mulai dan jam selesai
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(4)); // tanggal, jam mulai, jam selesai, kuota

      // Input jam mulai 10.00
      await tester.enterText(textFields.at(1), '10.00');
      await tester.pumpAndSettle();

      // Jam selesai otomatis terisi 10.25 (+25 menit sesi)
      final endField = tester.widget<TextField>(textFields.at(2));
      expect(endField.controller?.text, '10.25');
    });

    testWidgets('Simpan slot baru dari form Tambah Slot Baru berhasil', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: JadwalDokterPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Buka form
      await tester.tap(find.text('Tambah Slot Baru'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Senin, 3 November 2026');
      await tester.enterText(textFields.at(1), '13.00');
      await tester.pumpAndSettle();

      // Tap Simpan Slot
      await tester.tap(find.text('Simpan Slot'));
      await tester.pumpAndSettle();

      // Muncul dialog berhasil
      expect(find.text('Slot jadwal berhasil disimpan'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Slot 13.00 - 13.25 muncul di jadwal (sesi 25 menit, kuota 1 pasien)
      expect(find.text('13.00 - 13.25'), findsOneWidget);
      expect(find.text('Limit 1 Pasien'), findsOneWidget);
    });

    testWidgets('Slot yang terisi sebagian atau penuh menampilkan indikator kuota yang tepat', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final initialDays = [
        DayScheduleModel(
          date: 'Senin, 3 November 2026',
          slots: [
            ScheduleSlotModel(
              id: 's_full',
              time: '09.00 - 09.15',
              quota: 2,
              bookedCount: 2,
              isBooked: true,
              patientNames: ['Budi', 'Ani'],
            ),
            ScheduleSlotModel(
              id: 's_partial',
              time: '09.15 - 09.30',
              quota: 2,
              bookedCount: 1,
              isBooked: false,
              patientNames: ['Citra'],
            ),
            ScheduleSlotModel(
              id: 's_empty',
              time: '09.30 - 09.45',
              quota: 2,
              bookedCount: 0,
              isBooked: false,
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: JadwalDokterPage(initialScheduleDays: initialDays),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Penuh (2/2)'), findsOneWidget);
      expect(find.text('Budi, Ani'), findsOneWidget);
      expect(find.text('Sisa 1/2'), findsOneWidget);
      expect(find.text('Citra'), findsOneWidget);
      expect(find.text('Limit 2 Pasien'), findsOneWidget);
    });
  });

  group('ProfilDokterPenggunaPage Quota & Session Display Tests', () {
    testWidgets('Jam praktik otomatis dihapus dan hanya menampilkan jadwal dokter yang dibuka', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfilDokterPenggunaPage(
            doctorId: 'doc_1',
            doctorName: 'dr. Sarah Sp.KK',
            specialization: 'Spesialis Kulit',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profil Dokter'), findsOneWidget);
      expect(find.text('JADWAL TERSEDIA'), findsOneWidget);
      expect(find.text('Maks. 1 Konsultasi / Hari'), findsOneWidget);
      expect(find.textContaining('Jam Praktik:'), findsNothing);
      expect(find.textContaining('Tutup Otomatis'), findsNothing);
    });
  });

  group('Reschedule Consultation Logic & Flow Tests', () {
    test('rescheduleToTomorrow mengalihkan sesi ke besok hari tanpa mengubah status konfirmasi', () async {
      ConsultationService.resetInMemoryStore();
      final now = AppDates.nowWib();
      final todayIso = AppDates.iso(now);
      final todayDisplay = AppDates.display(now);

      ConsultationService.setInMemoryConsultation('consult_1', {
        'id': 'consult_1',
        'doctorId': 'doc_1',
        'doctorName': 'dr. Sarah',
        'patientId': 'patient_1',
        'patientName': 'Budi',
        'scheduleDate': todayDisplay,
        'dateIso': todayIso,
        'scheduleTime': '13.00 - 13.25',
        'timeStart': '13.00',
        'timeEnd': '13.25',
        'status': 'dikonfirmasi',
      });

      await ConsultationService.rescheduleToTomorrow(
        id: 'consult_1',
        doctorUid: 'doc_1',
        doctorName: 'dr. Sarah',
        patientName: 'Budi',
      );

      final updated = ConsultationService.getInMemoryConsultation('consult_1');
      expect(updated, isNotNull);
      final tomorrow = now.add(const Duration(days: 1));
      expect(updated!['dateIso'], AppDates.iso(tomorrow));
      expect(updated['scheduleDate'], AppDates.display(tomorrow));
      expect(updated['scheduleTime'], '13.00 - 13.25');
      expect(updated['status'], 'dikonfirmasi'); // Alur konfirmasi tetap!
      expect(updated['isRescheduled'], true);
    });

    test('rescheduleAllRemainingTodayToTomorrow mengalihkan seluruh pasien aktif hari ini ke besok', () async {
      ConsultationService.resetInMemoryStore();
      final now = AppDates.nowWib();
      final todayIso = AppDates.iso(now);
      final todayDisplay = AppDates.display(now);

      ConsultationService.setInMemoryConsultation('consult_2', {
        'id': 'consult_2',
        'doctorId': 'doc_2',
        'doctorName': 'dr. Amanda',
        'patientId': 'patient_2',
        'patientName': 'Siti',
        'scheduleDate': todayDisplay,
        'dateIso': todayIso,
        'scheduleTime': '13.30 - 13.55',
        'timeStart': '13.30',
        'timeEnd': '13.55',
        'status': 'menunggu_konfirmasi',
      });

      ConsultationService.setInMemoryConsultation('consult_3', {
        'id': 'consult_3',
        'doctorId': 'doc_2',
        'doctorName': 'dr. Amanda',
        'patientId': 'patient_3',
        'patientName': 'Dewi',
        'scheduleDate': todayDisplay,
        'dateIso': todayIso,
        'scheduleTime': '14.00 - 14.25',
        'timeStart': '14.00',
        'timeEnd': '14.25',
        'status': 'dikonfirmasi',
      });

      final count = await ConsultationService.rescheduleAllRemainingTodayToTomorrow(
        doctorUid: 'doc_2',
        doctorName: 'dr. Amanda',
      );

      expect(count, 2);

      final c2 = ConsultationService.getInMemoryConsultation('consult_2');
      final c3 = ConsultationService.getInMemoryConsultation('consult_3');
      expect(c2!['status'], 'menunggu_konfirmasi'); // Status konfirmasi awal tetap
      expect(c3!['status'], 'dikonfirmasi'); // Status konfirmasi awal tetap
      expect(c2['isRescheduled'], true);
      expect(c3['isRescheduled'], true);
    });
  });
}
