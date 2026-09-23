import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/consultation_service.dart';
import '../../services/user_service.dart';
import 'pengaturan_dokter_page.dart';
import 'edit_profil_dokter_page.dart';
import 'tentang_dokter_page.dart';
import 'riwayat_aktivitas_dokter_page.dart';
import '../../components/dialogs/logout_dialog.dart';

class ProfilDokterPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const ProfilDokterPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = false,
  });

  @override
  State<ProfilDokterPage> createState() => _ProfilDokterPageState();
}

class _ProfilDokterPageState extends State<ProfilDokterPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E1E1E);
  static const Color subText = Color(0xFF757575);
  static const Color statSectionBg = Color(0xFFFFD5C8);
  static const Color badgeBg = Color(0xFFFFD5C8);

  String _statKonsultasi = '9';
  String _statPasien = '4';
  String _statSelesai = '4';

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  /// Muat profile dokter + ringkasan praktik dari Firestore. Tanpa Firebase,
  /// seed demo tetap dipakai agar UI/tes tidak berubah.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final results = await Future.wait<Object?>([
        UserService.loadByUid(uid),
        ConsultationService.listForDoctor(uid, includeFinished: true),
      ]);
      final profile = results[0] as dynamic;
      final consults = results[1] as List<Map<String, dynamic>>?;
      if (!mounted) return;
      setState(() {
        if (profile != null) {
          final store = DoctorProfileStore();
          final name = (profile.name as String?) ?? '';
          if (name.isNotEmpty) store.name = name;
          final email = (profile.email as String?) ?? '';
          if (email.isNotEmpty) store.email = email;
          final phone = (profile.phone as String?) ?? '';
          if (phone.isNotEmpty) store.phone = phone;
          final address = (profile.address as String?) ?? '';
          if (address.isNotEmpty) store.address = address;
          final spec = (profile.specialization as String?) ?? '';
          if (spec.isNotEmpty) store.specialization = spec;
          final exp = (profile.experience as String?) ?? '';
          if (exp.isNotEmpty) store.experience = exp;
          final str = (profile.str as String?) ?? '';
          if (str.isNotEmpty) store.str = str;
          final bio = (profile.bio as String?) ?? '';
          if (bio.isNotEmpty) store.bio = bio;
        }
        if (consults != null && consults.isNotEmpty) {
          final pasien = consults
              .map((c) => (c['patientId'] as String?) ?? '')
              .where((id) => id.isNotEmpty)
              .toSet()
              .length;
          final selesai = consults
              .where((c) => ((c['status'] as String?) ?? '') == 'selesai')
              .length;
          _statKonsultasi = '${consults.length}';
          if (pasien > 0) _statPasien = '$pasien';
          _statSelesai = '$selesai';
        }
      });
    } catch (_) {
      // biarkan seed demo bila query gagal
    }
  }

  void _showSuccessDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 4,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Checkmark Icon + Title + Close Button
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD5C8),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.check,
                          color: Color(0xFFE65100),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Berhasil',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
                      child: const Icon(
                        LucideIcons.x,
                        size: 18,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Body text
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF4B5563),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),

                // OK Button
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryMaroon,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilDokterPage(
          onNavigateTab: widget.onNavigateTab,
          showBottomNav: true,
        ),
      ),
    );

    if (updated == true && mounted) {
      setState(() {});
      _showSuccessDialog('Profil dokter berhasil diperbarui');
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
            // 1. Header: Title "Profil Dokter"
            const Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 16.0,
                bottom: 8.0,
              ),
              child: Text(
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
      bottomNavigationBar: widget.showBottomNav
          ? DokterNavBottom(
              currentIndex: 4,
              onTap: (index) {
                if (index != 4) {
                  widget.onNavigateTab?.call(index);
                }
              },
            )
          : null,
    );
  }

  /// 2. Doctor Info Card (Avatar Initials, Name, Email, Badges)
  Widget _buildDoctorInfoCard() {
    final store = DoctorProfileStore();

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
          // Avatar (Initials e.g. "DA")
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
            child: Center(
              child: Text(
                store.initials,
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

          // Doctor details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  store.email,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: subText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Badge 1: Estetika Kulit
                    _buildPillBadge(store.specialization),
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
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Konsultasi
              Expanded(
                child: _buildPraktikStatCard(
                  icon: LucideIcons.messageSquare,
                  count: _statKonsultasi,
                  label: 'Konsultasi',
                ),
              ),
              const SizedBox(width: 10),

              // Pasien
              Expanded(
                child: _buildPraktikStatCard(
                  icon: LucideIcons.user,
                  count: _statPasien,
                  label: 'Pasien',
                ),
              ),
              const SizedBox(width: 10),

              // Selesai
              Expanded(
                child: _buildPraktikStatCard(
                  icon: LucideIcons.calendarCheck,
                  count: _statSelesai,
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
    final store = DoctorProfileStore();

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
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 18),

          // Telepon
          _buildInfoRow(
            icon: LucideIcons.phone,
            label: 'TELEPON',
            value: store.phone,
          ),
          const SizedBox(height: 18),

          // Alamat
          _buildInfoRow(
            icon: LucideIcons.mapPin,
            label: 'ALAMAT',
            value: store.address,
          ),
          const SizedBox(height: 18),

          // Spesialisasi
          _buildInfoRow(
            icon: LucideIcons.stethoscope,
            label: 'SPESIALISASI',
            value: store.specialization,
          ),
          const SizedBox(height: 18),

          // Pengalaman
          _buildInfoRow(
            icon: LucideIcons.briefcase,
            label: 'PENGALAMAN',
            value: store.experience,
          ),
          const SizedBox(height: 18),

          // STR
          _buildInfoRow(
            icon: LucideIcons.fileText,
            label: 'STR',
            value: store.str,
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
        'onTap': _handleEditProfile,
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
                showBottomNav: true,
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
              builder: (context) => TentangDokterPage(
                onNavigateTab: widget.onNavigateTab,
                showBottomNav: true,
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
              builder: (context) => RiwayatAktivitasDokterPage(
                onNavigateTab: widget.onNavigateTab,
                showBottomNav: true,
              ),
            ),
          );
        },
      },
      {
        'icon': LucideIcons.logOut,
        'title': 'Logout',
        'isDestructive': true,
        'onTap': () {
          LogoutDialog.show(context);
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
