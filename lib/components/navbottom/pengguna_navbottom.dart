import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PenggunaNavBottom extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const Color navBgColor = Color(0xFF8B2B38);

  const PenggunaNavBottom({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      const _NavItemData(
        icon: FontAwesomeIcons.house,
        label: 'Beranda',
        size: 19.0,
      ),
      const _NavItemData(
        icon: FontAwesomeIcons.stethoscope,
        label: 'Skin Check',
        size: 20.0,
      ),
      const _NavItemData(
        icon: FontAwesomeIcons.bookOpen,
        label: 'Skin Daily',
        size: 19.0,
      ),
      const _NavItemData(
        icon: FontAwesomeIcons.droplet,
        label: 'Skincare',
        size: 19.0,
      ),
      const _NavItemData(
        icon: FontAwesomeIcons.user,
        label: 'Profil',
        size: 19.0,
      ),
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        height: 74,
        decoration: BoxDecoration(
          color: navBgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(navItems.length, (index) {
            final isSelected = index == currentIndex;
            final item = navItems[index];
            final iconColor = isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.65);

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.22)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: FaIcon(
                          item.icon,
                          size: item.size,
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final double size;

  const _NavItemData({
    required this.icon,
    required this.label,
    required this.size,
  });
}
