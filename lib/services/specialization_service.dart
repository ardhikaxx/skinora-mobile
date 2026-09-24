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
    final trimmed = name.trim();
    final dup = await _col.where('name', isEqualTo: trimmed).limit(1).get();
    if (dup.docs.isNotEmpty) {
      throw StateError('Spesialisasi "$trimmed" sudah ada.');
    }
    await _col.add({
      'name': trimmed,
      'isActive': true,
      'createdBy': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> rename(String id, String name) async {
    if (!Backend.useFirebase) return;
    final trimmed = name.trim();
    final dup = await _col
        .where('name', isEqualTo: trimmed)
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty && dup.docs.first.id != id) {
      throw StateError('Spesialisasi "$trimmed" sudah ada.');
    }
    // Cascade: perbarui nama denormalisasi pada dokter bila rename.
    final snap = await _col.doc(id).get();
    final oldName = (snap.data()?['name'] as String?) ?? '';
    await _col.doc(id).update({
      'name': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (oldName.isNotEmpty && oldName != trimmed && Backend.useFirebase) {
      final doctors = await _db
          .collection('users')
          .where('role', isEqualTo: 'dokter')
          .where('specialization', isEqualTo: oldName)
          .get();
      final batch = _db.batch();
      for (final d in doctors.docs) {
        batch.update(d.reference, {
          'specialization': trimmed,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (doctors.docs.isNotEmpty) await batch.commit();
    }
  }

  static Future<void> setActive(String id, bool value) async {
    if (!Backend.useFirebase) return;
    await _col.doc(id).update({
      'isActive': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hapus hanya bila tidak direferensikan dokter (integritas referensial).
  static Future<void> delete(String id) async {
    if (!Backend.useFirebase) return;
    final snap = await _col.doc(id).get();
    final name = (snap.data()?['name'] as String?) ?? '';
    if (name.isNotEmpty) {
      final doctors = await _db
          .collection('users')
          .where('role', isEqualTo: 'dokter')
          .where('specialization', isEqualTo: name)
          .limit(1)
          .get();
      if (doctors.docs.isNotEmpty) {
        throw StateError(
          'Spesialisasi "$name" masih digunakan dokter. Nonaktifkan saja.',
        );
      }
    }
    await _col.doc(id).delete();
  }
}
