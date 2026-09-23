import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_article_model.dart';
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
    return AdminArticleModel(
      id: d.id,
      fsDocId: d.id,
      title: (m['title'] as String?) ?? '',
      category: (m['category'] as String?) ?? '',
      date: (m['date'] as String?) ?? '',
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
    final ref = await _col.add({
      'title': a.title,
      'category': a.category,
      'date': a.date,
      'content': a.content,
      'status': a.status == ArticleStatus.diterbitkan
          ? 'diterbitkan'
          : 'draf',
      'createdBy': 'admin',
      'updatedBy': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return a.copyWith(fsDocId: ref.id, id: ref.id);
  }

  static Future<void> update(AdminArticleModel a) async {
    if (!Backend.useFirebase) return;
    await _col.doc(a.backendId).update({
      'title': a.title,
      'category': a.category,
      'date': a.date,
      'content': a.content,
      'status': a.status == ArticleStatus.diterbitkan
          ? 'diterbitkan'
          : 'draf',
      'updatedBy': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateStatus(
    String id,
    ArticleStatus status,
  ) async {
    if (!Backend.useFirebase) return;
    await _col.doc(id).update({
      'status': status == ArticleStatus.diterbitkan
          ? 'diterbitkan'
          : 'draf',
      'updatedBy': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> delete(String id) async {
    if (!Backend.useFirebase) return;
    await _col.doc(id).delete();
  }
}
