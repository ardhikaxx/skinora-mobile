/// Kontrak payload notifikasi Skinora.
///
/// File ini adalah **satu-satunya** sumber kebenaran untuk:
/// * notification type (enum string yang dipakai client, Firestore, dan FCM)
/// * Android notification channel + prioritasnya
/// * struktur payload persisten (Firestore) sekaligus payload push (FCM)
/// * key ID deterministik untuk mencegah notification ganda
///
/// Prinsip:
/// * Deep-link tidak pernah ditentukan dari title/body — hanya dari [type]
///   dan [route]/[targetTab] yang eksplisit.
/// * Title/body tidak pernah memuat isi chat / data medis sensitif (privacy
///   lock screen).
library;

/// Channel notification Android/iOS. Identifier **stabil** — jangan diubah
/// setelah rilis karena user tidak bisa mengganti channel yang sudah dibuat.
class NotificationChannelId {
  NotificationChannelId._();

  static const String general = 'skinora_general';
  static const String consultation = 'skinora_consultation';
  static const String booking = 'skinora_booking';
  static const String system = 'skinora_system';
  static const String reminder = 'skinora_reminder';
}

/// Seluruh notification type yang dipakai Skinora.
///
/// Jangan memakai type generik seperti `ringkas` untuk event bisnis baru —
/// tambahkan type di sini + baris di `docs/NOTIFICATION_MATRIX.md`.
class NotificationType {
  NotificationType._();

  // --- Booking -------------------------------------------------------------
  static const String bookingCreated = 'booking_created';
  static const String bookingConfirmed = 'booking_confirmed';
  static const String bookingCancelled = 'booking_cancelled';

  // --- Konsultasi ----------------------------------------------------------
  static const String consultationStarted = 'consultation_started';
  static const String consultationMessage = 'consultation_message';
  static const String consultationCompleted = 'consultation_completed';

  // --- Akun (admin -> user/dokter) -----------------------------------------
  static const String doctorVerified = 'doctor_verified';
  static const String doctorRejected = 'doctor_rejected';
  static const String doctorSuspended = 'doctor_suspended';
  static const String doctorReactivated = 'doctor_reactivated';
  static const String patientSuspended = 'patient_suspended';
  static const String patientReactivated = 'patient_reactivated';

  // --- Admin audience ------------------------------------------------------
  static const String doctorVerificationPending = 'doctor_verification_pending';

  // --- Jadwal --------------------------------------------------------------
  static const String scheduleCreated = 'schedule_created';
  static const String scheduleChanged = 'schedule_changed';
  static const String scheduleCancelled = 'schedule_cancelled';

  // --- Konten & sistem -----------------------------------------------------
  static const String articlePublished = 'article_published';
  static const String system = 'system';
  static const String reminder = 'reminder';

  /// Legacy value yang masih dipakai dokumen lama.
  static const String legacyBooking = 'booking';
  static const String legacyConsultation = 'konsultasi';
  static const String legacyRingkas = 'ringkas';

  static const List<String> all = <String>[
    bookingCreated,
    bookingConfirmed,
    bookingCancelled,
    consultationStarted,
    consultationMessage,
    consultationCompleted,
    doctorVerified,
    doctorRejected,
    doctorSuspended,
    doctorReactivated,
    patientSuspended,
    patientReactivated,
    doctorVerificationPending,
    scheduleCreated,
    scheduleChanged,
    scheduleCancelled,
    articlePublished,
    system,
    reminder,
    legacyBooking,
    legacyConsultation,
    legacyRingkas,
  ];

  static bool isKnown(String? type) => type != null && all.contains(type);
}

/// Nilai yang valid untuk field `audience` pada dokumen `notifications`.
///
/// Keamanan: dokumen hanya boleh dibaca oleh penerima yang cocok —
/// Security Rules memvalidasi `user:{uid}` terhadap `request.auth.uid`.
class NotificationAudience {
  NotificationAudience._();

  static String user(String uid) => 'user:$uid';

  /// Legacy broadcast admin (dokumen lama). Dokumen baru memakai
  /// [user] per-admin agar state read/unread tidak berbagi antar admin.
  static const String legacyAdminRole = 'role:admin';
}

/// Role aplikasi (konsisten dengan field `users/{uid}.role`).
class NotificationRole {
  NotificationRole._();

  static const String pengguna = 'pengguna';
  static const String dokter = 'dokter';
  static const String admin = 'admin';

  static const List<String> all = <String>[pengguna, dokter, admin];
}

/// Nilai `targetTab` (index tab shell 0..4) yang dipakai deep-link.
class NotificationTab {
  NotificationTab._();

  // Shell pengguna: 0 Beranda, 1 Skin Check, 2 Skin Daily, 3 Skincare, 4 Profil
  static const int penggunaProfil = 4;

  // Shell dokter: 0 Beranda, 1 Jadwal, 2 Chat, 3 Riwayat, 4 Profil
  static const int dokterJadwal = 1;
  static const int dokterChat = 2;
  static const int dokterRiwayat = 3;
  static const int dokterProfil = 4;

