import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../components/dialogs/logout_dialog.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/consultation_service.dart';
import '../../services/user_service.dart';
import 'edit_profil_admin_page.dart';
import 'laporan_riwayat_page.dart';
import 'pengaturan_admin_page.dart';
import 'riwayat_aktivitas_admin_page.dart';
import 'tentang_admin_page.dart';

class ProfilAdminPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const ProfilAdminPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<ProfilAdminPage> createState() => _ProfilAdminPageState();
}

class _ProfilAdminPageState extends State<ProfilAdminPage> {
  // Brand color palette matching design
  static const Color primaryMaroon = Color(0xFF9E2A3B);
  static const Color darkText = Color(0xFF1E1E1E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color labelText = Color(0xFF8E8E93);
  static const Color badgeBg = Color(0xFFFFD5C8);

  // Profile data — seed demo HANYA tanpa Firebase. Dengan Firebase, default
  // placeholder kosong ('' / '-') hingga data asli dimuat dari Firestore.
  String _nama = Backend.useFirebase ? '' : 'Admin Skinora';
  String _email = Backend.useFirebase ? '' : 'admin@demo.com';
  String _telepon = Backend.useFirebase ? '-' : '081234567899';
  String _alamat = Backend.useFirebase ? '-' : 'Jl. Teknologi No. 1, Jakarta';
  String _tanggalLahir = Backend.useFirebase ? '-' : '1985-01-01';

  // Ringkasan platform — seed demo HANYA tanpa Firebase.
  String _statPengguna = Backend.useFirebase ? '0' : '5';
  String _statDokter = Backend.useFirebase ? '0' : '4';
  String _statKonsultasi = Backend.useFirebase ? '0' : '13';

  // Helper to extract initials (e.g., Admin Skinora -> AS)
  String get _initials {
    final parts = _nama.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'A';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  String _pick(Object? v, String fallback) {
    final s = (v as String?) ?? '';
    return s.isEmpty ? fallback : s;
  }

  /// Muat profile admin + statistik ringkasan. Tanpa Firebase (test), seed
  /// demo tetap dipakai. Dengan Firebase, hasil backend selalu menggantikan
  /// seed — termasuk saat kosong — agar UI sinkron dengan data asli.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    try {
      final results = await Future.wait<Object?>([
        AuthService.loadProfile(),
        UserService.countPengguna(),
        UserService.countDokterAktif(),
        ConsultationService.countAll(),
      ]);
      final profile = results[0] as dynamic;
      final pengguna = results[1] as int?;
      final dokter = results[2] as int?;
      final konsultasi = results[3] as int?;
      if (!mounted) return;
      setState(() {
        if (profile != null) {
          _nama = _pick(profile.name, '');
          _email = _pick(profile.email, '');
          _telepon = _pick(profile.phone, '-');
          _alamat = _pick(profile.address, '-');
          _tanggalLahir = _pick(profile.birthDate, '-');
        }
        if (pengguna != null) _statPengguna = '$pengguna';
        if (dokter != null) _statDokter = '$dokter';
        if (konsultasi != null) _statKonsultasi = '$konsultasi';
      });
    } catch (_) {
      // Query gagal → reset placeholder, jangan nilai demo di production.
      if (!mounted) return;
      setState(() {
        _nama = '';
        _email = '';
        _telepon = '-';
        _alamat = '-';
        _tanggalLahir = '-';
        _statPengguna = '0';
        _statDokter = '0';
        _statKonsultasi = '0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "Profil Admin"
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 18.0,
                bottom: 12.0,
              ),
              child: const Text(
                'Profil Admin',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            // Subtle divider line
            Container(
              height: 1,
              color: const Color(0xFFEEEEEE),
              margin: const EdgeInsets.only(bottom: 16.0),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 1. Admin Info Card (Avatar "AS", Name, Email, "Administrator" badge, "Edit" button)
                  _buildAdminInfoCard(),
                  const SizedBox(height: 16),

                  // 2. Ringkasan Platform Section (Maroon Card with 3 stats)
                  _buildRingkasanPlatformSection(),
                  const SizedBox(height: 16),

                  // 3. Informasi Section (Telepon, Alamat, Tanggal Lahir)
                  _buildInformasiSection(),
                  const SizedBox(height: 16),

                  // 4. Action Menu Card (Pengaturan, Tentang Aplikasi, Riwayat Aktivitas, Logout)
                  _buildActionMenuCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Admin Info Card
  Widget _buildAdminInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
      child: Row(
        children: [
          // Avatar rounded square with initials
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primaryMaroon,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryMaroon.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Admin details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nama,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _email,
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: subText,
                  ),
                ),
                const SizedBox(height: 8),
                // Administrator Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Administrator',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      color: primaryMaroon,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Edit text button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _navigateToEditProfile,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: primaryMaroon,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Ringkasan Platform Section (Maroon container with 3 stats)
  Widget _buildRingkasanPlatformSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: primaryMaroon,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryMaroon.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RINGKASAN PLATFORM',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // 1. Pengguna (5)
              Expanded(
                child: _buildPlatformStatCard(
                  icon: LucideIcons.users,
                  count: _statPengguna,
                  label: 'Pengguna',
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Dokter (4)
              Expanded(
                child: _buildPlatformStatCard(
                  icon: LucideIcons.stethoscope,
                  count: _statDokter,
                  label: 'Dokter',
                  onTap: () => widget.onNavigateTab?.call(1),
                ),
              ),
              const SizedBox(width: 10),

              // 3. Konsultasi (13)
              Expanded(
                child: _buildPlatformStatCard(
                  icon: LucideIcons.barChart2,
                  count: _statKonsultasi,
                  label: 'Konsultasi',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LaporanRiwayatPage(
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

  Widget _buildPlatformStatCard({
    required IconData icon,
    required String count,
    required String label,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(height: 8),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. Informasi Section (Telepon, Alamat, Tanggal Lahir)
  Widget _buildInformasiSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            'INFORMASI',
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 18),

          // Telepon
          _buildInfoRow(
            icon: LucideIcons.phone,
            label: 'TELEPON',
            value: _telepon,
          ),
          const SizedBox(height: 18),

          // Alamat
          _buildInfoRow(
            icon: LucideIcons.mapPin,
            label: 'ALAMAT',
            value: _alamat,
          ),
          const SizedBox(height: 18),

          // Tanggal Lahir
          _buildInfoRow(
            icon: LucideIcons.calendar,
            label: 'TANGGAL LAHIR',
            value: _tanggalLahir,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF757575)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: labelText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 4. Action Menu Card (Pengaturan, Tentang Aplikasi, Riwayat Aktivitas, Logout)
  Widget _buildActionMenuCard() {
    final menuItems = [
      {
        'icon': LucideIcons.settings,
        'title': 'Pengaturan',
        'isDestructive': false,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PengaturanAdminPage(
                onNavigateTab: widget.onNavigateTab,
              ),
            ),
          );
        },
      },
      {
        'icon': LucideIcons.info,
        'title': 'Tentang Aplikasi',
        'isDestructive': false,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TentangAdminPage(
                onNavigateTab: widget.onNavigateTab,
              ),
            ),
          );
        },
      },
      {
        'icon': LucideIcons.clock,
        'title': 'Riwayat Aktivitas',
        'isDestructive': false,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RiwayatAktivitasAdminPage(
                onNavigateTab: widget.onNavigateTab,
              ),
            ),
          );
        },
      },
      {
        'icon': LucideIcons.logOut,
        'title': 'Logout',
        'isDestructive': true,
        'onTap': _showLogoutConfirmation,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        children: menuItems.map((item) {
          final isDestructive = (item['isDestructive'] as bool?) ?? false;
          final icon = item['icon'] as IconData;
          final title = item['title'] as String;
          final onTap = item['onTap'] as VoidCallback?;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18.0,
                  vertical: 14.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isDestructive ? primaryMaroon : darkText,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: isDestructive ? primaryMaroon : darkText,
                        ),
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: Color(0xFF9E9E9E),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilAdminPage(
          initialNama: _nama,
          initialTelepon: _telepon,
          initialAlamat: _alamat,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _nama = result['nama'] ?? _nama;
        _telepon = result['telepon'] ?? _telepon;
        _alamat = result['alamat'] ?? _alamat;
      });
      AdminSuccessDialog.show(
        context,
        message: 'Profil admin berhasil diperbarui',
      );
    }
  }

  /// Dialog: Konfirmasi Logout
  void _showLogoutConfirmation() {
    LogoutDialog.show(
      context,
      message: 'Apakah Anda yakin ingin keluar?',
    );
  }
}
