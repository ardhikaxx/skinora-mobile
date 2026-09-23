import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/skin_service.dart';

class DailyHistoryEntry {
  final String date;
  final String status; // 'Baik', 'Sedang', 'Buruk'
  final String previewText;
  final List<String> locations;
  final List<String> symptoms;
  final String sleepTime;
  final String waterGlasses;
  final String food;
  final String activity;
  final bool routinePagi;
  final bool routineMalam;

  const DailyHistoryEntry({
    required this.date,
    required this.status,
    required this.previewText,
    required this.locations,
    required this.symptoms,
    required this.sleepTime,
    required this.waterGlasses,
    required this.food,
    required this.activity,
    required this.routinePagi,
    required this.routineMalam,
  });
}

class RiwayatSkinDailyPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const RiwayatSkinDailyPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = true,
  });

  @override
  State<RiwayatSkinDailyPage> createState() => _RiwayatSkinDailyPageState();
}

class _RiwayatSkinDailyPageState extends State<RiwayatSkinDailyPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color cardBorder = Color(0xFFEEEEEE);
  static const Color innerBorder = Color(0xFFE5E5EA);
  static const Color peachBg = Color(0xFFFFD5C8);
  static const Color pinkBurukBg = Color(0xFFFFCCD2);
  static const Color redBurukText = Color(0xFFD32F2F);

  // Track expanded cards
  final Set<int> _expandedIndices = {0};

  List<DailyHistoryEntry> _entries = Backend.useFirebase
      ? <DailyHistoryEntry>[]
      : const <DailyHistoryEntry>[
    DailyHistoryEntry(
      date: 'Jumat, 28 Agustus 2026',
      status: 'Baik',
      previewText: 'Berminyak  Komedo',
      locations: ['Hidung', 'Dahi'],
      symptoms: ['Berminyak', 'Komedo'],
      sleepTime: '23:00',
      waterGlasses: '8 gelas',
      food: 'Nasi, ayam panggang, salad, buah',
      activity: 'Kerja di kantor, meeting online',
      routinePagi: true,
      routineMalam: false,
    ),
    DailyHistoryEntry(
      date: 'Rabu, 26 Agustus 2026',
      status: 'Sedang',
      previewText: 'Jerawat  Kemerahan',
      locations: ['Pipi Kiri', 'Dagu'],
      symptoms: ['Jerawat', 'Kemerahan'],
      sleepTime: '23:30',
      waterGlasses: '6 gelas',
      food: 'Mie goreng, telur, jus jeruk',
      activity: 'Kuliah, tugas di kafe',
      routinePagi: true,
      routineMalam: true,
    ),
    DailyHistoryEntry(
      date: 'Selasa, 25 Agustus 2026',
      status: 'Baik',
      previewText: 'Normal',
      locations: ['T-Zone'],
      symptoms: ['Normal'],
      sleepTime: '22:30',
      waterGlasses: '8 gelas',
      food: 'Oatmeal, pisang, ayam rebus, sayur bayam',
      activity: 'Jogging pagi, kerja remote',
      routinePagi: true,
      routineMalam: true,
    ),
    DailyHistoryEntry(
      date: 'Senin, 24 Agustus 2026',
      status: 'Baik',
      previewText: 'Berminyak',
      locations: ['T-Zone', 'Hidung'],
      symptoms: ['Berminyak'],
      sleepTime: '23:00',
      waterGlasses: '7 gelas',
      food: 'Nasi merah, tahu tempe, ikan bakar',
      activity: 'Kerja di kantor seharian',
      routinePagi: true,
      routineMalam: true,
    ),
    DailyHistoryEntry(
      date: 'Minggu, 23 Agustus 2026',
      status: 'Buruk',
      previewText: 'Jerawat  Kemerahan  +1',
      locations: ['Pipi Kiri', 'Pipi Kanan', 'Dagu'],
      symptoms: ['Jerawat', 'Kemerahan', 'Beruntusan'],
      sleepTime: '01:00',
      waterGlasses: '5 gelas',
      food: 'Fast food, gorengan, boba tea',
      activity: 'Begadang nonton serial, di rumah saja',
      routinePagi: false,
      routineMalam: false,
    ),
    DailyHistoryEntry(
      date: 'Sabtu, 22 Agustus 2026',
      status: 'Sedang',
      previewText: 'Kusam',
      locations: ['Pipi Kiri', 'Hidung'],
      symptoms: ['Kusam'],
      sleepTime: '23:45',
      waterGlasses: '6 gelas',
      food: 'Soto ayam, kerupuk, teh manis',
      activity: 'Belanja bulanan, jalan-jalan outdoor',
      routinePagi: true,
      routineMalam: false,
    ),
    DailyHistoryEntry(
      date: 'Jumat, 21 Agustus 2026',
      status: 'Baik',
      previewText: 'Normal  Kombinasi',
      locations: ['T-Zone', 'Pipi Kanan'],
      symptoms: ['Normal', 'Kombinasi'],
      sleepTime: '22:15',
      waterGlasses: '8 gelas',
      food: 'Sup sayur, dada ayam, alpukat',
      activity: 'Gym ringan, istirahat cukup',
      routinePagi: true,
      routineMalam: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  /// Riwayat skin daily milik pengguna dari Firestore. Tanpa Firebase, seed
  /// demo tetap dipakai agar UI/tes tidak berubah.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final items = await SkinService.listSkinDailies(uid);
      if (!mounted) return;
      setState(() {
        _entries = items.map((m) {
          final symptoms =
              (m['symptoms'] as List?)?.cast<String>() ?? const <String>[];
          final locations =
              (m['locations'] as List?)?.cast<String>() ?? const <String>[];
          final status = (m['status'] as String?) ?? 'Baik';
          final preview =
              symptoms.isEmpty ? status : symptoms.join('  ');
          return DailyHistoryEntry(
            date: (m['dateDisplay'] as String?) ?? '',
            status: status,
            previewText: preview,
            locations: locations,
            symptoms: symptoms,
            sleepTime: (m['jamTidur'] as String?) ?? '-',
            waterGlasses: '${(m['air'] as String?) ?? '0'} gelas',
            food: (m['makanan'] as String?) ?? '-',
            activity: (m['aktivitas'] as String?) ?? '-',
            routinePagi: m['skincarePagi'] as bool? ?? false,
            routineMalam: m['skincareMalam'] as bool? ?? false,
          );
        }).toList();
        _expandedIndices.clear();
        if (_entries.isNotEmpty) _expandedIndices.add(0);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entries = <DailyHistoryEntry>[];
        _expandedIndices.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Back button and Title "Riwayat Skin Daily"
            Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
                right: 20.0,
                top: 14.0,
                bottom: 10.0,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(
                        LucideIcons.chevronLeft,
                        size: 22,
                        color: darkText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Riwayat Skin Daily',
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
              margin: const EdgeInsets.only(bottom: 14.0),
            ),

            // Main List of History Cards
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                itemCount: _entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  final isExpanded = _expandedIndices.contains(index);

                  return _buildHistoryCard(entry, index, isExpanded);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? PenggunaNavBottom(
              currentIndex: 2,
              onTap: (index) {
                Navigator.popUntil(context, (route) => route.isFirst);
                if (index != 2) {
                  widget.onNavigateTab?.call(index);
                }
              },
            )
          : null,
    );
  }

  /// History Card matching image copy 2.png (both collapsed & expanded states)
  Widget _buildHistoryCard(DailyHistoryEntry entry, int index, bool isExpanded) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.0),
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
              if (isExpanded) {
                _expandedIndices.remove(index);
              } else {
                _expandedIndices.add(index);
              }
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Date & Chevron
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.date,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    Icon(
                      isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 18,
                      color: subText,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Status Badge & Symptoms Preview Text
                Row(
                  children: [
                    _buildStatusBadge(entry.status),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.previewText,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: subText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Expanded Details Section
                if (isExpanded) ...[
                  const SizedBox(height: 18),

                  // 1. LOKASI GEJALA
                  const Text(
                    'LOKASI GEJALA',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: subText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: entry.locations.map((loc) => _buildDetailChip(loc)).toList(),
                  ),
                  const SizedBox(height: 14),

                  // 2. GEJALA KULIT
                  const Text(
                    'GEJALA KULIT',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: subText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: entry.symptoms.map((sym) => _buildDetailChip(sym)).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 3. Metric Boxes: TIDUR & AIR
                  Row(
                    children: [
                      // Tidur
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: innerBorder, width: 1.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(LucideIcons.moon, size: 13, color: subText),
                                  SizedBox(width: 5),
                                  Text(
                                    'TIDUR',
                                    style: TextStyle(
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.bold,
                                      color: subText,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                entry.sleepTime,
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Air
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: innerBorder, width: 1.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(LucideIcons.timer, size: 13, color: subText),
                                  SizedBox(width: 5),
                                  Text(
                                    'AIR',
                                    style: TextStyle(
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.bold,
                                      color: subText,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                entry.waterGlasses,
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. MAKANAN
                  const Text(
                    'MAKANAN',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: subText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.food,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: darkText,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. AKTIVITAS
                  const Text(
                    'AKTIVITAS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: subText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.activity,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: darkText,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. Skincare Routine Badges: Pagi ✓ / Malam ✕
                  Row(
                    children: [
                      _buildRoutineCheckBadge(
                        icon: LucideIcons.sun,
                        label: 'Pagi',
                        isDone: entry.routinePagi,
                      ),
                      const SizedBox(width: 10),
                      _buildRoutineCheckBadge(
                        icon: LucideIcons.moon,
                        label: 'Malam',
                        isDone: entry.routineMalam,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Status Badge (Baik / Sedang / Buruk)
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color textColor;

    switch (status) {
      case 'Buruk':
        bg = pinkBurukBg;
        textColor = redBurukText;
        break;
      case 'Sedang':
        bg = peachBg;
        textColor = primaryMaroon;
        break;
      case 'Baik':
      default:
        bg = peachBg;
        textColor = primaryMaroon;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  /// Detail Chip for Location or Symptom (e.g. "Hidung", "Dahi")
  Widget _buildDetailChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: peachBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          color: primaryMaroon,
        ),
      ),
    );
  }

  /// Routine Badge: e.g. "Pagi ✓" or "Malam ✕" matching image copy 2.png
  Widget _buildRoutineCheckBadge({
    required IconData icon,
    required String label,
    required bool isDone,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: peachBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: primaryMaroon),
          const SizedBox(width: 5),
          Text(
            isDone ? '$label ✓' : '$label ✕',
            style: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: primaryMaroon,
            ),
          ),
        ],
      ),
    );
  }
}
