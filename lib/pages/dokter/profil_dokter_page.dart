import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'pengaturan_dokter_page.dart';

class ProfilDokterPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const ProfilDokterPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<ProfilDokterPage> createState() => _ProfilDokterPageState();
}

class _ProfilDokterPageState extends State<ProfilDokterPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color statSectionBg = Color(0xFFFFD5C3);
  static const Color badgeBg = Color(0xFFFFD5C8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Title "Profil Dokter"
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 16.0,
                bottom: 8.0,
              ),
              child: const Text(
                'Profil Dokter',
                style: TextStyle(
                  fontFamily: 'serif',
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
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            ),

            // Main scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 2. Doctor Info Card
                  _buildDoctorInfoCard(),
                  const SizedBox(height: 18),

                  // 3. Ringkasan Praktik Section
                  _buildRingkasanPraktikSection(),
                  const SizedBox(height: 18),

                  // 4. Informasi Section
                  _buildInformasiSection(),
                  const SizedBox(height: 18),

                  // 5. Action Menu Card
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

  /// 2. Doctor Info Card (Avatar "DA", Name, Email, Badges)
  Widget _buildDoctorInfoCard() {
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
          // Avatar "DA"
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primaryMaroon,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryMaroon.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'DA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Doctor details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'dr. Anita Dewi, Sp.KK',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'anita@demo.com',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: subText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Badge 1: Estetika Kulit
                    _buildPillBadge('Estetika Kulit'),
                    const SizedBox(width: 6),
                    // Badge 2: Terverifikasi
                    _buildPillBadge('Terverifikasi'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: primaryMaroon,
        ),
      ),
    );
  }

  /// 3. Ringkasan Praktik Section
  Widget _buildRingkasanPraktikSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: statSectionBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RINGKASAN PRAKTIK',
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: darkText,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Konsultasi: 9
              Expanded(
                child: _buildPraktikStatCard(
                  icon: LucideIcons.messageSquare,
                  count: '9',
                  label: 'Konsultasi',
                ),
              ),
              const SizedBox(width: 10),

              // Pasien: 5
              Expanded(
                child: _buildPraktikStatCard(
                  icon: LucideIcons.user,
                  count: '5',
                  label: 'Pasien',
                ),
              ),
              const SizedBox(width: 10),

              // Selesai: 4
              Expanded(
                child: _buildPraktikStatCard(
                  icon: LucideIcons.calendarCheck,
                  count: '4',
                  label: 'Selesai',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPraktikStatCard({
    required IconData icon,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primaryMaroon,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Informasi Section (Telepon, Alamat, Spesialisasi, Pengalaman, STR)
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
            value: '081234567800',
          ),
          const SizedBox(height: 18),

          // Alamat
          _buildInfoRow(
            icon: LucideIcons.mapPin,
            label: 'ALAMAT',
            value: 'Jl. Melati No. 10, Jakarta',
          ),
          const SizedBox(height: 18),

          // Spesialisasi
          _buildInfoRow(
            icon: LucideIcons.stethoscope,
            label: 'SPESIALISASI',
            value: 'Estetika Kulit',
          ),
          const SizedBox(height: 18),

          // Pengalaman
          _buildInfoRow(
            icon: LucideIcons.briefcase,
            label: 'PENGALAMAN',
            value: '8 tahun',
          ),
          const SizedBox(height: 18),

          // STR
          _buildInfoRow(
            icon: LucideIcons.fileText,
            label: 'STR',
            value: 'STR-2018-12345',
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
                  color: subText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 5. Action Menu Card (Edit Profil, Pengaturan, Tentang Aplikasi, Riwayat Aktivitas, Logout)
  Widget _buildActionMenuCard() {
    final menuItems = [
      {
        'icon': LucideIcons.user,
        'title': 'Edit Profil',
        'isDestructive': false,
        'onTap': null,
      },
      {
        'icon': LucideIcons.settings,
        'title': 'Pengaturan',
        'isDestructive': false,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PengaturanDokterPage(
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
        'onTap': null,
      },
      {
        'icon': LucideIcons.clock,
        'title': 'Riwayat Aktivitas',
        'isDestructive': false,
        'onTap': null,
      },
      {
        'icon': LucideIcons.logOut,
        'title': 'Logout',
        'isDestructive': true,
        'onTap': () {
          Navigator.of(context).pushReplacementNamed('/login');
        },
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
          final isDestructive = item['isDestructive'] as bool;
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
                          fontWeight: FontWeight.bold,
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
}
