import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../services/activity_service.dart';
import '../services/backend.dart';
import '../services/notification_payload.dart';
import '../services/notification_service.dart';
import '../utils/app_dates.dart';

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
      type: NotificationType.bookingCreated,
      entityId: consultationRef.id,
      consultationId: consultationRef.id,
      audienceRole: NotificationRole.dokter,
      createdBy: patient.uid,
    );
    await NotificationService.notifyUser(
      uid: patient.uid,
      title: 'Booking Berhasil',
      description:
          'Konsultasi dengan $doctorName pada $scheduleDate $scheduleTime telah dijadwalkan.',
      iconKey: 'calendar',
      type: NotificationType.bookingCreated,
      entityId: consultationRef.id,
      consultationId: consultationRef.id,
      route: NotificationPageRoute.penggunaRiwayatKonsultasi,
      audienceRole: NotificationRole.pengguna,
      createdBy: patient.uid,
    );
    // Admin dashboard: booking baru (satu dokumen per admin, idempoten).
    await NotificationService.notifyAdmins(
      title: 'Konsultasi Baru',
      body: '${patient.name} memesan konsultasi dengan $doctorName '
          'pada $scheduleDate $scheduleTime',
      type: NotificationType.bookingCreated,
      iconKey: 'calendar',
      entityId: consultationRef.id,
      createdBy: patient.uid,
    );
    // Refresh chat feed agar listener pesan aktif segera untuk konsultasi baru.
    unawaited(NotificationService.refreshChatFeed());
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

  /// Stream konsultasi dokter (realtime). Secara default hanya yang aktif,
  /// atau semua termasuk selesai jika [includeFinished] bernilai true.
  static Stream<List<Map<String, dynamic>>> streamForDoctor(
    String doctorUid, {
    bool includeFinished = false,
  }) {
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
              .where((m) =>
                  includeFinished || (m['status'] as String?) != 'selesai')
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

  /// Stream riwayat konsultasi selesai dokter (realtime).
  static Stream<List<Map<String, dynamic>>> streamFinishedForDoctor(
    String doctorUid,
  ) {
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
              .where((m) => (m['status'] as String?) == 'selesai')
              .toList(),
        );
  }

  /// Stream semua konsultasi (admin realtime beranda & laporan).
  static Stream<List<Map<String, dynamic>>> streamAllConsultations({int? limit}) {
    if (!Backend.useFirebase) return const Stream.empty();
    var q = _col.orderBy('createdAt', descending: true);
    if (limit != null) q = q.limit(limit);
    return q.snapshots().map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
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

  static Future<Map<String, dynamic>?> getById(String id) => byId(id);

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
    String patientId = '';
    String patientName = '';
    String doctorId = '';
    String doctorName = '';
    final bool started = await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Konsultasi tidak ditemukan.');
      final status = (snap.data()?['status'] as String?) ?? 'terjadwal';
      if (status == 'selesai' || status == 'berlangsung') return false;
      if (status != 'terjadwal') {
        throw StateError('Status konsultasi tidak valid untuk dimulai.');
      }
      patientId = (snap.data()?['patientId'] as String?) ?? '';
      patientName = (snap.data()?['patientName'] as String?) ?? '';
      doctorId = (snap.data()?['doctorId'] as String?) ?? '';
      doctorName = (snap.data()?['doctorName'] as String?) ?? '';
      tx.update(ref, {
        'status': 'berlangsung',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (!started || patientId.isEmpty) return;
    await ActivityService.log(
      title: patientName.isNotEmpty
          ? 'Memulai konsultasi dengan $patientName'
          : 'Memulai konsultasi',
      tag: 'Konsultasi',
      actor: doctorName.isNotEmpty ? doctorName : 'Dokter',
      actorUid: doctorId,
    );
    // Pemberitahuan ke pasien: konsultasi dimulai (actor = dokter).
    await NotificationService.notifyUser(
      uid: patientId,
      title: 'Konsultasi Dimulai',
      description:
          'Konsultasi bersama $doctorName sudah dimulai. Silahkan masuk ke ruang konsultasi.',
      iconKey: 'messageSquare',
      type: NotificationType.consultationStarted,
      entityId: id,
      consultationId: id,
      audienceRole: NotificationRole.pengguna,
      createdBy: doctorId,
    );
    // Refresh chat feed agar listener pesan aktif segera di sisi dokter & pasien.
    unawaited(NotificationService.refreshChatFeed());
  }

  /// Tandai status konsultasi selesai (persisten ke Firestore saat jam slot berakhir).
  static Future<void> markSelesai(String id) async {
    if (!Backend.useFirebase || id.isEmpty) return;
    try {
      await _col.doc(id).update({
        'status': 'selesai',
        'updatedAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
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
    String patientId = '';
    final bool finished = await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Konsultasi tidak ditemukan.');
      final status = (snap.data()?['status'] as String?) ?? 'terjadwal';
      patientId = (snap.data()?['patientId'] as String?) ?? '';
      if (status == 'selesai') return false;
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
      return true;
    });
    if (!finished) return;
    await ActivityService.log(
      title: 'Konsultasi selesai dengan $patientName',
      tag: 'Konsultasi',
      actor: doctorName,
      actorUid: doctorUid,
    );
    // Pasien: konsultasi selesai + ajakan memberi rating (actor = dokter).
    if (patientId.isNotEmpty) {
      await NotificationService.notifyUser(
        uid: patientId,
        title: 'Konsultasi Selesai',
        description:
            'Konsultasi bersama $doctorName telah selesai. Berikan penilaian agar dokter dapat membantu lebih baik.',
        iconKey: 'check',
        type: NotificationType.consultationCompleted,
        entityId: id,
        consultationId: id,
        route: NotificationPageRoute.penggunaRiwayatKonsultasi,
        audienceRole: NotificationRole.pengguna,
        createdBy: doctorUid,
      );
    }
    // Dokter: ringkasan tindakan miliknya (actor = dokter sendiri, diizinkan
    // Security Rules karena audience = dirinya sendiri).
    await NotificationService.notifyUser(
      uid: doctorUid,
      title: 'Konsultasi Selesai',
      description: 'Konsultasi dengan $patientName telah diselesaikan.',
      iconKey: 'check',
      type: NotificationType.consultationCompleted,
      entityId: id,
      consultationId: id,
      route: NotificationPageRoute.dokterRiwayat,
      audienceRole: NotificationRole.dokter,
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
    // Kunci pengiriman: sesi yang sudah selesai atau lewat dari jadwal tidak boleh ada pesan baru.
    final consultSnap = await _col.doc(consultationId).get();
    final consultData = consultSnap.data();
    if (consultData != null) {
      final status = ((consultData['status'] as String?) ?? '').toLowerCase();
      final dateIso = (consultData['dateIso'] as String?) ?? '';
      final scheduleDate = (consultData['scheduleDate'] as String?) ?? '';
      final timeEnd = (consultData['timeEnd'] as String?) ?? (consultData['scheduleTime'] as String?) ?? '';
      final timeStart = (consultData['timeStart'] as String?) ?? '';
      final isExpired = status == 'selesai' ||
          AppDates.isConsultationExpired(
            dateIso: dateIso,
            scheduleDate: scheduleDate,
            timeEnd: timeEnd,
            timeStart: timeStart,
          );

      if (isExpired) {
        if (status != 'selesai') {
          // Tandai selesai otomatis bila jadwal konsultasi telah lampau
          _col.doc(consultationId).update({
            'status': 'selesai',
            'updatedAt': FieldValue.serverTimestamp(),
            'completedAt': FieldValue.serverTimestamp(),
          }).catchError((_) {});
        }
        throw StateError('Sesi konsultasi telah berakhir sesuai jadwal.');
      }
    }
    // ID dokumen pesan dipakai sebagai `eventId` notifikasi sehingga **setiap
    // pesan** menghasilkan notifikasi sendiri (bukan hanya pesan pertama per
    // konsultasi), sementara deep-link tetap memakai `consultationId`.
    final stampedTime = time.trim().isNotEmpty
        ? AppDates.formatChatTimeWib(time)
        : AppDates.formatChatTimeWib(AppDates.nowWib());
    final messageRef = await messages(consultationId).add({
      'consultationId': consultationId,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'time': stampedTime,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Notifikasi ke lawan bicara. Isi pesan TIDAK pernah disertakan — cukup
    // pemberitahuan generik agar privasi chat terjaga.
    try {
      final consult = await _col.doc(consultationId).get();
      final data = consult.data();
      if (data == null) return;
      final patientId = (data['patientId'] as String?) ?? '';
      final doctorId = (data['doctorId'] as String?) ?? '';
      final doctorName = (data['doctorName'] as String?) ?? 'Dokter';
      final patientName = (data['patientName'] as String?) ?? 'Pasien';
      final senderIsDoctor = senderRole == 'dokter';
      final target = senderIsDoctor ? patientId : doctorId;
      if (target.isEmpty || target == senderId) return;
      final senderName = senderIsDoctor ? doctorName : patientName;
      await NotificationService.notifyUser(
        uid: target,
        title: 'Pesan Baru dari $senderName',
        description: 'Anda menerima pesan baru dari $senderName.',
        iconKey: 'messageSquare',
        type: NotificationType.consultationMessage,
        entityId: consultationId,
        eventId: messageRef.id,
        consultationId: consultationId,
        audienceRole: senderIsDoctor
            ? NotificationRole.pengguna
            : NotificationRole.dokter,
        createdBy: senderId,
      );
    } catch (_) {
      // Notifikasi chat bersifat best-effort — pesan tetap tersimpan.
    }
  }
}
