import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'active_chat_registry.dart';
import 'auth_service.dart';
import 'backend.dart';
import 'device_token_service.dart';
import 'notification_controller.dart';
import 'notification_log.dart';
import 'notification_payload.dart';
import 'notification_repository.dart';
import 'notification_router.dart';
import 'reminder_scheduler.dart';
import 'user_service.dart';

/// ---------------------------------------------------------------------------
/// BACKGROUND HANDLER (top-level, isolate terpisah).
///
/// Wajib berupa fungsi top-level / static dan tidak boleh menyentuh
/// BuildContext. Firebase & plugin diinisialisasi ulang di isolate ini karena
/// state tidak dibagikan dengan UI isolate.
///
/// Dipanggil Firebase Messaging untuk **data-only message** ketika aplikasi
/// berada di background / terminated. Pesan `notification` (yang ditampilkan
/// otomatis oleh system) sengaja TIDAK dipakai Skinora agar judul, icon,
/// channel, sound, dan deep-link tetap terkendali serta tidak pernah dobel.
/// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> skinoraBackgroundMessageHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase init di background isolate gagal: $e');
  }
  await NotificationService.handleBackgroundMessage(message);
}

/// ---------------------------------------------------------------------------
/// LOCAL NOTIFICATION TAP HANDLER (background isolate).
///
/// `flutter_local_notifications` memanggil callback ini di isolate terpisah
/// ketika notification tray di-tap sementara aplikasi terminated.
/// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> skinoraLocalNotificationBackgroundHandler(
  NotificationResponse response,
) async {
  final payload = ReminderScheduler.decode(response.payload);
  if (payload.isEmpty) return;
  NotificationRouter.setPendingIntent(AppNotification.fromMap(payload));
  NotificationLog.info('local notification tap (background)');
}

