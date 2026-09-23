import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/skin_service.dart';

class SkincareHistoryEntry {
  final String date;
  final int pagiCount;
  final int malamCount;
  final List<String> pagiItems;
  final List<String> malamItems;

  const SkincareHistoryEntry({
    required this.date,
    required this.pagiCount,
    required this.malamCount,
    required this.pagiItems,
    required this.malamItems,
  });
}

class RiwayatSkincarePage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const RiwayatSkincarePage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = true,
  });

  @override
  State<RiwayatSkincarePage> createState() => _RiwayatSkincarePageState();
}

class _RiwayatSkincarePageState extends State<RiwayatSkincarePage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color cardBorder = Color(0xFFEEEEEE);
  static const Color peachBadgeBg = Color(0xFFFFD5C8);

  // Default expanded index 0 (Jumat, 28 Agustus 2026) matching image copy 4.png
  final Set<int> _expandedIndices = {0};

  List<SkincareHistoryEntry> _entries = Backend.useFirebase
      ? <SkincareHistoryEntry>[]
      : const <SkincareHistoryEntry>[
    SkincareHistoryEntry(
      date: 'Jumat, 28 Agustus 2026',
      pagiCount: 5,
      malamCount: 5,
      pagiItems: [
        'Cleanser',
        'Toner',
        'Serum',
        'Moisturizer',
        'Sunscreen',
      ],
      malamItems: [
        'Cleanser',
        'Toner',
        'Serum',
        'Moisturizer',
        'Night Cream',
      ],
    ),
    SkincareHistoryEntry(
      date: 'Kamis, 27 Agustus 2026',
      pagiCount: 5,
      malamCount: 4,
      pagiItems: [
        'Cleanser',
        'Facial Wash',
        'Toner',
        'Moisturizer',
        'Sunscreen',
      ],
      malamItems: [
        'Cleanser',
        'Toner',
        'Serum',
        'Night Cream',
      ],
    ),
    SkincareHistoryEntry(
      date: 'Rabu, 26 Agustus 2026',
      pagiCount: 5,
      malamCount: 5,
      pagiItems: [
        'Cleanser',
        'Toner',
        'Serum',
        'Moisturizer',
        'Sunscreen',
      ],
      malamItems: [
        'Cleanser',
        'Facial Wash',
        'Serum',
        'Moisturizer',
        'Night Cream',
      ],
    ),
    SkincareHistoryEntry(
      date: 'Selasa, 25 Agustus 2026',
      pagiCount: 4,
      malamCount: 3,
      pagiItems: [
        'Facial Wash',
        'Toner',
        'Moisturizer',
        'Sunscreen',
      ],
      malamItems: [
        'Facial Wash',
        'Toner',
        'Night Cream',
      ],
    ),
    SkincareHistoryEntry(
      date: 'Senin, 24 Agustus 2026',
      pagiCount: 4,
      malamCount: 4,
      pagiItems: [
        'Cleanser',
        'Toner',
        'Moisturizer',
        'Sunscreen',
      ],
      malamItems: [
        'Cleanser',
        'Facial Wash',
        'Moisturizer',
        'Sleeping Mask',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  /// Riwayat skincare milik pengguna dari Firestore. Tanpa Firebase, seed
  /// demo tetap dipakai agar UI/tes tidak berubah.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final items = await SkinService.listSkincare(uid);
      if (!mounted) return;
      setState(() {
        _entries = items.map((m) {
          final pagi =
              (m['morningSteps'] as List?)?.cast<String>() ?? const <String>[];
          final malam =
              (m['nightSteps'] as List?)?.cast<String>() ?? const <String>[];
          return SkincareHistoryEntry(
            date: (m['dateDisplay'] as String?) ?? '',
            pagiCount: pagi.length,
            malamCount: malam.length,
            pagiItems: pagi,
            malamItems: malam,
          );
        }).toList();
        _expandedIndices.clear();
        if (_entries.isNotEmpty) _expandedIndices.add(0);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entries = <SkincareHistoryEntry>[];
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
            // Top Bar: Back button and Title "Riwayat Skincare"
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
                    'Riwayat Skincare',
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
              currentIndex: 3,
              onTap: (index) {
                Navigator.popUntil(context, (route) => route.isFirst);
                if (index != 3) {
                  widget.onNavigateTab?.call(index);
                }
              },
            )
          : null,
    );
  }

  /// History Card matching image copy 4.png (collapsed & expanded states)
  Widget _buildHistoryCard(SkincareHistoryEntry entry, int index, bool isExpanded) {
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
                // Line 1: Date & Chevron
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
                const SizedBox(height: 10),

                // Line 2: Routine Badges (Pagi X produk, Malam Y produk)
                Row(
                  children: [
                    _buildCountBadge('Pagi ${entry.pagiCount} produk'),
                    const SizedBox(width: 8),
                    _buildCountBadge('Malam ${entry.malamCount} produk'),
                  ],
                ),

                // Expanded Section: PAGI & MALAM chip lists
                if (isExpanded) ...[
                  const SizedBox(height: 18),

                  // 1. PAGI Section
                  Row(
                    children: const [
                      Icon(LucideIcons.sun, size: 13, color: subText),
                      SizedBox(width: 5),
                      Text(
                        'PAGI',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: subText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.pagiItems.map((item) => _buildProductChip(item)).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 2. MALAM Section
                  Row(
                    children: const [
                      Icon(LucideIcons.moon, size: 13, color: subText),
                      SizedBox(width: 5),
                      Text(
                        'MALAM',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: subText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.malamItems.map((item) => _buildProductChip(item)).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Badge: "Pagi 5 produk" or "Malam 5 produk"
  Widget _buildCountBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.5),
      decoration: BoxDecoration(
        color: peachBadgeBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: primaryMaroon,
        ),
      ),
    );
  }

  /// Product Chip: e.g. "Cleanser", "Toner", "Serum"
  Widget _buildProductChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
      decoration: BoxDecoration(
        color: peachBadgeBg,
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
}
