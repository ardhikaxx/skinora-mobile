import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/user_service.dart';

class PengaturanPenggunaPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const PengaturanPenggunaPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<PengaturanPenggunaPage> createState() => _PengaturanPenggunaPageState();
}

class _PengaturanPenggunaPageState extends State<PengaturanPenggunaPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color labelColor = Color(0xFF555555);
  static const Color borderColor = Color(0xFFE5E5EA);
  static const Color cardBorder = Color(0xFFEEEEEE);

  bool _notificationsEnabled = true;
  late final TextEditingController _morningReminderController;
  late final TextEditingController _eveningReminderController;

  @override
  void initState() {
    super.initState();
    _morningReminderController = TextEditingController();
    _eveningReminderController = TextEditingController();
    _loadFromBackend();
  }

  /// Pengaturan milik pengguna dari Firestore. Tanpa Firebase, seed demo
  /// tetap dipakai agar UI/tes tidak berubah.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final profile = await UserService.loadByUid(uid);
      if (!mounted) return;
      setState(() {
        if (profile == null) {
          _notificationsEnabled = true;
          _morningReminderController.text = '';
          _eveningReminderController.text = '';
          return;
        }
        _notificationsEnabled = profile.notificationsEnabled;
        _morningReminderController.text = profile.morningReminder;
        _eveningReminderController.text = profile.eveningReminder;
      });
    } catch (_) {
      // Query gagal → biarkan nilai default yang aman.
    }
  }

  @override
  void dispose() {
    _morningReminderController.dispose();
    _eveningReminderController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryMaroon,
              onPrimary: Colors.white,
              onSurface: darkText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      setState(() {
        controller.text = '$hour:$minute';
      });
    }
  }

  Future<void> _saveSettings() async {
    if (Backend.useFirebase && AuthService.uid != null) {
      try {
        await UserService.updateSettings(
          AuthService.uid!,
          notificationsEnabled: _notificationsEnabled,
          morningReminder: _morningReminderController.text.trim(),
          eveningReminder: _eveningReminderController.text.trim(),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan berhasil disimpan'),
        backgroundColor: primaryMaroon,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Back button + Title "Pengaturan"
            Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
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
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Pengaturan',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20.0,
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

            // Main Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 1. NOTIFIKASI Card
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
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
                        const Text(
                          'NOTIFIKASI',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Switch Container Box matching mockup
                        Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: borderColor,
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
                                    fontWeight: FontWeight.w600,
                                    color: darkText,
                                  ),
                                ),
                              ),

                              // Pill Toggle Switch matching image
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _notificationsEnabled = !_notificationsEnabled;
                                  });
                                },
                                behavior: HitTestBehavior.opaque,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 48,
                                  height: 28,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: _notificationsEnabled
                                        ? primaryMaroon
                                        : const Color(0xFFD1D5DB),
                                  ),
                                  child: AnimatedAlign(
                                    duration: const Duration(milliseconds: 200),
                                    alignment: _notificationsEnabled
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 2,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
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

                  const SizedBox(height: 18),

                  // 2. PENGINGAT Card
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
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
                        const Text(
                          'PENGINGAT',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Subtitle: PENGINGAT PAGI
                        const Text(
                          'PENGINGAT PAGI',
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Morning time box
                        GestureDetector(
                          onTap: () => _pickTime(_morningReminderController),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: borderColor,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.clock,
                                  size: 18,
                                  color: Color(0xFF555555),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _morningReminderController.text.isEmpty
                                        ? ''
                                        : _morningReminderController.text,
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w500,
                                      color: darkText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Subtitle: PENGINGAT MALAM
                        const Text(
                          'PENGINGAT MALAM',
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Evening time box
                        GestureDetector(
                          onTap: () => _pickTime(_eveningReminderController),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: borderColor,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.clock,
                                  size: 18,
                                  color: Color(0xFF555555),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _eveningReminderController.text.isEmpty
                                        ? ''
                                        : _eveningReminderController.text,
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w500,
                                      color: darkText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Simpan Pengaturan Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
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
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMaroon,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: primaryMaroon.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PenggunaNavBottom(
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
