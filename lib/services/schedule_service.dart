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

  /// Stream realtime slot dokter — daftar selalu sinkron antar klien.
  static Stream<List<SlotRecord>> slotStream(String doctorUid) {
    if (!Backend.useFirebase || doctorUid.isEmpty) {
      return const Stream.empty();
    }
    return _slots(doctorUid).orderBy('createdAt').snapshots().map(
          (snap) => snap.docs.map((d) => _from(doctorUid, d)).toList(),
        );
  }

  /// Slot kosong saja (kompatibel rules read: `isBooked != true` untuk
  /// non-owner — query harus memfilter agar rules dapat memverifikasi).
  static Stream<List<SlotRecord>> bookableSlotStream(String doctorUid) {
    if (!Backend.useFirebase || doctorUid.isEmpty) {
      return const Stream.empty();
    }
    return _slots(doctorUid)
        .where('isBooked', isEqualTo: false)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => _from(doctorUid, d)).toList(),
        );
  }

  /// Slot layak booking: belum diambil, punya tanggal, belum lewat (WIB).
  static List<SlotRecord> bookableSlots(Iterable<SlotRecord> slots) =>
      slots
          .where(
            (s) =>
                !s.isBooked &&
                s.date.isNotEmpty &&
                !AppDates.isPastSlot(
                  dateIso: s.dateIso,
                  timeEnd: s.timeEnd,
                  timeStart: s.timeStart,
                ),
          )
          .toList();

  /// Tambah slot — mengembalikan document id Firestore.
  static Future<String> addSlot({
    required String doctorUid,
    required String date,
    required String time,
    required String timeStart,
    required String timeEnd,
  }) async {
    if (!Backend.useFirebase) return '';
    final normalizedStart = AppDates.formatHm(timeStart);
    final normalizedEnd = AppDates.formatHm(timeEnd);
    if (AppDates.isPastSlot(
      dateIso: AppDates.iso(AppDates.tryParseDisplay(date) ?? DateTime(2000)),
      timeEnd: normalizedEnd,
      timeStart: normalizedStart,
    )) {
      // Tanggal belum tentu parse; hanya tolak bila parse dan lampau.
      final parsed = AppDates.tryParseDisplay(date);
      if (parsed != null &&
          AppDates.isPastSlot(
            dateIso: AppDates.iso(parsed),
            timeEnd: normalizedEnd,
            timeStart: normalizedStart,
          )) {
        throw StateError('Tidak dapat menambah slot di masa lalu.');
      }
    }

    // Cegah duplikat/overlap pada tanggal sama.
    final existing = await _slots(doctorUid)
        .where('date', isEqualTo: date)
        .get();
    final newStart = _minutes(normalizedStart);
    final newEnd = _minutes(normalizedEnd);
    if (newEnd <= newStart) {
      throw StateError('Jam selesai harus setelah jam mulai.');
    }
    for (final d in existing.docs) {
      final m = d.data();
      final s = _minutes(AppDates.formatHm((m['timeStart'] as String?) ?? ''));
      final e = _minutes(AppDates.formatHm((m['timeEnd'] as String?) ?? ''));
      if (newStart < e && newEnd > s) {
        throw StateError('Slot berbenturan dengan jadwal yang sudah ada.');
      }
    }

    final ref = await _slots(doctorUid).add({
      'date': date,
      'time': time,
      'timeStart': normalizedStart,
      'timeEnd': normalizedEnd,
      'isBooked': false,
      'createdBy': doctorUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static int _minutes(String hm) {
    final parts = hm.split('.');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
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