/// Service terpusat seluruh lifecycle notifikasi:
/// init FCM, permission, channel, token device, foreground/background message,
/// presentasi local notification, tap handler, deep-link, unread, dan cleanup
/// saat logout. Halaman tidak boleh menaruh logika notifikasi sendiri.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static final List<StreamSubscription<dynamic>> _subs =
      <StreamSubscription<dynamic>>[];

  static bool _initialized = false;
  static bool _localInitialized = false;
  static bool _permissionRequested = false;

  static String? _uid;
  static String? _role;
  static bool _appNotificationsEnabled = true;

  /// SharedPreferences key: preference "notifikasi aktif" dipersist agar
  /// isolate background (FCM) menghormati pilihan user yang mematikan
  /// notifikasi di Pengaturan.
  static const String _enabledPrefsKey = 'skinora.notifications_enabled';

  /// Status permission OS (bukan preference aplikasi).
  static bool _osPermissionGranted = true;

  /// Listener Firestore notifikasi foreground (fallback bila FCM belum
  /// terkirim / Cloud Functions belum aktif).
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _feedSub;
  static bool _feedPrimed = false;

  // ---------------------------------------------------------------------------
  // Public state
  // ---------------------------------------------------------------------------
  static bool get isInitialized => _initialized;
  static String? get currentUid => _uid;
  static String? get currentRole => _role;
  static bool get appNotificationsEnabled => _appNotificationsEnabled;
  static bool get osPermissionGranted => _osPermissionGranted;

  static String userAudience(String uid) => NotificationAudience.user(uid);
  static const String adminAudience = NotificationAudience.legacyAdminRole;

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------
  /// Dipanggil di `main()` SETELAH `Firebase.initializeApp` dan SEBELUM
  /// `runApp`, sehingga shell role sudah memiliki infrastruktur notifikasi.
  static Future<void> init() async {
    if (_initialized || !Backend.useFirebase) return;
    _initialized = true;

    _appNotificationsEnabled = await _readEnabledPreference();

    await _initLocalNotifications();
    await _initFirebaseMessaging();
    await _initAuthLifecycle();
    _initLifecycleObserver();

    NotificationLog.info('NotificationService siap');
  }

  // ---------------------------------------------------------------------------
  // Public API — nama persis seperti kontrak sistem notifikasi
  // ---------------------------------------------------------------------------
  /// Alias [init]: inisialisasi `FlutterLocalNotificationsPlugin`, channel
  /// Android, FCM, listener lifecycle, dan sinkronisasi token/reminder.
  static Future<void> initialize() => init();

  /// Minta izin notifikasi: FCM (iOS APNs + badge/sound), Android 13+
  /// `POST_NOTIFICATIONS` via `flutter_local_notifications`, dan izin iOS
  /// sisi local notification.
  ///
  /// OS hanya menampilkan prompt sekali; panggilan berikutnya hanya
  /// membaca status terkini. [force] dipakai tombol "Izinkan Notifikasi"
  /// di Pengaturan untuk memanggil prompt ulang secara eksplisit.
  ///
  /// Mengembalikan `true` bila izin diberikan.
  static Future<bool> requestPermission({bool force = false}) async {
    if (!Backend.useFirebase) return false;
    if (_permissionRequested && !force) {
      await refreshPermissionStatus();
      return _osPermissionGranted;
    }
    _permissionRequested = true;

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      _osPermissionGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      NotificationLog.error('requestPermission gagal', e);
    }

    // Android 13+ juga butuh prompt dari flutter_local_notifications.
    try {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      NotificationLog.error('requestNotificationsPermission gagal', e);
    }

    // iOS: izin alert/badge/sound di sisi local notification.
    try {
      await _local
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      NotificationLog.error('iOS requestPermissions gagal', e);
    }

    NotificationLog.info('permission OS = $_osPermissionGranted');
    return _osPermissionGranted;
  }

  /// Tampilkan notifikasi native sekarang juga (foreground / background
  /// isolate). Idempoten — [SeenCache] memastikan satu `notificationId` hanya
  /// tampil sekali meski datang dari FCM dan Firestore sekaligus.
  static Future<void> showNotification(
    AppNotification n, {
    bool force = false,
  }) =>
      showLocalNotification(n, force: force);

  /// Jadwalkan notifikasi lokal satu kali pada [scheduledDate] (waktu lokal
  /// device). [id] dibuat deterministik bila tidak diisi agar memanggil method
  /// ini berulang tidak pernah menggandakan jadwal.
  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    int? id,
    String? payload,
  }) async {
    if (kIsWeb) return;
    final notificationId = id ?? localNotificationId(
      'scheduled|$title|${scheduledDate.millisecondsSinceEpoch}',
    );
    await ReminderScheduler.scheduleOneShot(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
    );
  }

  /// Batalkan satu notifikasi terjadwal berdasarkan ID.
  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    try {
      await _local.cancel(id: id);
    } catch (e) {
      NotificationLog.error('cancelNotification gagal', e);
    }
  }

  /// Batalkan seluruh notifikasi terjadwal di perangkat ini —
  /// reminder pagi/malam user aktif lalu semua sisa jadwal lokal.
  static Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    final uid = _uid;
    if (uid != null) await ReminderScheduler.cancelAll(uid);
    try {
      await _local.cancelAll();
    } catch (e) {
      NotificationLog.error('cancelAllNotifications gagal', e);
    }
  }

  /// Ambil token FCM perangkat dan simpan ke `users/{uid}/devices/{deviceId}`.
  /// Aman dipanggil ulang (upsert idempoten).
  static Future<void> registerFcmToken() => _registerCurrentToken();

  /// Satu-satunya jalur pemrosesan pesan FCM ketika aplikasi aktif
  /// (`FirebaseMessaging.onMessage`). Mengubah `RemoteMessage.data` menjadi
  /// notifikasi native via [showNotification] — tanpa duplikat karena payload
  /// FCM yang dikirim backend berupa **data-only**.
  static Future<void> handleForegroundMessage(RemoteMessage message) =>
      _onForegroundMessage(message);

  /// Satu-satunya jalur ketika user mengetuk notifikasi yang ditampilkan oleh
  /// `flutter_local_notifications` (payload JSON → deep-link [NotificationRouter]).
  static Future<void> handleNotificationTap(NotificationResponse response) =>
      _onLocalNotificationTap(response);

  static Future<void> _initLocalNotifications() async {
    if (kIsWeb) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    try {
      await _local.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
        onDidReceiveBackgroundNotificationResponse:
            skinoraLocalNotificationBackgroundHandler,
      );
      _localInitialized = true;
    } catch (e) {
      NotificationLog.error('init local notifications gagal', e);
      return;
    }

    await _createChannels();
  }

  /// Membuat seluruh channel satu kali. `createNotificationChannel` no-op
  /// bila channel sudah ada, jadi tidak ada pembuatan berulang yang merusak
  /// preferensi user terhadap channel.
  static Future<void> _createChannels() async {
    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    const channels = <AndroidNotificationChannel>[
      AndroidNotificationChannel(
        NotificationChannelId.general,
        'Umum',
        description: 'Notifikasi umum Skinora.',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        NotificationChannelId.booking,
        'Booking Konsultasi',
        description: 'Booking baru, perubahan, dan pembatalan jadwal.',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        NotificationChannelId.consultation,
        'Konsultasi & Chat',
        description: 'Pesan baru dan status konsultasi.',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        NotificationChannelId.system,
        'Sistem & Informasi',
        description: 'Informasi platform dan artikel terbaru.',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        NotificationChannelId.reminder,
        'Pengingat',
        description: 'Pengingat rutinitas pagi dan malam.',
        importance: Importance.defaultImportance,
      ),
    ];
    for (final channel in channels) {
      try {
        await android.createNotificationChannel(channel);
      } catch (e) {
        NotificationLog.error('gagal membuat channel ${channel.id}', e);
      }
    }
    NotificationLog.info('${channels.length} notification channel siap');
  }

  static Future<void> _initFirebaseMessaging() async {
    FirebaseMessaging.onBackgroundMessage(skinoraBackgroundMessageHandler);

    final messaging = FirebaseMessaging.instance;

    // Permission: iOS (APNs) + Android 13+ (POST_NOTIFICATIONS).
    await requestPermission();

    _subs.add(FirebaseMessaging.onMessage.listen(_onForegroundMessage));
    _subs.add(FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp));
    _subs.add(messaging.onTokenRefresh.listen(_onTokenRefresh));

    try {
      final token = await messaging.getToken();
      NotificationLog.info('FCM token: ${NotificationLog.shortToken(token)}');
    } catch (e) {
      NotificationLog.error('getToken gagal', e);
    }

    // Aplikasi dibuka dari notification tray saat terminated.
    try {
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        await _openFromRemoteMessage(initial, coldStart: true);
      }
    } catch (e) {
      NotificationLog.error('getInitialMessage gagal', e);
    }

    // Local notification yang membuka aplikasi saat terminated.
    try {
      final details = await _local.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        final payload =
            ReminderScheduler.decode(details?.notificationResponse?.payload);
        if (payload.isNotEmpty) {
          NotificationRouter.setPendingIntent(AppNotification.fromMap(payload));
        }
      }
    } catch (e) {
      NotificationLog.error('launch details gagal', e);
    }
  }

  // ---------------------------------------------------------------------------
  // Auth lifecycle
  // ---------------------------------------------------------------------------
  static Future<void> _initAuthLifecycle() async {
    _subs.add(
      AuthService.authStateChanges.listen((User? user) async {
        if (user == null) {
          await handleSignOut();
        } else {
          await handleSignIn(user.uid);
        }
      }),
    );
    // Sudah login saat aplikasi dibuka (hot restart / sesi berlanjut).
    final existing = AuthService.uid;
    if (existing != null) {
      await handleSignIn(existing);
    }
  }

  /// Login: daftarkan token device, muat role, sinkronkan reminder, lalu
  /// lanjutkan pending intent (notification tray yang dibuka sebelum login).
  static Future<void> handleSignIn(String uid) async {
    if (_uid == uid) return;
    // Pending intent dari notification tray harus bertahan melewati cleanup
    // logout di bawah — kalau tidak, tap notifikasi saat aplikasi belum
    // login akan hilang begitu sesi terbentuk.
    final retainedPending = NotificationRouter.pendingIntent;
    await handleSignOut(deactivateDevice: true);
    NotificationRouter.setPendingIntent(retainedPending);

    _uid = uid;
    try {
      final profile = await UserService.loadByUid(uid);
      _role = profile?.role;
      _appNotificationsEnabled = profile?.notificationsEnabled ?? true;
      await _writeEnabledPreference(_appNotificationsEnabled);
    } catch (e) {
      NotificationLog.error('gagal memuat profil notifikasi', e);
    }

    await _registerCurrentToken();
    await _syncRemindersFromProfile();
    _subscribeFeed();
    if (_role == NotificationRole.admin) {
      unawaited(_syncPendingDoctorVerifications());
    }

    NotificationLog.info('notifikasi aktif untuk role=$_role');

    final pending = NotificationRouter.pendingIntent;
    if (pending != null) {
      NotificationRouter.setPendingIntent(null);
      // Tunggu shell role selesai membangun guard-nya.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await _openIfAuthorized(pending);
    }
  }

  /// Logout: nonaktifkan token device ini (device lain tetap aktif),
  /// batalkan reminder lokal, hentikan semua listener.
  static Future<void> handleSignOut({bool deactivateDevice = true}) async {
    final uid = _uid;
    _uid = null;
    _role = null;
    _appNotificationsEnabled = true;

    await _feedSub?.cancel();
    _feedSub = null;
    _feedPrimed = false;

    NotificationController.reset();
    ActiveChatRegistry.clear();
    // Pending intent HANYA dibuang pada logout sungguhan (ada sesi aktif).
    // Saat aplikasi cold-start tanpa sesi, auth listener memanggil handler
    // ini dengan uid null — deep-link dari notification tray harus bertahan
    // sampai user selesai login.
    if (uid != null) {
      NotificationRouter.setPendingIntent(null);
    }

    if (uid != null && deactivateDevice && Backend.useFirebase) {
      try {
        await DeviceTokenService.deactivateCurrent(uid: uid);
      } catch (e) {
        NotificationLog.error('gagal nonaktifkan device', e);
      }
      try {
        await ReminderScheduler.cancelAll(uid);
      } catch (e) {
        NotificationLog.error('gagal batalkan reminder', e);
      }
    }
    NotificationLog.info('listener notifikasi dibersihkan (logout)');
  }

  // ---------------------------------------------------------------------------
  // Device token
  // ---------------------------------------------------------------------------
  static Future<void> _registerCurrentToken() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await DeviceTokenService.upsert(uid: uid, token: token);
    } catch (e) {
      NotificationLog.error('registrasi token gagal', e);
    }
  }

  static Future<void> _onTokenRefresh(String token) async {
    final uid = _uid;
    if (uid == null) return;
    NotificationLog.info('FCM token refresh: ${NotificationLog.shortToken(token)}');
    try {
      await DeviceTokenService.upsert(uid: uid, token: token);
    } catch (e) {
      NotificationLog.error('update token refresh gagal', e);
    }
  }

  // ---------------------------------------------------------------------------
  // Reminder
  // ---------------------------------------------------------------------------
  static Future<void> _syncRemindersFromProfile() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final profile = await UserService.loadByUid(uid);
      if (profile == null || _uid != uid) return;
      _appNotificationsEnabled = profile.notificationsEnabled;
      await ReminderScheduler.sync(
        uid: uid,
        enabled: profile.notificationsEnabled,
        morningReminder: profile.morningReminder,
        eveningReminder: profile.eveningReminder,
      );
    } catch (e) {
      NotificationLog.error('sinkron reminder gagal', e);
    }
  }

  /// Dipanggil halaman Pengaturan setelah user menyimpan preference.
  static Future<void> applyNotificationSettings({
    required bool notificationsEnabled,
    String morningReminder = '',
    String eveningReminder = '',
  }) async {
    _appNotificationsEnabled = notificationsEnabled;
    await _writeEnabledPreference(notificationsEnabled);

    final uid = _uid;
    if (uid == null) return;
    await ReminderScheduler.sync(
      uid: uid,
      enabled: notificationsEnabled,
      morningReminder: morningReminder,
      eveningReminder: eveningReminder,
    );
  }

  /// Preference "notifikasi aktif" — dibaca is UI maupun isolate background.
  static Future<bool> _readEnabledPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledPrefsKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> _writeEnabledPreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledPrefsKey, value);
    } catch (_) {
      // Preference lokal gagal tidak boleh membatalkan penyimpanan settings.
    }
  }

  // ---------------------------------------------------------------------------
  // Foreground
  // ---------------------------------------------------------------------------
  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    if (data.isEmpty) {
      // Pesan `notification` tidak dipakai Skinora; jika tetap datang,
      // system sudah menampilkannya — jangan ditampilkan dua kali.
      NotificationLog.info('pesan notification-type diabaikan (sudah system)');
      return;
    }
    final n = AppNotification.fromMap(data);
    if (n.id.isEmpty) return;
    NotificationLog.info('foreground message: ${n.type}');
    await showLocalNotification(n);
  }

  /// Handler untuk pesan yang diterima di background isolate.
  ///
  /// State statis tidak dibagi antar isolate, jadi preference "notifikasi
  /// aktif" dibaca ulang dari SharedPreferences sebelum menampilkan apa pun.
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    final data = message.data;
    if (data.isEmpty) return;
    if (!await _readEnabledPreference()) {
      NotificationLog.info('background message dilewati (notifikasi nonaktif)');
      return;
    }
    final n = AppNotification.fromMap(data);
    if (n.id.isEmpty) return;
    NotificationLog.info('background message: ${n.type}');
    await showLocalNotification(n, force: true);
  }

  static Future<void> _onMessageOpenedApp(RemoteMessage message) async {
    await _openFromRemoteMessage(message);
  }

  static Future<void> _openFromRemoteMessage(
    RemoteMessage message, {
    bool coldStart = false,
  }) async {
    final data = message.data;
    if (data.isEmpty) return;
    await _openIfAuthorized(AppNotification.fromMap(data));
  }

  // ---------------------------------------------------------------------------
  // Firestore feed foreground (fallback + sumber realtime in-app)
  // ---------------------------------------------------------------------------
  static void _subscribeFeed() {
    final uid = _uid;
    if (uid == null || !Backend.useFirebase) return;
    _feedSub?.cancel();
    _feedPrimed = false;
    _feedSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen(
      (snap) {
        if (!_feedPrimed) {
          // Snapshot pertama = histori yang sudah ada — jangan ditampilkan.
          _feedPrimed = true;
          return;
        }
        for (final change in snap.docChanges) {
          if (change.type != DocumentChangeType.added) continue;
          final n = AppNotification.fromMap({
            'notificationId': change.doc.id,
            ...change.doc.data()!,
          });
          unawaited(showLocalNotification(n));
        }
      },
      onError: (Object e) => NotificationLog.error('feed notifikasi', e),
    );
  }

  // ---------------------------------------------------------------------------
  // Presentasi local notification
  // ---------------------------------------------------------------------------
  /// Tampilkan native notification (foreground / background isolate).
  ///
  /// Anti-duplicate:
  /// * [SeenCache] menjamin satu `notificationId` hanya tampil sekali meski
  ///   datang dari dua jalur (FCM + Firestore) atau dipanggil dua kali.
  /// * Pesan di ruang konsultasi yang sedang dibuka tidak ditampilkan
  ///   (chat realtime yang menangani feedback) tetapi tetap tersimpan di
  ///   Firestore oleh pembuatnya.
  /// * Hanya notifikasi milik user yang sedang login yang tampil.
  static Future<void> showLocalNotification(
    AppNotification n, {
    bool force = false,
  }) async {
    if (n.id.isEmpty) return;
    if (!force) {
      if (_uid != null && n.recipientId.isNotEmpty && n.recipientId != _uid) {
        NotificationLog.info('tolak notifikasi lintas user: ${n.id}');
        return;
      }
      if (!_appNotificationsEnabled) return;
      if (ActiveChatRegistry.isActiveRoom(
        n.consultationId ?? n.entityId,
      )) {
        NotificationLog.info('lewati (ruang chat aktif): ${n.id}');
        return;
      }
    }

    if (!await SeenCache.markIfNew(n.id)) {
      NotificationLog.info('lewati duplikat: ${n.id}');
      return;
    }

    if (!_localInitialized) {
      await _ensureLocalInitialized();
      if (!_localInitialized) return;
    }

    final high = AppNotification.isHighPriority(n.type);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        n.resolvedChannel,
        _channelName(n.resolvedChannel),
        channelDescription: _channelDescription(n.resolvedChannel),
        icon: 'ic_stat_skinora',
        importance: high ? Importance.high : Importance.defaultImportance,
        priority: high ? Priority.high : Priority.defaultPriority,
        color: const Color(0xFF8B2B38),
        playSound: true,
        enableVibration: true,
        autoCancel: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: high
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      ),
    );

    try {
      await _local.show(
        id: localNotificationId(n.id),
        title: n.title,
        body: n.body,
        notificationDetails: details,
        payload: jsonEncode(n.toFcmData()),
      );
      NotificationLog.info('local notification tampil: ${n.id}');
    } catch (e) {
      NotificationLog.error('gagal menampilkan local notification', e);
    }
  }

  static Future<void> _ensureLocalInitialized() async {
    if (!Backend.useFirebase) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _local.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
        onDidReceiveBackgroundNotificationResponse:
            skinoraLocalNotificationBackgroundHandler,
      );
      _localInitialized = true;
    } catch (e) {
      NotificationLog.error('lazy init local notifications gagal', e);
    }
  }

  static String _channelName(String id) {
    switch (id) {
      case NotificationChannelId.booking:
        return 'Booking Konsultasi';
      case NotificationChannelId.consultation:
        return 'Konsultasi & Chat';
      case NotificationChannelId.system:
        return 'Sistem & Informasi';
      case NotificationChannelId.reminder:
        return 'Pengingat';
      default:
        return 'Umum';
    }
  }

  static String _channelDescription(String id) {
    switch (id) {
      case NotificationChannelId.booking:
        return 'Booking baru, perubahan, dan pembatalan jadwal.';
      case NotificationChannelId.consultation:
        return 'Pesan baru dan status konsultasi.';
      case NotificationChannelId.system:
        return 'Informasi platform dan artikel terbaru.';
      case NotificationChannelId.reminder:
        return 'Pengingat rutinitas pagi dan malam.';
      default:
        return 'Notifikasi umum Skinora.';
    }
  }

  /// ID local notification deterministik dari event key (31-bit).
  static int localNotificationId(String eventKey) {
    var hash = 0x811c9dc5;
    for (final code in eventKey.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  // ---------------------------------------------------------------------------
  // Tap handling -> deep-link
  // ---------------------------------------------------------------------------
  static Future<void> _onLocalNotificationTap(NotificationResponse r) async {
    final payload = ReminderScheduler.decode(r.payload);
    if (payload.isEmpty) return;
    await _openIfAuthorized(AppNotification.fromMap(payload));
  }

  /// Satu-satunya pintu masuk navigasi dari notifikasi.
  ///
  /// Menjaga dua jaminan:
  /// * role payload harus cocok dengan role user yang sedang login
  ///   (tidak ada notifikasi lintas role yang bisa dibuka);
  /// * bila user belum login, payload disimpan sebagai pending intent dan
  ///   dilanjutkan setelah guard shell selesai.
  static Future<void> _openIfAuthorized(AppNotification n) async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) {
      NotificationRouter.setPendingIntent(n);
      return;
    }
    if (_uid == null) {
      await handleSignIn(uid);
    }
    final role = _role;
    final payloadRole = NotificationRouter.roleOf(n);
    if (role != null && role.isNotEmpty && payloadRole != role) {
      NotificationLog.info(
        'tolak deep-link lintas role (payload=$payloadRole aktif=$role)',
      );
      return;
    }
    // Payload yang menyebut penerima lain (mis. token device user lain)
    // tidak boleh membuka konten user lain.
    if (n.recipientId.isNotEmpty && n.recipientId != uid) {
      NotificationLog.info('tolak deep-link penerima lain');
      return;
    }
    await NotificationRouter.open(n);
  }

  // ---------------------------------------------------------------------------
  // Permission lifecycle
  // ---------------------------------------------------------------------------
  static _ResumeObserver? _observer;

  static void _initLifecycleObserver() {
    if (_observer != null) return;
    _observer = _ResumeObserver();
    WidgetsBinding.instance.addObserver(_observer!);
  }

  /// Deteksi ulang status permission ketika aplikasi kembali ke foreground
  /// (mis. user baru saja mengaktifkan notifikasi di system settings).
  static Future<void> refreshPermissionStatus() async {
    if (!Backend.useFirebase) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _local.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final options = await ios?.checkPermissions();
        if (options != null) _osPermissionGranted = options.isEnabled;
      } else {
        final android = _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final enabled = await android?.areNotificationsEnabled();
        if (enabled != null) _osPermissionGranted = enabled;
      }
    } catch (e) {
      NotificationLog.error('cek permission OS gagal', e);
      return;
    }
    NotificationLog.info('permission OS = $_osPermissionGranted');
  }

  // ---------------------------------------------------------------------------
  // Fan-out helper
  // ---------------------------------------------------------------------------
  /// Notifikasi "dokter menunggu verifikasi" untuk admin yang sedang login.
  ///
  /// Dokter yang mendaftar tidak boleh menulis dokumen ke subcollection admin
  /// (rules hanya mengizinkan `care_link`/admin), jadi admin menemukan sendiri
  /// daftar `role = dokter, status = menunggu` ketika masuk.
  ///
  /// Idempoten: doc ID = `doctor_verification_pending__{adminUid}__{doctorUid}`,
  /// dan [NotificationRepository.create] melewatkan dokumen yang sudah ada —
  /// membuka aplikasi berulang tidak pernah menggandakan notifikasi.
  static Future<void> _syncPendingDoctorVerifications() async {
    final adminUid = _uid;
    if (adminUid == null || !Backend.useFirebase) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'dokter')
          .where('status', isEqualTo: 'menunggu')
          .get();
      for (final d in snap.docs) {
        final name = (d.data()['name'] as String?) ?? 'Seorang dokter';
        await NotificationRepository.create(
          AppNotification.forRecipient(
            type: NotificationType.doctorVerificationPending,
            recipientId: adminUid,
            audienceRole: NotificationRole.admin,
            title: 'Dokter Menunggu Verifikasi',
            body: '$name telah mendaftar dan menunggu verifikasi Anda.',
            entityId: d.id,
            route: NotificationPageRoute.adminDokter,
            iconKey: 'check',
            createdBy: adminUid,
          ),
        );
      }
      if (snap.docs.isNotEmpty) {
        NotificationLog.info(
          'sinkron dokter menunggu verifikasi: ${snap.docs.length}',
        );
      }
    } catch (e) {
      NotificationLog.error('sync dokter menunggu verifikasi', e);
    }
  }

  /// Fan-out ke **semua admin aktif** — satu dokumen per admin sehingga status
  /// read/unread tidak berbagi antar admin.
  static Future<void> notifyAdmins({
    required String title,
    required String body,
    String type = NotificationType.system,
    String iconKey = 'bell',
    String? entityId,
    String? route,
    int? targetTab,
    String? createdBy,
  }) async {
    if (!Backend.useFirebase) return;
    try {
      final admins = await UserService.listAdminUids();
      for (final adminUid in admins) {
        await NotificationRepository.create(
          AppNotification.forRecipient(
            type: type,
            recipientId: adminUid,
            audienceRole: NotificationRole.admin,
            title: title,
            body: body,
            entityId: entityId,
            route: route,
            targetTab: targetTab,
            iconKey: iconKey,
            createdBy: createdBy,
          ),
        );
      }
      NotificationLog.info('notifyAdmins -> ${admins.length} admin');
    } catch (e) {
      NotificationLog.error('notifyAdmins gagal', e);
    }
  }

  // ---------------------------------------------------------------------------
  // Legacy facade — dipertahankan agar pemanggil existing tidak berubah.
  // ---------------------------------------------------------------------------
  static Future<void> notifyUser({
    required String uid,
    required String title,
    required String description,
    String iconKey = 'bell',
    String type = NotificationType.legacyRingkas,
    required String createdBy,
    String? entityId,
    String? route,
    int? targetTab,
    String? audienceRole,
  }) async {
    if (!Backend.useFirebase) return;
    await NotificationRepository.create(
      AppNotification.forRecipient(
        type: type,
        recipientId: uid,
        audienceRole: audienceRole ?? _role ?? NotificationRole.pengguna,
        title: title,
        body: description,
        entityId: entityId,
        route: route,
        targetTab: targetTab,
        iconKey: iconKey,
        createdBy: createdBy,
      ),
    );
  }

  static Future<List<Map<String, dynamic>>> listForUser(
    String uid, {
    int? limit,
  }) =>
      NotificationRepository.streamForUser(
        uid,
        limit: limit ?? NotificationRepository.pageSize,
      ).first;

  static Stream<List<Map<String, dynamic>>> streamForUser(
    String uid, {
    int? limit,
  }) =>
      NotificationRepository.streamForUser(
        uid,
        limit: limit ?? NotificationRepository.pageSize,
      );

  /// Halaman berikutnya untuk infinite scroll (cursor `createdAt` terakhir).
  static Future<List<Map<String, dynamic>>> loadOlderForUser(
    String uid, {
    required int limit,
    Object? afterCreatedAt,
  }) =>
      NotificationRepository.loadOlderForUser(
        uid,
        limit: limit,
        afterCreatedAt: afterCreatedAt,
      );

  /// Ukuran halaman daftar notifikasi.
  static const int pageSize = NotificationRepository.pageSize;

  static Future<int> countUnread(String uid) =>
      NotificationRepository.countUnreadForUser(uid);

  static Stream<int> unreadStream(String uid) =>
      NotificationRepository.unreadStreamForUser(uid);

  static Future<void> markRead(String uid, String id) =>
      NotificationRepository.markRead(uid, id);
}

