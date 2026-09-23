import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/notification_service.dart';
import '../../services/user_service.dart';
import 'notifikasi_pengguna_page.dart';
import 'konsultasi_dokter_page.dart';
import 'edukasi_kulit_page.dart';

class BerandaPenggunaPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const BerandaPenggunaPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<BerandaPenggunaPage> createState() => _BerandaPenggunaPageState();
}

class _BerandaPenggunaPageState extends State<BerandaPenggunaPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF757575);
  static const Color peachCardBg = Color(0xFFFFD5C3);

  String _userName = 'Leonita Yulyta Agustin';
  int _unreadNotif = 2;

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  /// Profil + unread notifikasi dari Firestore. Tanpa Firebase, seed demo
  /// tetap dipakai agar UI/tes tidak berubah.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final results = await Future.wait<Object?>([
        UserService.loadByUid(uid),
        NotificationService.countUnread(NotificationService.userAudience(uid)),
      ]);
      final profile = results[0] as dynamic;
      final unread = results[1] as int?;
      if (!mounted) return;
      setState(() {
        final name = (profile?.name as String?) ?? '';
        if (name.isNotEmpty) _userName = name;
        if (unread != null) _unreadNotif = unread;
      });
    } catch (_) {
      // dashboard tetap menampilkan data demo bila query gagal
    }
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'L';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            // 1. Header Profile & Notification Bell
            _buildHeader(),
            const SizedBox(height: 20),

            // 2. Ringkasan Hari Ini Card
            _buildRingkasanHariIniCard(),
            const SizedBox(height: 20),

            // 3. Menu Cepat Card
            _buildMenuCepatCard(),
            const SizedBox(height: 20),

            // 4. Tips Hari Ini Card
            _buildTipsHariIniCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 1. Top Header: Avatar, Greeting, User Name, and Notification Bell
  Widget _buildHeader() {
    return Row(
      children: [
        // Avatar Initial (dynamic)
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: primaryMaroon,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryMaroon.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _initials(_userName),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Greeting & Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat pagi,',
                style: TextStyle(
                  fontSize: 13.0,
                  color: subText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),

        // Notification Bell Icon with Badge "2"
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotifikasiPenggunaPage(
                  onNavigateTab: widget.onNavigateTab,
                ),
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEEEEEE),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.bell,
                    size: 20,
                    color: darkText,
                  ),
                ),
              ),
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: primaryMaroon,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$_unreadNotif',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 2. Ringkasan Hari Ini Section (Peach Card containing 4 White Cards)
  Widget _buildRingkasanHariIniCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: peachCardBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RINGKASAN HARI INI',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: darkText,
            ),
          ),
          const SizedBox(height: 14),

          // Row 1: Skin Check & Skin Daily
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: LucideIcons.stethoscope,
                  title: 'Skin Check',
                  value: 'Kombinasi',
                  subtitle: '2026-08-28',
                  onTap: () => widget.onNavigateTab?.call(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  icon: LucideIcons.bookOpen,
                  title: 'Skin Daily',
                  value: 'Terisi',
                  subtitle: 'Baik',
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Skincare & Chat
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: LucideIcons.droplets,
                  title: 'Skincare',
                  value: 'Tercatat',
                  subtitle: '5 produk',
                  onTap: () => widget.onNavigateTab?.call(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  icon: LucideIcons.messageSquare,
                  title: 'Chat',
                  value: 'Jadwal',
                  subtitle: '2026-08-28',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KonsultasiDokterPenggunaPage(
                          onNavigateTab: widget.onNavigateTab,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: primaryMaroon,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.0,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Menu Cepat Card (White Card with 4-Column Grid)
  Widget _buildMenuCepatCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MENU CEPAT',
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: darkText,
            ),
          ),
          const SizedBox(height: 18),

          // Row 1: Skin Check, Skin Daily, Skincare, Konsultasi Dokter
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.stethoscope,
                  label: 'Skin Check',
                  onTap: () => widget.onNavigateTab?.call(1),
                ),
              ),
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.bookOpen,
                  label: 'Skin Daily',
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
              ),
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.droplets,
                  label: 'Skincare',
                  onTap: () => widget.onNavigateTab?.call(3),
                ),
              ),
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.messageSquare,
                  label: 'Konsultasi\nDokter',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KonsultasiDokterPenggunaPage(
                          onNavigateTab: widget.onNavigateTab,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Edukasi, Profil, and 2 empty placeholders for alignment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.bookMarked,
                  label: 'Edukasi',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EdukasiKulitPenggunaPage(
                          onNavigateTab: widget.onNavigateTab,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.user,
                  label: 'Profil',
                  onTap: () => widget.onNavigateTab?.call(4),
                ),
              ),
              const Expanded(child: SizedBox()),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMenuItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primaryMaroon,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryMaroon.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                color: darkText,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Tips Hari Ini Card (Maroon Banner with Droplet Icon & Advice)
  Widget _buildTipsHariIniCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: primaryMaroon,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryMaroon.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.droplets,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tips Hari Ini',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Minum air putih minimal 8 gelas sehari untuk menjaga kelembapan kulit Anda.',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
