import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../services/activity_service.dart';
import '../services/backend.dart';
import '../services/notification_service.dart';

/// Entity konsultasi + chat + booking (transaction/batch agar atomik).
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
  // Booking (batch atomik: slot + konsultasi + care_link + activity + notif)
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
    final consultationRef = _col.doc();
    final slotRef = _db
        .collection('users')
        .doc(doctorUid)
        .collection('slots')
        .doc(slotId);
    final slotSnap = await slotRef.get();
    if (!slotSnap.exists ||
        ((slotSnap.data()?['isBooked'] as bool?) ?? false)) {
      throw StateError('Slot sudah dibooking oleh pasien lain.');
    }

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    batch.update(slotRef, {
      'isBooked': true,
      'patientId': patient.uid,
      'patientName': patient.name,
      'updatedAt': now,
    });

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
      'createdAt': now,
      'updatedAt': now,
    });

    batch.set(_links.doc(linkId(patient.uid, doctorUid)), {
      'patientId': patient.uid,
      'doctorId': doctorUid,
      'createdBy': patient.uid,
      'createdAt': now,
    }, SetOptions(merge: true));

    await batch.commit();

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
  // Status lifecycle
  // ---------------------------------------------------------------------------
  static Future<void> markBerlangsung(String id) async {
    if (!Backend.useFirebase) return;
    await _col.doc(id).update({
      'status': 'berlangsung',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Menyelesaikan konsultasi (dokter) + activity log dalam satu batch.
  static Future<void> complete({
    required String id,
    required String doctorUid,
    required String doctorName,
    required String patientName,
    String? diagnosis,
    String? notes,
  }) async {
    if (!Backend.useFirebase) return;
    final batch = _db.batch();
    batch.update(_col.doc(id), {
      'status': 'selesai',
      'diagnosis': diagnosis ?? '',
      'notes': notes ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await ActivityService.log(
      title: 'Konsultasi selesai dengan $patientName',
      tag: 'Konsultasi',
      actor: doctorName,
      actorUid: doctorUid,
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
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'time': time,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
