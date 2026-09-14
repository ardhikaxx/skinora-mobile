import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'notifikasi_admin_page.dart';
import 'master_spesialisasi_page.dart';
import 'laporan_riwayat_page.dart';

class BerandaAdminPage extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const BerandaAdminPage({
    super.key,
    this.onNavigateTab,
  });

  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color statSectionBg = Color(0xFFFFD5C3);
  static const Color peachIconBg = Color(0xFFFFE3D8);
  static const Color activityIconBg = Color(0xFFFFD9CC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Admin Dashboard & Notification Button
              _buildHeader(context),
              const SizedBox(height: 20),

              // Section 1: STATISTIK
              _buildStatistikSection(),
              const SizedBox(height: 18),

              // Section 2: MENU CEPAT
              _buildMenuCepatSection(context),
              const SizedBox(height: 18),

              // Section 3: AKTIVITAS TERBARU
              _buildAktivitasTerbaruSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Header with Title, Subtitle, and Notification Bell with Badge
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Admin Dashboard',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkText,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Kelola aplikasi Skinora',
              style: TextStyle(
                fontSize: 13.5,
                color: subText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        // Notification button with badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotifikasiAdminPage(
                      onNavigateTab: onNavigateTab,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE5E5EA),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.bell,
                    size: 20,
                    color: Color(0xFF4A1A24),
                  ),
                ),
              ),
            ),
            // Red badge with count
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: primaryMaroon,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: const Center(
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Section 1: STATISTIK (peach box with 2x2 white cards)
  Widget _buildStatistikSection() {
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
            'STATISTIK',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: darkText,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.messageSquare,
                  count: '3',
                  label: 'Terjadwal',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.circleCheck,
                  count: '7',
                  label: 'Selesai',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.users,
                  count: '5',
                  label: 'Pengguna',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.stethoscope,
                  count: '4',
                  label: 'Dokter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
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
                size: 19,
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

  /// Section 2: MENU CEPAT
  Widget _buildMenuCepatSection(BuildContext context) {
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
            'MENU CEPAT',
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 16),
          // Row 1: Dokter, Pengguna, Edukasi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.stethoscope,
                  title: 'Dokter',
                  subtitle: 'Kelola verifikasi',
                  onTap: () => onNavigateTab?.call(1),
                ),
              ),
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.users,
                  title: 'Pengguna',
                  subtitle: 'Kelola pengguna',
                  onTap: () => onNavigateTab?.call(2),
                ),
              ),
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.fileText,
                  title: 'Edukasi',
                  subtitle: 'Kelola artikel',
                  onTap: () => onNavigateTab?.call(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Row 2: Spesialisasi, Laporan, Spacer
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.stethoscope,
                  title: 'Spesialisasi',
                  subtitle: 'Kelola spesialisasi',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MasterSpesialisasiPage(
                          onNavigateTab: onNavigateTab,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.messageSquare,
                  title: 'Laporan',
                  subtitle: 'Analitik & riwayat',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LaporanRiwayatPage(
                          onNavigateTab: onNavigateTab,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Expanded(
                child: SizedBox(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: peachIconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: primaryMaroon,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                color: subText,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section 3: AKTIVITAS TERBARU
  Widget _buildAktivitasTerbaruSection() {
    final activities = [
      {
        'title': 'Login berhasil',
        'time': '2026-08-27 08:00',
      },
      {
        'title': 'Melakukan Skin Check',
        'time': '2026-08-25 10:30',
      },
      {
        'title': 'Mencatat Skin Daily',
        'time': '2026-08-27 08:15',
      },
      {
        'title': 'Mencatat rutinitas skincare pagi',
        'time': '2026-08-27 07:30',
      },
      {
        'title': 'Booking konsultasi dengan dr. Anita',
        'time': '2026-08-26 14:00',
      },
      {
        'title': 'Konsultasi selesai dengan dr. Andi',
        'time': '2026-08-20 14:30',
      },
    ];

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
          Row(
            children: const [
              Icon(
                LucideIcons.clock,
                size: 16,
                color: Color(0xFF757575),
              ),
              SizedBox(width: 8),
              Text(
                'AKTIVITAS TERBARU',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = activities[index];
              return _buildActivityItem(
                title: item['title']!,
                time: item['time']!,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: activityIconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(
              LucideIcons.circleCheck,
              color: primaryMaroon,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11.0,
                  color: subText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


}
