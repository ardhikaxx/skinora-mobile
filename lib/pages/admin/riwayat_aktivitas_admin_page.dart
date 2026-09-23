import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/admin_navbottom.dart';
import '../../services/activity_service.dart';
import '../../services/backend.dart';
import '../../utils/app_dates.dart';

class AdminActivityItem {
  final String title;
  final String time;

  const AdminActivityItem({
    required this.title,
    required this.time,
  });
}

class RiwayatAktivitasAdminPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const RiwayatAktivitasAdminPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<RiwayatAktivitasAdminPage> createState() =>
      _RiwayatAktivitasAdminPageState();
}

class _RiwayatAktivitasAdminPageState extends State<RiwayatAktivitasAdminPage> {
  static const Color darkText = Color(0xFF1E293B);
  static const Color subText = Color(0xFF8E8E93);
  static const Color orangeIconBg = Color(0xFFFFD5C8);
  static const Color orangeIconColor = Color(0xFFE65100);

  /// Seed demo HANYA untuk widget test / mode tanpa Firebase.
  /// Dengan Firebase, daftar diisi dari Firestore (boleh kosong).
  final List<AdminActivityItem> _activities = Backend.useFirebase
      ? <AdminActivityItem>[]
      : <AdminActivityItem>[
          AdminActivityItem(
            title: 'Login admin berhasil',
            time: '2026-08-27 07:55',
          ),
          AdminActivityItem(
            title: 'Memverifikasi dr. Anita Dewi',
            time: '2026-08-15 10:00',
          ),
          AdminActivityItem(
            title: 'Mempublikasikan artikel:\nMengenal Tipe Kulit',
            time: '2026-08-01 12:00',
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

  /// Riwayat aktivitas global (admin) dari Firestore. Tanpa Firebase, data
  /// demo tetap dipakai agar UI/tes tidak berubah. Dengan Firebase, hasil
  /// backend selalu menggantikan seed — termasuk saat daftar kosong.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    try {
      final items = await ActivityService.listAll();
      if (!mounted) return;
      setState(() => _activities
        ..clear()
        ..addAll(items.map((m) => AdminActivityItem(
              title: (m['title'] as String?) ?? '',
              time: _fmtTime(m['createdAt']),
            ))));
    } catch (e) {
      // Query gagal → tampilkan kosong, jangan seed palsu di production.
      if (!mounted) return;
      setState(_activities.clear);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat riwayat aktivitas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Header: Chevron Left + Title
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 20.0,
                top: 16.0,
                bottom: 12.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      size: 22,
                      color: darkText,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Riwayat Aktivitas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                children: [
                  // Timeline Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18.0,
                      vertical: 16.0,
                    ),
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
                    child: Column(
                      children: List.generate(_activities.length, (index) {
                        final item = _activities[index];
                        final isLast = index == _activities.length - 1;

                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Peach Clock Icon Box
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: orangeIconBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      LucideIcons.clock,
                                      size: 20,
                                      color: orangeIconColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Title and Time
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold,
                                          color: darkText,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.time,
                                        style: const TextStyle(
                                          fontSize: 12.0,
                                          color: subText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!isLast) const SizedBox(height: 20),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminNavBottom(
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
