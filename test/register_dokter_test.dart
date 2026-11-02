import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/pages/auth/login_page.dart';
import 'package:skinora_app/pages/auth/register_dokter_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Registrasi Dokter (Opsi 2)', () {
    testWidgets('LoginPage menampilkan banner "Bergabung Sebagai Dokter Skinora"',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Cek teks card dokter
      expect(find.text('Bergabung Sebagai Dokter Skinora'), findsOneWidget);
      expect(
        find.text('Buka konsultasi online & bantu pasien kulit'),
        findsOneWidget,
      );
    });

    testWidgets('Tap banner dokter di LoginPage menavigasi ke RegisterDokterPage',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      final bannerFinder = find.text('Bergabung Sebagai Dokter Skinora');
      await tester.ensureVisible(bannerFinder);
      await tester.tap(bannerFinder);
      await tester.pumpAndSettle();

      // Memastikan berada di RegisterDokterPage
      expect(find.byType(RegisterDokterPage), findsOneWidget);
      expect(find.text('Pendaftaran Dokter'), findsOneWidget);
    });

    testWidgets('RegisterDokterPage menampilkan semua field form & info verifikasi',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterDokterPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Header & info verifikasi
      expect(find.text('Pendaftaran Dokter'), findsOneWidget);
      expect(find.text('Verifikasi Medis Skinora'), findsOneWidget);

      // Label fields
      expect(find.text('NAMA LENGKAP & GELAR *'), findsOneWidget);
      expect(find.text('SPESIALISASI *'), findsOneWidget);
      expect(find.text('NOMOR STR (SURAT TANDA REGISTRASI) *'), findsOneWidget);
      expect(find.text('PENGALAMAN PRAKTIK *'), findsOneWidget);
      expect(find.text('NOMOR TELEPON / WHATSAPP *'), findsOneWidget);
      expect(find.text('ALAMAT / TEMPAT PRAKTIK *'), findsOneWidget);
      expect(find.text('BIO SINGKAT (OPSIONAL)'), findsOneWidget);
      expect(find.text('EMAIL *'), findsOneWidget);
      expect(find.text('PASSWORD *'), findsOneWidget);

      // Tombol submit
      expect(find.text('Daftar Sebagai Dokter'), findsOneWidget);
    });

    testWidgets('Validasi form: field kosong menampilkan SnackBar peringatan',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterDokterPage(),
        ),
      );
      await tester.pumpAndSettle();

      final submitBtn = find.text('Daftar Sebagai Dokter');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      expect(
        find.text('Silahkan masukkan nama lengkap dan gelar dokter.'),
        findsOneWidget,
      );
    });

    testWidgets('Validasi form: nomor telepon minimal 8 digit',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterDokterPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Isi nama, str, pengalaman
      await tester.enterText(
        find.widgetWithText(TextField, 'dr. Sarah Wijaya, Sp.D.V.E.'),
        'dr. Sarah Wijaya',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Contoh: 31.1.1.100.1.20.123456'),
        'STR-12345678',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Contoh: 5 Tahun'),
        '4 Tahun',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '081234567890'),
        '123', // < 8 digit
      );

      final submitBtn = find.text('Daftar Sebagai Dokter');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      expect(find.text('Nomor telepon minimal 8 digit.'), findsOneWidget);
    });

    testWidgets('Validasi form: password minimal 6 karakter',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterDokterPage(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'dr. Sarah Wijaya, Sp.D.V.E.'),
        'dr. Sarah Wijaya',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Contoh: 31.1.1.100.1.20.123456'),
        'STR-12345678',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Contoh: 5 Tahun'),
        '4 Tahun',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '081234567890'),
        '081234567890',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'RS Hermina / Klinik Skinora Jakarta'),
        'Klinik Utama Skinora',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'dokter@skinora.com'),
        'dokter@skinora.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Minimal 6 karakter'),
        '123', // < 6 karakter
      );

      final submitBtn = find.text('Daftar Sebagai Dokter');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      expect(find.text('Password minimal 6 karakter.'), findsOneWidget);
    });
  });
}
