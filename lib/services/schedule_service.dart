import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/backend.dart';
import '../utils/app_dates.dart';

class SlotRecord {
  final String id;
  final String doctorId;
  final String date; // tampil: "Jumat, 28 Agustus 2026"
  final String time; // "09:00 - 09:30"
  final String timeStart;
  final String timeEnd;
  final bool isBooked;
  final String? patientId;
  final String? patientName;

  const SlotRecord({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.time,
    this.timeStart = '',
    this.timeEnd = '',
    this.isBooked = false,
    this.patientId,
    this.patientName,
  });

  /// yyyy-MM-dd bila tanggal tampil bisa diparse, else "".
  String get dateIso {
    final parsed = AppDates.tryParseDisplay(date);
    return parsed == null ? '' : AppDates.iso(parsed);
  }
}

/// Subcollection `users/{doctorUid}/slots`.
class ScheduleService {
  ScheduleService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _slots(String doctorUid) =>
      _db.collection('users').doc(doctorUid).collection('slots');

  static SlotRecord _from(
    String doctorUid,
    DocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final m = d.data() ?? const {};
    return SlotRecord(
      id: d.id,
      doctorId: doctorUid,
      date: (m['date'] as String?) ?? '',
      time: (m['time'] as String?) ?? '',
      timeStart: (m['timeStart'] as String?) ?? '',
      timeEnd: (m['timeEnd'] as String?) ?? '',
      isBooked: (m['isBooked'] as bool?) ?? false,
      patientId: m['patientId'] as String?,
      patientName: m['patientName'] as String?,
    );
  }

  static Future<List<SlotRecord>> listSlots(String doctorUid) async {
    if (!Backend.useFirebase || doctorUid.isEmpty) return const [];
    final snap = await _slots(doctorUid)
        .orderBy('createdAt')
        .get();
    return snap.docs.map((d) => _from(doctorUid, d)).toList();
  }

  static Future<void> addSlot({
    required String doctorUid,
    required String date,
    required String time,
    required String timeStart,
    required String timeEnd,
  }) async {
    if (!Backend.useFirebase) return;
    await _slots(doctorUid).add({
      'date': date,
      'time': time,
      'timeStart': timeStart,
      'timeEnd': timeEnd,
      'isBooked': false,
      'createdBy': doctorUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteSlot(String doctorUid, String slotId) async {
    if (!Backend.useFirebase) return;
    final ref = _slots(doctorUid).doc(slotId);
    final snap = await ref.get();
    if (!snap.exists) return;
    if ((snap.data()?['isBooked'] as bool?) ?? false) {
      throw StateError('Slot sudah dibooking dan tidak dapat dihapus.');
    }
    await ref.delete();
  }

  static Future<void> setAvailability(
    String doctorUid,
    bool isAvailable,
  ) async {
    if (!Backend.useFirebase) return;
    await _db.collection('users').doc(doctorUid).update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
