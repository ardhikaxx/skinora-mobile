import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/activity_service.dart';
import '../services/backend.dart';
import '../utils/app_dates.dart';

/// Data kesehatan milik pasien di subcollection `users/{uid}/...`.
class SkinService {
  SkinService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _col(
    String uid,
    String name,
  ) =>
      _db.collection('users').doc(uid).collection(name);

  static final List<Map<String, dynamic>> _cachedSkinChecks = [];
  static final StreamController<List<Map<String, dynamic>>>
      _cachedSkinChecksController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  static final List<Map<String, dynamic>> _cachedSkinDailies = [];
  static final StreamController<List<Map<String, dynamic>>>
      _cachedSkinDailiesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  static final List<Map<String, dynamic>> _cachedSkincareLogs = [];
  static final StreamController<List<Map<String, dynamic>>>
      _cachedSkincareLogsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // ---------------------------------------------------------------------------
  // Skin Check
  // ---------------------------------------------------------------------------
  static Future<void> saveSkinCheck({
    required String uid,
    required String name,
    required Map<String, String> answers,
    required String resultSkinType,
    required String resultSensitivity,
    required String resultAcneRisk,
    String? createdDisplay,
    String? createdIso,
  }) async {
    final now = AppDates.nowWib();
    final display = (createdDisplay != null && createdDisplay.trim().isNotEmpty)
        ? createdDisplay.trim()
        : AppDates.fullDisplayWib(now);
    final iso = (createdIso != null && createdIso.trim().isNotEmpty)
        ? createdIso.trim()
        : AppDates.iso(now);
    final millis = DateTime.now().millisecondsSinceEpoch;

    final record = <String, dynamic>{
      'id': 'sc_$millis',
      'createdDisplay': display,
      'createdIso': iso,
      'createdAt': now,
      'createdAtMillis': millis,
      ...answers,
      'resultSkinType': resultSkinType,
      'resultSensitivity': resultSensitivity,
      'resultAcneRisk': resultAcneRisk,
      'createdBy': uid,
    };

    if (!Backend.useFirebase) {
      _cachedSkinChecks.removeWhere((item) => item['id'] == record['id']);
      _cachedSkinChecks.insert(0, record);
      _cachedSkinChecksController.add(List.unmodifiable(_cachedSkinChecks));
      await ActivityService.log(
        title: 'Melakukan Skin Check',
        tag: 'Skin Check',
        actor: name,
        actorUid: uid,
      );
      return;
    }

    await _col(uid, 'skin_checks').add({
      ...record,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await ActivityService.log(
      title: 'Melakukan Skin Check',
      tag: 'Skin Check',
      actor: name,
      actorUid: uid,
    );
  }

  static Future<List<Map<String, dynamic>>> listSkinChecks(
    String uid, {
    int? limit,
  }) async {
    if (!Backend.useFirebase || uid.isEmpty) {
      if (limit != null && _cachedSkinChecks.length > limit) {
        return _cachedSkinChecks.sublist(0, limit);
      }
      return List.unmodifiable(_cachedSkinChecks);
    }
    try {
      var q = _col(uid, 'skin_checks').orderBy('createdAt', descending: true);
      if (limit != null) q = q.limit(limit);
      final snap = await q.get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      final snap = await _col(uid, 'skin_checks').get();
      final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      docs.sort((a, b) {
        final aTime = a['createdAtMillis'] ??
            (a['createdAt'] is Timestamp
                ? (a['createdAt'] as Timestamp).millisecondsSinceEpoch
                : 0);
        final bTime = b['createdAtMillis'] ??
            (b['createdAt'] is Timestamp
                ? (b['createdAt'] as Timestamp).millisecondsSinceEpoch
                : 0);
        if (aTime != 0 && bTime != 0) {
          return (bTime as num).compareTo(aTime as num);
        }
        return ((b['createdIso'] ?? '') as String)
            .compareTo((a['createdIso'] ?? '') as String);
      });
      if (limit != null && docs.length > limit) return docs.sublist(0, limit);
      return docs;
    }
  }

  /// Stream riwayat skin check milik pengguna secara realtime.
  static Stream<List<Map<String, dynamic>>> streamSkinChecks(
    String uid, {
    int? limit,
  }) {
    if (!Backend.useFirebase || uid.isEmpty) {
      return Stream<List<Map<String, dynamic>>>.multi((controller) {
        controller.add(List.unmodifiable(_cachedSkinChecks));
        final sub = _cachedSkinChecksController.stream.listen(
          (items) => controller.add(items),
          onError: (e) => controller.addError(e),
        );
        controller.onCancel = () => sub.cancel();
      });
    }
    var q = _col(uid, 'skin_checks').orderBy('createdAt', descending: true);
    if (limit != null) q = q.limit(limit);
    return q
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ---------------------------------------------------------------------------
  // Skin Daily
  // ---------------------------------------------------------------------------
  /// Status turunan dari gejala (konsisten dengan seed UI):
  /// >=2 gejala berat → Buruk; ada gejala masalah → Sedang; selain itu Baik.
  static String deriveDailyStatus(List<String> symptoms) {
    const heavy = {'Jerawat', 'Kemerahan', 'Beruntusan'};
    const moderate = {'Jerawat', 'Kemerahan', 'Kusam', 'Flek/Noda', 'Komedo'};
    final heavyHit = symptoms.where(heavy.contains).length;
    if (heavyHit >= 2) return 'Buruk';
    if (symptoms.any(moderate.contains)) return 'Sedang';
    return 'Baik';
  }

  /// Satu dokumen per user per tanggal (doc ID = dateIso) — anti-duplikat.
  static Future<void> saveSkinDaily({
    required String uid,
    required String name,
    required String dateDisplay,
    required String dateIso,
    required List<String> locations,
    required List<String> symptoms,
    required String kebiasaan,
    required String jamTidur,
    required String air,
    required String makanan,
    required String aktivitas,
    required bool skincarePagi,
    required bool skincareMalam,
  }) async {
    if (!Backend.useFirebase) return;
    final ref = _col(uid, 'skin_dailies').doc(dateIso);
    final data = <String, dynamic>{
      'dateDisplay': dateDisplay,
      'dateIso': dateIso,
      'locations': locations,
      'symptoms': symptoms,
      'kebiasaan': kebiasaan,
      'jamTidur': jamTidur,
      'air': air,
      'makanan': makanan,
      'aktivitas': aktivitas,
      'skincarePagi': skincarePagi,
      'skincareMalam': skincareMalam,
      'status': deriveDailyStatus(symptoms),
      'createdBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!Backend.useFirebase) {
      final idx = _cachedSkinDailies.indexWhere((item) => item['dateIso'] == dateIso);
      final record = <String, dynamic>{
        'id': dateIso,
        ...data,
        'createdAt': AppDates.nowWib(),
      };
      if (idx != -1) {
        _cachedSkinDailies[idx] = record;
      } else {
        _cachedSkinDailies.insert(0, record);
      }
      _cachedSkinDailiesController.add(List.unmodifiable(_cachedSkinDailies));
      await ActivityService.log(
        title: 'Mencatat Skin Daily',
        tag: 'Skin Daily',
        actor: name,
        actorUid: uid,
      );
      return;
    }

    final existing = await ref.get();
    if (existing.exists) {
      await ref.update({
        ...data,
        'createdAt': existing.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
      });
    } else {
      await ref.set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await ActivityService.log(
      title: 'Mencatat Skin Daily',
      tag: 'Skin Daily',
      actor: name,
      actorUid: uid,
    );
  }

  static Future<List<Map<String, dynamic>>> listSkinDailies(
    String uid,
  ) async {
    if (!Backend.useFirebase || uid.isEmpty) {
      return List.unmodifiable(_cachedSkinDailies);
    }
    try {
      final snap = await _col(uid, 'skin_dailies')
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      final snap = await _col(uid, 'skin_dailies').get();
      final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      docs.sort((a, b) => ((b['dateIso'] ?? '') as String).compareTo((a['dateIso'] ?? '') as String));
      return docs;
    }
  }

  /// Stream riwayat skin daily milik pengguna secara realtime.
  static Stream<List<Map<String, dynamic>>> streamSkinDailies(String uid) {
    if (!Backend.useFirebase || uid.isEmpty) {
      return Stream<List<Map<String, dynamic>>>.multi((controller) {
        controller.add(List.unmodifiable(_cachedSkinDailies));
        final sub = _cachedSkinDailiesController.stream.listen(
          (items) => controller.add(items),
          onError: (e) => controller.addError(e),
        );
        controller.onCancel = () => sub.cancel();
      });
    }
    return _col(uid, 'skin_dailies')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ---------------------------------------------------------------------------
  // Skincare routine (upsert per tanggal)
  // ---------------------------------------------------------------------------
  /// Satu dokumen per user per tanggal (doc ID = dateIso).
  /// Morning dan night menulis ke dokumen yang sama (merge).
  /// Mendukung simpan pagi saja, malam saja, atau keduanya sekaligus.
  static Future<void> saveSkincare({
    required String uid,
    required String name,
    required String dateDisplay,
    required String dateIso,
    List<String>? morningSteps,
    List<String>? nightSteps,
    bool? isMorning,
    bool? saveMorning,
    bool? saveNight,
  }) async {
    final bool doMorning =
        saveMorning ?? isMorning ?? (morningSteps != null);
    final bool doNight =
        saveNight ?? (isMorning != null ? !isMorning : nightSteps != null);

    final data = <String, dynamic>{
      'dateDisplay': dateDisplay,
      'dateIso': dateIso,
      if (doMorning) 'morningSteps': morningSteps ?? <String>[],
      if (doMorning) 'morningSaved': true,
      if (doNight) 'nightSteps': nightSteps ?? <String>[],
      if (doNight) 'nightSaved': true,
      'createdBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final String logTitle;
    if (doMorning && doNight) {
      logTitle = 'Mencatat rutinitas skincare pagi & malam';
    } else if (doMorning) {
      logTitle = 'Mencatat rutinitas skincare pagi';
    } else {
      logTitle = 'Mencatat rutinitas skincare malam';
    }

    if (!Backend.useFirebase) {
      final idx = _cachedSkincareLogs.indexWhere((item) => item['dateIso'] == dateIso);
      final existing = idx != -1 ? _cachedSkincareLogs[idx] : <String, dynamic>{};
      final merged = <String, dynamic>{
        'id': dateIso,
        'dateDisplay': dateDisplay,
        'dateIso': dateIso,
        'morningSteps': doMorning
            ? (morningSteps ?? <String>[])
            : (existing['morningSteps'] ?? <String>[]),
        'morningSaved': doMorning
            ? true
            : (existing['morningSaved'] == true),
        'nightSteps': doNight
            ? (nightSteps ?? <String>[])
            : (existing['nightSteps'] ?? <String>[]),
        'nightSaved': doNight
            ? true
            : (existing['nightSaved'] == true),
        'createdBy': uid,
        'createdAt': existing['createdAt'] ?? AppDates.nowWib(),
      };
      if (idx != -1) {
        _cachedSkincareLogs[idx] = merged;
      } else {
        _cachedSkincareLogs.insert(0, merged);
      }
      _cachedSkincareLogsController.add(List.unmodifiable(_cachedSkincareLogs));
      await ActivityService.log(
        title: logTitle,
        tag: 'Skincare',
        actor: name,
        actorUid: uid,
      );
      return;
    }

    final ref = _col(uid, 'skincare_logs').doc(dateIso);
    final existing = await ref.get();
    if (existing.exists) {
      await ref.update({
        ...data,
        'createdAt':
            existing.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
      });
    } else {
      await ref.set({
        ...data,
        if (!doMorning) 'morningSteps': <String>[],
        if (!doMorning) 'morningSaved': false,
        if (!doNight) 'nightSteps': <String>[],
        if (!doNight) 'nightSaved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await ActivityService.log(
      title: logTitle,
      tag: 'Skincare',
      actor: name,
      actorUid: uid,
    );
  }

  static Future<List<Map<String, dynamic>>> listSkincare(
    String uid,
  ) async {
    if (!Backend.useFirebase || uid.isEmpty) {
      return List.unmodifiable(_cachedSkincareLogs);
    }
    try {
      final snap = await _col(uid, 'skincare_logs')
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      final snap = await _col(uid, 'skincare_logs').get();
      final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      docs.sort((a, b) => ((b['dateIso'] ?? '') as String).compareTo((a['dateIso'] ?? '') as String));
      return docs;
    }
  }

  /// Stream riwayat skincare milik pengguna secara realtime.
  static Stream<List<Map<String, dynamic>>> streamSkincare(String uid) {
    if (!Backend.useFirebase || uid.isEmpty) {
      return Stream<List<Map<String, dynamic>>>.multi((controller) {
        controller.add(List.unmodifiable(_cachedSkincareLogs));
        final sub = _cachedSkincareLogsController.stream.listen(
          (items) => controller.add(items),
          onError: (e) => controller.addError(e),
        );
        controller.onCancel = () => sub.cancel();
      });
    }
    return _col(uid, 'skincare_logs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ---------------------------------------------------------------------------
  // Turunan insight
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> aggregateDailies(
    List<Map<String, dynamic>> dailies,
  ) {
    final list = [...dailies];
    String asIso(Map<String, dynamic> d) {
      final raw = (d['dateIso'] as String?) ?? '';
      if (raw.isNotEmpty) return raw;
      final parsed =
          AppDates.tryParseDisplay((d['dateDisplay'] as String?) ?? '');
      return parsed == null ? '' : AppDates.iso(parsed);
    }

    list.sort((a, b) => asIso(b).compareTo(asIso(a)));
    final recent = list.take(7).toList();

    int baik = 0, sedang = 0, buruk = 0;
    final symptomCount = <String, int>{};
    double waterTotal = 0;
    int waterCount = 0;
    int fullRoutineDays = 0;

    for (final d in recent) {
      switch ((d['status'] as String?) ?? 'Baik') {
        case 'Baik':
          baik++;
        case 'Sedang':
          sedang++;
        case 'Buruk':
          buruk++;
      }
      final symptoms = (d['symptoms'] as List?)?.cast<String>() ?? const [];
      for (final s in symptoms) {
        symptomCount[s] = (symptomCount[s] ?? 0) + 1;
      }
      final airRaw = ((d['air'] as String?) ?? '')
          .replaceAll(RegExp('[^0-9.,]'), '')
          .replaceAll(',', '.');
      final air = double.tryParse(airRaw);
      if (air != null) {
        waterTotal += air;
        waterCount++;
      }
      if ((d['skincarePagi'] as bool? ?? false) &&
          (d['skincareMalam'] as bool? ?? false)) {
        fullRoutineDays++;
      }
    }

    final sortedSymptoms = symptomCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topSymptom = sortedSymptoms.isEmpty
        ? '-'
        : '${sortedSymptoms.first.key} (${sortedSymptoms.first.value}x dari ${recent.length} hari)';

    return {
      'baik': baik,
      'sedang': sedang,
      'buruk': buruk,
      'topSymptom': topSymptom,
      'avgWater': waterCount == 0 ? 0.0 : waterTotal / waterCount,
      'fullRoutineDays': fullRoutineDays,
      'window': recent.length,
      'recent': recent,
    };
  }
}
