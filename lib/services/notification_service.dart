import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/backend.dart';

/// Koleksi `notifications`.
/// audience: 'user:{uid}' | 'role:admin'
class NotificationService {
  NotificationService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  static String userAudience(String uid) => 'user:$uid';
  static const String adminAudience = 'role:admin';

  static Future<void> notifyUser({
    required String uid,
    required String title,
    required String description,
    String iconKey = 'bell',
    String type = 'ringkas',
    required String createdBy,
  }) async {
    if (!Backend.useFirebase) return;
    await _col.add({
      'audience': userAudience(uid),
      'title': title,
      'description': description,
      'iconKey': iconKey,
      'type': type,
      'isUnread': true,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> notifyAdmins({
    required String title,
    required String description,
    String iconKey = 'bell',
    String type = 'ringkas',
    required String createdBy,
  }) async {
    if (!Backend.useFirebase) return;
    await _col.add({
      'audience': adminAudience,
      'title': title,
      'description': description,
      'iconKey': iconKey,
      'type': type,
      'isUnread': true,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> listAudience(
    String audience, {
    int? limit,
  }) async {
    if (!Backend.useFirebase) return const [];
    var q = _col
        .where('audience', isEqualTo: audience)
        .orderBy('createdAt', descending: true);
    if (limit != null) q = q.limit(limit);
    final snap = await q.get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  static Future<int> countUnread(String audience) async {
    final items = await listAudience(audience);
    return items.where((n) => n['isUnread'] == true).length;
  }

  /// Hanya field `isUnread` yang boleh diubah penerima.
  static Future<void> markRead(String id) async {
    if (!Backend.useFirebase) return;
    await _col.doc(id).update({'isUnread': false});
  }
}
