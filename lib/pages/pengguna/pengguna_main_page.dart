import 'package:flutter/material.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
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

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      BerandaPenggunaPage(
        onNavigateTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      SkinCheckPage(
        onNavigateTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const SkinDailyPage(),
      const SkincarePage(),
      const ProfilPenggunaPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: PenggunaNavBottom(
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
