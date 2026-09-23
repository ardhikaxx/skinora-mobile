import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../utils/app_dates.dart';

class DoctorActivityItem {
  final String title;
  final String timestamp;

  const DoctorActivityItem({
    required this.title,
    required this.timestamp,
  });
}

class RiwayatAktivitasDokterPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const RiwayatAktivitasDokterPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = true,
  });

  @override
  State<RiwayatAktivitasDokterPage> createState() =>
      _RiwayatAktivitasDokterPageState();
}

class _RiwayatAktivitasDokterPageState
    extends State<RiwayatAktivitasDokterPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E1E1E);
  static const Color subText = Color(0xFF757575);
  static const Color clockBg = Color(0xFFFFD5C8);
  static const Color clockColor = Color(0xFFE65100);

  // Seed demo HANYA untuk widget test / mode tanpa Firebase.
  // Dengan Firebase, daftar diisi dari Firestore (boleh kosong).
  List<DoctorActivityItem> activities = Backend.useFirebase
      ? const <DoctorActivityItem>[]
      : const [
          DoctorActivityItem(
            title: 'Konsultasi selesai dengan Annida Tri Aulia',
            timestamp: '2026-08-29 10:30',
          ),
          DoctorActivityItem(
            title: 'Login berhasil',
            timestamp: '2026-08-29 08:00',
          ),
          DoctorActivityItem(
            title: 'Konsultasi selesai dengan Leonita Yulyta Agustin',
            timestamp: '2026-08-28 14:00',
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

  /// Riwayat aktivitas milik dokter dari Firestore. Tanpa Firebase, seed
  /// demo tetap dipakai agar UI/tes tidak berubah. Dengan Firebase, hasil
  /// backend selalu menggantikan seed — termasuk saat kosong.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final items = await ActivityService.listMine(uid);
      if (!mounted) return;
      setState(() {
        activities = items
            .map((m) => DoctorActivityItem(
                  title: (m['title'] as String?) ?? '',
                  timestamp: _fmtTime(m['createdAt']),
                ))
            .toList();
      });
    } catch (_) {
      // Query gagal → tampilkan kosong, jangan seed palsu di production.
      if (!mounted) return;
      setState(() => activities = const <DoctorActivityItem>[]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
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
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Riwayat Aktivitas',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
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
            ),

            // Activity List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                itemCount: activities.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = activities[index];
                  return Container(
                    padding: const EdgeInsets.all(16.0),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Clock icon container
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: clockBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              LucideIcons.clock,
                              color: clockColor,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title and Timestamp
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
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
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? DokterNavBottom(
              currentIndex: 4,
              onTap: (index) {
                Navigator.pop(context);
                if (index != 4) {
                  widget.onNavigateTab?.call(index);
                }
              },
            )
          : null,
    );
  }
}
