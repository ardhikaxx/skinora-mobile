import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/components/notification_permission.dart';
import 'package:skinora_app/services/active_chat_registry.dart';
import 'package:skinora_app/services/notification_payload.dart';
import 'package:skinora_app/services/notification_router.dart';
import 'package:skinora_app/services/notification_service.dart';
import 'package:skinora_app/services/reminder_scheduler.dart';

/// Unit test logika notifikasi murni (tanpa Firebase / plugin).
///
/// Mencakup kontrak payload, key idempoten, pemetaan channel, resolver
/// deep-link per role, dan parser pengingat.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

    test('eventId membuat doc ID unik per pesan dalam satu konsultasi', () {
      final first = NotificationEventKey.build(
        type: NotificationType.consultationMessage,
        recipientId: 'doc-1',
        entityId: 'consult-1',
        eventId: 'msg-1',
      );
      final second = NotificationEventKey.build(
        type: NotificationType.consultationMessage,
        recipientId: 'doc-1',
        entityId: 'consult-1',
        eventId: 'msg-2',
      );
      expect(first, 'consultation_message__doc-1__consult-1--msg-1');
      expect(first, isNot(second));
    });

    test('eventId kosong/null tidak mengubah format doc ID lama', () {
      expect(
        NotificationEventKey.build(
          type: NotificationType.consultationMessage,
          recipientId: 'doc-1',
          entityId: 'consult-1',
          eventId: '',
        ),
        'consultation_message__doc-1__consult-1',
      );
      expect(
        NotificationEventKey.build(
          type: NotificationType.consultationMessage,
          recipientId: 'doc-1',
          entityId: 'consult-1',
        ),
        'consultation_message__doc-1__consult-1',
      );
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

    test('notifikasi chat per pesan: eventId unik, deep-link tetap sama', () {
      AppNotification chat(String messageId) =>
          AppNotification.forRecipient(
            type: NotificationType.consultationMessage,
            recipientId: 'doc-1',
            audienceRole: NotificationRole.dokter,
            title: 'Pesan Baru',
            body: 'Anda menerima pesan baru dari pasien.',
            entityId: 'consult-1',
            eventId: messageId,
            consultationId: 'consult-1',
            createdBy: 'patient-1',
          );

      final first = chat('msg-1');
      final second = chat('msg-2');

      // Doc ID berbeda → tiap pesan menghasilkan notifikasi baru.
      expect(first.id, isNot(second.id));
      expect(first.eventKey, first.id);

      // Deep-link tetap menunjuk ruang konsultasi yang sama.
      expect(first.entityId, 'consult-1');
      expect(second.entityId, 'consult-1');
      expect(first.consultationId, 'consult-1');

      final restored = AppNotification.fromMap(first.toFirestore());
      expect(restored.id, first.id);
      expect(restored.eventId, 'msg-1');
      expect(restored.consultationId, 'consult-1');
      expect(restored.entityId, 'consult-1');
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

  group('ActiveChatRegistry', () {
    test('isActiveRoom mendeteksi ruang yang sedang dibuka dan ditutup', () {
      expect(ActiveChatRegistry.isActiveRoom('consult-123'), isFalse);

      ActiveChatRegistry.open('consult-123');
      expect(ActiveChatRegistry.isActiveRoom('consult-123'), isTrue);
      expect(ActiveChatRegistry.isActiveRoom('consult-456'), isFalse);

      ActiveChatRegistry.close('consult-123');
      expect(ActiveChatRegistry.isActiveRoom('consult-123'), isFalse);
    });

    test('open dengan null atau string kosong diabaikan dengan aman', () {
      ActiveChatRegistry.open(null);
      ActiveChatRegistry.open('');
      expect(ActiveChatRegistry.isActiveRoom(null), isFalse);
      expect(ActiveChatRegistry.isActiveRoom(''), isFalse);
    });
  });

  group('SeenCache', () {
    setUp(() {
      SeenCache.debugClear();
    });

    test('markIfNew mengembalikan true untuk ID pertama, false untuk duplikat', () async {
      final isNew1 = await SeenCache.markIfNew('notif-unique-1');
      expect(isNew1, isTrue);

      final isNewAgain = await SeenCache.markIfNew('notif-unique-1');
      expect(isNewAgain, isFalse);

      final isNew2 = await SeenCache.markIfNew('notif-unique-2');
      expect(isNew2, isTrue);
    });

    test('markIfNew mengabaikan ID kosong', () async {
      final res = await SeenCache.markIfNew('');
      expect(res, isFalse);
    });
  });

  group('Chat dan Konsultasi Notifikasi Payload', () {
    test('notifikasi chat dokter -> pengguna memiliki targetRole dan consultationId valid', () {
      final n = AppNotification.forRecipient(
        type: NotificationType.consultationMessage,
        recipientId: 'patient-42',
        audienceRole: NotificationRole.pengguna,
        title: 'Pesan Baru dari dr. Anita',
        body: 'Anda menerima pesan baru dari dr. Anita.',
        entityId: 'consult-88',
        eventId: 'msg-99',
        consultationId: 'consult-88',
        doctorId: 'doc-1',
        patientId: 'patient-42',
        createdBy: 'doc-1',
      );

      expect(n.type, NotificationType.consultationMessage);
      expect(n.recipientId, 'patient-42');
      expect(n.audienceRole, NotificationRole.pengguna);
      expect(n.consultationId, 'consult-88');
      expect(n.eventId, 'msg-99');
      expect(n.title, 'Pesan Baru dari dr. Anita');

      final firestoreMap = n.toFirestore();
      expect(firestoreMap['consultationId'], 'consult-88');
      expect(firestoreMap['eventId'], 'msg-99');
      expect(firestoreMap['recipientUid'], 'patient-42');
      expect(firestoreMap['audience'], 'user:patient-42');

      final dest = NotificationRouter.resolve(n);
      expect(dest.kind, NotificationDestinationKind.room);
      expect(dest.shellRoute, NotificationPageRoute.penggunaShell);
      expect(dest.entityId, 'consult-88');
    });

    test('notifikasi chat pengguna -> dokter dibuka di ruang chat dokter', () {
      final n = AppNotification.forRecipient(
        type: NotificationType.consultationMessage,
        recipientId: 'doc-1',
        audienceRole: NotificationRole.dokter,
        title: 'Pesan Baru dari Leonita',
        body: 'Anda menerima pesan baru dari Leonita.',
        entityId: 'consult-88',
        eventId: 'msg-100',
        consultationId: 'consult-88',
        doctorId: 'doc-1',
        patientId: 'patient-42',
        createdBy: 'patient-42',
      );

      final dest = NotificationRouter.resolve(n);
      expect(dest.kind, NotificationDestinationKind.room);
      expect(dest.shellRoute, NotificationPageRoute.dokterShell);
      expect(dest.entityId, 'consult-88');
    });

    test('notifikasi booking baru dokter mengarah ke tab Jadwal dokter', () {
      final n = AppNotification.forRecipient(
        type: NotificationType.bookingCreated,
        recipientId: 'doc-1',
        audienceRole: NotificationRole.dokter,
        title: 'Konsultasi Baru',
        body: 'Leonita memesan konsultasi untuk jadwal 2026-08-28 09:00 - 09:30.',
        entityId: 'consult-88',
        consultationId: 'consult-88',
        doctorId: 'doc-1',
        patientId: 'patient-42',
        route: NotificationPageRoute.dokterShell,
        targetTab: NotificationTab.dokterJadwal,
        createdBy: 'patient-42',
      );

      expect(n.consultationId, 'consult-88');
      final dest = NotificationRouter.resolve(n);
      expect(dest.kind, NotificationDestinationKind.shell);
      expect(dest.shellRoute, NotificationPageRoute.dokterShell);
      expect(dest.tabIndex, NotificationTab.dokterJadwal);
    });

    test('notifikasi konsultasi dimulai mengarah ke ruang konsultasi pengguna', () {
      final n = AppNotification.forRecipient(
        type: NotificationType.consultationStarted,
        recipientId: 'patient-42',
        audienceRole: NotificationRole.pengguna,
        title: 'Konsultasi Dimulai',
        body: 'Konsultasi bersama dr. Anita sudah dimulai. Silakan masuk ke ruang konsultasi.',
        entityId: 'consult-88',
        consultationId: 'consult-88',
        doctorId: 'doc-1',
        patientId: 'patient-42',
        createdBy: 'doc-1',
      );

      expect(n.consultationId, 'consult-88');
      final dest = NotificationRouter.resolve(n);
      expect(dest.kind, NotificationDestinationKind.room);
      expect(dest.shellRoute, NotificationPageRoute.penggunaShell);
      expect(dest.entityId, 'consult-88');
    });
  });

  group('NotificationPermission UI & Gate', () {
    testWidgets('askNotificationPermission dialog returns false when Nanti is tapped', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await askNotificationPermission(context);
                  },
                  child: const Text('Show Dialog'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Notifikasi'), findsOneWidget);
      expect(find.text('Nanti'), findsOneWidget);
      expect(find.text('Izinkan'), findsOneWidget);

      await tester.tap(find.text('Nanti'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.text('Aktifkan Notifikasi'), findsNothing);
    });

    testWidgets('askNotificationPermission dialog returns true when Izinkan is tapped', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await askNotificationPermission(context);
                  },
                  child: const Text('Show Dialog'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Izinkan'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.text('Aktifkan Notifikasi'), findsNothing);
    });

    testWidgets('NotificationPermissionGate wraps child and renders cleanly', (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          builder: (context, child) => NotificationPermissionGate(
            navigatorKey: navKey,
            child: child ?? const SizedBox(),
          ),
          home: const Scaffold(
            body: Center(child: Text('Halaman Utama')),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Halaman Utama'), findsOneWidget);
    });
  });
}

