import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../models/admin_account_model.dart';
import '../../models/admin_user_model.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/user_service.dart';

class DetailAdminPage extends StatefulWidget {
  final AdminAccountModel admin;
  final ValueChanged<int>? onNavigateTab;

  const DetailAdminPage({
    super.key,
    required this.admin,
    this.onNavigateTab,
  });

  @override
  State<DetailAdminPage> createState() => _DetailAdminPageState();
}

class _DetailAdminPageState extends State<DetailAdminPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E293B);
  static const Color subText = Color(0xFF6B7280);

  late AdminAccountModel _admin;
  StreamSubscription<dynamic>? _profileSub;
  bool _isProcessing = false;

  bool get _isSelf =>
      Backend.useFirebase &&
      _admin.registered &&
      _admin.backendId == AuthService.uid;

  @override
  void initState() {
    super.initState();
    _admin = widget.admin;
    final uid = _admin.fsDocId ?? _admin.id;
    if (Backend.useFirebase && uid.isNotEmpty) {
      _profileSub = UserService.streamByUid(uid).listen((profile) {
        if (!mounted || profile == null) return;
        setState(() {
          _admin = _admin.copyWith(
            name: profile.name.isNotEmpty ? profile.name : _admin.name,
            phone: profile.phone.isNotEmpty ? profile.phone : _admin.phone,
            address: profile.address.isNotEmpty
                ? profile.address
                : _admin.address,
            birthDate: profile.birthDate.isNotEmpty
                ? profile.birthDate
                : _admin.birthDate,
            gender: profile.gender.isNotEmpty
                ? profile.gender
                : _admin.gender,
            status: profile.status.toLowerCase() == 'ditangguhkan'
                ? UserStatus.ditangguhkan
                : UserStatus.aktif,
          );
        });
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  Future<void> _persistStatus(AdminAccountModel updated) async {
    if (!Backend.useFirebase) return;
    await UserService.updateAdminStatus(updated);
    await ActivityService.log(
      title: updated.status == UserStatus.ditangguhkan
          ? 'Menangguhkan admin ${updated.name}'
          : 'Mengaktifkan kembali admin ${updated.name}',
      tag: 'Admin',
      actor: 'Admin',
      actorUid: AuthService.uid ?? 'admin',
    );
  }

  void _onTangguhkan() {
    if (_isSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak dapat menangguhkan akun sendiri.'),
        ),
      );
      return;
    }

    AdminConfirmDialog.show(
      context,
      title: 'Tangguhkan Admin',
      message:
          'Apakah Anda yakin ingin menangguhkan admin ini? Akses administrator ke sistem akan dibekukan sementara.',
      confirmLabel: 'Tangguhkan',
      confirmColor: const Color(0xFFEF4444),
      onConfirm: () async {
        Navigator.pop(context);
        setState(() => _isProcessing = true);
        final updated = _admin.copyWith(status: UserStatus.ditangguhkan);
        try {
          await _persistStatus(updated);
          if (!mounted) return;
          setState(() {
            _admin = updated;
            _isProcessing = false;
          });
          Navigator.pop(context, updated);
        } catch (e) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menangguhkan admin: $e')),
          );
        }
      },
    );
  }

  void _onAktifkanKembali() {
    AdminConfirmDialog.show(
      context,
      title: 'Aktifkan Kembali Admin',
      message:
          'Apakah Anda yakin ingin mengaktifkan kembali akun admin ini? Hak akses ke panel admin akan dipulihkan.',
      confirmLabel: 'Aktifkan',
      confirmColor: primaryMaroon,
      onConfirm: () async {
        Navigator.pop(context);
        setState(() => _isProcessing = true);
        final updated = _admin.copyWith(status: UserStatus.aktif);
        try {
          await _persistStatus(updated);
          if (!mounted) return;
          setState(() {
            _admin = updated;
            _isProcessing = false;
          });
          Navigator.pop(context, updated);
        } catch (e) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengaktifkan admin: $e')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSuspended = _admin.status == UserStatus.ditangguhkan;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Detail Admin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Profile Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
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
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: primaryMaroon,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _admin.initials,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _admin.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _admin.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: subText,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Badges Row
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: [
                              // Role Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryMaroon.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.shieldCheck,
                                      size: 13,
                                      color: primaryMaroon,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Administrator',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: primaryMaroon,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSuspended
                                      ? const Color(0xFFFFEBD8)
                                      : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isSuspended ? 'Ditangguhkan' : 'Aktif',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSuspended
                                        ? const Color(0xFFC2410C)
                                        : const Color(0xFF047857),
                                  ),
                                ),
                              ),

                              // Registered Status Badge
                              if (!_admin.registered)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Undangan (Belum Daftar)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Information Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
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
                            'INFORMASI ADMIN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: subText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: LucideIcons.mail,
                            label: 'Email',
                            value: _admin.email,
                          ),
                          const Divider(height: 24, color: Color(0xFFF3F4F6)),
                          _buildInfoRow(
                            icon: LucideIcons.phone,
                            label: 'Nomor Telepon',
                            value: _admin.phone.isNotEmpty ? _admin.phone : '-',
                          ),
                          const Divider(height: 24, color: Color(0xFFF3F4F6)),
                          _buildInfoRow(
                            icon: LucideIcons.mapPin,
                            label: 'Alamat',
                            value:
                                _admin.address.isNotEmpty ? _admin.address : '-',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Section
                    if (_isSelf) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFBBF7D0),
                            width: 1.0,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              LucideIcons.checkCircle2,
                              size: 18,
                              color: Color(0xFF15803D),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Ini adalah akun Anda saat ini. Anda tidak dapat menangguhkan akun Anda sendiri.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF15803D),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: isSuspended
                            ? ElevatedButton.icon(
                                onPressed: _isProcessing ? null : _onAktifkanKembali,
                                icon: const Icon(LucideIcons.checkCircle,
                                    size: 18, color: Colors.white),
                                label: const Text(
                                  'Aktifkan Kembali Admin',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: _isProcessing ? null : _onTangguhkan,
                                icon: const Icon(LucideIcons.shieldOff,
                                    size: 18, color: Color(0xFFEF4444)),
                                label: const Text(
                                  'Tangguhkan Admin',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFEF4444),
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
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
}
