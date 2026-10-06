import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/empty_state.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/notification_payload.dart';
import '../../services/notification_router.dart';
import '../../services/notification_service.dart';
import '../../utils/app_dates.dart';

class PenggunaNotificationModel {
  final String id;
  final String title;
  final String description;
  final String time;
  final IconData icon;
  bool isUnread;

  /// Salinan dokumen Firestore — dipakai NotificationRouter.open() ketika
  /// user mengetuk notifikasi.
  final Map<String, dynamic> raw;

  PenggunaNotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.isUnread,
    this.raw = const <String, dynamic>{},
  });
}

class NotifikasiPenggunaPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final List<PenggunaNotificationModel>? initialNotifications;

  const NotifikasiPenggunaPage({
    super.key,
    this.onNavigateTab,
    this.initialNotifications,
  });

  @override
  State<NotifikasiPenggunaPage> createState() => _NotifikasiPenggunaPageState();
}

class _NotifikasiPenggunaPageState extends State<NotifikasiPenggunaPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF555555);
  static const Color dateText = Color(0xFF8E8E93);
  static const Color peachIconBg = Color(0xFFFFD5C3);

  late final List<PenggunaNotificationModel> _notifications =
      widget.initialNotifications != null
          ? List.from(widget.initialNotifications!)
          : <PenggunaNotificationModel>[];

  @override
  void initState() {
    super.initState();
    _subscribeFeed();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _feedSub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  StreamSubscription<List<Map<String, dynamic>>>? _feedSub;
  final ScrollController _scroll = ScrollController();
  bool _loadingOlder = false;
  bool _hasMore = true;

  PenggunaNotificationModel _toModel(Map<String, dynamic> m) {
    final title = (m['title'] as String?) ?? '';
    // `description` adalah alias `body` — fallback ke `body` bila kosong.
    final desc = (m['description'] as String?)?.isNotEmpty == true
        ? m['description'] as String
        : (m['body'] as String?) ?? '';
    return PenggunaNotificationModel(
      id: (m['id'] as String?) ?? '',
      title: title,
      description: desc,
      time: _fmtTime(m['createdAt']),
      icon: _iconFor((m['type'] as String?) ?? ''),
      isUnread: m['isUnread'] == true || m['isRead'] == false,
      raw: m,
    );
  }

  /// Feed realtime halaman pertama (order createdAt desc).
  void _subscribeFeed() {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    _feedSub =
        NotificationService.streamForUser(uid)
            .listen((items) {
      if (!mounted) return;
      setState(() {
        _notifications
          ..clear()
          ..addAll(items.map(_toModel));
        _hasMore = items.length >= NotificationService.pageSize;
      });
    }, onError: (_) {
      // Stream gagal (mis. offline) → biarkan daftar terakhir, jangan hapus.
    });
  }

  /// Pagination: muat halaman berikutnya saat mendekati akhir daftar.
  void _onScroll() {
    if (_loadingOlder || !_hasMore || _notifications.isEmpty) return;
    if (_scroll.position.extentAfter > 240) return;
    final uid = AuthService.uid;
    if (!Backend.useFirebase || uid == null) return;
    _loadingOlder = true;
    NotificationService.loadOlderForUser(
      uid,
      limit: NotificationService.pageSize,
      afterCreatedAt: _notifications.isNotEmpty
          ? _notifications.last.raw['createdAt']
          : null,
    ).then((items) {
      if (!mounted) return;
      setState(() {
        final known = _notifications.map((n) => n.id).toSet();
        _notifications.addAll(
          items.map(_toModel).where((n) => !known.contains(n.id)),
        );
        _hasMore = items.length >= NotificationService.pageSize;
      });
    }).whenComplete(() => _loadingOlder = false);
  }

  String _fmtTime(Object? ts) {
    return AppDates.formatTimestampWib(ts, relative: true);
  }

  /// Pemetaan type → icon (berdasarkan type, bukan title agar tidak rapuh).
  IconData _iconFor(String type) {
    switch (type) {
      case 'consultation_started':
      case 'consultation_message':
      case 'consultation_completed':
      case 'konsultasi': // legacy
        return LucideIcons.messageSquare;
      case 'booking_created':
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'booking': // legacy
        return LucideIcons.calendar;
      case 'reminder':
        return LucideIcons.sunrise;
      case 'article_published':
        return LucideIcons.bookOpen;
      default:
        return LucideIcons.bell;
    }
  }

  /// Notifikasi audience pengguna di-stream realtime oleh [_subscribeFeed].

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with back button and centered title
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 14.0,
                bottom: 12.0,
              ),
              child: Row(
                children: [
                  // Back button squircle
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFEEEEEE),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.chevronLeft,
                          size: 20,
                          color: darkText,
                        ),
                      ),
                    ),
                  ),

                  // Centered Title "Notifikasi"
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 44.0),
                        child: const Text(
                          'Notifikasi',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subtle divider line
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(bottom: 14.0),
            ),

            // Notification List
            Expanded(
              child: _notifications.isEmpty
                  ? const EmptyStateWidget(
                      icon: LucideIcons.bell,
                      title: 'Belum ada notifikasi',
                      description:
                          'Notifikasi booking, konsultasi, dan pengingat Skin Daily akan muncul di sini.',
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final item = _notifications[index];
                        return _buildNotificationCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PenggunaNavBottom(
        currentIndex: 0,
        onTap: (index) {
          Navigator.pop(context);
          if (index != 0) {
            widget.onNavigateTab?.call(index);
          }
        },
      ),
    );
  }

  Widget _buildNotificationCard(PenggunaNotificationModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (item.isUnread) {
              setState(() {
                item.isUnread = false;
              });
            }
            if (Backend.useFirebase) {
              NotificationService.markRead(AuthService.uid ?? '', item.id).catchError((_) {});
              if (item.raw.isNotEmpty) {
                NotificationRouter.open(AppNotification.fromMap(item.raw))
                    .catchError((_) {});
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Peach Icon Container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: peachIconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      item.icon,
                      color: primaryMaroon,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Content Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + unread dot indicator
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                            ),
                          ),
                          if (item.isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: primaryMaroon,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Description
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: subText,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Date & Time with Clock Icon
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.clock,
                            size: 12,
                            color: dateText,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.time,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: dateText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
