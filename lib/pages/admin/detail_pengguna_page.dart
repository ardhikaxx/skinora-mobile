import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../components/navbottom/admin_navbottom.dart';
import '../../models/admin_user_model.dart';

class DetailPenggunaPage extends StatefulWidget {
  final AdminUserModel user;
  final ValueChanged<int>? onNavigateTab;

  const DetailPenggunaPage({
    super.key,
    required this.user,
    this.onNavigateTab,
  });

  @override
  State<DetailPenggunaPage> createState() => _DetailPenggunaPageState();
}

class _DetailPenggunaPageState extends State<DetailPenggunaPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E293B);
  static const Color subText = Color(0xFF6B7280);

  late AdminUserModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  void _onTangguhkan() {
    AdminConfirmDialog.show(
      context,
      title: 'Tangguhkan Pengguna',
      message: 'Apakah Anda yakin ingin menangguhkan pengguna ini?',
      confirmLabel: 'Tangguhkan',
      confirmColor: const Color(0xFFEF4444),
      onConfirm: () {
        final updatedUser = _user.copyWith(status: UserStatus.ditangguhkan);
        Navigator.pop(context, updatedUser);
      },
    );
  }

  void _onAktifkanKembali() {
    final updatedUser = _user.copyWith(status: UserStatus.aktif);
    Navigator.pop(context, updatedUser);
  }

  @override
  Widget build(BuildContext context) {
    final initialLetter = _user.name.isNotEmpty ? _user.name[0].toUpperCase() : 'U';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pop(context, _user);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFCFD),
        body: SafeArea(
          child: Column(
            children: [
              // Header: Back Chevron + Title
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 20.0,
                  top: 16.0,
                  bottom: 12.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        LucideIcons.chevronLeft,
                        size: 22,
                        color: darkText,
                      ),
                      onPressed: () => Navigator.pop(context, _user),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Detail Pengguna',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  children: [
                    // User Details Card
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFEEEEEE),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top: Avatar + Name & Badge
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: const BoxDecoration(
                                  color: primaryMaroon,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    initialLetter,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _user.name,
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.bold,
                                        color: darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _user.status == UserStatus.aktif
                                            ? const Color(0xFFFFD5C8)
                                            : const Color(0xFFFFEBD8),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _user.status.label,
                                        style: TextStyle(
                                          fontSize: 11.0,
                                          fontWeight: FontWeight.bold,
                                          color: _user.status == UserStatus.aktif
                                              ? const Color(0xFF9E2A3B)
                                              : const Color(0xFFC2410C),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFF1F2F4), height: 1),
                          const SizedBox(height: 16),

                          // Key-value rows
                          _buildInfoRow('Email', _user.email),
                          _buildInfoRow('Telepon', _user.phone),
                          _buildInfoRow('Alamat', _user.address, multiline: true),
                          _buildInfoRow('Tanggal Lahir', _user.birthDate),
                          _buildInfoRow('Jenis Kelamin', _user.gender),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Button
                    if (_user.status == UserStatus.aktif)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _onTangguhkan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryMaroon,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Tangguhkan',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _onAktifkanKembali,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryMaroon,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Aktifkan Kembali',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AdminNavBottom(
          currentIndex: 2,
          onTap: (index) {
            Navigator.popUntil(context, (route) => route.isFirst);
            if (index != 2) {
              widget.onNavigateTab?.call(index);
            }
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: subText,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
