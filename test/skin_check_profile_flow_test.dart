import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/models/user_profile.dart';
import 'package:skinora_app/pages/auth/register_page.dart';
import 'package:skinora_app/pages/pengguna/edit_profil_pengguna_page.dart';
import 'package:skinora_app/pages/pengguna/skin_check_page.dart';
import 'package:skinora_app/pages/pengguna/skin_check_question1_page.dart';
import 'package:skinora_app/pages/pengguna/skin_check_question2_page.dart';
import 'package:skinora_app/pages/pengguna/skin_check_question3_page.dart';
import 'package:skinora_app/pages/pengguna/skin_check_question4_page.dart';
import 'package:skinora_app/pages/pengguna/skin_check_question5_page.dart';
import 'package:skinora_app/pages/pengguna/skin_check_result_page.dart';
import 'package:skinora_app/services/skin_service.dart';
import 'package:skinora_app/services/user_service.dart';
import 'package:skinora_app/utils/app_dates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kalkulasi Usia Otomatis dari Tanggal Lahir (AppDates.calculateAge)', () {
    test('Menghitung usia dari format ISO yyyy-MM-dd dengan benar', () {
      final now = AppDates.nowWib();
      final birthYear = now.year - 24;
      final birthIso =
          '$birthYear-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final age = AppDates.calculateAge(birthIso);
      expect(age, 24);
    });

    test('Menyesuaikan jika ulang tahun belum lewat pada tahun berjalan', () {
      final now = AppDates.nowWib();
      final nextMonth = (now.month % 12) + 1;
      final birthYear = now.year - 20;
      final birthIso =
          '$birthYear-${nextMonth.toString().padLeft(2, '0')}-28';

      final age = AppDates.calculateAge(birthIso);
      if (now.month < nextMonth) {
        expect(age, 19);
      }
    });

    test('Mengembalikan 0 untuk string kosong, null, atau tidak valid', () {
      expect(AppDates.calculateAge(null), 0);
      expect(AppDates.calculateAge(''), 0);
      expect(AppDates.calculateAge('bukan-tanggal'), 0);
    });
  });

  group('Halaman Pendaftaran Pasien (RegisterPage) Tanggal Lahir & Jenis Kelamin', () {
    testWidgets('RegisterPage menampilkan field Tanggal Lahir dan Jenis Kelamin',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TANGGAL LAHIR'), findsOneWidget);
      expect(find.text('JENIS KELAMIN'), findsOneWidget);
      expect(find.text('Perempuan'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('Peringatan muncul jika tanggal lahir belum diisi',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Isi hanya nama, email, phone, password tapi tanggal lahir kosong
      await tester.enterText(
          find.widgetWithText(TextField, 'Nama Anda'), 'Budi Santoso');
      await tester.enterText(
          find.widgetWithText(TextField, 'contoh@email.com'), 'budi@mail.com');
      await tester.enterText(
          find.widgetWithText(TextField, '081234567890'), '081234567890');
      await tester.enterText(
          find.widgetWithText(TextField, 'Minimal 4 karakter'), 'pass123');

      final daftarBtn = find.text('Daftar');
      await tester.ensureVisible(daftarBtn);
      await tester.pumpAndSettle();
      await tester.tap(daftarBtn);
      await tester.pump();

      expect(find.textContaining('Silahkan lengkapi semua kolom pendaftaran'),
          findsOneWidget);
    });
  });

  group('Validasi Kelengkapan Profil & Modal Peringatan di SkinCheckPage', () {
    setUp(() {
      UserService.setMockCurrentProfile(null);
    });

    testWidgets(
        'Jika data pasien belum lengkap, modal template Data Profil Belum Lengkap muncul',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Pasien tanpa tanggal lahir & jenis kelamin
      UserService.setMockCurrentProfile(
        UserProfile(
          docId: 'patient_incomplete',
          name: 'Pasien Baru',
          birthDate: '',
          gender: '',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: SkinCheckPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan teks kuesioner kini 5 Pertanyaan
      expect(find.text('5 Pertanyaan'), findsOneWidget);

      // Tekan Mulai Skin Check
      final startBtn = find.text('Mulai Skin Check');
      await tester.ensureVisible(startBtn);
      await tester.pumpAndSettle();
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      // Modal template harus muncul
      expect(find.text('Data Profil Belum Lengkap'), findsOneWidget);
      expect(
        find.textContaining(
            'Untuk melakukan Skin Check, Anda perlu melengkapi data profil'),
        findsOneWidget,
      );
      expect(find.text('Nanti Saja'), findsOneWidget);
      expect(find.text('Lengkapi Profil'), findsOneWidget);
      final lengkapiText = tester.widget<Text>(find.text('Lengkapi Profil'));
      expect(lengkapiText.textAlign, TextAlign.center);
      expect(lengkapiText.maxLines, 1);

      // Tombol Nanti Saja menutup modal
      await tester.tap(find.text('Nanti Saja'));
      await tester.pumpAndSettle();
      expect(find.text('Data Profil Belum Lengkap'), findsNothing);
    });

    testWidgets(
        'Tombol Lengkapi Profil membuka EditProfilPenggunaPage',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      UserService.setMockCurrentProfile(
        UserProfile(
          docId: 'patient_incomplete',
          name: 'Pasien Belum Lengkap',
          birthDate: '',
          gender: '',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: SkinCheckPage(),
        ),
      );
      await tester.pumpAndSettle();

      final startBtn = find.text('Mulai Skin Check');
      await tester.ensureVisible(startBtn);
      await tester.pumpAndSettle();
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lengkapi Profil'));
      await tester.pumpAndSettle();

      // Harus berada di halaman Edit Profil
      expect(find.byType(EditProfilPenggunaPage), findsOneWidget);
      expect(find.text('Edit Profil'), findsOneWidget);
    });

    testWidgets(
        'Jika data pasien lengkap, langsung membuka Pertanyaan 1/5 dengan usia & gender otomatis',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = AppDates.nowWib();
      final birthYear = now.year - 25;
      final birthIso = '$birthYear-01-15';

      UserService.setMockCurrentProfile(
        UserProfile(
          docId: 'patient_complete',
          name: 'Siti Rahma',
          birthDate: birthIso,
          gender: 'Perempuan',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: SkinCheckPage(),
        ),
      );
      await tester.pumpAndSettle();

      final startBtn = find.text('Mulai Skin Check');
      await tester.ensureVisible(startBtn);
      await tester.pumpAndSettle();
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      // Langsung masuk ke pertanyaan 1/5 (tanpa tanya usia / gender)
      expect(find.byType(SkinCheckQuestion1Page), findsOneWidget);
      expect(find.text('PERTANYAAN 1/5'), findsOneWidget);
      expect(find.textContaining('Setelah mencuci wajah'), findsOneWidget);
    });
  });

  group('Alur Kuesioner 5 Pertanyaan Skin Check & Otomatisasi Data Pasien', () {
    testWidgets(
        'Navigasi 5 pertanyaan skin check berurutan dan penyimpanan hasil lengkap',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SkinCheckQuestion1Page(
            age: '25',
            gender: 'Perempuan',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Q1: Cuci Muka
      expect(find.text('PERTANYAAN 1/5'), findsOneWidget);
      await tester.tap(find.text('Terasa cukup nyaman'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selanjutnya'));
      await tester.pumpAndSettle();

      // Q2: Minyak
      expect(find.byType(SkinCheckQuestion2Page), findsOneWidget);
      expect(find.text('PERTANYAAN 2/5'), findsOneWidget);
      await tester
          .tap(find.text('Sedikit berminyak, terutama di area tertentu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selanjutnya'));
      await tester.pumpAndSettle();

      // Q3: Sensitivitas
      expect(find.byType(SkinCheckQuestion3Page), findsOneWidget);
      expect(find.text('PERTANYAAN 3/5'), findsOneWidget);
      await tester
          .tap(find.text('Kadang mengalami kemerahan atau iritasi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selanjutnya'));
      await tester.pumpAndSettle();

      // Q4: Kelembapan
      expect(find.byType(SkinCheckQuestion4Page), findsOneWidget);
      expect(find.text('PERTANYAAN 4/5'), findsOneWidget);
      await tester.enterText(
          find.widgetWithText(TextField, '74%'), '65%');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selanjutnya'));
      await tester.pumpAndSettle();

      // Q5: Suhu Cuaca
      expect(find.byType(SkinCheckQuestion5Page), findsOneWidget);
      expect(find.text('PERTANYAAN 5/5'), findsOneWidget);
      await tester.enterText(
          find.widgetWithText(TextField, '32°C'), '30°C');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Lihat Hasil'));
      await tester.pumpAndSettle();

      // Memastikan berhasil sampai di halaman Hasil
      expect(find.byType(SkinCheckResultPage), findsOneWidget);
      expect(find.text('Hasil'), findsOneWidget);

      // Verifikasi bahwa jawaban tersimpan di SkinService membawa age dan gender otomatis
      final history = await SkinService.listSkinChecks('demo_user');
      expect(history, isNotEmpty);
      expect(history.first['age'], '25');
      expect(history.first['gender'], 'Perempuan');
      expect(history.first['conditionAfterWash'], 'Terasa cukup nyaman');
      expect(history.first['temperature'], '30°C');
    });
  });
}
