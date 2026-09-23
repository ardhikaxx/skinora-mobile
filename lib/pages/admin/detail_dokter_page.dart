import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../components/navbottom/admin_navbottom.dart';
import '../../models/admin_doctor_model.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/user_service.dart';

class DetailDokterPage extends StatefulWidget {
  final AdminDoctorModel doctor;
  final ValueChanged<int>? onNavigateTab;

  const DetailDokterPage({
    super.key,
    required this.doctor,
    this.onNavigateTab,
  });

  @override
  State<DetailDokterPage> createState() => _DetailDokterPageState();
}

class _DetailDokterPageState extends State<DetailDokterPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E293B);
  static const Color subText = Color(0xFF6B7280);

  late AdminDoctorModel _doctor;

  @override
  void initState() {
    super.initState();
    _doctor = widget.doctor;
  }

  // --- Actions ---

  Future<void> _persistStatus(AdminDoctorModel updated, String tag) async {
    if (!Backend.useFirebase) return;
    await UserService.updateDokterStatus(updated);
    await ActivityService.log(
      title: '$tag ${updated.name}',
      tag: tag,
      actor: 'Admin',
      actorUid: AuthService.uid ?? 'admin',
    );
  }

  Future<void> _applyStatus({
    required DoctorStatus status,
    required String successMessage,
    required String activityTag,
  }) async {
    final updated = _doctor.copyWith(status: status);
    try {
      await _persistStatus(updated, activityTag);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $e')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _doctor = updated);
    AdminSuccessDialog.show(context, message: successMessage);
  }

  /// Action: Tangguhkan Dokter (Screen 4 & 5)
  void _onTangguhkan() {
    AdminConfirmDialog.show(
      context,
      title: 'Tangguhkan Dokter',
      message: 'Apakah Anda yakin ingin menangguhkan dokter ini?',
      confirmLabel: 'Tangguhkan',
      confirmColor: const Color(0xFFEF4444),
      onConfirm: () async {
        final updated = _doctor.copyWith(status: DoctorStatus.ditangguhkan);
        try {
          await _persistStatus(updated, 'Verifikasi');
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal memperbarui status: $e')),
            );
          }
          return;
        }
        if (!mounted) return;
        setState(() => _doctor = updated);
        AdminSuccessDialog.show(
          context,
          message: '${_doctor.name} telah ditangguhkan',
        );
      },
    );
  }

  /// Action: Aktifkan Kembali Dokter (Screen 6)
  void _onAktifkanKembali() {
    _applyStatus(
      status: DoctorStatus.terverifikasi,
      successMessage: '${_doctor.name} telah diaktifkan kembali',
      activityTag: 'Verifikasi',
    );
  }

  /// Action: Verifikasi Dokter (Screen 8)
  void _onVerifikasi() {
    AdminConfirmDialog.show(
      context,
      title: 'Verifikasi Dokter',
      message: 'Apakah Anda yakin ingin memverifikasi dokter ini?',
      confirmLabel: 'Verifikasi',
      confirmColor: primaryMaroon,
      iconColor: const Color(0xFFD97706),
      iconBgColor: const Color(0xFFFEF3C7),
      onConfirm: () async {
        final updated = _doctor.copyWith(status: DoctorStatus.terverifikasi);
        try {
          await _persistStatus(updated, 'Verifikasi');
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal memperbarui status: $e')),
            );
          }
          return;
        }
        if (!mounted) return;
        setState(() => _doctor = updated);
        AdminSuccessDialog.show(
          context,
          message: '${_doctor.name} telah diverifikasi',
        );
      },
    );
  }

  /// Action: Tolak Dokter (Screen 9)
  void _onTolak() {
    AdminConfirmDialog.show(
      context,
      title: 'Tolak Dokter',
      message: 'Apakah Anda yakin ingin menolak dokter ini?',
      confirmLabel: 'Tolak',
      confirmColor: const Color(0xFFEF4444),
      onConfirm: () async {
        final updated = _doctor.copyWith(status: DoctorStatus.ditolak);
        try {
          await _persistStatus(updated, 'Verifikasi');
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal memperbarui status: $e')),
            );
          }
          return;
        }
        if (!mounted) return;
        setState(() => _doctor = updated);
        AdminSuccessDialog.show(
          context,
          message: '${_doctor.name} telah ditolak',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pop(context, _doctor);
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
                      onPressed: () => Navigator.pop(context, _doctor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Detail Dokter',
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
                    // Doctor Details Card
                    _buildDoctorCard(),
                    const SizedBox(height: 20),

                    // Action Buttons depending on status
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AdminNavBottom(
          currentIndex: 1,
          onTap: (index) {
            Navigator.popUntil(context, (route) => route.isFirst);
            if (index != 1) {
              widget.onNavigateTab?.call(index);
            }
          },
        ),
      ),
    );
  }

  /// White Card containing Doctor Information
  Widget _buildDoctorCard() {
    return Container(
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
          // Row: Avatar 'd' + Name & Status Badge
          Row(
            children: [
              // Avatar circle 'd'
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: primaryMaroon,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'd',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name & Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _doctor.name,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(_doctor.status),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F2F4), height: 1),
          const SizedBox(height: 16),

          // Key-Value Rows
          _buildInfoRow('Email', _doctor.email),
          _buildInfoRow('Telepon', _doctor.phone),
          _buildInfoRow('Spesialisasi', _doctor.specialization),
          _buildInfoRow('Pengalaman', _doctor.experience),
          _buildInfoRow('STR', _doctor.str),

          const SizedBox(height: 12),

          // BIO Section
          const Text(
            'BIO',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: subText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _doctor.bio,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF374151),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  /// Key-value information row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: subText,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
        ],
      ),
    );
  }

  /// Status badge widget
  Widget _buildStatusBadge(DoctorStatus status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case DoctorStatus.terverifikasi:
        bgColor = const Color(0xFFFFD5C8);
        textColor = const Color(0xFF9E2A3B);
        break;
      case DoctorStatus.menunggu:
        bgColor = const Color(0xFFFFE5E0);
        textColor = const Color(0xFFD97706);
        break;
      case DoctorStatus.ditolak:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFEF4444);
        break;
      case DoctorStatus.ditangguhkan:
        bgColor = const Color(0xFFFFEDD5);
        textColor = const Color(0xFFC2410C);
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF4B5563);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  /// Action buttons depending on doctor status
  Widget _buildActionButtons() {
    switch (_doctor.status) {
      case DoctorStatus.terverifikasi:
        // Screen 3: "Tangguhkan" button
        return SizedBox(
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
        );

      case DoctorStatus.ditangguhkan:
        // Screen 6: "Aktifkan Kembali" button
        return SizedBox(
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
        );

      case DoctorStatus.menunggu:
        // Screen 7: "Verifikasi" & "Tolak" buttons stacked
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _onVerifikasi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryMaroon,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Verifikasi',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _onTolak,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Tolak',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );

      case DoctorStatus.ditolak:
        // Screen 10: No action buttons
        return const SizedBox.shrink();

      default:
        return const SizedBox.shrink();
    }
  }
}
