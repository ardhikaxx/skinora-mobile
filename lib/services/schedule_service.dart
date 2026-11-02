import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/doctor_practice_settings.dart';
import '../services/activity_service.dart';
import '../services/backend.dart';
import '../services/notification_payload.dart';
import '../services/notification_service.dart';
import '../utils/app_dates.dart';

class SlotRecord {
  final String id;
  final String doctorId;
  final String date; // tampil: "Jumat, 28 Agustus 2026"
  final String time; // "09.00 - 09.15" atau "09:00 - 09:30"
  final String timeStart;
  final String timeEnd;
  final bool isBooked;
  final int quota; // Batas kuota pasien untuk sesi ini (default 1)
  final int bookedCount; // Berapa pasien yang sudah booking
  final List<String> patientIds;
  final List<String> patientNames;
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
    this.quota = 1,
    this.bookedCount = 0,
    this.patientIds = const [],
    this.patientNames = const [],
    this.patientId,
    this.patientName,
  });

  /// Sisa kuota pasien yang masih tersedia untuk sesi ini.
  int get remainingQuota {
    final effectiveCount =
        bookedCount > 0 ? bookedCount : (isBooked ? quota : 0);
    final remaining = quota - effectiveCount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Apakah sesi sudah penuh mencapai batas maksimal kuota pasien.
  bool get isFull => isBooked || (bookedCount >= quota && quota > 0);

  /// yyyy-MM-dd bila tanggal tampil bisa diparse, else "".
  String get dateIso {
    final parsed = AppDates.tryParseDisplay(date);
    return parsed == null ? '' : AppDates.iso(parsed);
  }
}

/// Status kelayakan sebuah slot untuk memulai konsultasi saat ini.
enum SlotAvailability {
  /// Slot boleh dipakai (sudah masuk jam konsultasi, belum berakhir).
  available,

  /// Belum masuk jam mulai konsultasi.
  upcoming,

  /// Sudah melewati jam selesai konsultasi.
  expired,

  /// Sudah penuh / dibooking pasien.
  booked,
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
    final quota = (m['quota'] as num?)?.toInt() ?? 1;
    final isBooked = (m['isBooked'] as bool?) ?? false;
    final patientIdsRaw = m['patientIds'];
    final patientIds = patientIdsRaw is List
        ? patientIdsRaw.map((e) => e.toString()).toList()
        : <String>[];
    final patientNamesRaw = m['patientNames'];
    final patientNames = patientNamesRaw is List
        ? patientNamesRaw.map((e) => e.toString()).toList()
        : <String>[];
    int bookedCount = (m['bookedCount'] as num?)?.toInt() ?? 0;
    if (bookedCount == 0 && patientIds.isNotEmpty) {
      bookedCount = patientIds.length;
    } else if (bookedCount == 0 && isBooked) {
      bookedCount = quota;
    }

