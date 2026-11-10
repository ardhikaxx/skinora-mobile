import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skinora_app/pages/dokter/chat_konsultasi_page.dart';
import 'package:skinora_app/pages/pengguna/menunggu_konfirmasi_page.dart';
import 'package:skinora_app/pages/pengguna/profil_dokter_page.dart';
import 'package:skinora_app/services/consultation_service.dart';
import 'package:skinora_app/services/schedule_service.dart';
import 'package:skinora_app/utils/app_dates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Alur Booking Konsultasi Pasien Sebelum Jam Sesi Dimulai', () {
    testWidgets('Pasien dapat memilih slot konsultasi di jam 15.30 sebelum jam 15.30 dan muncul dialog konfirmasi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Siapkan tanggal yang belum lewat (misal besok atau format tanggal masa depan)
      final futureDate = AppDates.nowWib().add(const Duration(days: 1));
      final dateDisplay = AppDates.display(futureDate).toUpperCase();

      // Siapkan dokter dengan slot jam 15.30
      final doctor = DoctorProfileDetailModel(
        id: 'doc_1',
        name: 'dr. Sarah Sp.KK',
        specialization: 'Spesialis Kulit & Kelamin',
        experience: '5 Tahun',
        bio: 'Dokter spesialis kulit dan kelamin.',
        schedules: [
          DoctorScheduleModel(
            dayDate: dateDisplay,
            timeSlots: const ['15.30 - 16.00'],
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
            initialSlots: [
              SlotRecord(
                id: 'slot_1530',
                doctorId: 'doc_1',
                date: dateDisplay,
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

      // Muncul dialog menunggu konfirmasi dokter
      expect(find.text('Menunggu Konfirmasi Dokter...'), findsOneWidget);
      expect(find.text('Belum Waktunya Konsultasi'), findsNothing);

      // Tunggu delay navigasi dialog
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Pasien diarahkan ke halaman awal Menunggu Verifikasi Dokter dengan tombol kembali
      expect(find.text('Menunggu Verifikasi Dokter'), findsWidgets);
      expect(find.byIcon(LucideIcons.chevronLeft), findsOneWidget);

      // Pasien klik tombol kembali ke halaman profil dokter
      await tester.tap(find.byIcon(LucideIcons.chevronLeft));
      await tester.pumpAndSettle();

      // Kembali di profil dokter, slot yang dipilih sekarang berstatus "Menunggu Verifikasi"
      expect(find.text('Menunggu Verifikasi'), findsOneWidget);

      // Jika pasien mengeklik lagi slot yang sudah dipilih, TIDAK muncul dialog "Menunggu Konfirmasi Dokter..."
      // melainkan LANGSUNG diarahkan ke halaman menunggu verifikasi dokter
      await tester.tap(find.text('15.30 - 16.00'));
      await tester.pumpAndSettle();

      // Memastikan langsung di halaman Menunggu Verifikasi Dokter
      expect(find.text('Menunggu Verifikasi Dokter'), findsWidgets);
      expect(find.text('Menunggu Konfirmasi Dokter...'), findsNothing);
    });
  });

  group('Halaman Menunggu Verifikasi Pasien & Masuk Ruang Chat Setelah Diverifikasi', () {
    testWidgets('Tampil status menunggu verifikasi dan berubah jadi Mulai Konsultasi saat terverifikasi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final futureDate = AppDates.nowWib().add(const Duration(days: 1));
      final dateDisplay = AppDates.display(futureDate).toUpperCase();
      final dateIso = AppDates.iso(futureDate);

      await tester.pumpWidget(
        MaterialApp(
          home: MenungguKonfirmasiPage(
            doctorId: 'doc_1',
            doctorName: 'dr. Sarah Sp.KK',
            specialization: 'Spesialis Kulit',
            dateTime: '$dateDisplay • 15.30 WIB',
            scheduleDate: dateDisplay,
            scheduleTime: '15.30 - 16.00',
            dateIso: dateIso,
            timeStart: '15.30',
            timeEnd: '16.00',
            initialIsConfirmed: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi tampilan awal status Menunggu Verifikasi
      expect(find.text('Menunggu Verifikasi Dokter'), findsWidgets);
      expect(find.text('Menunggu Verifikasi'), findsOneWidget);
      expect(find.text('Mulai Konsultasi'), findsNothing);

      // Tampilkan dengan status sudah diverifikasi (initialIsConfirmed: true)
      await tester.pumpWidget(
        MaterialApp(
          home: MenungguKonfirmasiPage(
            doctorId: 'doc_1',
            doctorName: 'dr. Sarah Sp.KK',
            specialization: 'Spesialis Kulit',
            dateTime: '$dateDisplay • 15.30 WIB',
            scheduleDate: dateDisplay,
            scheduleTime: '15.30 - 16.00',
            dateIso: dateIso,
            timeStart: '15.30',
            timeEnd: '16.00',
            initialIsConfirmed: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tampil status Terverifikasi dan tombol Mulai Konsultasi
      expect(find.text('Jadwal Terverifikasi'), findsOneWidget);
      expect(find.text('Terverifikasi'), findsOneWidget);
      expect(find.text('Mulai Konsultasi'), findsOneWidget);
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

      // Status berubah menjadi "Terverifikasi" dan tombol berubah menjadi "Mulai Konsultasi"
      expect(find.text('Terverifikasi'), findsOneWidget);
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

  group('Validasi Jadwal Lewat Waktu & Jadwal Terkonfirmasi', () {
    testWidgets('Jadwal yang sudah lewat tanggal atau jamnya tidak dapat dipilih dan berstatus Selesai', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Siapkan tanggal yang sudah lampau (kemarin)
      final pastDate = AppDates.nowWib().subtract(const Duration(days: 2));
      final pastDateDisplay = AppDates.display(pastDate).toUpperCase();

      final doctor = DoctorProfileDetailModel(
        id: 'doc_past',
        name: 'dr. Budi Sp.KK',
        specialization: 'Spesialis Kulit',
        experience: '8 Tahun',
        bio: 'Dokter spesialis kulit.',
        schedules: [
          DoctorScheduleModel(
            dayDate: pastDateDisplay,
            timeSlots: const ['09.00 - 09.30'],
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
            initialSlots: [
              SlotRecord(
                id: 'slot_past_1',
                doctorId: 'doc_past',
                date: pastDateDisplay,
                time: '09.00 - 09.30',
                timeStart: '09.00',
                timeEnd: '09.30',
                quota: 1,
                bookedCount: 0,
                isBooked: false,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan slot yang lampau menampilkan badge Selesai
      expect(find.text('09.00 - 09.30'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

      // Tap slot yang lampau
      await tester.tap(find.text('09.00 - 09.30'));
      await tester.pump();

      // Menampilkan SnackBar peringatan bahwa jadwal sudah berakhir
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('sudah berakhir dan tidak dapat dipilih'), findsOneWidget);
    });

    testWidgets('Jadwal yang sudah dikonfirmasi dokter jika diklik lagi diarahkan ke MenungguKonfirmasiPage dengan tombol Mulai Konsultasi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final futureDate = AppDates.nowWib().add(const Duration(days: 1));
      final dateDisplay = AppDates.display(futureDate).toUpperCase();

      final doctor = DoctorProfileDetailModel(
        id: 'doc_confirmed',
        name: 'dr. Maya Sp.KK',
        specialization: 'Spesialis Kulit',
        experience: '4 Tahun',
        bio: 'Dokter spesialis kulit.',
        schedules: [
          DoctorScheduleModel(
            dayDate: dateDisplay,
            timeSlots: const ['14.00 - 14.30'],
          ),
        ],
      );

      final slot = SlotRecord(
        id: 'slot_conf_1',
        doctorId: 'doc_confirmed',
        date: dateDisplay,
        time: '14.00 - 14.30',
        timeStart: '14.00',
        timeEnd: '14.30',
        quota: 1,
        bookedCount: 1,
        isBooked: true,
        patientId: 'user_local',
      );

      // Simulasikan konsultasi sudah terdaftar dan terkonfirmasi
      ConsultationService.setInMemoryConsultation('slot_conf_1_user_local', {
        'id': 'slot_conf_1_user_local',
        'slotId': 'slot_conf_1',
        'doctorId': 'doc_confirmed',
        'doctorName': 'dr. Maya Sp.KK',
        'specialization': 'Spesialis Kulit',
        'patientId': 'user_local',
        'patientName': 'Pasien',
        'status': 'dikonfirmasi',
        'scheduleDate': dateDisplay,
        'scheduleTime': '14.00 - 14.30',
        'timeStart': '14.00',
        'timeEnd': '14.30',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilDokterPenggunaPage(
            doctorId: doctor.id,
            doctorName: doctor.name,
            specialization: doctor.specialization,
            initialDoctor: doctor,
            initialSlots: [slot],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Slot berstatus Terverifikasi
      expect(find.text('Terverifikasi'), findsOneWidget);

      // Pasien klik slot yang sudah terverifikasi tersebut
      await tester.tap(find.text('14.00 - 14.30'));
      await tester.pumpAndSettle();

      // Langsung diarahkan ke halaman MenungguKonfirmasiPage dengan tampilan Jadwal Terverifikasi dan tombol Mulai Konsultasi
      expect(find.text('Jadwal Terverifikasi'), findsOneWidget);
      expect(find.text('Mulai Konsultasi'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronLeft), findsOneWidget);
    });
  });

  group('Batas Waktu Menunggu Verifikasi (Auto-Cancel / Expired) & Pengembalian Kuota', () {
    testWidgets('MenungguKonfirmasiPage menampilkan status Jadwal Kedaluwarsa dan tombol Pilih Jadwal Lain jika melewati batas waktu', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Siapkan tanggal lampau
      final pastDate = AppDates.nowWib().subtract(const Duration(days: 1));
      final pastDateDisplay = AppDates.display(pastDate).toUpperCase();
      final dateIso = AppDates.iso(pastDate);

      ConsultationService.setInMemoryConsultation('c_expired_1', {
        'id': 'c_expired_1',
        'doctorId': 'doc_test',
        'doctorName': 'dr. Sarah Sp.KK',
        'patientId': 'user_local',
        'patientName': 'Pasien',
        'status': 'menunggu_konfirmasi',
        'scheduleDate': pastDateDisplay,
        'dateIso': dateIso,
        'timeStart': '10.00',
        'timeEnd': '10.30',
        'scheduleTime': '10.00 - 10.30',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MenungguKonfirmasiPage(
            consultationId: 'c_expired_1',
            doctorId: 'doc_test',
            doctorName: 'dr. Sarah Sp.KK',
            specialization: 'Spesialis Kulit',
            dateTime: '$pastDateDisplay • 10.00 WIB',
            scheduleDate: pastDateDisplay,
            scheduleTime: '10.00 - 10.30',
            dateIso: dateIso,
            timeStart: '10.00',
            timeEnd: '10.30',
            initialIsConfirmed: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan status berubah menjadi Kedaluwarsa dan ada tombol Pilih Jadwal Lain
      expect(find.text('Kedaluwarsa'), findsOneWidget);
      expect(find.text('Jadwal Kedaluwarsa'), findsOneWidget);
      expect(find.text('Pilih Jadwal Lain'), findsOneWidget);
      expect(find.textContaining('Kuota konsultasi Anda hari ini telah dikembalikan'), findsOneWidget);
    });

    test('hasConsultationOnDate mengembalikan false dan mengembalikan kuota harian jika jadwal menunggu verifikasi telah kedaluwarsa', () async {
      final pastDate = AppDates.nowWib().subtract(const Duration(days: 1));
      final pastDateDisplay = AppDates.display(pastDate).toUpperCase();
      final dateIso = AppDates.iso(pastDate);

      ConsultationService.setInMemoryConsultation('c_expired_limit', {
        'id': 'c_expired_limit',
        'doctorId': 'doc_1',
        'patientId': 'patient_test_quota',
        'status': 'menunggu_konfirmasi',
        'scheduleDate': pastDateDisplay,
        'dateIso': dateIso,
        'timeStart': '08.00',
        'timeEnd': '08.30',
        'scheduleTime': '08.00 - 08.30',
      });

      final hasLimit = await ConsultationService.hasConsultationOnDate(
        patientUid: 'patient_test_quota',
        dateIso: dateIso,
        scheduleDate: pastDateDisplay,
      );

      // Kuota harian dikembalikan (hasLimit bernilai false sehingga pasien bebas memilih jadwal baru)
      expect(hasLimit, isFalse);
    });

    test('Skenario spesifik: slot 09.00 - 09.15 jika telah lewat jam konsultasi otomatis kedaluwarsa dan kuota harian dikembalikan', () async {
      // Skenario hari ini namun jam konsultasi sudah lewat (misal slot 09.00 - 09.15 di waktu lampau)
      final pastDate = AppDates.nowWib().subtract(const Duration(days: 1));
      final pastDateDisplay = AppDates.display(pastDate).toUpperCase();
      final dateIso = AppDates.iso(pastDate);

      ConsultationService.setInMemoryConsultation('c_slot_0915', {
        'id': 'c_slot_0915',
        'doctorId': 'doc_spesifik',
        'patientId': 'patient_0915',
        'status': 'menunggu_konfirmasi',
        'scheduleDate': pastDateDisplay,
        'dateIso': dateIso,
        'timeStart': '09.00',
        'timeEnd': '09.15',
        'scheduleTime': '09.00 - 09.15',
      });

      // Pengecekan hasConsultationOnDate mendeteksi bahwa slot 09.00-09.15 telah lewat jamnya
      final hasLimit = await ConsultationService.hasConsultationOnDate(
        patientUid: 'patient_0915',
        dateIso: dateIso,
        scheduleDate: pastDateDisplay,
      );

      expect(hasLimit, isFalse);

      // Status konsultasi otomatis berubah menjadi dibatalkan
      final doc = ConsultationService.getInMemoryConsultation('c_slot_0915');
      expect(doc?['status'], equals('dibatalkan'));
      expect(doc?['cancelReason'], contains('tanpa konfirmasi dokter'));
    });
  });

  group('Validasi Jam Konsultasi: Tombol Mulai Konsultasi Nonaktif (Abu-abu / Disable) Sebelum Jam Sesi Tiba', () {
    testWidgets('Role Dokter: Tombol Mulai Konsultasi disable (abu-abu) jika sudah diverifikasi tapi belum waktunya', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final futureDate = AppDates.nowWib().add(const Duration(days: 1));
      final futureDateIso = AppDates.iso(futureDate);
      final futureDateDisplay = AppDates.display(futureDate).toUpperCase();

      await tester.pumpWidget(
        MaterialApp(
          home: ChatKonsultasiPage(
            showBottomNav: false,
            initialConsultations: [
              ConsultationItemModel(
                id: 'c_doc_upcoming',
                patientName: 'Pasien Masa Depan',
                dateTime: '$futureDateDisplay • 15:30 - 16:00',
                status: 'Terjadwal',
                dateIso: futureDateIso,
                scheduleDate: futureDateDisplay,
                timeStart: '15.30',
                timeEnd: '16.00',
                scheduleTime: '15.30 - 16.00',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cari tombol Mulai Konsultasi
      final btnFinder = find.widgetWithText(ElevatedButton, 'Mulai Konsultasi');
      expect(btnFinder, findsOneWidget);

      final button = tester.widget<ElevatedButton>(btnFinder);
      // Tombol harus disabled (onPressed null)
      expect(button.onPressed, isNull);

      // Keterangan menunggu jadwal konsultasi tampil
      expect(find.text('Menunggu jam jadwal konsultasi untuk memulai'), findsOneWidget);

      // Dicoba tap tidak bereaksi dan tidak pindah ke ruang chat
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();
      expect(find.text('Selesaikan Konsultasi?'), findsNothing);
    });

    testWidgets('Role Pasien: Tombol Mulai Konsultasi disable (abu-abu) di MenungguKonfirmasiPage jika sudah diverifikasi tapi belum jamnya', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final futureDate = AppDates.nowWib().add(const Duration(days: 1));
      final futureDateIso = AppDates.iso(futureDate);
      final futureDateDisplay = AppDates.display(futureDate).toUpperCase();

      ConsultationService.setInMemoryConsultation('c_patient_upcoming', {
        'id': 'c_patient_upcoming',
        'doctorId': 'doc_1',
        'doctorName': 'dr. Sarah Sp.KK',
        'patientId': 'patient_local',
        'patientName': 'Pasien Uji',
        'status': 'terjadwal',
        'scheduleDate': futureDateDisplay,
        'dateIso': futureDateIso,
        'timeStart': '15.30',
        'timeEnd': '16.00',
        'scheduleTime': '15.30 - 16.00',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MenungguKonfirmasiPage(
            consultationId: 'c_patient_upcoming',
            doctorId: 'doc_1',
            doctorName: 'dr. Sarah Sp.KK',
            specialization: 'Spesialis Kulit',
            dateTime: '$futureDateDisplay • 15.30 - 16.00 WIB',
            scheduleDate: futureDateDisplay,
            scheduleTime: '15.30 - 16.00',
            dateIso: futureDateIso,
            timeStart: '15.30',
            timeEnd: '16.00',
            status: 'terjadwal',
            initialIsConfirmed: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan status Jadwal Terverifikasi
      expect(find.text('Jadwal Terverifikasi'), findsOneWidget);

      // Cari tombol Mulai Konsultasi
      final btnFinder = find.widgetWithText(ElevatedButton, 'Mulai Konsultasi');
      expect(btnFinder, findsOneWidget);

      final button = tester.widget<ElevatedButton>(btnFinder);
      // Tombol harus disabled (onPressed null)
      expect(button.onPressed, isNull);

      // Menampilkan petunjuk tombol akan aktif saat jam jadwal dimulai
      expect(find.text('Tombol akan aktif otomatis saat jam jadwal konsultasi dimulai'), findsOneWidget);
    });

    testWidgets('Role Pasien: Tombol Mulai Konsultasi aktif jika jadwal sudah tiba', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Buat tanggal lampau beberapa jam yang lalu hari ini atau kemarin
      final pastDate = AppDates.nowWib().subtract(const Duration(hours: 1));
      final pastDateIso = AppDates.iso(pastDate);
      final pastDateDisplay = AppDates.display(pastDate).toUpperCase();

      ConsultationService.setInMemoryConsultation('c_patient_active', {
        'id': 'c_patient_active',
        'doctorId': 'doc_1',
        'doctorName': 'dr. Sarah Sp.KK',
        'patientId': 'patient_local',
        'patientName': 'Pasien Uji',
        'status': 'terjadwal',
        'scheduleDate': pastDateDisplay,
        'dateIso': pastDateIso,
        'timeStart': '08.00',
        'timeEnd': '08.30',
        'scheduleTime': '08.00 - 08.30',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MenungguKonfirmasiPage(
            consultationId: 'c_patient_active',
            doctorId: 'doc_1',
            doctorName: 'dr. Sarah Sp.KK',
            specialization: 'Spesialis Kulit',
            dateTime: '$pastDateDisplay • 08.00 - 08.30 WIB',
            scheduleDate: pastDateDisplay,
            scheduleTime: '08.00 - 08.30',
            dateIso: pastDateIso,
            timeStart: '08.00',
            timeEnd: '08.30',
            status: 'terjadwal',
            initialIsConfirmed: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final btnFinder = find.widgetWithText(ElevatedButton, 'Mulai Konsultasi');
      expect(btnFinder, findsOneWidget);

      final button = tester.widget<ElevatedButton>(btnFinder);
      // Tombol aktif karena waktu sudah tiba
      expect(button.onPressed, isNotNull);
    });
  });
}
