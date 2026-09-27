import 'package:flutter/foundation.dart';

/// Logger kecil khusus notifikasi.
///
/// Aturan privasi:
/// * token FCM hanya dicetak 8 karakter pertama (bukan token utuh)
/// * isi chat / data medis tidak pernah di-log
/// * log verbose hanya aktif ketika `kDebugMode`
class NotificationLog {
  NotificationLog._();

  static const String _tag = 'SkinoraNotif';

  static void info(String message) {
    debugPrint('$_tag: $message');
  }

  static void error(String message, Object? error) {
    debugPrint('$_tag ERROR: $message${error == null ? '' : ' — $error'}');
  }

  /// Aman untuk production: hanya menampilkan prefiks token.
  static String shortToken(String? token) {
    if (token == null || token.isEmpty) return '(none)';
    if (token.length <= 12) return '***';
    return '${token.substring(0, 8)}…(${token.length})';
  }
}