  // Shell admin: 0 Beranda, 1 Dokter, 2 Pengguna, 3 Edukasi, 4 Profil
  static const int adminDokter = 1;
  static const int adminPengguna = 2;
  static const int adminEdukasi = 3;
}

/// Route named aplikasi yang dipakai deep-link (lihat `lib/main.dart`).
class NotificationPageRoute {
  NotificationPageRoute._();

  static const String penggunaShell = '/pengguna';
  static const String dokterShell = '/dokter';
  static const String adminShell = '/admin';

  static const String penggunaNotifikasi = '/pengguna/notifikasi';
  static const String penggunaRiwayatKonsultasi = '/pengguna/riwayat-konsultasi';
  static const String penggunaEdukasi = '/pengguna/edukasi';

  static const String dokterNotifikasi = '/dokter/notifikasi';
  static const String dokterRiwayat = '/dokter/riwayat';

  static const String adminNotifikasi = '/admin/notifikasi';
  static const String adminDokter = '/admin/dokter';

  /// Route yang dibuka dengan argumen (tidak bisa dipakai pushNamed).
  static const String penggunaRuangKonsultasi = '/pengguna/ruang-konsultasi';
  static const String dokterRuangChat = '/dokter/chat/ruang';
}

/// Payload notifikasi terstruktur — dipakai untuk Firestore document sekaligus
/// FCM data message (keduanya memakai field names yang sama agar satu parser).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.audience,
    required this.audienceRole,
    required this.type,
    required this.title,
    required this.body,
    this.description,
    this.entityId,
    this.route,
    this.targetTab,
    this.consultationId,
    this.bookingId,
    this.doctorId,
    this.patientId,
    this.articleId,
    this.slotId,
    this.channel,
    this.iconKey = 'bell',
    this.createdBy,
    this.metadata = const <String, String>{},
  });

  final String id;
  final String recipientId;
  final String audience;
  final String audienceRole;
  final String type;
  final String title;

  /// Body aman untuk lock screen (tanpa isi chat / data medis).
  final String body;

  /// Alias legacy [body] — dokumen lama memakai `description`.
  final String? description;

  final String? entityId;
  final String? route;
  final int? targetTab;
  final String? consultationId;
  final String? bookingId;
  final String? doctorId;
  final String? patientId;
  final String? articleId;
  final String? slotId;
  final String? channel;
  final String iconKey;
  final String? createdBy;
  final Map<String, String> metadata;

  /// Konstruktor praktis untuk satu penerima.
  ///
  /// [id] dihitung deterministik dari type + penerima + [entityId] sehingga
  /// event yang sama tidak pernah menghasilkan dua dokumen.
  factory AppNotification.forRecipient({
    required String type,
    required String recipientId,
    required String audienceRole,
    required String title,
    required String body,
    String? entityId,
    String? route,
    int? targetTab,
    String? consultationId,
    String? bookingId,
    String? doctorId,
    String? patientId,
    String? articleId,
    String? slotId,
    String iconKey = 'bell',
    String? createdBy,
    Map<String, String> metadata = const <String, String>{},
  }) {
    return AppNotification(
      id: NotificationEventKey.build(
        type: type,
        recipientId: recipientId,
        entityId: entityId,
      ),
      recipientId: recipientId,
      audience: NotificationAudience.user(recipientId),
      audienceRole: audienceRole,
      type: type,
      title: title,
      body: body,
      entityId: entityId,
      route: route,
      targetTab: targetTab,
      consultationId: consultationId,
      bookingId: bookingId,
      doctorId: doctorId,
      patientId: patientId,
      articleId: articleId,
      slotId: slotId,
      iconKey: iconKey,
      createdBy: createdBy,
      metadata: metadata,
    );
  }

  /// Channel yang dipakai untuk type ini.
  String get resolvedChannel => channel ?? channelForType(type);

  /// Deep-link yang dipakai untuk type ini bila [route] tidak diisi.
  String get resolvedRoute => route ?? NotificationPageRoute.penggunaShell;

  /// Dokumen Firestore yang akan ditulis (belum termasuk server timestamp).
  ///
  /// Field `description` diisi dari [body] agar halaman Notifikasi existing
  /// (yang membaca `description` + `isUnread`) tetap berfungsi tanpa perubahan.
  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'id': id,
      'recipientId': recipientId,
      // `recipientUid` adalah field yang divalidasi Security Rules;
      // `recipientId` adalah alias modern agar payload FCM & Firestore seragam.
      'recipientUid': recipientId,
      'audience': audience,
      'audienceRole': audienceRole,
      'type': type,
      'title': title,
      'body': body,
      'description': description ?? body,
      'isRead': false,
      'isUnread': true,
      'readAt': null,
      'entityId': entityId,
      'route': resolvedRoute,
      'targetTab': targetTab,
      'consultationId': consultationId,
      'bookingId': bookingId,
      'doctorId': doctorId,
      'patientId': patientId,
      'articleId': articleId,
      'slotId': slotId,
      'channel': resolvedChannel,
      'iconKey': iconKey,
      'createdBy': createdBy ?? recipientId,
      'eventKey': eventKey,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  /// Key idempoten: `type` + penerima + entity.
  ///
  /// Ditulis oleh Cloud Functions dan client dengan doc ID yang sama sehingga
  /// retry / dua code path tidak pernah menghasilkan dokumen ganda.
  String get eventKey => NotificationEventKey.build(
        type: type,
        recipientId: recipientId,
        entityId: entityId,
      );

  /// Map untuk FCM **data-only message** (tanpa blok `notification`).
  Map<String, String> toFcmData() {
    return <String, String>{
      'notificationId': id,
      'type': type,
      'audience': audience,
      'audienceRole': audienceRole,
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'route': resolvedRoute,
      'channel': resolvedChannel,
      'entityId': ?entityId,
      'targetTab': ?targetTab?.toString(),
      'consultationId': ?consultationId,
      'bookingId': ?bookingId,
      'doctorId': ?doctorId,
      'patientId': ?patientId,
      'articleId': ?articleId,
      'slotId': ?slotId,
      'createdBy': ?createdBy,
      'eventKey': eventKey,
    };
  }

  /// Parse dari FCM data map / Firestore map (semua nilai berupa String di
  /// FCM, native type di Firestore).
  factory AppNotification.fromMap(Map<Object?, Object?> map) {
    String? str(String key) {
      final v = map[key];
      if (v == null) return null;
      final s = v.toString();
      return s.isEmpty ? null : s;
    }

    final type = str('type') ?? NotificationType.system;
    final audienceRaw = str('audience');
    final recipientId = str('recipientId') ??
        str('recipientUid') ??
        (audienceRaw != null && audienceRaw.startsWith('user:')
            ? audienceRaw.substring('user:'.length)
            : '');
    final id = str('notificationId') ??
        str('id') ??
        str('eventKey') ??
        NotificationEventKey.build(
          type: type,
          recipientId: recipientId,
          entityId: str('entityId'),
        );
    final body = str('body') ?? str('description') ?? '';
    final tabRaw = str('targetTab');
    final tab = tabRaw == null ? null : int.tryParse(tabRaw);

    return AppNotification(
      id: id,
      recipientId: recipientId,
      audience: audienceRaw ??
          (recipientId.isEmpty
              ? NotificationAudience.legacyAdminRole
              : NotificationAudience.user(recipientId)),
      audienceRole: str('audienceRole') ?? NotificationRole.pengguna,
      type: type,
      title: str('title') ?? 'Skinora',
      body: body,
      description: str('description'),
      entityId: str('entityId'),
      route: str('route'),
      targetTab: tab,
      consultationId: str('consultationId'),
      bookingId: str('bookingId'),
      doctorId: str('doctorId'),
      patientId: str('patientId'),
      articleId: str('articleId'),
      slotId: str('slotId'),
      channel: str('channel'),
      iconKey: str('iconKey') ?? 'bell',
      createdBy: str('createdBy'),
    );
  }

  /// Channel Android/iOS untuk sebuah type.
  ///
  /// Hanya event yang benar-benar butuh perhatian segera (booking,
  /// konsultasi) yang memakai importance `high`; sisanya `default` agar
  /// tidak semua notifikasi jadi high priority.
  static String channelForType(String type) {
    switch (type) {
      case NotificationType.bookingCreated:
      case NotificationType.bookingConfirmed:
      case NotificationType.bookingCancelled:
        return NotificationChannelId.booking;
      case NotificationType.consultationStarted:
      case NotificationType.consultationMessage:
      case NotificationType.consultationCompleted:
        return NotificationChannelId.consultation;
      case NotificationType.reminder:
        return NotificationChannelId.reminder;
      case NotificationType.system:
      case NotificationType.doctorVerificationPending:
      case NotificationType.articlePublished:
        return NotificationChannelId.system;
      default:
        return NotificationChannelId.general;
    }
  }

  /// `true` bila type ini layak memakai priority high.
  static bool isHighPriority(String type) {
    switch (type) {
      case NotificationType.bookingCreated:
      case NotificationType.bookingConfirmed:
      case NotificationType.consultationStarted:
      case NotificationType.consultationMessage:
        return true;
      default:
        return false;
    }
  }
}

/// Pembuat ID deterministik untuk notification document.
///
/// Format: `{type}__{recipient}__{entity}` — aman untuk doc ID Firestore
/// (tanpa `/`), maksimum 1500 byte, dan selalu sama untuk event yang sama.
class NotificationEventKey {
  NotificationEventKey._();

  static String build({
    required String type,
    required String recipientId,
    String? entityId,
  }) {
    final safeType = _sanitize(type.isEmpty ? NotificationType.system : type);
    final safeRecipient = _sanitize(recipientId);
    final safeEntity = _sanitize(entityId ?? '');
    const sep = '__';
    return '$safeType$sep$safeRecipient$sep$safeEntity';
  }

  static String _sanitize(String value) {
    final v = value.replaceAll(RegExp(r'[/\n\r]'), '-').trim();
    return v.isEmpty ? '-' : v;
  }
}
