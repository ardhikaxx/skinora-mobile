import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';

class TentangPenggunaPage extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const TentangPenggunaPage({
    super.key,
    this.onNavigateTab,
  });

  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color cardBorder = Color(0xFFEEEEEE);
  static const Color innerBorder = Color(0xFFEBEBEB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Back button + Title "Tentang"
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
                    'Tentang',
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

            // Main Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // Main Card matching center screen of image copy 4.png
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 32.0,
                    ),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Droplet Logo Squircle
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            color: primaryMaroon,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: primaryMaroon.withValues(alpha: 0.28),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              LucideIcons.droplets,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Title "Skinora"
                        const Text(
                          'Skinora',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Version badge "VERSI 1.0.0"
                        const Text(
                          'VERSI 1.0.0',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: primaryMaroon,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Inset description container
                        Container(
                          padding: const EdgeInsets.all(18.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: innerBorder,
                              width: 1.0,
                            ),
                          ),
                          child: const Text(
                            'Skinora adalah aplikasi perawatan kulit cerdas yang membantu Anda memahami kondisi kulit, memantau rutinitas sehari-hari, dan berkonsultasi dengan dokter spesialis kulit.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF4B5563),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Developer info
                        const Text(
                          'Dikembangkan oleh Tim Skinora',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: subText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Copyright
                        const Text(
                          '© 2026 Skinora',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: subText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
            onNavigateTab?.call(index);
          }
        },
      ),
    );
  }
}
