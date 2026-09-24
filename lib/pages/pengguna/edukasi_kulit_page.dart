import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/empty_state.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/article_service.dart';
import '../../services/backend.dart';
import '../../utils/app_dates.dart';
import 'detail_edukasi_page.dart';

class SkinEducationModel {
  final String id;
  final String category;
  final String title;
  final String snippet;
  final String date;
  final String content;

  const SkinEducationModel({
    required this.id,
    required this.category,
    required this.title,
    required this.snippet,
    required this.date,
    this.content = '',
  });
}

class EdukasiKulitPenggunaPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const EdukasiKulitPenggunaPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<EdukasiKulitPenggunaPage> createState() =>
      _EdukasiKulitPenggunaPageState();
}

class _EdukasiKulitPenggunaPageState extends State<EdukasiKulitPenggunaPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF757575);
  static const Color dateText = Color(0xFF9E9E9E);
  static const Color categoryBadgeBg = Color(0xFFFFD5C8);

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';

  List<String> _categories = Backend.useFirebase
      ? <String>['Semua']
      : <String>[
    'Semua',
    'Kulit Dasar',
    'Skincare',
    'Kulit Bermasalah',
    'Nutrisi Kulit',
    'Tips & Trik',
  ];

  List<SkinEducationModel> _allArticles = Backend.useFirebase
      ? <SkinEducationModel>[]
      : const <SkinEducationModel>[
    SkinEducationModel(
      id: '1',
      category: 'KULIT DASAR',
      title: 'Mengenal Tipe Kulit Wajah Anda',
      snippet:
          'Pelajari cara mengenali tipe kulit wajah Anda untuk perawatan yang tepat.',
      date: '1 Agu 2026',
    ),
    SkinEducationModel(
      id: '2',
      category: 'SKINCARE',
      title: 'Rutinitas Skincare Pagi yang Benar',
      snippet:
          'Langkah-langkah rutinitas skincare pagi yang benar untuk kulit sehat.',
      date: '5 Agu 2026',
    ),
    SkinEducationModel(
      id: '3',
      category: 'KULIT BERMASALAH',
      title: 'Cara Mengatasi Jerawat Secara Alami',
      snippet:
          'Tips mengatasi jerawat dengan bahan-bahan alami yang aman.',
      date: '10 Agu 2026',
    ),
    SkinEducationModel(
      id: '4',
      category: 'SKINCARE',
      title: 'Pentingnya Sunscreen untuk Kesehatan Kulit',
      snippet:
          'Kenali pentingnya sunscreen dan cara memilih yang tepat untuk kulit.',
      date: '15 Agu 2026',
    ),
    SkinEducationModel(
      id: '5',
      category: 'NUTRISI KULIT',
      title: 'Makanan yang Bagus untuk Kesehatan Kulit',
      snippet:
          'Makanan sehat yang dapat membantu menjaga kesehatan kulit dari dalam.',
      date: '18 Agu 2026',
    ),
    SkinEducationModel(
      id: '6',
      category: 'TIPS & TRIK',
      title: 'Perawatan Kulit untuk Pemula',
      snippet:
          'Panduan sederhana memulai rutinitas skincare bagi pemula.',
      date: '20 Agu 2026',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Artikel terbit dari Firestore. Tanpa Firebase, seed demo tetap dipakai
  /// agar UI/tes tidak berubah.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    try {
      final articles = await ArticleService.listPublished();
      if (!mounted) return;
      setState(() {
        _allArticles = articles
            .map((a) => SkinEducationModel(
                  id: a.backendId,
                  category: a.category.toUpperCase(),
                  title: a.title,
                  snippet: a.content.isEmpty
                      ? a.title
                      : (a.content.length > 140
                          ? '${a.content.substring(0, 140)}…'
                          : a.content),
                  date: a.date.isNotEmpty
                      ? a.date
                      : AppDates.short(AppDates.nowWib()),
                  content: a.content,
                ))
            .toList();
        _categories = <String>{
          'Semua',
          for (final a in articles)
            if (a.category.isNotEmpty) a.category,
        }.toList();
        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory = 'Semua';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allArticles = <SkinEducationModel>[];
        _categories = <String>['Semua'];
        _selectedCategory = 'Semua';
      });
    }
  }

  List<SkinEducationModel> get _filteredArticles {
    final query = _searchController.text.trim().toLowerCase();
    return _allArticles.where((article) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          article.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesQuery = query.isEmpty ||
          article.title.toLowerCase().contains(query) ||
          article.snippet.toLowerCase().contains(query) ||
          article.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final articles = _filteredArticles;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title "Edukasi Kulit"
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 16.0,
                bottom: 10.0,
              ),
              child: const Text(
                'Edukasi Kulit',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            // Subtle divider line
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(bottom: 14.0),
            ),

            // Main Scrollable List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 1. Search Box (Centered placeholder per design mockup)
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE5E5EA),
                        width: 1.0,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textAlign: TextAlign.center,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Cari artikel...',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF9E9E9E),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Category Filter Chips (Horizontal list)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 9.0,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryMaroon
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryMaroon
                                      : const Color(0xFFE5E5EA),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF444444),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Article Cards List
                  if (articles.isEmpty)
                    _buildArticlesEmptyState()
                  else
                    ...articles.map((item) => _buildArticleCard(item)),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PenggunaNavBottom(
        currentIndex: 0,
        onTap: (index) {
          Navigator.pop(context);
          if (index != 0) {
            widget.onNavigateTab?.call(index);
          }
        },
      ),
    );
  }

  Widget _buildArticlesEmptyState() {
    final query = _searchController.text.trim();
    if (_allArticles.isEmpty) {
      return const EmptyStateWidget(
        icon: LucideIcons.bookOpen,
        title: 'Belum ada artikel edukasi',
        description:
            'Artikel tentang perawatan kulit dari Skinora akan muncul di sini.',
      );
    }
    if (query.isNotEmpty) {
      return NoSearchResultWidget(
        title: 'Artikel tidak ditemukan',
        description:
            'Tidak ada artikel yang cocok dengan "$query". Coba ubah kata kunci.',
        onAction: () {
          _searchController.clear();
          setState(() {});
        },
      );
    }
    if (_selectedCategory != 'Semua') {
      return EmptyStateWidget(
        icon: LucideIcons.filter,
        title: 'Tidak ada artikel pada kategori ini',
        description: 'Belum ada artikel dengan kategori "$_selectedCategory".',
        actionLabel: 'Tampilkan Semua',
        onAction: () => setState(() => _selectedCategory = 'Semua'),
      );
    }
    return const EmptyStateWidget(
      icon: LucideIcons.bookOpen,
      title: 'Belum ada artikel',
      description: 'Artikel edukasi kulit akan muncul di sini.',
    );
  }

  Widget _buildArticleCard(SkinEducationModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailEdukasiPenggunaPage(
                  article: item,
                  onNavigateTab: widget.onNavigateTab,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Book Open Outline Icon
                Padding(
                  padding: const EdgeInsets.only(top: 2.0, right: 14.0),
                  child: const Icon(
                    LucideIcons.bookOpen,
                    color: Color(0xFF8E8E93),
                    size: 22,
                  ),
                ),

                // Right Content Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Badge & Chevron Right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 3.0,
                            ),
                            decoration: BoxDecoration(
                              color: categoryBadgeBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.category,
                              style: const TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                color: primaryMaroon,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: Color(0xFF9E9E9E),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Article Title
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Snippet
                      Text(
                        item.snippet,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: subText,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Date with Clock Icon
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.clock,
                            size: 12,
                            color: dateText,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.date,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: dateText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
