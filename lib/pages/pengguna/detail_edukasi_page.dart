import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import 'edukasi_kulit_page.dart';

class DetailEdukasiPenggunaPage extends StatelessWidget {
  final SkinEducationModel? article;
  final ValueChanged<int>? onNavigateTab;

  const DetailEdukasiPenggunaPage({
    super.key,
    this.article,
    this.onNavigateTab,
  });

  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF461220);
  static const Color subText = Color(0xFF8E8E93);
  static const Color categoryBadgeBg = Color(0xFFFED0BB);
  static const Color bodyTextColor = Color(0xFF4A4A4A);

  static SkinEducationModel? _resolveArticle(SkinEducationModel? article) {
    return article;
  }

  @override
  Widget build(BuildContext context) {
    final currentArticle = _resolveArticle(article);

    if (currentArticle == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFCFCFD),
        body: SafeArea(
          child: Column(
            children: [
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
                      'Edukasi',
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
              Container(
                height: 1,
                color: const Color(0xFFF0F0F0),
                margin: const EdgeInsets.only(bottom: 14.0),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Artikel tidak ditemukan',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: subText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: PenggunaNavBottom(
          currentIndex: -1,
          onTap: (index) {
            Navigator.popUntil(context, (route) => route.isFirst);
            if (index != 0) {
              onNavigateTab?.call(index);
            }
          },
        ),
      );
    }

    final displayDate = currentArticle.date.contains('Agu')
        ? currentArticle.date.replaceAll('Agu', 'Agustus')
        : currentArticle.date;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar: Back Arrow and Title "Edukasi"
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
                    'Edukasi',
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
                  // 1. Category Badge
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 5.0,
                      ),
                      decoration: BoxDecoration(
                        color: categoryBadgeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentArticle.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          color: primaryMaroon,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. Article Title
                  Text(
                    currentArticle.title,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                      letterSpacing: -0.3,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3. Date with Clock Icon
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 13,
                        color: subText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        displayDate,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: subText,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 4. Main Content Card matching image copy 4.png
                  _buildArticleContentCard(currentArticle),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PenggunaNavBottom(
        currentIndex: -1,
        onTap: (index) {
          Navigator.popUntil(context, (route) => route.isFirst);
          if (index != 0) {
            onNavigateTab?.call(index);
          }
        },
      ),
    );
  }

  Widget _buildArticleContentCard(SkinEducationModel article) {
    final body = article.content.isNotEmpty ? article.content : article.snippet;
    return Container(
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
          Text(
            body,
            style: const TextStyle(
              fontSize: 13.5,
              color: bodyTextColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
