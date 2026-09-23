import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/backend.dart';

class SpecializationRecord {
  final String id;
  final String name;
  final bool isActive;
  const SpecializationRecord({
    required this.id,
    required this.name,
    required this.isActive,
  });
}

/// Koleksi `specializations` (master data — hanya admin yang menulis).
class SpecializationService {
  SpecializationService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('specializations');

  static Future<List<SpecializationRecord>> list() async {
    if (!Backend.useFirebase) return const [];
    final snap = await _col.get();
    return snap.docs
        .map((d) => SpecializationRecord(
              id: d.id,
              name: (d.data()['name'] as String?) ?? '',
              isActive: (d.data()['isActive'] as bool?) ?? true,
            ))
        .toList();
  }

  /// Hanya nama aktif — untuk dropdown form & chip kategori pengguna.
  static Future<List<String>> listActiveNames() async {
    final all = await list();
    return all.where((s) => s.isActive).map((s) => s.name).toList();
  }

  static Future<void> create(String name) async {
    if (!Backend.useFirebase) return;
    await _col.add({
      'name': name,
      'isActive': true,
      'createdBy': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> rename(String id, String name) async {
    if (!Backend.useFirebase) return;
    await _col.doc(id).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setActive(String id, bool value) async {
    if (!Backend.useFirebase) return;
    await _col.doc(id).update({
      'isActive': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> delete(String id) async {
    if (!Backend.useFirebase) return;
    await _col.doc(id).delete();
  }
}
