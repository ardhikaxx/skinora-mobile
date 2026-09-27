import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'backend.dart';
import 'notification_log.dart';
import 'notification_payload.dart';

/// Scheduled local notification untuk **Pengingat Pagi/Malam** di
/// Pengaturan Role Pengguna.
///
/// Berbeda dari push notification event: reminder ini sepenuhnya lokal,
/// dijadwalkan di perangkat, dan tidak membutuhkan server.
///
/// Kontrak:
/// * Preference disimpan di Firestore (`users/{uid}.settings.morningReminder`
///   dan `settings.eveningReminder`, format `HH.MM`).
/// * Mengubah jam ⇒ schedule lama dibatalkan dulu lalu diganti (tidak dobel).
/// * `notificationsEnabled = false` ⇒ seluruh schedule dibatalkan.
/// * ID deterministik (`uid` + jenis reminder) ⇒ membuka aplikasi berkali-kali
///   tidak pernah menggandakan pengingat.
class ReminderScheduler {
  ReminderScheduler._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _timezoneReady = false;

  /// Zona yang dipakai untuk menghitung waktu fire.
  ///
  /// Konsisten dengan `AppDates` yang memakai zona Indonesia; offset device
  /// dipetakan ke zona IANA terdekat (WIB/WITA/WIT).
  static String resolveLocationName({DateTime? now}) {
    final totalMinutes = (now ?? DateTime.now()).timeZoneOffset.inMinutes;
    if (totalMinutes == 8 * 60) return 'Asia/Makassar';
    if (totalMinutes == 9 * 60) return 'Asia/Jayapura';
    return 'Asia/Jakarta';
  }

  static Future<void> _ensureTimezone() async {
    if (_timezoneReady) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(resolveLocationName()));
    } catch (e) {
      NotificationLog.error(
        'zona waktu tidak dikenal, fallback Asia/Jakarta',
        e,
      );
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }
    _timezoneReady = true;
  }

  /// ID deterministik per user + jenis reminder (31-bit, aman di Android).
  static int notificationId(String uid, String kind) {
    var hash = 0x811c9dc5; // FNV-1a offset basis
    final input = '$uid|$kind';
    for (final code in input.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static const List<String> _kinds = <String>['morning', 'evening'];

  static Future<void> _cancel(String uid) async {
    for (final kind in _kinds) {
      try {
        await _plugin.cancel(id: notificationId(uid, kind));
      } catch (e) {
        NotificationLog.error('gagal membatalkan reminder $kind', e);
      }
    }
  }

  /// Sinkronkan schedule dengan preference terbaru.
  ///
  /// Selalu membatalkan schedule lama terlebih dahulu sehingga aman dipanggil
  /// berulang (idempotent).
  static Future<void> sync({
    required String uid,
    required bool enabled,
    String morningReminder = '',
    String eveningReminder = '',
  }) async {
    if (!Backend.useFirebase || uid.isEmpty) return;
    await _ensureTimezone();
    await _cancel(uid);
    if (!enabled) {
      NotificationLog.info('reminder dibatalkan (notifikasi nonaktif)');
      return;
    }

    await _schedule(
      uid: uid,
      kind: 'morning',
      raw: morningReminder,
      title: 'Pengingat Pagi Skinora',
      body: 'Saatnya mencatat Skin Daily dan merawat kulit pagi ini.',
    );
    await _schedule(
      uid: uid,
      kind: 'evening',
      raw: eveningReminder,
      title: 'Pengingat Malam Skinora',
      body: 'Jangan lupa mencatat Skin Daily dan rutinitas malam Anda.',
    );
  }

  static Future<void> _schedule({
    required String uid,
    required String kind,
    required String raw,
    required String title,
    required String body,
  }) async {
    final parsed = parseReminder(raw);
    if (parsed == null) return;
    final (hour, minute) = parsed;

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final payload = AppNotification.forRecipient(
      type: NotificationType.reminder,
      recipientId: uid,
      audienceRole: NotificationRole.pengguna,
      title: title,
      body: body,
      route: NotificationPageRoute.penggunaShell,
      targetTab: 0,
      metadata: <String, String>{'reminder': kind},
    ).toFcmData();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationChannelId.reminder,
        'Pengingat Skinora',
        channelDescription: 'Pengingat rutinitas Skin Daily pagi dan malam.',
        icon: 'ic_stat_skinora',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: const Color(0xFF8B2B38),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id: notificationId(uid, kind),
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduled, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: jsonEncode(payload),
      );
      NotificationLog.info(
        'reminder $kind dijadwalkan '
        '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      NotificationLog.error('gagal menjadwalkan reminder $kind', e);
    }
  }

  /// Pastikan database timezone siap dipakai oleh [scheduleOneShot].
  static Future<void> ensureTimezone() => _ensureTimezone();

  /// Jadwalkan notifikasi lokal **satu kali** pada [scheduledDate] (waktu lokal
  /// device). [id] harus deterministik agar tidak ada jadwal ganda.
  static Future<void> scheduleOneShot({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _ensureTimezone();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationChannelId.general,
        'Skinora',
        channelDescription: 'Notifikasi umum Skinora.',
        icon: 'ic_stat_skinora',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFF8B2B38),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
      NotificationLog.info('schedule one-shot id=$id');
    } catch (e) {
      NotificationLog.error('gagal menjadwalkan one-shot', e);
    }
  }

  /// Batalkan semua reminder milik user (logout / mematikan notifikasi).
  static Future<void> cancelAll(String uid) async {
    if (!Backend.useFirebase || uid.isEmpty) return;
    await _ensureTimezone();
    await _cancel(uid);
  }

  /// Parse `HH.MM` / `HH:MM` / `H:MM` menjadi `(hour, minute)`.
  /// Mengembalikan null bila format tidak valid.
  static (int, int)? parseReminder(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final parts = value.split(RegExp(r'[:.]'));
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour, minute);
  }

  /// Decode payload local notification kembali menjadi map seragam
  /// (sama dengan FCM data message).
  static Map<Object?, Object?> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const <Object?, Object?>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded;
    } catch (e) {
      NotificationLog.error('payload notification tidak valid', e);
    }
    return const <Object?, Object?>{};
  }
}
