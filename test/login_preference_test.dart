import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skinora_app/pages/auth/login_page.dart';
import 'package:skinora_app/services/login_preference_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('LoginPreferenceService', () {
    test('default aktif dan belum ada email tersimpan', () async {
      expect(await LoginPreferenceService.isRememberEnabled(), isTrue);
      expect(await LoginPreferenceService.rememberedEmail(), isEmpty);
    });

    test('remember menyimpan email yang dinormalisasi', () async {
      await LoginPreferenceService.remember('  Siti.Aminah@Example.COM ');
      expect(
        await LoginPreferenceService.rememberedEmail(),
        'siti.aminah@example.com',
      );
      expect(await LoginPreferenceService.isRememberEnabled(), isTrue);
    });

    test('forget menghapus email dan mematikan "Ingat saya"', () async {
      await LoginPreferenceService.remember('siti@example.com');
      await LoginPreferenceService.forget();
      expect(await LoginPreferenceService.rememberedEmail(), isEmpty);
      expect(await LoginPreferenceService.isRememberEnabled(), isFalse);
    });

    test('email tidak dipakai saat "Ingat saya" dimatikan', () async {
      await LoginPreferenceService.remember('siti@example.com');
      await LoginPreferenceService.setRememberEnabled(false);
      expect(await LoginPreferenceService.rememberedEmail(), isEmpty);
    });
  });

  group('LoginPage - Ingat saya', () {
    testWidgets('email akun terakhir otomatis terisi', (tester) async {
      await LoginPreferenceService.remember('siti.aminah@example.com');

      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      final emailField = tester.widget<TextField>(find.byType(TextField).first);
      expect(emailField.controller?.text, 'siti.aminah@example.com');
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });

    testWidgets('tanpa email tersimpan kolom tetap kosong', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      final emailField = tester.widget<TextField>(find.byType(TextField).first);
      expect(emailField.controller?.text, isEmpty);
    });

    testWidgets('mematikan "Ingat saya" menghapus email tersimpan',
        (tester) async {
      await LoginPreferenceService.remember('siti.aminah@example.com');

      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      expect(await LoginPreferenceService.rememberedEmail(), isEmpty);
      expect(await LoginPreferenceService.isRememberEnabled(), isFalse);
    });
  });
}
