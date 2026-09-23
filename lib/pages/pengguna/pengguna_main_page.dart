import 'package:flutter/material.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import 'beranda_page.dart';
import 'skin_check_page.dart';
import 'skin_daily_page.dart';
import 'skincare_page.dart';
import 'profil_pengguna_page.dart';

class PenggunaMainPage extends StatefulWidget {
  const PenggunaMainPage({super.key});

  @override
  State<PenggunaMainPage> createState() => _PenggunaMainPageState();
}

class _PenggunaMainPageState extends State<PenggunaMainPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _ensureSignedIn();
  }

  /// Guard: shell pengguna hanya boleh dibuka saat sesi Firebase Auth +
  /// role 'pengguna' (dilewati di widget test di mana Firebase tidak terinit).
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
      if (profile != null && profile.role != 'pengguna') {
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
      BerandaPenggunaPage(onNavigateTab: _changeTab),
      SkinCheckPage(onNavigateTab: _changeTab),
      SkinDailyPage(onNavigateTab: _changeTab),
      SkincarePage(onNavigateTab: _changeTab),
      ProfilPenggunaPage(onNavigateTab: _changeTab),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: PenggunaNavBottom(
        currentIndex: _currentIndex,
        onTap: _changeTab,
      ),
    );
  }
}
