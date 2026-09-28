import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/auth_service.dart';
import '../services/backend.dart';
import '../services/notification_service.dart';

/// Warna brand (konsisten dengan halaman pengaturan ketiga role).
const Color _primaryMaroon = Color(0xFFB23A48);
const Color _darkText = Color(0xFF461220);
const Color _subText = Color(0xFF6B7280);
const Color _borderColor = Color(0xFFE5E5EA);

/// Dialog alasan izin notifikasi.
///
/// Mengembalikan `true` bila user menekan "Izinkan". Dialog ditampilkan hanya
/// setelah aplikasi punya sesi login, sehingga konteksnya jelas.
Future<bool> askNotificationPermission(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8EA),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.bellRing,
                    color: _primaryMaroon,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Aktifkan Notifikasi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Supaya Anda tidak melewatkan balasan chat dokter, '
                'konsultasi baru, dan pengingat perawatan kulit, Skinora '
                'perlu izin menampilkan notifikasi di perangkat ini.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: _subText,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: _subText,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Nanti',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryMaroon,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Izinkan',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
  return accepted ?? false;
}

/// Panduan ketika prompt OS tidak lagi bisa ditampilkan (permanen ditolak).
Future<void> showNotificationSettingsGuide(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Notifikasi Belum Aktif',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _darkText,
          ),
        ),
        content: const Text(
          'Android/iOS tidak menampilkan dialog izin lagi karena pernah '
          'ditolak. Buka Pengaturan > Aplikasi > Skinora > Notifikasi, lalu '
          'aktifkan izinnya agar chat dokter dan konsultasi baru muncul.',
          style: TextStyle(fontSize: 13, height: 1.45, color: _subText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(foregroundColor: _primaryMaroon),
            child: const Text(
              'Mengerti',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}

/// Minta izin notifikasi ke OS dan beri panduan bila tetap ditolak.
///
/// Mengembalikan `true` bila izin akhirnya aktif.
Future<bool> requestSystemNotificationPermission(BuildContext context) async {
  final granted = await NotificationService.requestPermission(force: true);
  if (granted) return true;
  if (context.mounted) await showNotificationSettingsGuide(context);
  return false;
}

/// Penjaga izin notifikasi di level aplikasi.
///
/// Dipasang sebagai `MaterialApp.builder` sehingga begitu user punya sesi
/// (login baru atau sesi berlanjut) aplikasi langsung meminta izin notifikasi
/// satu kali — inilah jalur yang benar-benar memunculkan dialog OS, karena
/// permintaan dari `main()` sebelum frame pertama bisa diabaikan sistem.
class NotificationPermissionGate extends StatefulWidget {
  const NotificationPermissionGate({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  /// Navigator root `MaterialApp` — dialog ditampilkan di atas halaman aktif.
  final GlobalKey<NavigatorState> navigatorKey;

  final Widget child;

  @override
  State<NotificationPermissionGate> createState() =>
      _NotificationPermissionGateState();
}

class _NotificationPermissionGateState extends State<NotificationPermissionGate>
    with WidgetsBindingObserver {
  StreamSubscription<User?>? _authSub;
  bool _dialogVisible = false;
  bool _checking = false;
  bool _sessionDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Minta izin langsung begitu aplikasi pertama kali dibuka (landing di /login ataupun lainnya)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_promptIfPermissionMissing());
    });

    _authSub = AuthService.authStateChanges.listen((User? user) {
      if (user != null) {
        unawaited(_promptIfPermissionMissing());
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Sinkronkan status izin setelah user kembali dari system settings.
      unawaited(NotificationService.refreshPermissionStatus());
    }
  }

  Future<void> _promptIfPermissionMissing() async {
    if (_dialogVisible || _checking || _sessionDismissed) return;
    _checking = true;
    try {
      final granted = await NotificationService.refreshPermissionStatus();
      if (granted) return;

      // Beri waktu sejenak agar route & context frame pertama mount sempurna
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      final navContext = widget.navigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;

      _dialogVisible = true;
      final accepted = await askNotificationPermission(navContext);
      _dialogVisible = false;

      if (!mounted) return;

      if (accepted) {
        if (navContext.mounted) {
          await requestSystemNotificationPermission(navContext);
        } else {
          await NotificationService.requestPermission(force: true);
        }
        await NotificationService.markPermissionDialogAsked();
      } else {
        // User menekan "Nanti": lewati prompt selama sesi ini agar tidak mengganggu navigasi
        _sessionDismissed = true;
      }
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Baris status izin notifikasi OS untuk halaman Pengaturan ketiga role.
///
/// Menampilkan status sebenarnya (bukan sekadar toggle aplikasi) sehingga user
/// tahu ketika notifikasi diblokir di pengaturan sistem, lengkap dengan tombol
/// "Izinkan" untuk meminta ulang.
class SystemNotificationPermissionTile extends StatefulWidget {
  const SystemNotificationPermissionTile({super.key});

  @override
  State<SystemNotificationPermissionTile> createState() =>
      _SystemNotificationPermissionTileState();
}

class _SystemNotificationPermissionTileState
    extends State<SystemNotificationPermissionTile> {
  @override
  void initState() {
    super.initState();
    if (Backend.useFirebase) {
      unawaited(NotificationService.refreshPermissionStatus());
    }
  }

  Future<void> _handleTap() async {
    final granted = await NotificationService.refreshPermissionStatus();
    if (!mounted) return;
    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi sistem sudah aktif di perangkat ini'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final accepted = await askNotificationPermission(context);
    if (!mounted || !accepted) return;
    await requestSystemNotificationPermission(context);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NotificationService.permissionGranted,
      builder: (context, granted, _) {
        return Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: granted ? Colors.white : const Color(0xFFFFF6F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: granted ? _borderColor : const Color(0xFFF3C9C9),
            ),
          ),
          child: Row(
            children: [
              Icon(
                granted ? LucideIcons.bellRing : LucideIcons.bellOff,
                size: 18,
                color: granted ? const Color(0xFF555555) : _primaryMaroon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Izin Notifikasi Sistem',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      granted
                          ? 'Aktif — chat dokter & konsultasi baru akan diberitahukan.'
                          : 'Belum aktif — notifikasi chat & konsultasi tidak akan muncul.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: granted ? _subText : _primaryMaroon,
                        fontWeight:
                            granted ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!granted) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _handleTap,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _primaryMaroon,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Izinkan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
