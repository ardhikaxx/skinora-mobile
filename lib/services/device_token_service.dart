import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend.dart';
import 'notification_log.dart';

/// Registry device token FCM: `users/{uid}/devices/{deviceId}`.
///
/// Kenapa subcollection per user:
/// * Security Rules mudah: hanya pemilik UID yang boleh menulis tokennya.
/// * Satu user bisa login di banyak perangkat — token lain tidak tersentuh.
/// * Logout cukup menonaktifkan **satu** device (`isActive: false`), bukan
///   menghapus seluruh histori notifikasi.
class DeviceTokenService {
  DeviceTokenService._();

  static const String _devicePrefsKey = 'skinora.device_id';

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static String get platformName {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  /// ID perangkat yang stabil selama instalasi yang sama.
  ///
  /// Disimpan di SharedPreferences; bila belum ada dibuat random.
  static Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_devicePrefsKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _generateId();
    await prefs.setString(_devicePrefsKey, generated);
    return generated;
  }

  static String _generateId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static DocumentReference<Map<String, dynamic>> _ref(String uid, String id) =>
      _db.collection('users').doc(uid).collection('devices').doc(id);

  /// Simpan / perbarui token device ini untuk [uid].
  static Future<void> upsert({
    required String uid,
    required String token,
  }) async {
    if (!Backend.useFirebase || uid.isEmpty || token.isEmpty) return;
    final id = await deviceId();
    final now = FieldValue.serverTimestamp();
    try {
      final doc = _ref(uid, id);
      final snap = await doc.get();
      final data = <String, dynamic>{
        'token': token,
        'platform': platformName,
        'isActive': true,
        'updatedAt': now,
        'lastSeenAt': now,
      };
      if (snap.exists) {
        await doc.update(data);
      } else {
        await doc.set(<String, dynamic>{
          ...data,
          'deviceId': id,
          'createdAt': now,
        });
      }
      NotificationLog.info('device token tersimpan ($platformName)');
    } catch (e) {
      NotificationLog.error('gagal simpan device token', e);
    }
  }

  /// Nonaktifkan device ini (dipanggil saat logout) tanpa menyentuh device
  /// milik sesi lain.
  static Future<void> deactivateCurrent({required String uid}) async {
    if (!Backend.useFirebase || uid.isEmpty) return;
    try {
      final id = await deviceId();
      await _ref(uid, id).update(<String, dynamic>{
        'isActive': false,
        'token': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      NotificationLog.info('device token dinonaktifkan (logout)');
    } catch (e) {
      NotificationLog.error('gagal nonaktifkan device token', e);
    }
  }

  /// Daftar token aktif milik [uid] — dipakai Cloud Functions / debugging.
  static Future<List<String>> activeTokens(String uid) async {
    if (!Backend.useFirebase || uid.isEmpty) return const [];
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) => (d.data()['token'] as String?) ?? '')
        .where((t) => t.isNotEmpty)
        .toList();
  }
}
