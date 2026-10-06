import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/empty_state.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../utils/app_dates.dart';

class ActivityItem {
  final String title;
  final String timestamp;

  const ActivityItem({
    required this.title,
    required this.timestamp,
  });
}

class RiwayatAktivitasPenggunaPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final List<ActivityItem>? initialActivities;

  const RiwayatAktivitasPenggunaPage({
    super.key,
    this.onNavigateTab,
    this.initialActivities,
  });

  @override
  State<RiwayatAktivitasPenggunaPage> createState() =>
      _RiwayatAktivitasPenggunaPageState();
}

class _RiwayatAktivitasPenggunaPageState
    extends State<RiwayatAktivitasPenggunaPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color cardBorder = Color(0xFFEEEEEE);
  static const Color itemBorder = Color(0xFFF0F0F0);
  static const Color iconBadgeBg = Color(0xFFFFECEB);
  static const Color iconColor = Color(0xFFD9534F);

  late List<ActivityItem> activities = widget.initialActivities != null
      ? List.from(widget.initialActivities!)
      : <ActivityItem>[];

  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _fmtTime(Object? ts) {
    if (ts is Timestamp) return AppDates.formatTimestampWib(ts.toDate());
    return ts?.toString() ?? '';
  }

  /// Riwayat aktivitas milik pengguna dari Firestore secara realtime.
  void _loadFromBackend() {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    _sub?.cancel();
    _sub = ActivityService.streamMine(uid).listen(
      (items) {
        if (!mounted) return;
        setState(() {
          activities = items
              .map((m) => ActivityItem(
                    title: (m['title'] as String?) ?? '',
                    timestamp: _fmtTime(m['createdAt']),
                  ))
              .toList();
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => activities = <ActivityItem>[]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Back button + Title "Riwayat Aktivitas"
            Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
                right: 20.0,
                top: 14.0,
                bottom: 10.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      color: primaryMaroon,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Riwayat Aktivitas',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Subtle divider line
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(bottom: 16.0),
            ),

            // Main Content: Outer Card enclosing activity list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: cardBorder,
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
                    child: activities.isEmpty
                        ? const CompactEmptyState(
                            icon: LucideIcons.history,
                            title: 'Belum ada aktivitas',
                            description:
                                'Aktivitas seperti Skin Check, Skin Daily, dan konsultasi akan tercatat di sini.',
                          )
                        : Column(
                            children: activities.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final isLast = index == activities.length - 1;

                              return Container(
                                margin:
                                    EdgeInsets.only(bottom: isLast ? 0 : 10.0),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0,
                                  vertical: 12.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: itemBorder,
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Peach/Pink Square Icon Badge
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: iconBadgeBg,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          LucideIcons.clock,
                                          size: 18,
                                          color: iconColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Title and Timestamp
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: darkText,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            item.timestamp,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: subText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PenggunaNavBottom(
        currentIndex: 4,
        onTap: (index) {
          Navigator.popUntil(context, (route) => route.isFirst);
          if (index != 4) {
            widget.onNavigateTab?.call(index);
          }
        },
      ),
    );
  }
}
