import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/notification_service.dart';
import '../../utils/app_dates.dart';

class DoctorNotificationModel {
  final String id;
  final String title;
  final String description;
  final String time;
  final IconData icon;
  bool isUnread;

  DoctorNotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.isUnread,
  });
}

class NotifikasiDokterPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const NotifikasiDokterPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<NotifikasiDokterPage> createState() => _NotifikasiDokterPageState();
}

class _NotifikasiDokterPageState extends State<NotifikasiDokterPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF666666);
  static const Color dateText = Color(0xFF9E9E9E);
  static const Color peachIconBg = Color(0xFFFFD5C8);

  final List<DoctorNotificationModel> _notifications = [
    DoctorNotificationModel(
      id: '1',
      title: 'Booking Baru',
      description: 'Leonita booking jadwal konsultasi untuk hari ini',
      time: '2026-08-28 08:30',
      icon: LucideIcons.calendar,
      isUnread: true,
    ),
    DoctorNotificationModel(
      id: '2',
      title: 'Jadwal Hari Ini',
      description: 'Anda memiliki 3 konsultasi hari ini',
      time: '2026-08-28 07:00',
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
    if (type == 'booking' || title.contains('Booking')) {
      return LucideIcons.calendar;
    }
    if (title.contains('Jadwal') || title.contains('Konsultasi')) {
      return LucideIcons.messageSquare;
    }
    return LucideIcons.bell;
  }

  /// Notifikasi audience dokter dari Firestore. Tanpa Firebase, seed demo
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
            return DoctorNotificationModel(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  // Back button with rounded box style
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
                          color: const Color(0xFFE5E5EA),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.chevronLeft,
                          size: 20,
                          color: Color(0xFF4A1A24),
                        ),
                      ),
                    ),
                  ),

                  // Title centered
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Notifikasi',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),

                  // Spacer to balance the back button
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // Subtle divider line
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(top: 4.0, bottom: 16.0),
            ),

            // Notification list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 4.0,
                ),
                itemCount: _notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  return _buildNotificationCard(item);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DokterNavBottom(
        currentIndex: 0,
        onTap: (index) {
          Navigator.pop(context);
          if (index > 0) {
            widget.onNavigateTab?.call(index);
          }
        },
      ),
    );
  }

  Widget _buildNotificationCard(DoctorNotificationModel item) {
    return Container(
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
          onTap: () {
            setState(() {
              item.isUnread = false;
            });
            if (Backend.useFirebase && !item.id.contains(RegExp(r'^\d+$'))) {
              NotificationService.markRead(item.id).catchError((_) {});
            }
            _handleNotificationAction(item);
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Soft peach/coral square with maroon icon
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

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Unread indicator dot
                      Row(
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                          if (item.isUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 6.5,
                              height: 6.5,
                              decoration: const BoxDecoration(
                                color: primaryMaroon,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Description
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: subText,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Timestamp row
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.clock,
                            size: 12.5,
                            color: dateText,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.time,
                            style: const TextStyle(
                              fontSize: 11.0,
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

  void _handleNotificationAction(DoctorNotificationModel item) {
    if (item.title.contains('Booking')) {
      Navigator.pop(context);
      widget.onNavigateTab?.call(1); // Go to Jadwal
    } else if (item.title.contains('Jadwal')) {
      Navigator.pop(context);
      widget.onNavigateTab?.call(1); // Go to Jadwal
    }
  }
}
