import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import 'riwayat_skin_check_page.dart';

class SkinCheckResultPage extends StatelessWidget {
  final String skinType;
  final String sensitivity;
  final String acneRisk;
  final ValueChanged<int>? onNavigateTab;

  const SkinCheckResultPage({
    super.key,
    this.skinType = 'Normal',
    this.sensitivity = 'Sensitif',
    this.acneRisk = 'Tidak Rentan',
    this.onNavigateTab,
  });

  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF461220);
  static const Color subText = Color(0xFF8E8E93);
  static const Color resultCardBg = Color(0xFFFEB4A8);
  static const Color iconPeachBg = Color(0xFFFFDCD5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header: Back chevron + "Hasil"
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
                    'Hasil',
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

            // Main scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 2. Large Peach Result Card matching image copy 8.png
                  _buildMainResultCard(),

                  const SizedBox(height: 22),

                  // 3. Section Title: "TIPS PERAWATAN"
                  const Text(
                    'TIPS PERAWATAN',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Tips Card Container
                  _buildTipsCard(),

                  const SizedBox(height: 20),

                  // 5. Button "Ulangi Skin Check" (Outlined)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Pop all question pages back to initial Skin Check page
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        // If navigated from tab 1, switch or stay on tab 1
                        onNavigateTab?.call(1);
                      },
                      icon: const Icon(
                        LucideIcons.rotateCcw,
                        size: 18,
                        color: primaryMaroon,
                      ),
                      label: const Text(
                        'Ulangi Skin Check',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: primaryMaroon,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryMaroon, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 6. Button "Lihat Riwayat" (Filled Maroon)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RiwayatSkinCheckPage(
                              onNavigateTab: onNavigateTab,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        LucideIcons.clock,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Lihat Riwayat',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMaroon,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
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
            onNavigateTab?.call(index);
          }
        },
      ),
    );
  }

  Widget _buildMainResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: resultCardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top maroon squircle with sun icon
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: primaryMaroon,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.sun,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // "JENIS KULIT ANDA"
          const Text(
            'JENIS KULIT ANDA',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Color(0xFF6B2A30),
            ),
          ),
          const SizedBox(height: 4),

          // Big Skin Type: "Normal"
          Text(
            skinType,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 26.0,
              fontWeight: FontWeight.bold,
              color: darkText,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),

          // Two white info cards: SENSITIVITAS & RISIKO JERAWAT
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 14.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        LucideIcons.shieldCheck,
                        size: 20,
                        color: primaryMaroon,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'SENSITIVITAS',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: subText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sensitivity,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: primaryMaroon,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 14.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: const [
                      Icon(
                        LucideIcons.triangleAlert,
                        size: 20,
                        color: primaryMaroon,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'RISIKO JERAWAT',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: subText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tidak Rentan',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: primaryMaroon,
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

  Widget _buildTipsCard() {
    final tips = [
      const _TipItem(
        icon: LucideIcons.clipboardCheck,
        text: 'Pertahankan rutinitas skincare yang sudah berjalan',
      ),
      const _TipItem(
        icon: LucideIcons.sun,
        text: 'Gunakan sunscreen setiap hari',
      ),
      const _TipItem(
        icon: LucideIcons.shield,
        text: 'Hindari produk dengan fragrance dan alkohol',
      ),
      const _TipItem(
        icon: LucideIcons.triangleAlert,
        text: 'Gunakan produk non-comedogenic',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16.0),
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
      child: Column(
        children: tips.map((item) {
          final isLast = tips.indexOf(item) == tips.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0.0 : 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconPeachBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      item.icon,
                      size: 18,
                      color: primaryMaroon,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      item.text,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: darkText,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TipItem {
  final IconData icon;
  final String text;

  const _TipItem({
    required this.icon,
    required this.text,
  });
}
