import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/notification_service.dart';
import '../../utils/app_dates.dart';

class PenggunaNotificationModel {
  final String id;
  final String title;
  final String description;
  final String time;
  final IconData icon;
  bool isUnread;

  PenggunaNotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.isUnread,
  });
}

class NotifikasiPenggunaPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const NotifikasiPenggunaPage({
    super.key,
    this.onNavigateTab,
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

  final List<PenggunaNotificationModel> _notifications = [
    PenggunaNotificationModel(
      id: '1',
      title: 'Konsultasi Hari Ini',
      description: 'Anda memiliki konsultasi dengan dr. Anita Dewi jam 09:00',
      time: '2026-08-28 07:00',
      icon: LucideIcons.messageSquare,
      isUnread: true,
    ),
    PenggunaNotificationModel(
      id: '2',
      title: 'Skin Daily',
      description: 'Jangan lupa mencatat Skin Daily hari ini!',
      time: '2026-08-28 08:00',
      icon: LucideIcons.bell,
      isUnread: true,
    ),
    PenggunaNotificationModel(
      id: '3',
      title: 'Tips Kulit',
      description: 'Minum minimal 8 gelas air putih sehari untuk kulit sehat',
      time: '2026-08-27 10:00',
      icon: LucideIcons.bell,
      isUnread: false,
    ),
    PenggunaNotificationModel(
      id: '4',
      title: 'Konsultasi Selesai',
      description: 'Konsultasi dengan dr. Andi telah selesai. Berikan rating!',
      time: '2026-08-20 15:00',
      icon: LucideIcons.messageSquare,
      isUnread: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  String _fmtTime(Object? ts) {
    if (ts is Timestamp) return AppDates.dateTime(ts.toDate());
    return ts?.toString() ?? '';
  }

  IconData _iconFor(String title, String type) {
    if (type == 'booking' || title.contains('Konsultasi') || title.contains('Booking')) {
      return LucideIcons.messageSquare;
    }
    return LucideIcons.bell;
  }

  /// Notifikasi audience pengguna dari Firestore. Tanpa Firebase, seed demo
  /// tetap dipakai agar UI/tes tidak berubah.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final items = await NotificationService.listAudience(
        NotificationService.userAudience(uid),
      );
      if (!mounted) return;
      setState(() {
        if (items.isEmpty) return;
        _notifications
          ..clear()
          ..addAll(items.map((m) {
            final title = (m['title'] as String?) ?? '';
            return PenggunaNotificationModel(
              id: (m['id'] as String?) ?? '',
              title: title,
              description: (m['description'] as String?) ?? '',
              time: _fmtTime(m['createdAt']),
              icon: _iconFor(title, (m['type'] as String?) ?? ''),
              isUnread: m['isUnread'] == true,
            );
          }));
      });
    } catch (_) {
      // biarkan seed demo bila query gagal
    }
  }

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
              child: ListView.builder(
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
            if (Backend.useFirebase && !item.id.contains(RegExp(r'^\d+$'))) {
              NotificationService.markRead(item.id).catchError((_) {});
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
