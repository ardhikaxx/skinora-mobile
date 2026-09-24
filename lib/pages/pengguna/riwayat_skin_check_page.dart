import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/empty_state.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/skin_service.dart';
import '../../utils/app_dates.dart';
import 'skin_check_result_page.dart';

class SkinCheckHistoryModel {
  final String id;
  final String date;
  final String skinType;
  final String subtitle;
  final IconData icon;
  final List<String> tags;
  final List<String> neutralTags;

  const SkinCheckHistoryModel({
    required this.id,
    required this.date,
    required this.skinType,
    required this.subtitle,
    required this.icon,
    required this.tags,
    this.neutralTags = const [],
  });
}

class RiwayatSkinCheckPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const RiwayatSkinCheckPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<RiwayatSkinCheckPage> createState() => _RiwayatSkinCheckPageState();
}

class _RiwayatSkinCheckPageState extends State<RiwayatSkinCheckPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color dateColor = Color(0xFF8E8E93);
  static const Color peachIconBg = Color(0xFFFED0BB);
  static const Color chipPeachBg = Color(0xFFFED0BB);
  static const Color chipPeachText = Color(0xFF8B2B38);
  static const Color chipNeutralBg = Colors.white;
  static const Color chipNeutralBorder = Color(0xFFE5E5EA);
  static const Color chipNeutralText = Color(0xFF6B5E5E);

  List<SkinCheckHistoryModel> _historyList = Backend.useFirebase
      ? <SkinCheckHistoryModel>[]
      : const <SkinCheckHistoryModel>[
    SkinCheckHistoryModel(
      id: '1',
      date: '2026-08-28',
      skinType: 'Kombinasi',
      subtitle: 'Sensitif - Rentan',
      icon: LucideIcons.shield,
      tags: ['Kombinasi', 'Sensitif', 'Rentan'],
    ),
    SkinCheckHistoryModel(
      id: '2',
      date: '2026-08-10',
      skinType: 'Normal',
      subtitle: 'Non-Sensitif - Tidak Rentan',
      icon: LucideIcons.sun,
      tags: ['Normal', 'Non-Sensitif', 'Tidak Rentan'],
      neutralTags: ['Non-Sensitif'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  String _fmtDate(Object? ts) {
    if (ts is Timestamp) return AppDates.iso(ts.toDate());
    return ts?.toString() ?? '';
  }

  /// Riwayat skin check milik pengguna dari Firestore. Tanpa Firebase, seed
  /// demo tetap dipakai agar UI/tes tidak berubah.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final items = await SkinService.listSkinChecks(uid);
      if (!mounted) return;
      setState(() {
        _historyList = items.map((m) {
          final skinType = (m['resultSkinType'] as String?) ?? 'Normal';
          final sensitivity = (m['resultSensitivity'] as String?) ?? 'Non-Sensitif';
          final acneRisk = (m['resultAcneRisk'] as String?) ?? 'Tidak Rentan';
          final nonSens = !sensitivity.toLowerCase().contains('sensitif') ||
              sensitivity.toLowerCase().contains('non');
          final notRentan = acneRisk.toLowerCase().contains('tidak');
          final tags = [
            skinType,
            nonSens ? 'Non-Sensitif' : sensitivity,
            notRentan ? 'Tidak Rentan' : acneRisk,
          ];
          return SkinCheckHistoryModel(
            id: (m['id'] as String?) ?? '',
            date: _fmtDate(m['createdAt']),
            skinType: skinType,
            subtitle:
                '${nonSens ? 'Non-Sensitif' : sensitivity} - $acneRisk',
            icon: skinType.toLowerCase() == 'normal'
                ? LucideIcons.sun
                : LucideIcons.shield,
            tags: tags,
            neutralTags: [
              if (nonSens) 'Non-Sensitif',
              if (notRentan) 'Tidak Rentan',
            ],
          );
        }).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _historyList = <SkinCheckHistoryModel>[]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header: Back Button & Title "Riwayat" matching image.png
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 14.0,
                bottom: 12.0,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back button squircle container on the left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E5EA),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.chevronLeft,
                            color: darkText,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Centered Title "Riwayat"
                  const Text(
                    'Riwayat',
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

            // Main scrollable list of skin check history
            Expanded(
              child: _historyList.isEmpty
                  ? EmptyStateWidget(
                      icon: LucideIcons.stethoscope,
                      title: 'Belum ada hasil Skin Check',
                      description:
                          'Cek kondisi kulit Anda untuk mengetahui tipe kulit, tingkat sensitivitas, dan risiko jerawat.',
                      actionLabel: 'Mulai Skin Check',
                      onAction: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                        widget.onNavigateTab?.call(1);
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: _historyList.length,
                      itemBuilder: (context, index) {
                        final item = _historyList[index];
                        return _buildHistoryCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PenggunaNavBottom(
        currentIndex: 1,
        onTap: (index) {
          Navigator.popUntil(context, (route) => route.isFirst);
          if (index != 1) {
            widget.onNavigateTab?.call(index);
          }
        },
      ),
    );
  }

  Widget _buildHistoryCard(SkinCheckHistoryModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Open Result page for this history item
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SkinCheckResultPage(
                skinType: item.skinType,
                sensitivity: item.tags.contains('Sensitif')
                    ? 'Sensitif'
                    : 'Non-Sensitif',
                acneRisk: item.tags.contains('Rentan')
                    ? 'Rentan'
                    : 'Tidak Rentan',
                onNavigateTab: widget.onNavigateTab,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Date
            Text(
              item.date,
              style: const TextStyle(
                fontSize: 12.5,
                color: dateColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Icon + Skin Type & Subtitle
            Row(
              children: [
                // Soft peach squircle icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: peachIconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      item.icon,
                      color: primaryMaroon,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Skin type and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.skinType,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: subText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Chips Row
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: item.tags.map((tag) {
                final isNeutral = item.neutralTags.contains(tag);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: isNeutral ? chipNeutralBg : chipPeachBg,
                    borderRadius: BorderRadius.circular(14),
                    border: isNeutral
                        ? Border.all(
                            color: chipNeutralBorder,
                            width: 1.0,
                          )
                        : null,
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isNeutral ? chipNeutralText : chipPeachText,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
