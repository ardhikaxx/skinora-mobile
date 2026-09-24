import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/backend.dart';

/// Koleksi `activities` — write-only log (immutable bagi client).
class ActivityService {
  ActivityService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('activities');

  /// `actor` selalu diambil dari `users/{uid}.name` agar cocok dengan
  /// Security Rules (`request.resource.data.actor == userData.name`).
  static Future<void> log({
    required String title,
    required String tag,
    required String actor,
    required String actorUid,
  }) async {
    if (!Backend.useFirebase) return;
    if (actorUid.isEmpty) return;
    var resolved = actor.trim();
    try {
      final snap = await _db.collection('users').doc(actorUid).get();
      final name = (snap.data()?['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) resolved = name;
    } catch (_) {
      // fallback: actor yang dipass caller
    }
    if (resolved.isEmpty) return;
    await _col.add({
      'title': title,
      'tag': tag,
      'actor': resolved,
      'actorUid': actorUid,
      'createdBy': actorUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Aktivitas milik user (tampil di Riwayat Aktivitas per-role).
  static Future<List<Map<String, dynamic>>> listMine(String actorUid) async {
    if (!Backend.useFirebase) return const [];
    final snap = await _col
        .where('actorUid', isEqualTo: actorUid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Semua aktivitas (khusus admin — laporan & beranda).
  static Future<List<Map<String, dynamic>>> listAll({int? limit}) async {
    if (!Backend.useFirebase) return const [];
    var q = _col.orderBy('createdAt', descending: true);
    if (limit != null) q = q.limit(limit);
    final snap = await q.get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}
