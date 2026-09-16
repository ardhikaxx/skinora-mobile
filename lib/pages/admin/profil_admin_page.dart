import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'laporan_riwayat_page.dart';

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

  // Profile data
  String _nama = 'Admin Skinora';
  String _email = 'admin@demo.com';
  String _telepon = '081234567899';
  String _alamat = 'Jl. Teknologi No. 1, Jakarta';
  String _tanggalLahir = '1985-01-01';

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
              onTap: _showEditProfileDialog,
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
                  count: '5',
                  label: 'Pengguna',
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Dokter (4)
              Expanded(
                child: _buildPlatformStatCard(
                  icon: LucideIcons.stethoscope,
                  count: '4',
                  label: 'Dokter',
                  onTap: () => widget.onNavigateTab?.call(1),
                ),
              ),
              const SizedBox(width: 10),

              // 3. Konsultasi (13)
              Expanded(
                child: _buildPlatformStatCard(
                  icon: LucideIcons.barChart2,
                  count: '13',
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
        'onTap': _showPengaturanDialog,
      },
      {
        'icon': LucideIcons.info,
        'title': 'Tentang Aplikasi',
        'isDestructive': false,
        'onTap': _showTentangAplikasiDialog,
      },
      {
        'icon': LucideIcons.clock,
        'title': 'Riwayat Aktivitas',
        'isDestructive': false,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LaporanRiwayatPage(
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

  /// Dialog: Edit Profil Admin
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _nama);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _telepon);
    final addressController = TextEditingController(text: _alamat);
    final birthDateController = TextEditingController(text: _tanggalLahir);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edit Profil Admin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField('Nama Lengkap', nameController),
                const SizedBox(height: 12),
                _buildTextField('Email', emailController),
                const SizedBox(height: 12),
                _buildTextField('Nomor Telepon', phoneController),
                const SizedBox(height: 12),
                _buildTextField('Alamat', addressController),
                const SizedBox(height: 12),
                _buildTextField('Tanggal Lahir (YYYY-MM-DD)', birthDateController),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF757575),
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _nama = nameController.text.trim().isEmpty
                                ? _nama
                                : nameController.text.trim();
                            _email = emailController.text.trim().isEmpty
                                ? _email
                                : emailController.text.trim();
                            _telepon = phoneController.text.trim().isEmpty
                                ? _telepon
                                : phoneController.text.trim();
                            _alamat = addressController.text.trim().isEmpty
                                ? _alamat
                                : addressController.text.trim();
                            _tanggalLahir = birthDateController.text.trim().isEmpty
                                ? _tanggalLahir
                                : birthDateController.text.trim();
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profil admin berhasil diperbarui'),
                              backgroundColor: primaryMaroon,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryMaroon,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF757575),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryMaroon, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  /// Bottom Sheet: Pengaturan
  void _showPengaturanDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool notifSistem = true;
        bool modeGelap = false;
        bool twoFactor = true;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pengaturan Admin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Notifikasi Sistem'),
                    subtitle: const Text('Terima pembaruan penting platform'),
                    activeColor: primaryMaroon,
                    value: notifSistem,
                    onChanged: (val) {
                      setModalState(() => notifSistem = val);
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mode Gelap'),
                    subtitle: const Text('Aktifkan tema gelap pada antarmuka'),
                    activeColor: primaryMaroon,
                    value: modeGelap,
                    onChanged: (val) {
                      setModalState(() => modeGelap = val);
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Autentikasi 2 Langkah'),
                    subtitle: const Text('Tingkatkan keamanan akun administrator'),
                    activeColor: primaryMaroon,
                    value: twoFactor,
                    onChanged: (val) {
                      setModalState(() => twoFactor = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMaroon,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Bottom Sheet: Tentang Aplikasi
  void _showTentangAplikasiDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.sparkles,
                    color: primaryMaroon,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Skinora Mobile App',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Versi 1.0.0 (Build 1)',
                style: TextStyle(
                  fontSize: 13,
                  color: subText,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Skinora adalah platform layanan kesehatan dan konsultasi dokter spesialis kulit terpercaya. Membantu menghubungkan pengguna dengan dokter profesional.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryMaroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dialog: Konfirmasi Logout
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Konfirmasi Logout',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun admin Skinora?',
            style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryMaroon,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