/// Observer lifecycle untuk deteksi permission saat app resume.
class _ResumeObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(NotificationService.refreshPermissionStatus());
    }
  }
}

/// Cache ID notifikasi yang sudah ditampilkan.
///
/// Menjaga satu event tidak menghasilkan dua native notification, termasuk
/// ketika event datang dari dua isolate (foreground FCM + background handler).
/// Dibatasi 50 entri terbaru agar tidak tumbuh tanpa batas; persistensi
/// ringkas di SharedPreferences membuatnya lintas isolate.
class SeenCache {
  SeenCache._();

  static const String _prefsKey = 'skinora.seen_notification_ids';
  static const int _max = 50;
  static final List<String> _memory = <String>[];
  static Future<void>? _loaded;

  static Future<void> _ensureLoaded() {
    return _loaded ??= _load();
  }

  static Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_prefsKey) ?? <String>[];
      _memory
        ..clear()
        ..addAll(stored);
    } catch (e) {
      NotificationLog.error('gagal memuat seen cache', e);
    }
  }

  /// Tandai [id]; mengembalikan `false` bila sudah pernah dilihat.
  static Future<bool> markIfNew(String id) async {
    if (id.isEmpty) return false;
    await _ensureLoaded();
    if (_memory.contains(id)) return false;
    _memory.insert(0, id);
    if (_memory.length > _max) {
      _memory.removeRange(_max, _memory.length);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _memory);
    } catch (e) {
      NotificationLog.error('gagal menyimpan seen cache', e);
    }
    return true;
  }

  static void debugClear() {
    _memory.clear();
    _loaded = null;
  }
}
