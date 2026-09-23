import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../components/navbottom/admin_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/user_service.dart';

class PengaturanAdminPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const PengaturanAdminPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<PengaturanAdminPage> createState() => _PengaturanAdminPageState();
}

class _PengaturanAdminPageState extends State<PengaturanAdminPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E293B);
  static const Color subText = Color(0xFF6B7280);

  bool _enableNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Ambil `settings.notificationsEnabled` milik admin. Tanpa Firebase,
  /// nilai default demo dipertahankan agar UI/tes tidak berubah.
  Future<void> _loadSettings() async {
    if (!Backend.useFirebase) return;
    try {
      final profile = await AuthService.loadProfile();
      if (!mounted || profile == null) return;
      setState(() => _enableNotifications = profile.notificationsEnabled);
    } catch (_) {
      // biarkan nilai default
    }
  }

  Future<void> _handleSave() async {
    final uid = AuthService.uid;
    if (Backend.useFirebase && uid != null) {
      try {
        await UserService.updateSettings(
          uid,
          notificationsEnabled: _enableNotifications,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan pengaturan: $e')),
        );
        return;
      }
    }
    if (!mounted) return;
    AdminSuccessDialog.show(
      context,
      message: 'Pengaturan admin berhasil disimpan',
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
            // Header: Chevron Left + Title
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
                    'Pengaturan',
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

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                children: [
                  // Label NOTIFIKASI
                  const Text(
                    'NOTIFIKASI',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: subText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Notification Card with Switch
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                        const Icon(
                          LucideIcons.bell,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Aktifkan Notifikasi',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: _enableNotifications,
                          activeColor: primaryMaroon,
                          onChanged: (val) {
                            setState(() {
                              _enableNotifications = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Simpan Pengaturan Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
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
                          borderRadius: BorderRadius.circular(14),
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
      bottomNavigationBar: AdminNavBottom(
        currentIndex: 4,
        onTap: (index) {
          Navigator.popUntil(context, (route) => route.isFirst);
          if (index != 4) {
            widget.onNavigateTab?.call(index);
          }
        },
      ),
    );
  }
}