    return SlotRecord(
      id: d.id,
      doctorId: doctorUid,
      date: (m['date'] as String?) ?? '',
      time: (m['time'] as String?) ?? '',
      timeStart: (m['timeStart'] as String?) ?? '',
      timeEnd: (m['timeEnd'] as String?) ?? '',
      isBooked: isBooked || (bookedCount >= quota && quota > 0),
      quota: quota > 0 ? quota : 1,
      bookedCount: bookedCount,
      patientIds: patientIds,
      patientNames: patientNames,
      patientId: m['patientId'] as String?,
      patientName: m['patientName'] as String?,
    );
  }

  static Future<List<SlotRecord>> listSlots(String doctorUid) async {
    if (!Backend.useFirebase || doctorUid.isEmpty) return const [];
    final snap = await _slots(doctorUid).orderBy('createdAt').get();
    return snap.docs.map((d) => _from(doctorUid, d)).toList();
  }

  /// Stream realtime semua slot dokter (sinkron antar dokter & pasien).
  static Stream<List<SlotRecord>> slotStream(String doctorUid) {
    if (!Backend.useFirebase || doctorUid.isEmpty) {
      return const Stream.empty();
    }
    return _slots(doctorUid).orderBy('createdAt').snapshots().map(
          (snap) => snap.docs.map((d) => _from(doctorUid, d)).toList(),
        );
  }

  /// Slot kosong / belum penuh saja (kompatibel rules read).
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

  /// Slot layak booking: belum penuh, punya tanggal, belum lewat (WIB).
  static List<SlotRecord> bookableSlots(Iterable<SlotRecord> slots) =>
      slots
          .where(
            (s) =>
                !s.isFull &&
                s.date.isNotEmpty &&
                !AppDates.isPastSlot(
                  dateIso: s.dateIso,
                  timeEnd: s.timeEnd,
                  timeStart: s.timeStart,
                ),
          )
          .toList();

  /// Kelayakan slot untuk **memulai konsultasi** sekarang (WIB).
  static SlotAvailability availabilityOf(SlotRecord slot) {
    if (slot.isFull) return SlotAvailability.booked;
    final start = slot.timeStart.isNotEmpty
        ? slot.timeStart
        : slot.time.split('-').first.trim();
    if (AppDates.isSlotUpcoming(
      dateIso: slot.dateIso,
      scheduleDate: slot.date,
      timeStart: start,
    )) {
      return SlotAvailability.upcoming;
    }
    if (slot.timeEnd.isNotEmpty &&
        AppDates.isPastSlot(
          dateIso: slot.dateIso,
          scheduleDate: slot.date,
          timeStart: start,
          timeEnd: slot.timeEnd,
        )) {
      return SlotAvailability.expired;
    }
    return SlotAvailability.available;
  }

  /// Tambah slot manual dengan batas [quota] pasien (default 1).
  static Future<String> addSlot({
    required String doctorUid,
    required String date,
    required String time,
    required String timeStart,
    required String timeEnd,
    int quota = 1,
  }) async {
    if (!Backend.useFirebase) return '';
    final normalizedStart = AppDates.formatHm(timeStart);
    final normalizedEnd = AppDates.formatHm(timeEnd);
    if (AppDates.isPastSlot(
      dateIso: AppDates.iso(AppDates.tryParseDisplay(date) ?? DateTime(2000)),
      timeEnd: normalizedEnd,
      timeStart: normalizedStart,
    )) {
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

    final safeQuota = quota > 0 ? quota : 1;
    final ref = await _slots(doctorUid).add({
      'date': date,
      'time': time,
      'timeStart': normalizedStart,
      'timeEnd': normalizedEnd,
      'quota': safeQuota,
      'bookedCount': 0,
      'patientIds': <String>[],
      'patientNames': <String>[],
      'isBooked': false,
      'createdBy': doctorUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await NotificationService.notifyUser(
      uid: doctorUid,
      title: 'Jadwal Ditambahkan',
      description: 'Slot $date $time berhasil ditambahkan ke jadwal praktik.',
      iconKey: 'calendar',
      type: NotificationType.scheduleCreated,
      entityId: ref.id,
      audienceRole: NotificationRole.dokter,
      createdBy: doctorUid,
    );
    return ref.id;
  }

  /// Otomatis membuat sesi-sesi konsultasi berdasarkan [DoctorPracticeSettings].
  ///
  /// Contoh: Jam buka 09.00 - 12.00, durasi 15 menit, kuota 2 pasien/sesi:
  /// Menghasilkan sesi 09.00-09.15 (kuota 2), 09.15-09.30 (kuota 2), dst.
  static Future<int> generatePracticeSlots({
    required String doctorUid,
    required String date,
    required DoctorPracticeSettings settings,
  }) async {
    if (!Backend.useFirebase || doctorUid.isEmpty) return 0;
    final sessions = settings.generateSessions();
    if (sessions.isEmpty) return 0;

    // Ambil slot yang sudah ada pada tanggal tersebut agar tidak bentrok
    final existingSnap =
        await _slots(doctorUid).where('date', isEqualTo: date).get();
    final existingRanges = <String>{};
    for (final d in existingSnap.docs) {
      final s = (d.data()['timeStart'] as String?) ?? '';
      final e = (d.data()['timeEnd'] as String?) ?? '';
      if (s.isNotEmpty && e.isNotEmpty) {
        existingRanges.add('$s-$e');
      }
    }

    int createdCount = 0;
    final batch = _db.batch();
    for (final sess in sessions) {
      final key = '${sess.timeStart}-${sess.timeEnd}';
      if (existingRanges.contains(key)) continue;

      final docRef = _slots(doctorUid).doc();
      batch.set(docRef, {
        'date': date,
        'time': sess.displayRange,
        'timeStart': sess.timeStart,
        'timeEnd': sess.timeEnd,
        'quota': sess.quota,
        'bookedCount': 0,
        'patientIds': <String>[],
        'patientNames': <String>[],
        'isBooked': false,
        'createdBy': doctorUid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      createdCount++;
    }

    if (createdCount > 0) {
      await batch.commit();
      await ActivityService.log(
        title: 'Menerapkan $createdCount sesi praktik otomatis ($date)',
        tag: 'Jadwal',
        actor: 'Dokter',
        actorUid: doctorUid,
      );
    }
    return createdCount;
  }

  /// Simpan pengaturan jam buka, jam tutup, durasi sesi, dan limit kuota
  /// pasien yang diatur sendiri oleh dokter (bukan admin).
  static Future<void> savePracticeSettings(
    String doctorUid,
    DoctorPracticeSettings settings,
  ) async {
    if (!Backend.useFirebase || doctorUid.isEmpty) return;
    await _db.collection('users').doc(doctorUid).update({
      'practiceSettings': settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await ActivityService.log(
      title: 'Memperbarui pengaturan jadwal & kuota praktik',
      tag: 'Pengaturan',
      actor: 'Dokter',
      actorUid: doctorUid,
    );
  }

  /// Ambil pengaturan praktik dokter sekali dari Firestore.
  static Future<DoctorPracticeSettings> getPracticeSettings(
    String doctorUid,
  ) async {
    if (!Backend.useFirebase || doctorUid.isEmpty) {
      return const DoctorPracticeSettings();
    }
    try {
      final doc = await _db.collection('users').doc(doctorUid).get();
      if (!doc.exists) return const DoctorPracticeSettings();
      final data = doc.data()?['practiceSettings'] as Map<String, dynamic>?;
      return DoctorPracticeSettings.fromMap(data);
    } catch (_) {
      return const DoctorPracticeSettings();
    }
  }

  /// Stream realtime pengaturan praktik dokter.
  static Stream<DoctorPracticeSettings> streamPracticeSettings(
    String doctorUid,
  ) {
    if (!Backend.useFirebase || doctorUid.isEmpty) {
      return Stream.value(const DoctorPracticeSettings());
    }
    return _db.collection('users').doc(doctorUid).snapshots().map((snap) {
      if (!snap.exists) return const DoctorPracticeSettings();
      final data = snap.data()?['practiceSettings'] as Map<String, dynamic>?;
      return DoctorPracticeSettings.fromMap(data);
    });
  }

  static int _minutes(String hm) {
    final parts = hm.replaceAll(':', '.').split('.');
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
    final data = snap.data() ?? const <String, dynamic>{};
    final isBooked = (data['isBooked'] as bool?) ?? false;
    final bookedCount = (data['bookedCount'] as num?)?.toInt() ?? 0;
    if (isBooked || bookedCount > 0) {
      throw StateError('Slot sudah dibooking dan tidak dapat dihapus.');
    }
    final m = snap.data() ?? const <String, dynamic>{};
    final date = (m['date'] as String?) ?? '';
    final time = (m['time'] as String?) ?? '';
    await ref.delete();
    await ActivityService.log(
      title: 'Menghapus jadwal $date $time',
      tag: 'Jadwal',
      actor: 'Dokter',
      actorUid: doctorUid,
    );
    await NotificationService.notifyUser(
      uid: doctorUid,
      title: 'Jadwal Dihapus',
      description: 'Slot $date $time dihapus dari jadwal praktik.',
      iconKey: 'calendar',
      type: NotificationType.scheduleCancelled,
      entityId: slotId,
      audienceRole: NotificationRole.dokter,
      createdBy: doctorUid,
    );
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
    await ActivityService.log(
      title: isAvailable
          ? 'Membuka jadwal praktik'
          : 'Menutup jadwal praktik',
      tag: 'Jadwal',
      actor: 'Dokter',
      actorUid: doctorUid,
    );
    await NotificationService.notifyUser(
      uid: doctorUid,
      title: isAvailable ? 'Praktik Dibuka' : 'Praktik Ditutup',
      description: isAvailable
          ? 'Ketersediaan jadwal diubah: praktik dibuka untuk booking.'
          : 'Ketersediaan jadwal diubah: praktik ditutup untuk booking.',
      iconKey: 'calendar',
      type: NotificationType.scheduleChanged,
      entityId: 'availability-${DateTime.now().millisecondsSinceEpoch}',
      audienceRole: NotificationRole.dokter,
      createdBy: doctorUid,
    );
  }
}
