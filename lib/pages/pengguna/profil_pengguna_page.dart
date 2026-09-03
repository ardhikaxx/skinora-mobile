import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfilPenggunaPage extends StatelessWidget {
  const ProfilPenggunaPage({super.key});

  static const Color primaryColor = Color(0xFFB23A48);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengguna - Profil'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.user, size: 56, color: primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Profil Pengguna',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Informasi Akun & Pengaturan Pengguna',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
              icon: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 16),
              label: const Text('Keluar / Ganti Role'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
