import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/services/notification_payload.dart';
import 'package:skinora_app/services/notification_router.dart';
import 'package:skinora_app/services/reminder_scheduler.dart';

/// Unit test logika notifikasi murni (tanpa Firebase / plugin).
///
/// Mencakup kontrak payload, key idempoten, pemetaan channel, resolver
/// deep-link per role, dan parser pengingat.
void main() {
  group('NotificationEventKey', () {
    test('deterministik untuk type + penerima + entity yang sama', () {
      final a = NotificationEventKey.build(
        type: NotificationType.bookingCreated,
        recipientId: 'doc-1',
        entityId: 'slot-9',
      );
      final b = NotificationEventKey.build(
        type: NotificationType.bookingCreated,
        recipientId: 'doc-1',
        entityId: 'slot-9',
      );
      expect(a, b);
      expect(a, 'booking_created__doc-1__slot-9');
    });

    test('berbeda penerima menghasilkan doc ID berbeda (fan-out)', () {
      final admin1 = NotificationEventKey.build(
        type: NotificationType.articlePublished,
        recipientId: 'admin-1',
        entityId: 'art-7',
      );
      final admin2 = NotificationEventKey.build(
        type: NotificationType.articlePublished,
        recipientId: 'admin-2',
        entityId: 'art-7',
      );
      expect(admin1, isNot(admin2));
    });

    test('tanda slash / baris baru dinetralisir agar aman jadi doc ID', () {
      final key = NotificationEventKey.build(
        type: NotificationType.system,
        recipientId: 'a/b',
        entityId: 'x\ny',
      );
      expect(key.contains('/'), isFalse);
      expect(key.contains('\n'), isFalse);
      expect(key, 'system__a-b__x-y');
    });

    test('entity kosong tetap menghasilkan tiga segmen', () {
      final key = NotificationEventKey.build(
        type: NotificationType.system,
        recipientId: 'u1',
      );
      expect(key.split('__'), hasLength(3));
      expect(key, 'system__u1__-');
    });
  });

  group('AppNotification payload', () {
    test('toFirestore -> fromMap mempertahankan data navigasi', () {
      final n = AppNotification.forRecipient(
        type: NotificationType.consultationMessage,
        recipientId: 'patient-1',
        audienceRole: NotificationRole.dokter,
        title: 'Pesan Baru',
        body: 'Anda menerima pesan baru dari dr. Anita.',
        entityId: 'consult-1',
        route: NotificationPageRoute.dokterShell,
        targetTab: NotificationTab.dokterChat,
        iconKey: 'messageSquare',
        createdBy: 'doctor-1',
      );

      final stored = n.toFirestore();
      expect(stored['isUnread'], isTrue);
      expect(stored['isRead'], isFalse);
      expect(stored['description'], n.body);
      expect(stored['recipientUid'], 'patient-1');
      expect(stored['audience'], 'user:patient-1');

      final restored = AppNotification.fromMap(stored);
      expect(restored.id, n.id);
      expect(restored.recipientId, 'patient-1');
      expect(restored.type, NotificationType.consultationMessage);
      expect(restored.audienceRole, NotificationRole.dokter);
      expect(restored.entityId, 'consult-1');
      expect(restored.route, NotificationPageRoute.dokterShell);
      expect(restored.targetTab, NotificationTab.dokterChat);
      expect(restored.body, n.body);
    });

    test('fromMap menerima payload FCM berbasis string', () {
      final n = AppNotification.fromMap(<Object?, Object?>{
        'notificationId': 'booking_created__u1__slot-2',
        'type': 'booking_created',
        'audience': 'user:u1',
        'recipientUid': 'u1',
        'title': 'Booking Baru',
        'body': 'Ada booking baru',
        'entityId': 'slot-2',
        'targetTab': '4',
      });
      expect(n.id, 'booking_created__u1__slot-2');
      expect(n.recipientId, 'u1');
      expect(n.targetTab, 4);
      expect(n.audienceRole, NotificationRole.pengguna);
    });

    test('fromMap tanpa ID apa pun membangun key dari isi payload', () {
      final n = AppNotification.fromMap(<Object?, Object?>{
        'type': 'system',
        'recipientId': 'u9',
        'entityId': 'e9',
      });
      expect(n.id, 'system__u9__e9');
    });
  });

  group('channel + prioritas', () {
    test('event booking/konsultasi memakai channel high', () {
      expect(
        NotificationChannelId.booking,
        AppNotification.channelForType(NotificationType.bookingCreated),
      );
      expect(
        NotificationChannelId.consultation,
        AppNotification.channelForType(
          NotificationType.consultationMessage,
        ),
      );
      expect(
        NotificationChannelId.system,
        AppNotification.channelForType(NotificationType.system),
      );
      expect(
        NotificationChannelId.reminder,
        AppNotification.channelForType(NotificationType.reminder),
      );
    });

    test('hanya event mendesak yang prioritas tinggi', () {
      expect(AppNotification.isHighPriority(NotificationType.bookingCreated),
          isTrue);
      expect(
        AppNotification.isHighPriority(NotificationType.consultationStarted),
        isTrue,
      );
      expect(
        AppNotification.isHighPriority(NotificationType.consultationCompleted),
        isFalse,
      );
      expect(AppNotification.isHighPriority(NotificationType.system),
          isFalse);
      expect(
        AppNotification.isHighPriority(NotificationType.articlePublished),
        isFalse,
      );
    });

    test('tipe legacy tetap dikenali', () {
      expect(NotificationType.isKnown(NotificationType.legacyBooking), isTrue);
      expect(NotificationType.isKnown(NotificationType.legacyRingkas), isTrue);
      expect(NotificationType.isKnown('bukan-tipe'), isFalse);
      expect(NotificationType.isKnown(null), isFalse);
    });
  });

  group('NotificationRouter.resolve', () {
    AppNotification build({
      required String type,
      required String role,
      String? entityId,
      String? route,
      int? targetTab,
    }) =>
        AppNotification(
          id: 'x',
          recipientId: 'u1',
          audience: NotificationAudience.user('u1'),
          audienceRole: role,
          type: type,
          title: 't',
          body: 'b',
          entityId: entityId,
          route: route,
          targetTab: targetTab,
        );

    test('pesan chat pengguna dibuka di ruang konsultasi', () {
      final dest = NotificationRouter.resolve(
        build(
          type: NotificationType.consultationMessage,
          role: NotificationRole.pengguna,
          entityId: 'consult-1',
        ),
      );
      expect(dest.kind, NotificationDestinationKind.room);
      expect(dest.shellRoute, NotificationPageRoute.penggunaShell);
      expect(dest.entityId, 'consult-1');
    });

    test('pesan chat dokter dibuka di ruang chat dokter', () {
      final dest = NotificationRouter.resolve(
        build(
          type: NotificationType.consultationMessage,
          role: NotificationRole.dokter,
          entityId: 'consult-1',
        ),
      );
      expect(dest.kind, NotificationDestinationKind.room);
      expect(dest.shellRoute, NotificationPageRoute.dokterShell);
    });

    test('booking pengguna mengarah ke riwayat konsultasi', () {
      final dest = NotificationRouter.resolve(
        build(
          type: NotificationType.bookingCreated,
          role: NotificationRole.pengguna,
        ),
      );
      expect(dest.kind, NotificationDestinationKind.page);
      expect(dest.pageRoute, NotificationPageRoute.penggunaRiwayatKonsultasi);
    });

    test('artikel terbit mengarah ke edukasi pengguna', () {
      final dest = NotificationRouter.resolve(
        build(
          type: NotificationType.articlePublished,
          role: NotificationRole.pengguna,
          entityId: 'art-1',
        ),
      );
      expect(dest.kind, NotificationDestinationKind.page);
      expect(dest.pageRoute, NotificationPageRoute.penggunaEdukasi);
    });

    test('dokter baru menunggu verifikasi mengarah ke tab Dokter admin', () {
      final dest = NotificationRouter.resolve(
        build(
          type: NotificationType.doctorVerificationPending,
          role: NotificationRole.admin,
        ),
      );
      expect(dest.kind, NotificationDestinationKind.shell);
      expect(dest.shellRoute, NotificationPageRoute.adminShell);
      expect(dest.tabIndex, NotificationTab.adminDokter);
    });

    test('verifikasi dokter mengarah ke tab Profil dokter', () {
      final dest = NotificationRouter.resolve(
        build(type: NotificationType.doctorVerified, role: NotificationRole.dokter),
      );
      expect(dest.tabIndex, NotificationTab.dokterProfil);
    });

    test('pengguna ditangguhkan mengarah ke tab Profil pengguna', () {
      final dest = NotificationRouter.resolve(
        build(
          type: NotificationType.patientSuspended,
          role: NotificationRole.pengguna,
        ),
      );
      expect(dest.tabIndex, NotificationTab.penggunaProfil);
    });

    test('type tak dikenal jatuh ke beranda role (fallback aman)', () {
      final dest = NotificationRouter.resolve(
        build(type: 'tipe-asing', role: NotificationRole.dokter),
      );
      expect(dest.kind, NotificationDestinationKind.shell);
      expect(dest.shellRoute, NotificationPageRoute.dokterShell);
      expect(dest.tabIndex, 0);
    });

    test('role mengikuti audienceRole, bukan menebak dari judul', () {
      final dest = NotificationRouter.resolve(
        build(
          type: NotificationType.system,
          role: NotificationRole.admin,
          route: '/pengguna/notifikasi',
        ),
      );
      expect(dest.shellRoute, NotificationPageRoute.adminShell);
    });
  });

  group('ReminderScheduler', () {
    test('parse jam 07:30 dan 21:00', () {
      expect(ReminderScheduler.parseReminder('07:30'), (7, 30));
      expect(ReminderScheduler.parseReminder('21:00'), (21, 0));
      expect(ReminderScheduler.parseReminder('7:05'), (7, 5));
    });

    test('format tidak valid ditolak', () {
      expect(ReminderScheduler.parseReminder(''), isNull);
      expect(ReminderScheduler.parseReminder('25:00'), isNull);
      expect(ReminderScheduler.parseReminder('07:60'), isNull);
      expect(ReminderScheduler.parseReminder('pagi'), isNull);
    });

    test('payload reminder bisa di-encode dan di-decode', () {
      final payload = AppNotification.forRecipient(
        type: NotificationType.reminder,
        recipientId: 'u1',
        audienceRole: NotificationRole.pengguna,
        title: 'Pengingat Pagi',
        body: 'Saatnya mencatat Skin Daily.',
      ).toFcmData();

      final decoded = ReminderScheduler.decode(jsonEncode(payload));
      expect(decoded['type'], NotificationType.reminder);
      expect(decoded['title'], 'Pengingat Pagi');
      expect(decoded['recipientId'], 'u1');
    });

    test('decode menolak payload rusak tanpa melempar', () {
      expect(ReminderScheduler.decode(null), isEmpty);
      expect(ReminderScheduler.decode(''), isEmpty);
      expect(ReminderScheduler.decode('bukan-json'), isEmpty);
    });
  });
}
