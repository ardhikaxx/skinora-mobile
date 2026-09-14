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

  void _changeTab(int index) {
    if (index >= 0 && index < 5) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      BerandaDokterPage(onNavigateTab: _changeTab),
      JadwalDokterPage(onNavigateTab: _changeTab),
      ChatKonsultasiPage(onNavigateTab: _changeTab),
      RiwayatKonsultasiPage(onNavigateTab: _changeTab),
      ProfilDokterPage(onNavigateTab: _changeTab),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: DokterNavBottom(
        currentIndex: _currentIndex,
        onTap: _changeTab,
      ),
    );
  }
}
