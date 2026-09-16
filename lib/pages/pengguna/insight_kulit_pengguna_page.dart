import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';

class DailyInsightHistoryItem {
  final String date;
  final String symptoms;
  final String status; // 'Baik', 'Sedang', 'Buruk'

  const DailyInsightHistoryItem({
    required this.date,
    required this.symptoms,
    required this.status,
  });
}

class InsightKulitPenggunaPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const InsightKulitPenggunaPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = true,
  });

  @override
  State<InsightKulitPenggunaPage> createState() =>
      _InsightKulitPenggunaPageState();
}

class _InsightKulitPenggunaPageState extends State<InsightKulitPenggunaPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color cardBorder = Color(0xFFEEEEEE);
  static const Color peachBg = Color(0xFFFFD5C8);
  static const Color pinkBurukBg = Color(0xFFFFCCD2);
  static const Color redBurukText = Color(0xFFD32F2F);

  final List<DailyInsightHistoryItem> _history7Hari = const [
    DailyInsightHistoryItem(
      date: '2026-08-28',
      symptoms: 'Berminyak, Komedo',
      status: 'Baik',
    ),
    DailyInsightHistoryItem(
      date: '2026-08-26',
      symptoms: 'Jerawat, Kemerahan',
      status: 'Sedang',
    ),
    DailyInsightHistoryItem(
      date: '2026-08-25',
      symptoms: 'Normal',
      status: 'Baik',
    ),
    DailyInsightHistoryItem(
      date: '2026-08-24',
      symptoms: 'Berminyak',
      status: 'Baik',
    ),
    DailyInsightHistoryItem(
      date: '2026-08-23',
      symptoms: 'Jerawat, Kemerahan, Beruntusan',
      status: 'Buruk',
    ),
    DailyInsightHistoryItem(
      date: '2026-08-22',
      symptoms: 'Kusam',
      status: 'Sedang',
    ),
    DailyInsightHistoryItem(
      date: '2026-08-21',
      symptoms: 'Normal, Kombinasi',
      status: 'Baik',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Back arrow and Title "Insight Kulit"
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
                    'Insight Kulit',
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

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 1. RINGKASAN KONDISI Card
                  _buildRingkasanKondisiCard(),
                  const SizedBox(height: 16),

                  // 2. POLA HIDUP Card
                  _buildPolaHidupCard(),
                  const SizedBox(height: 16),

                  // 3. RIWAYAT 7 HARI Card
                  _buildRiwayat7HariCard(),
                  const SizedBox(height: 24),
                ],
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

  /// 1. Card: RINGKASAN KONDISI
  Widget _buildRingkasanKondisiCard() {
    return Container(
      padding: const EdgeInsets.all(18.0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + "RINGKASAN KONDISI"
          Row(
            children: const [
              Icon(
                LucideIcons.trendingUp,
                size: 18,
                color: primaryMaroon,
              ),
              SizedBox(width: 8),
              Text(
                'RINGKASAN KONDISI',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Stat Blocks: 4 Baik, 2 Sedang, 1 Buruk
          Row(
            children: [
              // Baik
              Expanded(
                child: _buildConditionBox(
                  count: '4',
                  label: 'Baik',
                  bgColor: peachBg,
                  textColor: primaryMaroon,
                ),
              ),
              const SizedBox(width: 10),

              // Sedang
              Expanded(
                child: _buildConditionBox(
                  count: '2',
                  label: 'Sedang',
                  bgColor: peachBg,
                  textColor: primaryMaroon,
                ),
              ),
              const SizedBox(width: 10),

              // Buruk
              Expanded(
                child: _buildConditionBox(
                  count: '1',
                  label: 'Buruk',
                  bgColor: pinkBurukBg,
                  textColor: redBurukText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subtitle: "Kondisi kulit paling sering: Berminyak (2x dari 7 hari)"
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 13.0,
                color: Color(0xFF4A4A4A),
                height: 1.35,
              ),
              children: [
                TextSpan(text: 'Kondisi kulit paling sering: '),
                TextSpan(
                  text: 'Berminyak',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                TextSpan(text: ' (2x dari 7 hari)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Condition Box Component (e.g. "4 Baik")
  Widget _buildConditionBox({
    required String count,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Card: POLA HIDUP
  Widget _buildPolaHidupCard() {
    return Container(
      padding: const EdgeInsets.all(18.0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + "POLA HIDUP"
          Row(
            children: const [
              Icon(
                LucideIcons.timer,
                size: 18,
                color: primaryMaroon,
              ),
              SizedBox(width: 8),
              Text(
                'POLA HIDUP',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2 Life Style Stat Cards
          Row(
            children: [
              // Rata-rata Air/Hari
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: peachBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rata-rata Air/Hari',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: '7 ',
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.w900,
                                color: darkText,
                              ),
                            ),
                            TextSpan(
                              text: 'gelas',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.normal,
                                color: darkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Skincare Lengkap
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: peachBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Skincare Lengkap',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: '4 ',
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.w900,
                                color: darkText,
                              ),
                            ),
                            TextSpan(
                              text: 'dari 7 hari',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.normal,
                                color: darkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Card: RIWAYAT 7 HARI
  Widget _buildRiwayat7HariCard() {
    return Container(
      padding: const EdgeInsets.all(18.0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + "RIWAYAT 7 HARI"
          Row(
            children: const [
              Icon(
                LucideIcons.sparkles,
                size: 18,
                color: primaryMaroon,
              ),
              SizedBox(width: 8),
              Text(
                'RIWAYAT 7 HARI',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // List of 7 Days
          ...List.generate(_history7Hari.length, (index) {
            final item = _history7Hari[index];
            final isLast = index == _history7Hari.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Date and Symptoms
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.date,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.symptoms,
                              style: const TextStyle(
                                fontSize: 12.0,
                                color: subText,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status Badge
                      _buildStatusBadge(item.status),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(
                    height: 14,
                    color: Color(0xFFF4F4F6),
                  ),
              ],
            );
          }),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
