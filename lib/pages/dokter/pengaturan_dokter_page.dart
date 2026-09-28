import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import '../../components/notification_permission.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/notification_service.dart';
import '../../services/user_service.dart';

class PengaturanDokterPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const PengaturanDokterPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = true,
  });

  @override
  State<PengaturanDokterPage> createState() => _PengaturanDokterPageState();
}

class _PengaturanDokterPageState extends State<PengaturanDokterPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E1E1E);

  bool _isNotificationActive = true;

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  /// Muat settings dari Firestore. Tanpa Firebase, default UI tetap dipakai.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final profile = await UserService.loadByUid(uid);
      if (profile == null || !mounted) return;
      setState(() {
        _isNotificationActive = profile.notificationsEnabled;
      });
    } catch (_) {
      // biarkan default bila query gagal
    }
  }

  Future<void> _handleSave() async {
    if (Backend.useFirebase) {
      final uid = AuthService.uid;
      if (uid != null) {
        try {
          await UserService.updateSettings(
            uid,
            notificationsEnabled: _isNotificationActive,
          );
          await ActivityService.log(
            title: 'Mengubah pengaturan',
            tag: 'Pengaturan',
            actor: 'Dokter',
            actorUid: uid,
          );
          // Sinkronkan permission OS + batalkan pengingat yang tidak relevan.
          await NotificationService.applyNotificationSettings(
            notificationsEnabled: _isNotificationActive,
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan pengaturan: $e')),
          );
          return;
        }
      }
    }
    if (!mounted) return;
    AdminSuccessDialog.show(
      context,
      message: 'Pengaturan dokter berhasil disimpan',
      onOk: () {
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with back button and title
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 20.0,
                top: 14.0,
                bottom: 10.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      color: primaryMaroon,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Pengaturan',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Subtle divider line
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(bottom: 16.0),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Card: NOTIFIKASI
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18.0),
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
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NOTIFIKASI',
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Inner Box with Bell icon, text, and toggle switch
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.bell,
                                size: 18,
                                color: Color(0xFF555555),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Aktifkan Notifikasi',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                              ),
                              CupertinoSwitch(
                                value: _isNotificationActive,
                                activeTrackColor: primaryMaroon,
                                onChanged: (value) {
                                  setState(() {
                                    _isNotificationActive = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Status izin notifikasi OS (Android 13+ / iOS): user tahu
                  // bila notifikasi diblokir sistem & bisa meminta izin ulang.
                  const SystemNotificationPermissionTile(),

                  const SizedBox(height: 18),

                  // Button: "Simpan Pengaturan"
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _handleSave,
                      icon: const Icon(
                        LucideIcons.save,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Simpan Pengaturan',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMaroon,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
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
                Navigator.pop(context);
                if (index != 4) {
                  widget.onNavigateTab?.call(index);
                }
              },
            )
          : null,
    );
  }
}
