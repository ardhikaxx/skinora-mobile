import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/user_service.dart';
import 'edit_profil_pengguna_page.dart';
import 'pengaturan_pengguna_page.dart';
import 'tentang_pengguna_page.dart';
import 'riwayat_aktivitas_pengguna_page.dart';
import '../../components/dialogs/logout_dialog.dart';

class ProfilPenggunaPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const ProfilPenggunaPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = false,
  });

  @override
  State<ProfilPenggunaPage> createState() => _ProfilPenggunaPageState();
}

class _ProfilPenggunaPageState extends State<ProfilPenggunaPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color avatarBg = Color(0xFF9E2A3B);
  static const Color cardBorder = Color(0xFFEEEEEE);
  static const Color innerBorder = Color(0xFFEBEBEB);

  String _name = Backend.useFirebase ? '' : 'Leonita Yulyta Agustin';
  String _email = Backend.useFirebase ? '' : 'leonita@demo.com';
  String _phone = Backend.useFirebase ? '' : '081234567890';
  String _address =
      Backend.useFirebase ? '' : 'Jl. Sudirman No. 123, Jakarta';
  String _birthDate = Backend.useFirebase ? '' : '1995-06-15';
  String _gender = Backend.useFirebase ? '' : 'Perempuan';

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  /// Profile milik pengguna dari Firestore. Tanpa Firebase, seed demo
  /// tetap dipakai agar UI/tes tidak berubah.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final profile = await UserService.loadByUid(uid);
      if (!mounted) return;
      if (profile == null) {
        setState(() {
          _name = '-';
          _email = '-';
          _phone = '-';
          _address = '-';
          _birthDate = '-';
          _gender = '-';
        });
        return;
      }
      setState(() {
        _name = profile.name;
        _email = profile.email;
        _phone = profile.phone;
        _address = profile.address;
        _birthDate = profile.birthDate;
        _gender = profile.gender;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _name = '-';
        _email = '-';
        _phone = '-';
        _address = '-';
        _birthDate = '-';
        _gender = '-';
      });
    }
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '-';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  void _showLogoutDialog() {
    LogoutDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header: "Profil"
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 16.0,
                bottom: 10.0,
              ),
              child: const Text(
                'Profil',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            // Subtle divider line
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(bottom: 16.0),
            ),

            // Main scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 2. User Account Header Card matching image copy.png
                  _buildUserHeaderCard(),

                  const SizedBox(height: 16),

                  // 3. "INFORMASI" Section Card
                  _buildInformasiCard(),

                  const SizedBox(height: 16),

                  // 4. Menu List Card (Pengaturan, Tentang Aplikasi, Riwayat Aktivitas, Logout)
                  _buildMenuListCard(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? PenggunaNavBottom(
              currentIndex: 4,
              onTap: (index) {
                widget.onNavigateTab?.call(index);
              },
            )
          : null,
    );
  }

  /// Top User Account Card with Avatar, Name, Email, and Edit Button
  Widget _buildUserHeaderCard() {
    // Split name into first two words and remainder for exact line wrapping matching mockup
    final nameParts = _name.split(' ');
    final firstName = nameParts.take(2).join(' ');
    final lastName = nameParts.length > 2 ? nameParts.skip(2).join(' ') : '';

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardBorder,
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
          // Maroon Squircle Avatar with "LY" initials
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: avatarBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                _initials(_name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name & Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                    height: 1.2,
                  ),
                ),
                if (lastName.isNotEmpty)
                  Text(
                    lastName,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                      height: 1.2,
                    ),
                  ),
                const SizedBox(height: 5),
                Text(
                  _email,
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: subText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // "Edit" text button
          InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilPenggunaPage(
                    initialName: _name,
                    initialPhone: _phone,
                    initialAddress: _address,
                    onNavigateTab: widget.onNavigateTab,
                  ),
                ),
              );
              if (result != null && result is Map<String, String>) {
                setState(() {
                  if (result['name']?.isNotEmpty == true) {
                    _name = result['name']!;
                  }
                  if (result['phone']?.isNotEmpty == true) {
                    _phone = result['phone']!;
                  }
                  if (result['address'] != null) {
                    _address = result['address']!;
                  }
                });
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                'Edit',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: primaryMaroon,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Middle Card: "INFORMASI" with 4 inner rounded boxes
  Widget _buildInformasiCard() {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardBorder,
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
          // Section Title: "INFORMASI"
          const Text(
            'INFORMASI',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: darkText,
            ),
          ),
          const SizedBox(height: 14),

          // 1. Telepon
          _buildInfoField(
            icon: LucideIcons.phone,
            label: 'TELEPON',
            value: _phone,
          ),
          const SizedBox(height: 12),

          // 2. Alamat
          _buildInfoField(
            icon: LucideIcons.mapPin,
            label: 'ALAMAT',
            value: _address,
          ),
          const SizedBox(height: 12),

          // 3. Tanggal Lahir
          _buildInfoField(
            icon: LucideIcons.calendar,
            label: 'TANGGAL LAHIR',
            value: _birthDate,
          ),
          const SizedBox(height: 12),

          // 4. Jenis Kelamin
          _buildInfoField(
            icon: LucideIcons.user,
            label: 'JENIS KELAMIN',
            value: _gender,
          ),
        ],
      ),
    );
  }

  /// Single Info Row inside its own white inner rounded box
  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: innerBorder,
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: subText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: subText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Card: Menu List
  Widget _buildMenuListCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardBorder,
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
        children: [
          // 1. Pengaturan
          _buildMenuRow(
            icon: LucideIcons.settings,
            title: 'Pengaturan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PengaturanPenggunaPage(
                    onNavigateTab: widget.onNavigateTab,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),

          // 2. Tentang Aplikasi
          _buildMenuRow(
            icon: LucideIcons.info,
            title: 'Tentang Aplikasi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TentangPenggunaPage(
                    onNavigateTab: widget.onNavigateTab,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),

          // 3. Riwayat Aktivitas
          _buildMenuRow(
            icon: LucideIcons.clock,
            title: 'Riwayat Aktivitas',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RiwayatAktivitasPenggunaPage(
                    onNavigateTab: widget.onNavigateTab,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),

          // 4. Logout
          _buildMenuRow(
            icon: LucideIcons.logOut,
            title: 'Logout',
            iconColor: const Color(0xFFE53935),
            textColor: const Color(0xFFE53935),
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  /// Single Clickable Row in Menu List
  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: iconColor ?? darkText,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? darkText,
                ),
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: subText,
            ),
          ],
        ),
      ),
    );
  }
}
