import 'dart:async';

import 'package:flutter/foundation.dart';

import 'backend.dart';
import 'notification_repository.dart';

/// State unread badge yang dibagikan seluruh role.
///
/// Satu stream Firestore per user (`users/{uid}/notifications`) dipakai bersama
/// oleh semua halaman (beranda, notifikasi) sehingga tidak ada listener ganda
/// untuk user yang sama. Stream di-reset ketika user logout lalu dibuat ulang
/// pada login berikutnya.
class NotificationController {
  NotificationController._();

  static final Map<String, _UnreadEntry> _entries = <String, _UnreadEntry>{};

  /// Listener unread realtime milik [uid].
  ///
  /// Nilai pertama dikirim segera setelah snapshot pertama Firestore tiba,
  /// jadi badge selalu sinkron tanpa refresh manual.
  static ValueListenable<int> unread(String uid) {
    if (!Backend.useFirebase || uid.isEmpty) return ValueNotifier<int>(0);
    final entry = _entries.putIfAbsent(uid, () => _UnreadEntry(uid));
    entry.ensureListening();
    return entry.notifier;
  }

  /// Dipanggil ketika user logout / sesi berakhir.
  ///
  /// Listener dibatalkan dan nilai direset ke 0; notifier tidak di-dispose
  /// agar halaman yang masih ter-mount tidak melempar error saat removeListener.
  static void reset() {
    for (final entry in _entries.values) {
      entry.cancel();
    }
  }

  /// Jumlah stream yang sedang aktif (untuk debug/test).
  static int get activeListenerCount =>
      _entries.values.where((e) => e.subscription != null).length;

  /// Hapus seluruh entry (dipakai test).
  static void debugClear() {
    for (final entry in _entries.values) {
      entry.cancel();
    }
    _entries.clear();
  }
}

class _UnreadEntry {
  _UnreadEntry(this.uid);

  final String uid;
  final ValueNotifier<int> notifier = ValueNotifier<int>(0);
  StreamSubscription<int>? subscription;

  void ensureListening() {
    if (subscription != null) return;
    subscription = NotificationRepository.unreadStreamForUser(uid).listen(
      (int value) => notifier.value = value,
      onError: (Object error) {
        // Jangan ubah nilai badge saat query gagal (offline / rules).
        debugPrint('unread stream error: $error');
      },
    );
  }

  void cancel() {
    subscription?.cancel();
    subscription = null;
    notifier.value = 0;
  }
}
