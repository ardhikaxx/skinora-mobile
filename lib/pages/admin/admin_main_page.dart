import 'package:flutter/material.dart';
import '../../components/navbottom/admin_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
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

  @override
  void initState() {
    super.initState();
    _ensureSignedIn();
  }

  /// Guard: shell admin hanya boleh dibuka saat sesi Firebase Auth + role
  /// 'admin' (dilewati di widget test di mana Firebase tidak terinit).
  Future<void> _ensureSignedIn() async {
    if (!Backend.useFirebase) return;
    if (AuthService.uid == null) {
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }
    try {
      final profile = await AuthService.loadProfile();
      if (!mounted) return;
      if (profile != null && profile.role != 'admin') {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (_) {
      // role gagal dibaca → tetap biarkan shell (jangan redirect salah)
    }
  }

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
      ManajemenDokterPage(onNavigateTab: _changeTab),
      ManajemenPenggunaPage(onNavigateTab: _changeTab),
      ManajemenEdukasiPage(onNavigateTab: _changeTab),
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
