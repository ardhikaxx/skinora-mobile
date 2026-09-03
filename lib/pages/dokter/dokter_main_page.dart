import 'package:flutter/material.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import 'beranda_page.dart';
import 'jadwal_page.dart';
import 'chat_konsultasi_page.dart';
import 'riwayat_konsultasi_page.dart';
import 'profil_dokter_page.dart';

class DokterMainPage extends StatefulWidget {
  const DokterMainPage({super.key});

  @override
  State<DokterMainPage> createState() => _DokterMainPageState();
}

class _DokterMainPageState extends State<DokterMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    BerandaDokterPage(),
    JadwalDokterPage(),
    ChatKonsultasiPage(),
    RiwayatKonsultasiPage(),
    ProfilDokterPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: DokterNavBottom(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
