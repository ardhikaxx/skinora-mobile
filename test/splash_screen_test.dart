import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/pages/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen UI & Flow', () {
    testWidgets('menampilkan background maroon, logo, judul Skinora, dan tagline',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/login': (context) => const Scaffold(body: Text('Login Screen')),
          },
          home: const SplashScreen(
            displayDuration: Duration(milliseconds: 300),
          ),
        ),
      );

      // Verifikasi warna background maroon
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);
      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffold.backgroundColor, const Color(0xFFB23A48));

      // Verifikasi teks judul brand
      expect(find.text('Skinora'), findsOneWidget);

      // Verifikasi teks tagline
      expect(find.text('Glow up bersama Skinora'), findsOneWidget);

      // Verifikasi gambar logo
      expect(find.byType(Image), findsOneWidget);

      // Jalankan sisa animasi dan timer
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
    });

    testWidgets('berpindah ke /login bila pengguna belum login setelah durasi selesai',
        (tester) async {
      String? navigatedRoute;

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(
                  displayDuration: Duration(milliseconds: 100),
                ),
            '/login': (context) {
              navigatedRoute = '/login';
              return const Scaffold(body: Text('Halaman Login'));
            },
            '/pengguna': (context) {
              navigatedRoute = '/pengguna';
              return const Scaffold(body: Text('Halaman Pengguna'));
            },
          },
        ),
      );

      expect(find.text('Skinora'), findsOneWidget);
      expect(navigatedRoute, isNull);

      // Lewati durasi splash
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Terkonfirmasi navigasi ke /login
      expect(navigatedRoute, '/login');
      expect(find.text('Halaman Login'), findsOneWidget);
    });
  });
}
