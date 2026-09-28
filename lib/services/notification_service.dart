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
  // Jembatan antar-isolate: UI isolate tidak berbagi state statis dengan
  // background isolate, jadi payload disimpan dulu ke penyimpanan lokal
  // supaya deep-link tetap berfungsi setelah aplikasi selesai dibuka.
  await NotificationService.persistPendingIntent(payload);
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

  /// Status permission OS yang bisa didengarkan UI (gate izin & halaman
  /// Pengaturan) sehingga selalu reaktif ketika user mengubahnya di system
  /// settings lalu kembali ke aplikasi.
  static final ValueNotifier<bool> permissionGranted =
      ValueNotifier<bool>(true);

  /// Flag "dialog izin sudah pernah ditampilkan" Ã¢â‚¬â€ sekali per perangkat agar
  /// prompt tidak muncul berulang di setiap login.
  static const String _permissionAskedPrefsKey =
      'skinora.notification_permission_asked';

  /// Jembatan payload tap notifikasi antar-isolate: callback tap di background
  /// isolate tidak berbagi state dengan UI isolate, jadi payload ditulis ke
  /// SharedPreferences lalu dipulihkan saat aplikasi dibuka.
  static const String _pendingIntentPrefsKey =
      'skinora.pending_notification_payload';

  /// Listener Firestore notifikasi foreground (fallback bila FCM belum
  /// terkirim / Cloud Functions belum aktif).
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _feedSub;
  static bool _feedPrimed = false;

  /// Listener realtime konsultasi aktif (dokter / pasien).
  static StreamSubscription<dynamic>? _consultationsSub;
  static bool _consultationsPrimed = false;

  /// Map listener pesan chat per-konsultasi (key: consultationId).
  static final Map<String, StreamSubscription<dynamic>> _chatSubsMap =
      <String, StreamSubscription<dynamic>>{};
  /// Set konsultasi yang sudah di-prime (snapshot pertama terlewati).
  static final Set<String> _chatPrimed = <String>{};

  /// Ambang "notifikasi masih segar" untuk jalur Firestore.
  ///
  /// Snapshot pertama (cache lokal → server) bisa memuat dokumen lama yang
  /// baru tersinkron; hanya dokumen dalam rentang ini yang ditampilkan sebagai
  /// native notification supaya tidak ada belasan notifikasi lama sekaligus.
  /// Diperlebar ke 30 menit untuk menangani keterlambatan sinkronisasi
  /// Firestore saat koneksi buruk.
  static const Duration _freshWindow = Duration(minutes: 30);

  // ---------------------------------------------------------------------------
  // Public state
  // ---------------------------------------------------------------------------
  static bool get isInitialized => _initialized;
  static String? get currentUid => _uid;
  static String? get currentRole => _role;
  static bool get appNotificationsEnabled => _appNotificationsEnabled;
  static bool get osPermissionGranted => _osPermissionGranted;

  /// Update status permission sekaligus menyiarkannya ke UI.
  static void _setOsPermission(bool value) {
    _osPermissionGranted = value;
    if (permissionGranted.value != value) {
      permissionGranted.value = value;
    }
  }

  static String userAudience(String uid) => NotificationAudience.user(uid);
  static const String adminAudience = NotificationAudience.legacyAdminRole;

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------
  /// Dipanggil di `main()` SETELAH `Firebase.initializeApp` dan SEBELUM
  /// `runApp`, sehingga shell role sudah memiliki infrastruktur notifikasi.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _appNotificationsEnabled = await _readEnabledPreference();

    await _initLocalNotifications();
    if (Backend.useFirebase) {
      await _initFirebaseMessaging();
      await _initAuthLifecycle();
    }
    _initLifecycleObserver();
    await refreshPermissionStatus();

    NotificationLog.info('NotificationService siap');
  }

  // ---------------------------------------------------------------------------
  // Public API Ã¢â‚¬â€ nama persis seperti kontrak sistem notifikasi
  // ---------------------------------------------------------------------------
  /// Alias [init]: inisialisasi `FlutterLocalNotificationsPlugin`, channel
  /// Android, FCM, listener lifecycle, dan sinkronisasi token/reminder.
  static Future<void> initialize() => init();

  /// Minta izin notifikasi: Android 13+ `POST_NOTIFICATIONS` via
  /// `flutter_local_notifications`, iOS (alert/badge/sound), lalu FCM
  /// (APNs iOS + fallback status Android).
  ///
  /// Urutan ini penting: prompt dari local-notifications adalah yang benar-
  /// benar menampilkan dialog sistem. Panggilan di `main()` sebelum frame
  /// pertama bisa diabaikan OS, jadi jalur utama adalah dialog izin di
  /// `NotificationPermissionGate` (setelah login) dan tombol di Pengaturan.
  ///
  /// OS hanya menampilkan prompt sekali; panggilan berikutnya hanya
  /// membaca status terkini. [force] dipakai tombol "Izinkan Notifikasi"
  /// di Pengaturan untuk memanggil prompt ulang secara eksplisit.
  ///
  /// Mengembalikan `true` bila izin diberikan.
  static Future<bool> requestPermission({bool force = false}) async {
    if (kIsWeb) return _osPermissionGranted;
    if (_permissionRequested && !force) {
      await refreshPermissionStatus();
      return _osPermissionGranted;
    }
    _permissionRequested = true;

    // 1) Prompt resmi sisi local notification (satu-satunya yang memunculkan
    //    dialog POST_NOTIFICATIONS di Android 13+).
    await _ensureLocalInitialized();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _local
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _local
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      NotificationLog.error('prompt izin notifikasi lokal gagal', e);
    }

    // 2) FCM: APNs (iOS) + badge/sound sekaligus fallback status Android.
    if (Backend.useFirebase) {
      try {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        final authorized =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
                settings.authorizationStatus == AuthorizationStatus.provisional;
        if (authorized) _setOsPermission(true);
      } catch (e) {
        NotificationLog.error('requestPermission FCM gagal', e);
      }
    }

    // 3) Status sebenarnya dibaca ulang (Android: areNotificationsEnabled)
    //    agar UI tidak menampilkan "izin aktif" padahal belum.
    await refreshPermissionStatus();
    NotificationLog.info('permission OS = $_osPermissionGranted');
    return _osPermissionGranted;
  }

  /// `true` bila dialog izin sudah pernah ditampilkan di perangkat ini.
  ///
  /// Dipersist di SharedPreferences sehingga prompt hanya muncul sekali,
  /// tetapi status izin tetap dicek ulang setiap aplikasi kembali ke depan.
  static Future<bool> hasAskedPermissionDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_permissionAskedPrefsKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Tandai dialog izin sudah pernah ditampilkan (tidak menunggu hasil).
  static Future<void> markPermissionDialogAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionAskedPrefsKey, true);
    } catch (_) {
      // Best-effort: gagal menyimpan flag hanya berarti dialog bisa muncul lagi.
    }
  }

  /// Simpan payload tap notifikasi ke penyimpanan lokal.
  ///
  /// Dipakai callback tap di background isolate (aplikasi terminated) yang
  /// tidak berbagi state dengan UI isolate; payload dipulihkan saat init
  /// berikutnya lalu diteruskan ke [NotificationRouter].
  static Future<void> persistPendingIntent(
    Map<Object?, Object?> payload,
  ) async {
    if (payload.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingIntentPrefsKey, jsonEncode(payload));
    } catch (e) {
      NotificationLog.error('gagal menyimpan pending intent', e);
    }
  }

  static Future<void> _restorePersistedPendingIntent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingIntentPrefsKey);
      if (raw == null || raw.isEmpty) return;
      await prefs.remove(_pendingIntentPrefsKey);
      final payload = ReminderScheduler.decode(raw);
      if (payload.isEmpty) return;
      NotificationRouter.setPendingIntent(AppNotification.fromMap(payload));
      NotificationLog.info('pending intent dipulihkan dari penyimpanan lokal');
    } catch (e) {
      NotificationLog.error('gagal memulihkan pending intent', e);
    }
  }

  /// Tampilkan notifikasi native sekarang juga (foreground / background
  /// isolate). Idempoten Ã¢â‚¬â€ [SeenCache] memastikan satu `notificationId` hanya
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

  /// Batalkan seluruh notifikasi terjadwal di perangkat ini Ã¢â‚¬â€
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
  /// notifikasi native via [showNotification] Ã¢â‚¬â€ tanpa duplikat karena payload
  /// FCM yang dikirim backend berupa **data-only**.
  static Future<void> handleForegroundMessage(RemoteMessage message) =>
      _onForegroundMessage(message);

  /// Satu-satunya jalur ketika user mengetuk notifikasi yang ditampilkan oleh
  /// `flutter_local_notifications` (payload JSON Ã¢â€ â€™ deep-link [NotificationRouter]).
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

    // iOS: presentasi notifikasi di foreground (alert, badge, sound).
    // Tanpa ini notifikasi FCM yang datang saat app aktif di iOS tidak tampil.
    try {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      NotificationLog.error('setForegroundNotificationPresentationOptions gagal', e);
    }

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

    // Cadangan: payload yang ditulis callback tap di background isolate
    // (state antar-isolate tidak dibagi). Hanya dipakai bila launch details
    // belum membawa intent apa pun.
    if (NotificationRouter.pendingIntent == null) {
      await _restorePersistedPendingIntent();
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
    // logout di bawah Ã¢â‚¬â€ kalau tidak, tap notifikasi saat aplikasi belum
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
    // Chat feed: dengarkan pesan baru di semua konsultasi aktif milik user
    // sebagai fallback jika FCM Cloud Functions belum aktif.
    if (_role == NotificationRole.pengguna ||
        _role == NotificationRole.dokter) {
      unawaited(_subscribeChatFeed());
    }
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

    // Bersihkan listener konsultasi & pesan chat per-konsultasi.
    await _consultationsSub?.cancel();
    _consultationsSub = null;
    _consultationsPrimed = false;

    for (final sub in _chatSubsMap.values) {
      await sub.cancel();
    }
    _chatSubsMap.clear();
    _chatPrimed.clear();

    NotificationController.reset();
    ActiveChatRegistry.clear();
    // Pending intent HANYA dibuang pada logout sungguhan (ada sesi aktif).
    // Saat aplikasi cold-start tanpa sesi, auth listener memanggil handler
    // ini dengan uid null Ã¢â‚¬â€ deep-link dari notification tray harus bertahan
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

  /// Preference "notifikasi aktif" Ã¢â‚¬â€ dibaca is UI maupun isolate background.
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
      // system sudah menampilkannya Ã¢â‚¬â€ jangan ditampilkan dua kali.
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
          // Snapshot pertama = histori yang sudah ada Ã¢â‚¬â€ jangan ditampilkan.
          _feedPrimed = true;
          return;
        }
        for (final change in snap.docChanges) {
          if (change.type != DocumentChangeType.added) continue;
          final data = change.doc.data() ?? const <String, dynamic>{};
          final n = AppNotification.fromMap(<Object?, Object?>{
            'notificationId': change.doc.id,
            ...data,
          });
          // Dokumen lama yang baru tersinkron (cache Ã¢â€ â€™ server) tidak
          // ditampilkan agar tidak muncul belasan notifikasi sekaligus saat
          // aplikasi dibuka; badge & daftar tetap diperbarui halaman
          // Notifikasi (stream Firestore yang sama).
          if (!_isFresh(data['createdAt'])) {
            NotificationLog.info('lewati notifikasi lama: ${n.id}');
            continue;
          }
          unawaited(showLocalNotification(n));
        }
      },
      onError: (Object e) => NotificationLog.error('feed notifikasi', e),
    );
  }

  /// Refresh chat feed setelah ada konsultasi baru (booking baru, dsb.)
  /// agar listener pesan baru langsung aktif tanpa re-login.
  /// Refresh chat feed setelah ada konsultasi baru (booking baru, dsb.)
  /// agar listener pesan aktif segera tanpa re-login.
  static Future<void> refreshChatFeed() async {
    if (_uid == null) return;
    final role = _role;
    if (role != NotificationRole.pengguna && role != NotificationRole.dokter) {
      return;
    }
    await _subscribeChatFeed();
  }

  /// `true` bila `createdAt` dokumen masih dalam [_freshWindow].
  ///
  /// Dokumen tanpa timestamp server (mis. payload FCM murni) dianggap segar.
  static bool _isFresh(Object? createdAt) {
    if (createdAt is! Timestamp) return true;
    final age = DateTime.now().difference(createdAt.toDate());
    return age <= _freshWindow;
  }

  // ---------------------------------------------------------------------------
  // Chat feed fallback (notifikasi pesan baru saat FCM Cloud Functions belum aktif)
  // ---------------------------------------------------------------------------
  /// Dengarkan seluruh konsultasi aktif milik user secara realtime beserta
  /// pesan barunya.
  ///
  /// Anti-spam & keandalan:
  /// * Query sederhana terindeks: where(field == uid).orderBy(createdAt DESC).
  /// * Filter 'selesai' di memori sehingga tidak membutuhkan composite index kompleks.
  /// * Menggunakan stream snapshots() sehingga booking baru langsung terdeteksi
  ///   dan pesan baru langsung dimonitor tanpa re-login!
  /// * Snapshot pertama dilewati (prime) agar pesan lama tidak memunculkan notif.
  /// * Pesan dari diri sendiri tidak dinotifikasikan.
  /// * Ruang yang sedang dibuka ([ActiveChatRegistry]) dikecualikan.
  /// * [SeenCache] mencegah notif ganda dengan jalur FCM / Firestore.
  static Future<void> _subscribeChatFeed() async {
    final uid = _uid;
    final role = _role;
    if (uid == null || role == null || !Backend.useFirebase) return;

    try {
      await _consultationsSub?.cancel();
      _consultationsSub = null;
      _consultationsPrimed = false;

      final db = FirebaseFirestore.instance;
      final field = role == NotificationRole.dokter ? 'doctorId' : 'patientId';

      _consultationsSub = db
          .collection('consultations')
          .where(field, isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(25)
          .snapshots()
          .listen(
        (consultationsSnap) {
          final currentUid = _uid;
          if (currentUid == null) return;

          final activeConsultationIds = <String>{};

          for (final change in consultationsSnap.docChanges) {
            final doc = change.doc;
            final data = doc.data() ?? const <String, dynamic>{};
            final status = (data['status'] as String?) ?? 'terjadwal';
            final consultationId = doc.id;

            if (status == 'selesai') {
              // Konsultasi selesai -> bersihkan listener pesan
              _chatSubsMap.remove(consultationId)?.cancel();
              _chatPrimed.remove(consultationId);
              continue;
            }

            activeConsultationIds.add(consultationId);

            // Notifikasi konsultasi baru secara realtime ketika ada booking masuk
            if (_consultationsPrimed && change.type == DocumentChangeType.added) {
              if (_isFresh(data['createdAt'])) {
                final patientName =
                    (data['patientName'] as String?) ?? 'Pasien';
                final doctorName = (data['doctorName'] as String?) ?? 'Dokter';
                final scheduleDate =
                    (data['scheduleDate'] as String?) ?? '';
                final scheduleTime =
                    (data['scheduleTime'] as String?) ?? '';
                final isDoctor = role == NotificationRole.dokter;

                final notifTitle =
                    isDoctor ? 'Konsultasi Baru' : 'Konsultasi Terjadwal';
                final notifBody = isDoctor
                    ? '$patientName memesan konsultasi untuk jadwal $scheduleDate $scheduleTime.'
                    : 'Konsultasi bersama $doctorName pada $scheduleDate $scheduleTime telah dijadwalkan.';

                final newConsultNotif = AppNotification.forRecipient(
                  type: NotificationType.bookingCreated,
                  recipientId: currentUid,
                  audienceRole: role,
                  title: notifTitle,
                  body: notifBody,
                  entityId: consultationId,
                  consultationId: consultationId,
                  doctorId: (data['doctorId'] as String?) ?? '',
                  patientId: (data['patientId'] as String?) ?? '',
                  route: isDoctor
                      ? NotificationPageRoute.dokterShell
                      : NotificationPageRoute.penggunaRiwayatKonsultasi,
                  targetTab: isDoctor ? NotificationTab.dokterChat : null,
                  createdBy: (data['createdBy'] as String?) ?? currentUid,
                );
                unawaited(showLocalNotification(newConsultNotif));
              }
            }

            // Notifikasi jika status konsultasi berubah menjadi 'berlangsung'
            if (_consultationsPrimed &&
                change.type == DocumentChangeType.modified &&
                status == 'berlangsung') {
              if (role == NotificationRole.pengguna) {
                final doctorName =
                    (data['doctorName'] as String?) ?? 'Dokter';
                final startedNotif = AppNotification.forRecipient(
                  type: NotificationType.consultationStarted,
                  recipientId: currentUid,
                  audienceRole: NotificationRole.pengguna,
                  title: 'Konsultasi Dimulai',
                  body:
                      'Konsultasi bersama $doctorName sudah dimulai. Silahkan masuk ke ruang konsultasi.',
                  entityId: consultationId,
                  consultationId: consultationId,
                  doctorId: (data['doctorId'] as String?) ?? '',
                  patientId: (data['patientId'] as String?) ?? '',
                  route: NotificationPageRoute.penggunaRuangKonsultasi,
                  createdBy: (data['doctorId'] as String?) ?? currentUid,
                );
                unawaited(showLocalNotification(startedNotif));
              }
            }

            // Pasang listener pesan untuk konsultasi aktif bila belum terpasang
            if (!_chatSubsMap.containsKey(consultationId)) {
              _attachMessageListener(consultationId, data);
            }
          }

          if (!_consultationsPrimed) {
            _consultationsPrimed = true;
          }

          // Bersihkan listener untuk konsultasi yang tidak lagi aktif
          final inactiveIds = _chatSubsMap.keys
              .where((id) => !activeConsultationIds.contains(id))
              .toList();
          for (final remId in inactiveIds) {
            _chatSubsMap.remove(remId)?.cancel();
            _chatPrimed.remove(remId);
          }
        },
        onError: (Object e) {
          NotificationLog.error('_subscribeChatFeed consultations stream error', e);
        },
      );

      NotificationLog.info('chat feed realtime subscribed untuk role=$role');
    } catch (e) {
      NotificationLog.error('_subscribeChatFeed gagal', e);
    }
  }

  static void _attachMessageListener(
    String consultationId,
    Map<String, dynamic> consultationData,
  ) {
    final db = FirebaseFirestore.instance;
    final doctorId = (consultationData['doctorId'] as String?) ?? '';
    final patientId = (consultationData['patientId'] as String?) ?? '';
    final doctorName = (consultationData['doctorName'] as String?) ?? 'Dokter';
    final patientName =
        (consultationData['patientName'] as String?) ?? 'Pasien';

    bool primed = false;

    final sub = db
        .collection('consultations')
        .doc(consultationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .listen(
      (msgSnap) {
        if (!primed) {
          // Lewati snapshot pertama (histori pesan yang sudah ada).
          primed = true;
          _chatPrimed.add(consultationId);
          return;
        }

        final currentUid = _uid;
        if (currentUid == null) return;

        for (final change in msgSnap.docChanges) {
          if (change.type != DocumentChangeType.added) continue;

          final msgData = change.doc.data() ?? const <String, dynamic>{};
          final senderId = (msgData['senderId'] as String?) ?? '';
          if (senderId == currentUid) continue; // Jangan menotifikasi diri sendiri

          // Jika user sedang aktif membuka ruang konsultasi ini, lewati native notification
          if (ActiveChatRegistry.isActiveRoom(consultationId)) {
            NotificationLog.info(
              'chat notif dilewati (ruang chat aktif): $consultationId',
            );
            continue;
          }

          final senderIsDoctor = (msgData['senderRole'] as String?) == 'dokter';
          final senderName = senderIsDoctor ? doctorName : patientName;
          final notifTitle = 'Pesan Baru dari $senderName';
          final notifBody = 'Anda menerima pesan baru dari $senderName.';
          final targetRole = senderIsDoctor
              ? NotificationRole.pengguna
              : NotificationRole.dokter;

          final msgId = change.doc.id;
          final n = AppNotification.forRecipient(
            type: NotificationType.consultationMessage,
            recipientId: currentUid,
            audienceRole: targetRole,
            title: notifTitle,
            body: notifBody,
            entityId: consultationId,
            eventId: msgId,
            consultationId: consultationId,
            doctorId: doctorId,
            patientId: patientId,
            createdBy: senderId,
          );

          unawaited(showLocalNotification(n));
          NotificationLog.info(
            'chat feed notif (local): konsultasi=$consultationId msg=$msgId dari=$senderName',
          );
        }
      },
      onError: (Object e) {
        NotificationLog.error('chat feed error ($consultationId)', e);
      },
    );

    _chatSubsMap[consultationId] = sub;
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

    // Cek izin OS
    if (!_osPermissionGranted) {
      final refreshed = await refreshPermissionStatus();
      if (!refreshed) {
        NotificationLog.info(
          'lewati presentasi (izin OS belum diberikan): ${n.id}',
        );
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

    AndroidNotificationDetails buildAndroid(String icon) =>
        AndroidNotificationDetails(
          n.resolvedChannel,
          _channelName(n.resolvedChannel),
          channelDescription: _channelDescription(n.resolvedChannel),
          icon: icon,
          importance: high ? Importance.high : Importance.defaultImportance,
          priority: high ? Priority.high : Priority.defaultPriority,
          color: const Color(0xFF8B2B38),
          playSound: true,
          enableVibration: true,
          autoCancel: true,
        );

    final details = NotificationDetails(
      android: buildAndroid('ic_stat_skinora'),
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
      // Fallback: beberapa perangkat tidak memuat ic_stat_skinora dengan benar
      // (resolusi / XML vector) Ã¢â‚¬â€ pakai ic_launcher sebagai cadangan.
      NotificationLog.error('gagal menampilkan local notification, mencoba fallback icon', e);
      try {
        final fallbackDetails = NotificationDetails(
          android: buildAndroid('@mipmap/ic_launcher'),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: high
                ? InterruptionLevel.timeSensitive
                : InterruptionLevel.active,
          ),
        );
        await _local.show(
          id: localNotificationId(n.id),
          title: n.title,
          body: n.body,
          notificationDetails: fallbackDetails,
          payload: jsonEncode(n.toFcmData()),
        );
        NotificationLog.info('local notification tampil (fallback icon): ${n.id}');
      } catch (e2) {
        NotificationLog.error('gagal menampilkan local notification (fallback)', e2);
      }
    }
  }

  static Future<void> _ensureLocalInitialized() async {
    if (kIsWeb) return;
    if (_localInitialized) return;
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
      await _createChannels();
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
  ///
  /// Mengembalikan status terbaru sehingga pemanggil (gate izin / halaman
  /// Pengaturan) bisa bereaksi tanpa query tambahan.
  static Future<bool> refreshPermissionStatus() async {
    if (kIsWeb) {
      _setOsPermission(true);
      return true;
    }
    await _ensureLocalInitialized();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final enabled = await android?.areNotificationsEnabled();
        if (enabled != null) {
          _setOsPermission(enabled);
        } else if (Backend.useFirebase) {
          final settings =
              await FirebaseMessaging.instance.getNotificationSettings();
          _setOsPermission(
            settings.authorizationStatus == AuthorizationStatus.authorized ||
                settings.authorizationStatus ==
                    AuthorizationStatus.provisional,
          );
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _local.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final options = await ios?.checkPermissions();
        if (options != null) _setOsPermission(options.isEnabled);
      } else {
        // Desktop: tidak ada izin runtime notifikasi.
        _setOsPermission(true);
      }
    } catch (e) {
      NotificationLog.error('cek permission OS gagal', e);
      return _osPermissionGranted;
    }
    NotificationLog.info('permission OS = $_osPermissionGranted');
    return _osPermissionGranted;
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
  /// dan [NotificationRepository.create] melewatkan dokumen yang sudah ada Ã¢â‚¬â€
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

  /// Fan-out ke **semua admin aktif** Ã¢â‚¬â€ satu dokumen per admin sehingga status
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
  // Legacy facade Ã¢â‚¬â€ dipertahankan agar pemanggil existing tidak berubah.
  // ---------------------------------------------------------------------------
  static Future<void> notifyUser({
    required String uid,
    required String title,
    required String description,
    String iconKey = 'bell',
    String type = NotificationType.legacyRingkas,
    required String createdBy,
    String? entityId,
    String? eventId,
    String? consultationId,
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
        eventId: eventId,
        consultationId: consultationId,
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

