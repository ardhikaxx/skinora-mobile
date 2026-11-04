import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
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

  // In-memory fallback untuk testing / offline environment
  static final Map<String, Map<String, dynamic>> _inMemoryStore = {};
  static final StreamController<List<Map<String, dynamic>>> _inMemoryCtrl =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  static void resetInMemoryStore() {
    _inMemoryStore.clear();
    _inMemoryCtrl.add([]);
  }

  static void setInMemoryConsultation(String id, Map<String, dynamic> data) {
    _inMemoryStore[id] = Map<String, dynamic>.from(data);
    _inMemoryCtrl.add(_inMemoryStore.values.toList());
  }

  static Map<String, dynamic>? getInMemoryConsultation(String id) =>
      _inMemoryStore[id];

  // ---------------------------------------------------------------------------
  // Aturan 1 Pasien 1 Konsultasi per Hari
  // ---------------------------------------------------------------------------
  /// Memeriksa apakah pasien sudah memiliki jadwal konsultasi pada tanggal
  /// tertentu ([dateIso] atau [scheduleDate]) dengan status aktif (bukan dibatalkan).
  /// Bila ditemukan konsultasi 'menunggu_konfirmasi' yang sudah melewati jam mulai sesi,
  /// sistem otomatis membatalkan konsultasi tersebut dan mengembalikan kuota harian pasien.
  static Future<bool> hasConsultationOnDate({
    required String patientUid,
    required String dateIso,
    String? scheduleDate,
  }) async {
    if (patientUid.isEmpty) return false;
    if (!Backend.useFirebase) {
      for (final doc in _inMemoryStore.values) {
        if (doc['patientId'] == patientUid) {
          final status = ((doc['status'] as String?) ?? '').toLowerCase();
          if (status != 'dibatalkan') {
            if (status == 'menunggu_konfirmasi') {
              final dIso = (doc['dateIso'] as String?) ?? '';
              final sDate = (doc['scheduleDate'] as String?) ?? '';
              final tStart = (doc['timeStart'] as String?) ?? '';
              final tEnd = (doc['timeEnd'] as String?) ?? '';
              if (AppDates.isPastSlot(
                dateIso: dIso,
                scheduleDate: sDate,
                timeStart: tStart,
                timeEnd: tEnd,
              )) {
                doc['status'] = 'dibatalkan';
                doc['cancelReason'] =
                    'Kedaluwarsa: Melewati batas waktu konsultasi tanpa konfirmasi dokter';
                continue;
              }
            }
            if (dateIso.isNotEmpty && doc['dateIso'] == dateIso) return true;
            if (scheduleDate != null &&
                scheduleDate.isNotEmpty &&
                doc['scheduleDate'] == scheduleDate) {
              return true;
            }
          }
        }
      }
      return false;
    }
    try {
      if (dateIso.isNotEmpty) {
        final snap = await _col
            .where('patientId', isEqualTo: patientUid)
            .where('dateIso', isEqualTo: dateIso)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          final status =
              ((data['status'] as String?) ?? '').toLowerCase();
          if (status != 'dibatalkan') {
            if (status == 'menunggu_konfirmasi') {
              final dIso = (data['dateIso'] as String?) ?? '';
              final sDate = (data['scheduleDate'] as String?) ?? '';
              final tStart = (data['timeStart'] as String?) ?? '';
              final tEnd = (data['timeEnd'] as String?) ?? '';
              if (AppDates.isPastSlot(
                dateIso: dIso,
                scheduleDate: sDate,
                timeStart: tStart,
                timeEnd: tEnd,
              )) {
                unawaited(autoCancelExpiredConsultation(doc.id));
                continue;
              }
            }
            return true;
          }
        }
      }
      if (scheduleDate != null && scheduleDate.isNotEmpty) {
        final dateSnap = await _col
            .where('patientId', isEqualTo: patientUid)
            .where('scheduleDate', isEqualTo: scheduleDate)
            .get();
        for (final doc in dateSnap.docs) {
          final data = doc.data();
          final status =
              ((data['status'] as String?) ?? '').toLowerCase();
          if (status != 'dibatalkan') {
            if (status == 'menunggu_konfirmasi') {
              final dIso = (data['dateIso'] as String?) ?? '';
              final sDate = (data['scheduleDate'] as String?) ?? '';
              final tStart = (data['timeStart'] as String?) ?? '';
              final tEnd = (data['timeEnd'] as String?) ?? '';
              if (AppDates.isPastSlot(
                dateIso: dIso,
                scheduleDate: sDate,
                timeStart: tStart,
                timeEnd: tEnd,
              )) {
                unawaited(autoCancelExpiredConsultation(doc.id));
                continue;
              }
            }
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

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
      final consultationDocId = '${slotId}_${patient.uid}';
      final doc = <String, dynamic>{
        'id': consultationDocId,
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
        'status': 'menunggu_konfirmasi',
        'diagnosis': null,
        'notes': null,
        'slotId': slotId,
        'createdBy': patient.uid,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };
      _inMemoryStore[consultationDocId] = doc;
      _inMemoryCtrl.add(_inMemoryStore.values.toList());
      return consultationDocId;
    }

    final authUid = AuthService.uid;
    final effectiveUid = (patient.uid.isNotEmpty && patient.uid != 'user_local')
        ? patient.uid
        : (authUid ?? patient.uid);
    final effectiveName = patient.name.trim().isNotEmpty
        ? patient.name.trim()
        : 'Pasien';

    // 1 Pasien 1 Konsultasi per Hari agar adil untuk semua pasien.
    final alreadyBooked = await hasConsultationOnDate(
      patientUid: effectiveUid,
      dateIso: dateIso,
      scheduleDate: scheduleDate,
    );
    if (alreadyBooked) {
      throw StateError(
        'Anda sudah memiliki jadwal konsultasi pada hari ini. Setiap pasien dibatasi maksimal 1 kali konsultasi per hari agar pasien lainnya kebagian jadwal.',
      );
    }

    // ID deterministik per kombinasi slot + pasien: mendukung kuota > 1
    // pasien per slot tanpa saling menimpa.
    final consultationDocId = '${slotId}_$effectiveUid';
    final consultationRef = _col.doc(consultationDocId);
    final slotRef = _db
        .collection('users')
        .doc(doctorUid)
        .collection('slots')
        .doc(slotId);
    final linkRef = _links.doc(linkId(effectiveUid, doctorUid));
    final now = FieldValue.serverTimestamp();

    // Satu transaksi atomik: slot + konsultasi + care_link.
    await _db.runTransaction((tx) async {
      final slotSnap = await tx.get(slotRef);
      if (!slotSnap.exists) {
        throw StateError('Slot jadwal tidak ditemukan.');
      }
      final slotData = slotSnap.data() ?? const <String, dynamic>{};
      final quota = (slotData['quota'] as num?)?.toInt() ?? 1;
      final isBooked = (slotData['isBooked'] as bool?) ?? false;

      final patientIdsRaw = slotData['patientIds'];
      final patientIds = patientIdsRaw is List
          ? patientIdsRaw.map((e) => e.toString()).toList()
          : <String>[];
      final patientNamesRaw = slotData['patientNames'];
      final patientNames = patientNamesRaw is List
          ? patientNamesRaw.map((e) => e.toString()).toList()
          : <String>[];

      int bookedCount = (slotData['bookedCount'] as num?)?.toInt() ?? 0;
      if (bookedCount == 0 && patientIds.isNotEmpty) {
        bookedCount = patientIds.length;
      } else if (bookedCount == 0 && isBooked) {
        bookedCount = quota;
      }

      if (patientIds.contains(effectiveUid) ||
          slotData['patientId'] == effectiveUid) {
        throw StateError('Anda sudah terdaftar pada sesi jadwal ini.');
      }

      if (isBooked || (bookedCount >= quota && quota > 0)) {
        throw StateError('Slot jadwal sudah penuh untuk sesi ini.');
      }

      final newBookedCount = bookedCount + 1;
      final newIsBooked = newBookedCount >= quota;
      final newPatientIds = List<String>.from(patientIds)..add(effectiveUid);
      final newPatientNames = List<String>.from(patientNames)..add(effectiveName);

      tx.update(slotRef, {
        'bookedCount': newBookedCount,
        'isBooked': newIsBooked,
        'patientIds': newPatientIds,
        'patientNames': newPatientNames,
        'patientId': effectiveUid,
        'patientName': effectiveName,
        'updatedAt': now,
      });
      tx.set(consultationRef, {
        'patientId': effectiveUid,
        'patientName': effectiveName,
        'doctorId': doctorUid,
        'doctorName': doctorName,
        'specialization': specialization,
        'scheduleDate': scheduleDate,
        'dateIso': dateIso,
        'scheduleTime': scheduleTime,
        'timeStart': timeStart,
        'timeEnd': timeEnd,
        'status': 'menunggu_konfirmasi',
        'diagnosis': null,
        'notes': null,
        'slotId': slotId,
        'createdBy': effectiveUid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(linkRef, {
        'patientId': effectiveUid,
        'doctorId': doctorUid,
        'slotId': slotId,
        'createdBy': effectiveUid,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await ActivityService.log(
      title: 'Booking konsultasi dengan $doctorName',
      tag: 'Booking',
      actor: effectiveName,
      actorUid: effectiveUid,
    );
    await NotificationService.notifyUser(
      uid: doctorUid,
      title: 'Penjadwalan Konsultasi Baru',
      description:
          '$effectiveName memilih jadwal konsultasi pada $scheduleDate $scheduleTime. Silakan verifikasi jadwal ini.',
      iconKey: 'calendar',
      type: NotificationType.bookingCreated,
      entityId: consultationRef.id,
      consultationId: consultationRef.id,
      audienceRole: NotificationRole.dokter,
      createdBy: effectiveUid,
    );
    await NotificationService.notifyUser(
      uid: effectiveUid,
      title: 'Menunggu Verifikasi Dokter',
      description:
          'Jadwal konsultasi Anda bersama $doctorName pada $scheduleDate $scheduleTime sedang menunggu verifikasi dokter.',
      iconKey: 'calendar',
      type: NotificationType.bookingCreated,
      entityId: consultationRef.id,
      consultationId: consultationRef.id,
      route: NotificationPageRoute.penggunaRiwayatKonsultasi,
      audienceRole: NotificationRole.pengguna,
      createdBy: effectiveUid,
    );
    // Admin dashboard: booking baru (satu dokumen per admin, idempoten).
    await NotificationService.notifyAdmins(
      title: 'Konsultasi Baru',
      body: '$effectiveName memesan konsultasi dengan $doctorName '
          'pada $scheduleDate $scheduleTime',
      type: NotificationType.bookingCreated,
      iconKey: 'calendar',
      entityId: consultationRef.id,
      createdBy: effectiveUid,
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
    if (doctorUid.isEmpty) return const Stream.empty();
    if (!Backend.useFirebase) {
      final initial = _inMemoryStore.values
          .where((m) =>
              m['doctorId'] == doctorUid &&
              (includeFinished ||
                  ((m['status'] as String?) != 'selesai' &&
                      (m['status'] as String?) != 'dibatalkan')))
          .toList();
      return _inMemoryCtrl.stream
          .map((list) => list
              .where((m) =>
                  m['doctorId'] == doctorUid &&
                  (includeFinished ||
                      ((m['status'] as String?) != 'selesai' &&
                          (m['status'] as String?) != 'dibatalkan')))
              .toList())
          .startWith(initial);
    }
    return _col
        .where('doctorId', isEqualTo: doctorUid)
        .snapshots()
        .map(
          (snap) {
            final docs =
                snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
            docs.sort((a, b) {
              final aCreated = a['createdAt'];
              final bCreated = b['createdAt'];
              if (aCreated is Timestamp && bCreated is Timestamp) {
                return bCreated.compareTo(aCreated);
              }
              return 0;
            });
            return docs
                .where((m) =>
                    includeFinished ||
                    ((m['status'] as String?) != 'selesai' &&
                        (m['status'] as String?) != 'dibatalkan'))
                .toList();
          },
        );
  }

  /// Stream konsultasi pasien (status terjadwal/berlangsung/selesai live).
  static Stream<List<Map<String, dynamic>>> streamForPatient(
    String patientUid,
  ) {
    if (patientUid.isEmpty) return const Stream.empty();
    if (!Backend.useFirebase) {
      final initial = _inMemoryStore.values
          .where((m) => m['patientId'] == patientUid)
          .toList();
      return _inMemoryCtrl.stream
          .map((list) =>
              list.where((m) => m['patientId'] == patientUid).toList())
          .startWith(initial);
    }
    return _col
        .where('patientId', isEqualTo: patientUid)
        .snapshots()
        .map((snap) {
      final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      docs.sort((a, b) {
        final aCreated = a['createdAt'];
        final bCreated = b['createdAt'];
        if (aCreated is Timestamp && bCreated is Timestamp) {
          return bCreated.compareTo(aCreated);
        }
        return 0;
      });
      return docs;
    });
  }

  /// Stream 1 dokumen konsultasi (badge status live di ruang chat).
  static Stream<Map<String, dynamic>?> streamById(String id) {
    if (id.isEmpty) return const Stream.empty();
    if (!Backend.useFirebase) {
      final initial = _inMemoryStore[id];
      return _inMemoryCtrl.stream
          .map((_) => _inMemoryStore[id])
          .startWith(initial);
    }
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
  /// Konfirmasi jadwal konsultasi oleh dokter.
  static Future<void> confirm({
    required String id,
    required String doctorUid,
    required String doctorName,
    required String patientName,
  }) async {
    if (!Backend.useFirebase) {
      if (_inMemoryStore.containsKey(id)) {
        _inMemoryStore[id]!['status'] = 'dikonfirmasi';
        _inMemoryStore[id]!['confirmedAt'] = DateTime.now();
        _inMemoryStore[id]!['updatedAt'] = DateTime.now();
        _inMemoryCtrl.add(_inMemoryStore.values.toList());
      }
      return;
    }
    final ref = _col.doc(id);
    String patientId = '';
    final bool confirmed = await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Konsultasi tidak ditemukan.');
      final status = ((snap.data()?['status'] as String?) ?? '').toLowerCase();
      patientId = (snap.data()?['patientId'] as String?) ?? '';
      if (status == 'selesai') return false;
      tx.update(ref, {
        'status': 'dikonfirmasi',
        'confirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (!confirmed) return;
    await ActivityService.log(
      title: 'Memverifikasi jadwal konsultasi dengan $patientName',
      tag: 'Konsultasi',
      actor: doctorName,
      actorUid: doctorUid,
    );
    if (patientId.isNotEmpty) {
      await NotificationService.notifyUser(
        uid: patientId,
        title: 'Jadwal Konsultasi Diverifikasi',
        description:
            'Dokter $doctorName telah memverifikasi jadwal konsultasi Anda. Anda sekarang dapat memasuki ruangan chat konsultasi.',
        iconKey: 'calendar',
        type: NotificationType.consultationStarted,
        entityId: id,
        consultationId: id,
        route: NotificationPageRoute.penggunaRiwayatKonsultasi,
        audienceRole: NotificationRole.pengguna,
        createdBy: doctorUid,
      );
    }
    unawaited(NotificationService.refreshChatFeed());
  }

  static Future<void> markBerlangsung(String id) async {
    if (!Backend.useFirebase) {
      if (_inMemoryStore.containsKey(id)) {
        _inMemoryStore[id]!['status'] = 'berlangsung';
        _inMemoryStore[id]!['updatedAt'] = DateTime.now();
        _inMemoryCtrl.add(_inMemoryStore.values.toList());
      }
      return;
    }
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
      if (status != 'terjadwal' && status != 'dikonfirmasi') {
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

  /// Membatalkan konsultasi secara otomatis apabila jam mulai sesi tiba namun
  /// belum diverifikasi oleh dokter, sehingga kuota harian pasien dikembalikan.
  static Future<bool> autoCancelExpiredConsultation(String id) async {
    if (id.isEmpty) return false;
    if (!Backend.useFirebase) {
      final doc = _inMemoryStore[id];
      if (doc == null) return false;
      final status = ((doc['status'] as String?) ?? '').toLowerCase();
      if (status != 'menunggu_konfirmasi') return false;

      doc['status'] = 'dibatalkan';
      doc['cancelReason'] =
          'Jadwal konsultasi telah kedaluwarsa karena melewati batas waktu konfirmasi dokter. Kuota konsultasi Anda hari ini telah dikembalikan.';
      doc['cancelledAt'] = DateTime.now();
      doc['updatedAt'] = DateTime.now();
      _inMemoryCtrl.add(_inMemoryStore.values.toList());
      return true;
    }

    try {
      final ref = _col.doc(id);
      final snap = await ref.get();
      if (!snap.exists) return false;
      final data = snap.data();
      if (data == null) return false;
      final status = ((data['status'] as String?) ?? '').toLowerCase();
      if (status != 'menunggu_konfirmasi') return false;

      final patientId = (data['patientId'] as String?) ?? '';
      final doctorId = (data['doctorId'] as String?) ?? '';
      final doctorName = (data['doctorName'] as String?) ?? 'Dokter';
      final scheduleDate = (data['scheduleDate'] as String?) ?? '';
      final scheduleTime = (data['scheduleTime'] as String?) ?? '';
      final slotId = (data['slotId'] as String?) ?? '';

      await ref.update({
        'status': 'dibatalkan',
        'cancelReason':
            'Jadwal konsultasi telah kedaluwarsa karena melewati batas waktu konfirmasi dokter. Kuota konsultasi Anda hari ini telah dikembalikan.',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Lepas kuota slot dokter bila ada
      if (slotId.isNotEmpty && doctorId.isNotEmpty) {
        try {
          final slotRef = _db
              .collection('users')
              .doc(doctorId)
              .collection('slots')
              .doc(slotId);
          await _db.runTransaction((tx) async {
            final sSnap = await tx.get(slotRef);
            if (!sSnap.exists) return;
            final sData = sSnap.data()!;
            final pIds =
                List<String>.from((sData['patientIds'] as List?) ?? []);
            pIds.remove(patientId);
            final currentCount = (sData['bookedCount'] as num?)?.toInt() ?? 0;
            final newCount = currentCount > 0 ? currentCount - 1 : 0;
            final quota = (sData['quota'] as num?)?.toInt() ?? 1;
            tx.update(slotRef, {
              'bookedCount': newCount,
              'isBooked': newCount >= quota,
              'patientIds': pIds,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          });
        } catch (_) {}
      }

      if (patientId.isNotEmpty) {
        await ActivityService.log(
          title: 'Jadwal konsultasi dibatalkan otomatis (kedaluwarsa)',
          tag: 'Konsultasi',
          actor: 'Sistem',
          actorUid: patientId,
        );

        await NotificationService.notifyUser(
          uid: patientId,
          title: 'Jadwal Konsultasi Dibatalkan Otomatis',
          description:
              'Jadwal konsultasi bersama $doctorName pada $scheduleDate $scheduleTime telah kedaluwarsa karena melewati batas waktu konfirmasi dokter. Kuota konsultasi Anda hari ini telah dikembalikan.',
          iconKey: 'calendar',
          type: NotificationType.bookingCancelled,
          entityId: id,
          consultationId: id,
          route: NotificationPageRoute.penggunaRiwayatKonsultasi,
          audienceRole: NotificationRole.pengguna,
          createdBy: patientId,
        );
      }

      return true;
    } catch (_) {
      return false;
    }
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
    if (!Backend.useFirebase) {
      if (_inMemoryStore.containsKey(id)) {
        _inMemoryStore[id]!['status'] = 'selesai';
        _inMemoryStore[id]!['diagnosis'] = diagnosis ?? '';
        _inMemoryStore[id]!['notes'] = notes ?? '';
        _inMemoryStore[id]!['completedAt'] = DateTime.now();
        _inMemoryStore[id]!['updatedAt'] = DateTime.now();
        _inMemoryCtrl.add(_inMemoryStore.values.toList());
      }
      return;
    }
    final ref = _col.doc(id);
    String patientId = '';
    final bool finished = await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Konsultasi tidak ditemukan.');
      final status = (snap.data()?['status'] as String?) ?? 'terjadwal';
      patientId = (snap.data()?['patientId'] as String?) ?? '';
      if (status == 'selesai') return false;
      if (status != 'berlangsung' && status != 'terjadwal' && status != 'dikonfirmasi') {
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
      if (status == 'menunggu_konfirmasi') {
        throw StateError(
          'Konsultasi belum dikonfirmasi oleh dokter. Mohon tunggu konfirmasi dokter sebelum dapat mengirim pesan.',
        );
      }
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

extension _StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T initial) async* {
    yield initial;
    yield* this;
  }
}
