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

  final List<Widget> _pages = const [
    BerandaAdminPage(),
    ManajemenDokterPage(),
    ManajemenPenggunaPage(),
    ManajemenEdukasiPage(),
    ProfilAdminPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AdminNavBottom(
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
