import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ManajemenPenggunaPage extends StatelessWidget {
  const ManajemenPenggunaPage({super.key});

  static const Color primaryColor = Color(0xFFB23A48);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Manajemen Pengguna Umum'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.userGroup, size: 56, color: primaryColor),
            SizedBox(height: 16),
            Text(
              'Manajemen Pengguna Umum',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kelola Data Pengguna',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
