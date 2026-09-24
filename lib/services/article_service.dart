import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/admin_article_model.dart';
import '../services/activity_service.dart';
import '../services/backend.dart';

/// Koleksi `articles` — admin menulis, pengguna membaca yang terbit.
class ArticleService {
  ArticleService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('articles');

  static AdminArticleModel fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    final statusRaw = (m['status'] as String?) ?? 'draf';
    final publishedAt = m['publishedAt'];
    String date = (m['date'] as String?) ?? '';
    if (date.isEmpty && publishedAt is Timestamp) {
      final wib = DateTime.fromMillisecondsSinceEpoch(
        publishedAt.millisecondsSinceEpoch,
      ).add(const Duration(hours: 7));
      date = wib.toIso8601String().substring(0, 10);
    }
    return AdminArticleModel(
      id: d.id,
      fsDocId: d.id,
      title: (m['title'] as String?) ?? '',
      category: (m['category'] as String?) ?? '',
      date: date,
      content: (m['content'] as String?) ?? '',
      status: statusRaw == 'diterbitkan'
          ? ArticleStatus.diterbitkan
          : ArticleStatus.draf,
    );
  }

  /// Semua artikel (admin).
  static Future<List<AdminArticleModel>> listAll() async {
    if (!Backend.useFirebase) return const [];
    final snap = await _col.orderBy('createdAt', descending: true).get();
    return snap.docs.map(fromDoc).toList();
  }

  /// Hanya yang diterbitkan (pengguna).
  static Future<List<AdminArticleModel>> listPublished() async {
    if (!Backend.useFirebase) return const [];
    final snap = await _col
        .where('status', isEqualTo: 'diterbitkan')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(fromDoc).toList();
  }

  static Future<AdminArticleModel> create(AdminArticleModel a) async {
    if (!Backend.useFirebase) return a;
    final published = a.status == ArticleStatus.diterbitkan;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
    final ref = await _col.add({
      'title': a.title,
      'category': a.category,
      'date': a.date,
      'content': a.content,
      'status': published ? 'diterbitkan' : 'draf',
      if (published) 'publishedAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      'updatedBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _log(
      published
          ? 'Membuat & menerbitkan artikel "${a.title}"'
          : 'Membuat draf artikel "${a.title}"',
      uid,
    );
    return a.copyWith(fsDocId: ref.id, id: ref.id);
  }

  static Future<void> update(AdminArticleModel a) async {
    if (!Backend.useFirebase) return;
    final nowPublished = a.status == ArticleStatus.diterbitkan;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
    await _col.doc(a.backendId).update({
      'title': a.title,
      'category': a.category,
      'date': a.date,
      'content': a.content,
      'status': nowPublished ? 'diterbitkan' : 'draf',
      if (nowPublished) 'publishedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _log('Mengedit artikel "${a.title}"', uid);
  }

  static Future<void> updateStatus(
    String id,
    ArticleStatus status, {
    String? title,
  }) async {
    if (!Backend.useFirebase) return;
    final published = status == ArticleStatus.diterbitkan;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
    await _col.doc(id).update({
      'status': published ? 'diterbitkan' : 'draf',
      if (published) 'publishedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final label = title ?? 'artikel';
    await _log(
      published ? 'Mempublikasikan $label' : 'Menolak terbit $label',
      uid,
    );
  }

  static Future<void> delete(String id, {String? title}) async {
    if (!Backend.useFirebase) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
    await _col.doc(id).delete();
    await _log('Menghapus artikel "${title ?? id}"', uid);
  }

  static Future<void> _log(String title, String uid) async {
    try {
      // Rules: actor harus = users/{uid}.name persis.
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final name = (userDoc.data()?['name'] as String?) ?? '';
      if (name.isEmpty) return;
      await ActivityService.log(
        title: title,
        tag: 'Artikel',
        actor: name,
        actorUid: uid,
      );
    } catch (_) {
      // Activity log tidak boleh menjatuhkan operasi utama.
    }
  }
}
