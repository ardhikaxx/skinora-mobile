import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import 'skin_check_question1_page.dart';
import 'riwayat_skin_check_page.dart';

class SkinCheckPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const SkinCheckPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = false,
  });

  @override
  State<SkinCheckPage> createState() => _SkinCheckPageState();
}

class _SkinCheckPageState extends State<SkinCheckPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF757575);
  static const Color peachBg = Color(0xFFFFD5C3);
  static const Color peachIconBg = Color(0xFFFFD5C8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header: "Skin Check" on the left, "Riwayat >" on the right
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 16.0,
                bottom: 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Skin Check',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                      letterSpacing: -0.2,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RiwayatSkinCheckPage(
                            onNavigateTab: widget.onNavigateTab,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 2.0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Riwayat',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: primaryMaroon,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: primaryMaroon,
                          ),
                        ],
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
              margin: const EdgeInsets.only(bottom: 16.0),
            ),

            // Main scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 2. Maroon Hero Banner
                  _buildHeroBanner(),
                  const SizedBox(height: 18),

                  // 3. "YANG ANDA DAPATKAN" Card
                  _buildYangAndaDapatkanCard(),
                  const SizedBox(height: 18),

                  // 4. "DISCLAIMER" Card
                  _buildDisclaimerCard(),
                  const SizedBox(height: 18),

                  // 5. "7 Pertanyaan" Card
                  _buildPertanyaanCard(),
                  const SizedBox(height: 18),

                  // 6. "Mulai Skin Check >" Button
                  _buildMulaiSkinCheckButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? PenggunaNavBottom(
              currentIndex: 1,
              onTap: (index) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                widget.onNavigateTab?.call(index);
              },
            )
          : null,
    );
  }

  /// 2. Maroon Hero Banner with Stethoscope Icon, Title & Description
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: primaryMaroon,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryMaroon.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Translucent Stethoscope Icon Box
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.stethoscope,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Skin Check',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            'Kenali jenis kulit Anda melalui kuesioner berbasis SVM.',
            style: TextStyle(
              fontSize: 13.0,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// 3. "YANG ANDA DAPATKAN" Card with 3 items
  Widget _buildYangAndaDapatkanCard() {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YANG ANDA DAPATKAN',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: darkText,
            ),
          ),
          const SizedBox(height: 16),

          // Item 1: Jenis Kulit
          _buildBenefitItem(
            icon: LucideIcons.droplets,
            title: 'Jenis Kulit',
            subtitle: 'Kering, Normal, Kombinasi, atau Berminyak',
          ),
          const SizedBox(height: 14),

          // Item 2: Sensitivitas
          _buildBenefitItem(
            icon: LucideIcons.shield,
            title: 'Sensitivitas',
            subtitle: 'Apakah kulit Anda sensitif',
          ),
          const SizedBox(height: 14),

          // Item 3: Risiko Jerawat
          _buildBenefitItem(
            icon: LucideIcons.triangleAlert,
            title: 'Risiko Jerawat',
            subtitle: 'Tingkat kerentanan jerawat',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        // Peach Squircle Icon Box
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: peachIconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              icon,
              color: primaryMaroon,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Text Information
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: subText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 4. "DISCLAIMER" Peach Card
  Widget _buildDisclaimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: peachBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                LucideIcons.triangleAlert,
                size: 18,
                color: primaryMaroon,
              ),
              SizedBox(width: 8),
              Text(
                'DISCLAIMER',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Hasil bersifat edukatif dan bukan pengganti diagnosis medis. Konsultasikan dengan dokter spesialis kulit.',
            style: TextStyle(
              fontSize: 12.0,
              color: darkText,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// 5. "7 Pertanyaan" Card
  Widget _buildPertanyaanCard() {
    return Container(
      width: double.infinity,
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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                LucideIcons.clock,
                size: 16,
                color: darkText,
              ),
              SizedBox(width: 8),
              Text(
                '7 Pertanyaan',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Kuesioner pilihan ganda. Jawab sesuai kondisi kulit Anda saat ini.',
            style: TextStyle(
              fontSize: 12.0,
              color: subText,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// 6. "Mulai Skin Check >" Button
  Widget _buildMulaiSkinCheckButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SkinCheckQuestion1Page(
                onNavigateTab: widget.onNavigateTab,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMaroon,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Mulai Skin Check',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
