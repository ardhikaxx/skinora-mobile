import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/pages/auth/forgot_password_page.dart';
import 'package:skinora_app/pages/auth/login_page.dart';
import 'package:skinora_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForgotPasswordPage UI & Validation', () {
    testWidgets('menampilkan halaman Lupa Kata Sandi dengan elemen lengkap',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordPage(initialEmail: 'user@example.com'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      expect(find.text('Kembali ke Masuk'), findsOneWidget);
      expect(find.text('EMAIL AKUN'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.text('Kirim Email Reset'), findsOneWidget);
    });

    testWidgets('validasi: memunculkan pesan error saat email kosong',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordPage(initialEmail: ''),
        ),
      );
      await tester.pumpAndSettle();

      // Tap tombol Kirim Email Reset saat email kosong
      await tester.tap(find.text('Kirim Email Reset'));
      await tester.pumpAndSettle();

      expect(find.text('Alamat email wajib diisi.'), findsOneWidget);
    });

    testWidgets('validasi: memunculkan pesan error saat format email tidak valid',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordPage(initialEmail: 'email_tanpa_domain'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kirim Email Reset'));
      await tester.pumpAndSettle();

      expect(
        find.text('Format email tidak valid. Contoh: nama@domain.com'),
        findsOneWidget,
      );
    });

    testWidgets('menekan tombol Kembali kembali ke halaman sebelumnya',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordPage(),
                  ),
                ),
                child: const Text('Buka Halaman'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buka halaman
      await tester.tap(find.text('Buka Halaman'));
      await tester.pumpAndSettle();

      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);

      // Tekan tombol kembali (arrow left)
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();

      expect(find.text('Lupa Kata Sandi?'), findsNothing);
      expect(find.text('Buka Halaman'), findsOneWidget);
    });
  });

  group('LoginPage - Lupa Password Flow', () {
    testWidgets('menekan Lupa password? di LoginPage membuka ForgotPasswordPage',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      expect(find.text('Lupa password?'), findsOneWidget);

      // Klik link "Lupa password?"
      await tester.tap(find.text('Lupa password?'));
      await tester.pumpAndSettle();

      // Halaman baru ForgotPasswordPage harus terbuka
      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      expect(find.text('Kirim Email Reset'), findsOneWidget);
      expect(find.text('Kembali ke Masuk'), findsOneWidget);
    });

    testWidgets('email yang diketik di LoginPage otomatis diteruskan ke ForgotPasswordPage',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      // Ketik email di LoginPage
      await tester.enterText(
        find.byType(TextField).first,
        'pengguna@skinora.com',
      );
      await tester.pumpAndSettle();

      // Klik link "Lupa password?"
      await tester.tap(find.text('Lupa password?'));
      await tester.pumpAndSettle();

      // ForgotPasswordPage terbuka dengan email terisi
      expect(find.text('pengguna@skinora.com'), findsOneWidget);
    });
  });

  group('AuthService describePasswordResetError', () {
    test('mengonversi berbagai kode error ke bahasa Indonesia yang ramah', () {
      expect(
        AuthService.describePasswordResetError(
          FirebaseAuthException(code: 'invalid-email'),
        ),
        'Format alamat email tidak valid.',
      );

      expect(
        AuthService.describePasswordResetError(
          FirebaseAuthException(code: 'user-not-found'),
        ),
        'Akun dengan email ini tidak ditemukan.',
      );

      expect(
        AuthService.describePasswordResetError(
          FirebaseAuthException(code: 'too-many-requests'),
        ),
        'Terlalu banyak permintaan reset kata sandi. Silakan tunggu beberapa saat.',
      );

      expect(
        AuthService.describePasswordResetError(
          FirebaseAuthException(code: 'network-request-failed'),
        ),
        'Koneksi gagal. Periksa jaringan internet Anda.',
      );

      expect(
        AuthService.describePasswordResetError(
          FirebaseAuthException(code: 'missing-email'),
        ),
        'Silakan masukkan alamat email Anda.',
      );

      expect(
        AuthService.describePasswordResetError(
          const FormatException('Firebase Auth belum aktif.'),
        ),
        'Firebase Auth belum aktif.',
      );
    });
  });
}
