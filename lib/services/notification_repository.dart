import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../services/backend.dart';
import '../services/notification_log.dart';
import '../services/notification_payload.dart';

/// Akses Firestore untuk notifikasi persisten per user.
///
/// Path: `users/{recipientUid}/notifications/{notificationId}`.
///
/// Keputusan layout subcollection:
/// * Setiap user hanya punya **satu** koleksi notifikasi miliknya sendiri →
///   Security Rules cukup memvalidasi `{uid}` path terhadap `request.auth.uid`,
///   tidak ada koleksi global yang bisa dibaca lintas role.
/// * Unread badge tinggal `where('isUnread', isEqualTo: true)` pada subcollection
///   sendiri → tidak butuh index komposit.
/// * Pagination `orderBy('createdAt', descending: true)` hanya memakai index
///   single-field bawaan.
///
/// `audience`/`recipientUid` tetap disimpan di tiap dokumen sebagai metadata
/// (dan untuk kebutuhan audit), tetapi **bukan** kunci baca lagi.
class NotificationRepository {
  NotificationRepository._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Subcollection notifikasi milik [uid].
  static CollectionReference<Map<String, dynamic>> _colFor(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('notifications');

  /// Jumlah dokumen per halaman ketika user scroll ke bawah.
  static const int pageSize = 30;

  // ---------------------------------------------------------------------------
  // Create (idempotent)
  // ---------------------------------------------------------------------------
  /// Menulis notifikasi ke subcollection penerima dengan doc ID deterministik.
  ///
  /// Idempotent: bila dokumen dengan ID yang sama sudah ada (retry / dua code
  /// path), tulisan kedua dilewatkan — tidak pernah ada dokumen ganda. Kegagalan
  /// write tidak di-throw agar alur bisnis (booking, chat, verifikasi) tidak
  /// gagal hanya karena notifikasi.
  static Future<void> create(AppNotification notification) async {
    if (!Backend.useFirebase) return;
    if (notification.id.isEmpty) return;
    final recipient = notification.recipientId.trim();
    if (recipient.isEmpty) {
      // `role:admin` legacy / dokumen tanpa penerima perorangan tidak punya
      // path subcollection — lewati (fan-out admin selalu memakai uid asli).
      NotificationLog.error(
        'lewati notifikasi tanpa recipientId',
        notification.id,
      );
      return;
    }

    final ref = _colFor(recipient).doc(notification.id);
    try {
      final existing = await ref.get();
      if (existing.exists) {
        NotificationLog.info('lewati duplikat: ${notification.id}');
        return;
      }
    } on FirebaseException catch (e) {
      NotificationLog.error('cek duplikat ${notification.id}', e.code);
    }

    final data = notification.toFirestore();
    data['title'] = _clamp(notification.title, 200);
    data['body'] = _clamp(notification.body, 1000);
    data['description'] = _clamp(
      notification.description ?? notification.body,
      1000,
    );
    data['createdBy'] = _creatorOf(notification);
    // Sumber waktu: server, bukan clock device.
    data['createdAt'] = FieldValue.serverTimestamp();

    try {
      await ref.set(data);
      NotificationLog.info('dibuat: ${notification.id}');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'already-exists') {
        // Race: dokumen baru saja dibuat oleh jalur lain — bukan error.
        NotificationLog.info('sudah ada (race): ${notification.id}');
        return;
      }
      NotificationLog.error('gagal menulis ${notification.id}', e.code);
    } catch (e) {
      NotificationLog.error('gagal menulis ${notification.id}', e);
    }
  }

  /// Fan-out ke banyak penerima (mis. semua admin / semua pengguna).
  static Future<void> createMany(List<AppNotification> items) async {
    for (final item in items) {
      await create(item);
    }
  }

  static String _clamp(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);

