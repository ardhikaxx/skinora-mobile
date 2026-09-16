import 'package:flutter/material.dart';
import '../../components/navbottom/admin_navbottom.dart';
import 'beranda_page.dart';
import 'manajemen_dokter_page.dart';
import 'manajemen_pengguna_page.dart';
import 'manajemen_edukasi_page.dart';
import 'profil_admin_page.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
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
      BerandaAdminPage(onNavigateTab: _changeTab),
      const ManajemenDokterPage(),
      const ManajemenPenggunaPage(),
      const ManajemenEdukasiPage(),
      ProfilAdminPage(onNavigateTab: _changeTab),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: AdminNavBottom(
        currentIndex: _currentIndex,
        onTap: _changeTab,
      ),
    );
  }
}
