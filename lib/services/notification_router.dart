import 'package:flutter/material.dart';

import '../pages/dokter/ruang_chat_dokter_page.dart';
import '../pages/pengguna/ruang_konsultasi_page.dart';
import '../services/consultation_service.dart';
import '../services/notification_log.dart';
import '../services/notification_payload.dart';

/// Permintaan pergantian tab shell yang dikirim oleh [NotificationRouter].
class ShellTabRequest {
  const ShellTabRequest({required this.shellRoute, required this.index});

  final String shellRoute;
  final int index;
}

enum NotificationDestinationKind {
  /// Kembali ke shell role lalu pindah tab.
  shell,

  /// Buka named route (halaman tanpa argumen).
  page,

  /// Buka ruang konsultasi/chat dengan `entityId`.
  room,
}

class NotificationDestination {
  const NotificationDestination({
    required this.kind,
    required this.shellRoute,
    required this.tabIndex,
    this.pageRoute,
    this.entityId,
  });

  final NotificationDestinationKind kind;
  final String shellRoute;
  final int tabIndex;
  final String? pageRoute;
  final String? entityId;
}

/// Resolver deep-link notifikasi.
///
/// Tidak ada navigasi yang di-hardcode di Firebase Messaging handler —
/// semua payload diarahkan ke sini agar logika tujuan terpusat dan bisa
/// diuji tanpa Firebase.
class NotificationRouter {
  NotificationRouter._();

  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Shell (beranda) mendengarkan ValueNotifier ini untuk ganti tab.
  static final ValueNotifier<ShellTabRequest?> shellTabRequest =
      ValueNotifier<ShellTabRequest?>(null);

  /// Payload yang diterima sebelum user login / sebelum shell siap.
  static AppNotification? _pendingIntent;

  static AppNotification? get pendingIntent => _pendingIntent;

  static void configure({required GlobalKey<NavigatorState> navigatorKey}) {
    _navigatorKey = navigatorKey;
  }

  static void setPendingIntent(AppNotification? notification) {
    _pendingIntent = notification;
  }

  // ---------------------------------------------------------------------------
  // Resolve
  // ---------------------------------------------------------------------------
  /// Named route yang bisa dibuka tanpa argumen.
  static const Set<String> _pageRoutes = <String>{
    NotificationPageRoute.penggunaNotifikasi,
    NotificationPageRoute.penggunaRiwayatKonsultasi,
    NotificationPageRoute.penggunaEdukasi,
    NotificationPageRoute.dokterNotifikasi,
    NotificationPageRoute.dokterRiwayat,
    NotificationPageRoute.adminNotifikasi,
    NotificationPageRoute.adminDokter,
  };

  static String roleOf(AppNotification n) {
    if (NotificationRole.all.contains(n.audienceRole)) return n.audienceRole;
    final route = n.route ?? '';
    if (route.startsWith('/admin')) return NotificationRole.admin;
    if (route.startsWith('/dokter')) return NotificationRole.dokter;
    return NotificationRole.pengguna;
  }

  /// Tujuan navigasi untuk sebuah payload (murni fungsi — aman diuji).
  static NotificationDestination resolve(AppNotification n) {
    final role = roleOf(n);
    final byType = _byType(role, n.type, n.entityId);

    // 1. Type yang selalu punya tujuan tetap (ruang chat) menang.
    if (byType != null &&
        byType.kind == NotificationDestinationKind.room) {
      return byType;
    }

    // 2. Route eksplisit dari payload bila memang route valid tanpa argumen.
    final route = n.route;
    if (route != null && _pageRoutes.contains(route)) {
      return NotificationDestination(
        kind: NotificationDestinationKind.page,
        shellRoute: shellOf(role),
        tabIndex: n.targetTab ?? 0,
        pageRoute: route,
      );
    }

    // 3. Pemetaan type -> tujuan.
    if (byType != null) return byType;

    // 4. Fallback aman: beranda role.
    return NotificationDestination(
      kind: NotificationDestinationKind.shell,
      shellRoute: shellOf(role),
      tabIndex: 0,
    );
  }

  static String shellOf(String role) {
    switch (role) {
      case NotificationRole.admin:
        return NotificationPageRoute.adminShell;
      case NotificationRole.dokter:
        return NotificationPageRoute.dokterShell;
      default:
        return NotificationPageRoute.penggunaShell;
    }
  }

