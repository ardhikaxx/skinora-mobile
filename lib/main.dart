import 'package:flutter/material.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/admin/admin_main_page.dart';
import 'pages/dokter/dokter_main_page.dart';
import 'pages/pengguna/pengguna_main_page.dart';

void main() {
  runApp(const SkinoraApp());
}

class SkinoraApp extends StatelessWidget {
  const SkinoraApp({super.key});

  static const Color brandColor = Color(0xFFB23A48);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skinora App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandColor,
          primary: brandColor,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFCFCFD),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF321417),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF321417),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/admin': (context) => const AdminMainPage(),
        '/dokter': (context) => const DokterMainPage(),
        '/pengguna': (context) => const PenggunaMainPage(),
      },
    );
  }
}