  /// Pembuat dokumen — wajib `request.auth.uid` menurut Security Rules.
  ///
  /// String kosong dianggap tidak ada sehingga jatuh ke sesi login aktif,
  /// lalu ke penerima (kasus notifikasi milik sendiri seperti reminder).
  static String _creatorOf(AppNotification notification) {
    final explicit = (notification.createdBy ?? '').trim();
    if (explicit.isNotEmpty) return explicit;
    return AuthService.uid ?? notification.recipientId;
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------
  static Query<Map<String, dynamic>> _baseQuery(String uid) => _colFor(uid)
      .orderBy('createdAt', descending: true);

  /// Stream realtime halaman pertama (default [NotificationRepository.pageSize]).
  static Stream<List<Map<String, dynamic>>> streamForUser(
    String uid, {
    int limit = pageSize,
  }) {
    if (!Backend.useFirebase || uid.isEmpty) return const Stream.empty();
    return _baseQuery(uid)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(_withId).toList());
  }

  /// Load tambahan ketika user scroll ke bawah (pagination).
  ///
  /// [afterCreatedAt] adalah `createdAt` dokumen terakhir yang sudah tampil
  /// (type `Timestamp`); null → muat dari awal lagi. Dokumen yang sama di-
  /// [limit] awal bisa muncul kembali, jadi caller menggabungkan berdasarkan
  /// `id` (tidak ada duplikat di UI).
  static Future<List<Map<String, dynamic>>> loadOlderForUser(
    String uid, {
    required int limit,
    Object? afterCreatedAt,
  }) async {
    if (!Backend.useFirebase || uid.isEmpty) return const [];
    Query<Map<String, dynamic>> q = _baseQuery(uid);
    if (afterCreatedAt is Timestamp) {
      q = q.startAfter(<Object?>[afterCreatedAt]);
    }
    final snap = await q.limit(limit).get();
    return snap.docs.map(_withId).toList();
  }

  static Map<String, dynamic> _withId(DocumentSnapshot<Map<String, dynamic>> d) {
    return <String, dynamic>{'id': d.id, ...?d.data()};
  }

  /// Ambil satu notifikasi (untuk verifikasi sebelum markRead).
  static Future<Map<String, dynamic>?> byId(String uid, String id) async {
    if (!Backend.useFirebase || uid.isEmpty || id.isEmpty) return null;
    final snap = await _colFor(uid).doc(id).get();
    if (!snap.exists) return null;
    return _withId(snap);
  }

  // ---------------------------------------------------------------------------
  // Unread
  // ---------------------------------------------------------------------------
  /// Stream jumlah unread **realtime**.
  ///
  /// Hanya membaca dokumen yang `isUnread == true` (biasanya sedikit),
  /// bukan seluruh history — badge tidak pernah melakukan full scan.
  /// Karena berada di subcollection milik user, filter equality tunggal sudah
  /// cukup (index single-field bawaan, tanpa index komposit).
  static Stream<int> unreadStreamForUser(String uid) {
    if (!Backend.useFirebase || uid.isEmpty) return const Stream.empty();
    return _colFor(uid)
        .where('isUnread', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  static Future<int> countUnreadForUser(String uid) async {
    if (!Backend.useFirebase || uid.isEmpty) return 0;
    final q = _colFor(uid).where('isUnread', isEqualTo: true);
    try {
      final agg = await q.count().get();
      return agg.count ?? 0;
    } on FirebaseException {
      final snap = await q.get();
      return snap.docs.length;
    }
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------
  /// Tandai sudah dibaca — atomik, memakai server timestamp untuk `readAt`.
  static Future<void> markRead(String uid, String id) async {
    if (!Backend.useFirebase || uid.isEmpty || id.isEmpty) return;
    try {
      await _colFor(uid).doc(id).update(<String, dynamic>{
        'isUnread': false,
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      NotificationLog.info('markRead: $id');
    } on FirebaseException catch (e) {
      NotificationLog.error('markRead gagal', e.code);
    }
  }
}
