import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class JadwalDokterPage extends StatelessWidget {
  const JadwalDokterPage({super.key});

  static const Color primaryColor = Color(0xFFB23A48);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokter - Jadwal'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.calendarCheck, size: 56, color: primaryColor),
            SizedBox(height: 16),
            Text(
              'Jadwal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Jadwal Praktik & Konsultasi Dokter',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
