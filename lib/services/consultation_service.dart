import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../services/activity_service.dart';
import '../services/backend.dart';
import '../services/notification_service.dart';

/// Entity konsultasi + chat + booking.
///
/// Booking dua fase agar kompatibel Security Rules (rules menilai get()
/// terhadap state sebelum transaksi):
/// 1) transaksi: book slot (anti double-book);
/// 2) batch: buat consultation (id deterministik = slotId) + care_link;
/// 3) bila (2) gagal → unbook slot (hanya bila consultation belum ada).
class ConsultationService {
  ConsultationService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('consultations');
  static CollectionReference<Map<String, dynamic>> get _links =>
      _db.collection('care_links');

  static String linkId(String patientId, String doctorId) =>
      '${patientId}_$doctorId';

  // ---------------------------------------------------------------------------
  // Booking
  // ---------------------------------------------------------------------------
  static Future<String> book({
    required String doctorUid,
    required String doctorName,
    required String specialization,
    required String slotId,
    required String scheduleDate,
    required String scheduleTime,
    required UserProfile patient,
    required String dateIso,
    required String timeStart,
    required String timeEnd,
  }) async {
    if (!Backend.useFirebase) {
      return 'demo-consultation';
    }
    // ID deterministik: satu konsultasi per slot (mencegah double dokumen).
    final consultationRef = _col.doc(slotId);
    final slotRef = _db
        .collection('users')
        .doc(doctorUid)
        .collection('slots')
        .doc(slotId);
    final linkRef = _links.doc(linkId(patient.uid, doctorUid));
    final now = FieldValue.serverTimestamp();

    // Fase 1 — book slot secara atomik (tolak bila sudah diambil lain).
    await _db.runTransaction((tx) async {
      final slotSnap = await tx.get(slotRef);
      if (!slotSnap.exists ||
          ((slotSnap.data()?['isBooked'] as bool?) ?? false)) {
        throw StateError('Slot sudah dibooking oleh pasien lain.');
      }
      if (slotSnap.data()?['patientId'] != null &&
          slotSnap.data()?['patientId'] != patient.uid) {
        throw StateError('Slot sudah dibooking oleh pasien lain.');
      }
      tx.update(slotRef, {
        'isBooked': true,
        'patientId': patient.uid,
        'patientName': patient.name,
        'updatedAt': now,
      });
    });

    // Fase 2 — consultation + care_link.
    try {
      final batch = _db.batch();
      batch.set(consultationRef, {
        'patientId': patient.uid,
        'patientName': patient.name,
        'doctorId': doctorUid,
        'doctorName': doctorName,
        'specialization': specialization,
        'scheduleDate': scheduleDate,
        'dateIso': dateIso,
        'scheduleTime': scheduleTime,
        'timeStart': timeStart,
        'timeEnd': timeEnd,
        'status': 'terjadwal',
        'diagnosis': null,
        'notes': null,
        'slotId': slotId,
        'createdBy': patient.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(linkRef, {
        'patientId': patient.uid,
        'doctorId': doctorUid,
        'slotId': slotId,
        'createdBy': patient.uid,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
    } catch (_) {
      // Kompensasi: lepas booking bila consultation gagal dibuat.
      try {
        final consultSnap = await consultationRef.get();
        if (!consultSnap.exists) {
          await slotRef.update({
            'isBooked': false,
            'patientId': FieldValue.delete(),
            'patientName': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {
        // best-effort
      }
      rethrow;
    }

    await ActivityService.log(
      title: 'Booking konsultasi dengan $doctorName',
      tag: 'Booking',
      actor: patient.name,
      actorUid: patient.uid,
    );
    await NotificationService.notifyUser(
      uid: doctorUid,
      title: 'Booking Baru',
      description:
          '${patient.name} memesan konsultasi untuk jadwal $scheduleDate $scheduleTime',
      iconKey: 'calendar',
      type: 'booking',
      createdBy: patient.uid,
    );
    await NotificationService.notifyUser(
      uid: patient.uid,
      title: 'Booking Berhasil',
      description:
          'Konsultasi dengan $doctorName pada $scheduleDate $scheduleTime telah dijadwalkan.',
      iconKey: 'calendar',
      type: 'booking',
      createdBy: patient.uid,
    );
    return consultationRef.id;
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> listForDoctor(
    String doctorUid, {
    bool includeFinished = false,
  }) async {
    if (!Backend.useFirebase || doctorUid.isEmpty) return const [];
    final snap = await _col
        .where('doctorId', isEqualTo: doctorUid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .where((m) =>
            includeFinished || (m['status'] as String?) != 'selesai')
        .toList();
  }

  static Future<List<Map<String, dynamic>>> listForPatient(
    String patientUid,
  ) async {
    if (!Backend.useFirebase || patientUid.isEmpty) return const [];
    final snap = await _col
        .where('patientId', isEqualTo: patientUid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Stream konsultasi aktif dokter (realtime — booking baru langsung muncul).
  static Stream<List<Map<String, dynamic>>> streamForDoctor(String doctorUid) {
    if (!Backend.useFirebase || doctorUid.isEmpty) {
      return const Stream.empty();
    }
    return _col
        .where('doctorId', isEqualTo: doctorUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => {'id': d.id, ...d.data()})
              .where((m) => (m['status'] as String?) != 'selesai')
              .toList(),
        );
  }

  /// Stream konsultasi pasien (status terjadwal/berlangsung/selesai live).
  static Stream<List<Map<String, dynamic>>> streamForPatient(
    String patientUid,
  ) {
    if (!Backend.useFirebase || patientUid.isEmpty) {
      return const Stream.empty();
    }
    return _col
        .where('patientId', isEqualTo: patientUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Stream 1 dokumen konsultasi (badge status live di ruang chat).
  static Stream<Map<String, dynamic>?> streamById(String id) {
    if (!Backend.useFirebase || id.isEmpty) return const Stream.empty();
    return _col.doc(id).snapshots().map(
          (s) => s.exists ? {'id': s.id, ...s.data()!} : null,
        );
  }

  static Future<int> countAll() async {
    if (!Backend.useFirebase) return 0;
    try {
      final snap = await _col.count().get();
      return snap.count ?? 0;
    } on FirebaseException {
      final snap = await _col.get();
      return snap.docs.length;
    }
  }

  /// Jumlah konsultasi dengan status tertentu (dashboard/laporan admin).
  static Future<int> countByStatus(String status) async {
    if (!Backend.useFirebase) return 0;
    final q = _col.where('status', isEqualTo: status);
    try {
      final snap = await q.count().get();
      return snap.count ?? 0;
    } on FirebaseException {
      final snap = await q.get();
      return snap.docs.length;
    }
  }

  static Future<Map<String, dynamic>?> byId(String id) async {
    if (!Backend.useFirebase) return null;
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    return {'id': snap.id, ...snap.data()!};
  }

  static Future<List<String>> patientIdsForDoctor(String doctorUid) async {
    final list = await listForDoctor(doctorUid, includeFinished: true);
    return list
        .map((m) => (m['patientId'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Status lifecycle (hanya dokter — diverifikasi Security Rules)
  // ---------------------------------------------------------------------------
  static Future<void> markBerlangsung(String id) async {
    if (!Backend.useFirebase) return;
    final ref = _col.doc(id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Konsultasi tidak ditemukan.');
      final status = (snap.data()?['status'] as String?) ?? 'terjadwal';
      if (status == 'selesai' || status == 'berlangsung') return;
      if (status != 'terjadwal') {
        throw StateError('Status konsultasi tidak valid untuk dimulai.');
      }
      tx.update(ref, {
        'status': 'berlangsung',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Menyelesaikan konsultasi (dokter) + activity log.
  static Future<void> complete({
    required String id,
    required String doctorUid,
    required String doctorName,
    required String patientName,
    String? diagnosis,
    String? notes,
  }) async {
    if (!Backend.useFirebase) return;
    final ref = _col.doc(id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Konsultasi tidak ditemukan.');
      final status = (snap.data()?['status'] as String?) ?? 'terjadwal';
      if (status == 'selesai') return;
      if (status != 'berlangsung' && status != 'terjadwal') {
        throw StateError('Status konsultasi tidak dapat diselesaikan.');
      }
      tx.update(ref, {
        'status': 'selesai',
        'diagnosis': diagnosis ?? '',
        'notes': notes ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      });
    });
    await ActivityService.log(
      title: 'Konsultasi selesai dengan $patientName',
      tag: 'Konsultasi',
      actor: doctorName,
      actorUid: doctorUid,
    );
    await NotificationService.notifyUser(
      uid: doctorUid,
      title: 'Konsultasi Selesai',
      description: 'Konsultasi dengan $patientName telah diselesaikan.',
      iconKey: 'check',
      type: 'konsultasi',
      createdBy: doctorUid,
    );
  }

  // ---------------------------------------------------------------------------
  // Chat messages (subcollection, stream realtime)
  // ---------------------------------------------------------------------------
  static CollectionReference<Map<String, dynamic>> messages(
    String consultationId,
  ) =>
      _col.doc(consultationId).collection('messages');

  static Stream<List<Map<String, dynamic>>> messageStream(
    String consultationId,
  ) {
    if (!Backend.useFirebase) return const Stream.empty();
    return messages(consultationId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Future<List<Map<String, dynamic>>> loadMessages(
    String consultationId,
  ) async {
    if (!Backend.useFirebase) return const [];
    final snap = await messages(consultationId).orderBy('createdAt').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  static Future<void> sendMessage({
    required String consultationId,
    required String senderId,
    required String senderRole,
    required String text,
    required String time,
  }) async {
    if (!Backend.useFirebase) return;
    await messages(consultationId).add({
      'consultationId': consultationId,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'time': time,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
