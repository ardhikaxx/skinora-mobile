import 'package:flutter/material.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
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

  // Epoch per tab: naik saat tab aktif dipilih ulang → ValueKey berubah →
  // child remount → initState/stream jalan ulang (refresh data Firestore).
  final List<int> _tabEpoch = List<int>.filled(5, 0);

  @override
  void initState() {
    super.initState();
    _ensureSignedIn();
  }

  /// Guard: shell dokter hanya boleh dibuka saat sesi Firebase Auth + role
  /// 'dokter' (dilewati di widget test di mana Firebase tidak terinit).
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
      if (profile != null && profile.role != 'dokter') {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (_) {
      // role gagal dibaca → tetap biarkan shell (jangan redirect salah)
    }
  }

  void _changeTab(int index) {
    if (index < 0 || index >= 5) return;
    final sameTab = index == _currentIndex;
    setState(() {
      _currentIndex = index;
      if (sameTab) {
        _tabEpoch[index] += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ValueKey per generasi remount: setiap kali tab aktif dipilih ulang,
    // generasi naik sehingga IndexedStack rebuild child → initState jalan
    // ulang dan stream/daftar di-refresh dari Firestore.
    final pages = [
      BerandaDokterPage(
        key: ValueKey('beranda${_tabEpoch[0]}'),
        onNavigateTab: _changeTab,
      ),
      JadwalDokterPage(
        key: ValueKey('jadwal${_tabEpoch[1]}'),
        onNavigateTab: _changeTab,
      ),
      ChatKonsultasiPage(
        key: ValueKey('chat${_tabEpoch[2]}'),
        onNavigateTab: _changeTab,
      ),
      RiwayatKonsultasiPage(
        key: ValueKey('riwayat${_tabEpoch[3]}'),
        onNavigateTab: _changeTab,
      ),
      ProfilDokterPage(
        key: ValueKey('profil${_tabEpoch[4]}'),
        onNavigateTab: _changeTab,
      ),
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