  static NotificationDestination? _byType(
    String role,
    String type,
    String? entityId,
  ) {
    NotificationDestination room(String shell) => NotificationDestination(
          kind: NotificationDestinationKind.room,
          shellRoute: shell,
          tabIndex: 0,
          entityId: entityId,
        );

    NotificationDestination shell(int tab) => NotificationDestination(
          kind: NotificationDestinationKind.shell,
          shellRoute: shellOf(role),
          tabIndex: tab,
        );

    NotificationDestination page(String route) => NotificationDestination(
          kind: NotificationDestinationKind.page,
          shellRoute: shellOf(role),
          tabIndex: 0,
          pageRoute: route,
        );

    if (role == NotificationRole.pengguna) {
      switch (type) {
        case NotificationType.consultationStarted:
        case NotificationType.consultationMessage:
          return room(NotificationPageRoute.penggunaShell);
        case NotificationType.consultationCompleted:
        case NotificationType.bookingCreated:
        case NotificationType.bookingConfirmed:
        case NotificationType.bookingCancelled:
          return page(NotificationPageRoute.penggunaRiwayatKonsultasi);
        case NotificationType.articlePublished:
          return page(NotificationPageRoute.penggunaEdukasi);
        case NotificationType.patientSuspended:
        case NotificationType.patientReactivated:
          return shell(NotificationTab.penggunaProfil);
        case NotificationType.system:
        case NotificationType.reminder:
          return shell(0);
      }
      return null;
    }

    if (role == NotificationRole.dokter) {
      switch (type) {
        case NotificationType.consultationMessage:
          return room(NotificationPageRoute.dokterShell);
        case NotificationType.consultationCompleted:
          return page(NotificationPageRoute.dokterRiwayat);
        case NotificationType.consultationStarted:
          return shell(NotificationTab.dokterChat);
        case NotificationType.bookingCreated:
        case NotificationType.bookingConfirmed:
        case NotificationType.bookingCancelled:
        case NotificationType.scheduleCreated:
        case NotificationType.scheduleChanged:
        case NotificationType.scheduleCancelled:
          return shell(NotificationTab.dokterJadwal);
        case NotificationType.doctorVerified:
        case NotificationType.doctorRejected:
        case NotificationType.doctorSuspended:
        case NotificationType.doctorReactivated:
          return shell(NotificationTab.dokterProfil);
        case NotificationType.system:
          return shell(0);
      }
      return null;
    }

    // Admin
    switch (type) {
      case NotificationType.doctorVerificationPending:
        return shell(NotificationTab.adminDokter);
      case NotificationType.system:
      case NotificationType.reminder:
        return shell(0);
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Navigate
  // ---------------------------------------------------------------------------
  static Future<void> open(AppNotification notification) async {
    final nav = _navigatorKey?.currentState;
    if (nav == null) {
      // Navigator belum siap (cold start dari notification tray).
      _pendingIntent = notification;
      NotificationLog.info('pending intent disimpan: ${notification.id}');
      return;
    }
    final dest = resolve(notification);
    NotificationLog.info(
      'tap ${notification.type} -> ${dest.kind.name} '
      '${dest.pageRoute ?? dest.shellRoute}#${dest.tabIndex}',
    );

    switch (dest.kind) {
      case NotificationDestinationKind.room:
        _ensureShell(nav, dest.shellRoute);
        await _openRoom(nav, notification, dest);
        break;
      case NotificationDestinationKind.page:
        _ensureShell(nav, dest.shellRoute);
        final route = dest.pageRoute;
        if (route != null) nav.pushNamed(route);
        break;
      case NotificationDestinationKind.shell:
        _ensureShell(nav, dest.shellRoute);
        _requestTab(dest.shellRoute, dest.tabIndex);
        break;
    }
  }

  static void _requestTab(String shellRoute, int index) {
    // Reset dulu agar ValueNotifier selalu notify walaupun nilai sama.
    shellTabRequest.value = null;
    shellTabRequest.value = ShellTabRequest(shellRoute: shellRoute, index: index);
  }

  /// Pastikan shell role berada di paling atas; bila tidak ada di stack,
  /// bangun ulang shell (user sudah login — diverifikasi NotificationService).
  static void _ensureShell(NavigatorState nav, String shellRoute) {
    var reachedShell = false;
    nav.popUntil((route) {
      if (route.settings.name == shellRoute) {
        reachedShell = true;
        return true;
      }
      return route.isFirst;
    });
    if (!reachedShell) {
      nav.pushNamedAndRemoveUntil(shellRoute, (route) => false);
    }
  }

  static Future<void> _openRoom(
    NavigatorState nav,
    AppNotification notification,
    NotificationDestination dest,
  ) async {
    final id = dest.entityId ?? notification.consultationId;
    if (id == null || id.isEmpty) return;

    Map<String, dynamic>? consult;
    try {
      consult = await ConsultationService.byId(id);
    } catch (e) {
      NotificationLog.error('gagal memuat konsultasi $id', e);
    }

    if (!nav.mounted) return;

    if (roleOf(notification) == NotificationRole.dokter) {
      final date = (consult?['scheduleDate'] as String?) ?? '';
      final time = (consult?['scheduleTime'] as String?) ?? '';
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => RuangChatDokterPage(
            consultationId: id,
            patientName: (consult?['patientName'] as String?) ?? '',
            dateTime: date.isEmpty ? time : '$date • $time',
          ),
        ),
      );
      return;
    }

    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => RuangKonsultasiPenggunaPage(
          consultationId: id,
          doctorId: consult?['doctorId'] as String?,
          doctorName: (consult?['doctorName'] as String?) ?? '',
          status: (consult?['status'] as String?) ?? '',
        ),
      ),
    );
  }
}
