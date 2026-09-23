import 'package:flutter/material.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../components/navbottom/admin_navbottom.dart';
import '../../models/admin_article_model.dart';
import '../../services/article_service.dart';
import '../../services/backend.dart';
import 'edit_artikel_page.dart';
import 'tambah_artikel_page.dart';

class ManajemenEdukasiPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const ManajemenEdukasiPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = false,
  });

  @override
  State<ManajemenEdukasiPage> createState() => _ManajemenEdukasiPageState();
}

class _ManajemenEdukasiPageState extends State<ManajemenEdukasiPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E1E1E);
  static const Color subText = Color(0xFF757575);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Diterbitkan',
    'Draf',
  ];

  /// Seed demo HANYA untuk widget test / mode tanpa Firebase.
  /// Dengan Firebase, daftar diisi dari Firestore (boleh kosong).
  final List<AdminArticleModel> _articles = Backend.useFirebase
      ? <AdminArticleModel>[]
      : <AdminArticleModel>[
          AdminArticleModel(
            id: '1',
            title: 'Mengenal Tipe Kulit Wajah Anda',
            category: 'Kulit Dasar',
            date: '2026-08-01',
            content:
                'Pelajari cara mengenali tipe kulit wajah Anda untuk perawatan yang lebih tepat.',
            status: ArticleStatus.diterbitkan,
          ),
          AdminArticleModel(
            id: '2',
            title: 'Rutinitas Skincare Pagi yang Ber',
            category: 'Skincare',
            date: '2026-08-05',
            content:
                'Langkah-langkah rutinitas skincare pagi yang benar untuk kulit sehat.',
            status: ArticleStatus.diterbitkan,
          ),
          AdminArticleModel(
            id: '3',
            title: 'Cara Mengatasi Jerawat Secara',
            category: 'Kulit Bermasalah',
            date: '2026-08-10',
            content: 'Tips mengatasi jerawat dengan bahan-bahan alami yang aman.',
            status: ArticleStatus.diterbitkan,
          ),
          AdminArticleModel(
            id: '4',
            title: 'Pentingnya Sunscreen untuk Kes',
            category: 'Skincare',
            date: '2026-08-15',
            content:
                'Kenali pentingnya sunscreen dan cara memilih yang tepat untuk kulit Anda.',
            status: ArticleStatus.diterbitkan,
          ),
          AdminArticleModel(
            id: '5',
            title: 'Makanan yang Bagus untuk Kese',
            category: 'Nutrisi Kulit',
            date: '2026-08-18',
            content:
                'Makanan sehat yang dapat membantu menjaga kesehatan kulit dari dalam.',
            status: ArticleStatus.diterbitkan,
          ),
          AdminArticleModel(
            id: '6',
            title: 'Perawatan Kulit untuk Pemula',
            category: 'Tips & Trik',
            date: '2026-08-20',
            content: 'Panduan sederhana memulai rutinitas skincare bagi pemula.',
            status: ArticleStatus.diterbitkan,
          ),
          AdminArticleModel(
            id: '7',
            title: 'Draft: Treatment Laser Terbaru',
            category: 'Treatment',
            date: '2026-08-22',
            content: 'Artikel tentang treatment laser terbaru.',
            status: ArticleStatus.draf,
          ),
        ];

  List<AdminArticleModel> get _filteredArticles {
    return _articles.where((article) {
      // 1. Filter status
      if (_selectedFilter == 'Diterbitkan' &&
          article.status != ArticleStatus.diterbitkan) {
        return false;
      }
      if (_selectedFilter == 'Draf' && article.status != ArticleStatus.draf) {
        return false;
      }

      // 2. Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = article.title.toLowerCase().contains(query);
        final matchCategory = article.category.toLowerCase().contains(query);
        final matchContent = article.content.toLowerCase().contains(query);
        return matchTitle || matchCategory || matchContent;
      }

      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  /// Ambil artikel dari Firestore. Tanpa Firebase (test), seed demo tetap
  /// dipakai. Dengan Firebase, hasil backend selalu menggantikan seed —
  /// termasuk saat daftar kosong — agar UI sinkron dengan data asli.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    try {
      final articles = await ArticleService.listAll();
      if (!mounted) return;
      setState(() => _articles
        ..clear()
        ..addAll(articles));
    } catch (_) {
      // Query gagal → tampilkan kosong, jangan seed palsu di production.
      if (!mounted) return;
      setState(_articles.clear);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _navigateToTambahArtikel() async {
    final result = await Navigator.push<AdminArticleModel>(
      context,
      MaterialPageRoute(
        builder: (context) => TambahArtikelPage(
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _articles.insert(0, result);
      });
      AdminSuccessDialog.show(
        context,
        message: 'Artikel baru berhasil ditambahkan',
      );
    }
  }

  Future<void> _navigateToEditArtikel(AdminArticleModel article) async {
    final result = await Navigator.push<AdminArticleModel>(
      context,
      MaterialPageRoute(
        builder: (context) => EditArtikelPage(
          article: article,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        final index = _articles.indexWhere((a) => a.id == result.id);
        if (index != -1) {
          _articles[index] = result;
        }
      });
      AdminSuccessDialog.show(
        context,
        message: 'Artikel berhasil diperbarui',
      );
    }
  }

  Future<void> _handleToggleStatus(AdminArticleModel article) async {
    final newStatus = article.status == ArticleStatus.diterbitkan
        ? ArticleStatus.draf
        : ArticleStatus.diterbitkan;
    if (Backend.useFirebase) {
      try {
        await ArticleService.updateStatus(article.backendId, newStatus);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status artikel: $e')),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      article.status = newStatus;
    });

    final message = article.status == ArticleStatus.diterbitkan
        ? 'Artikel berhasil diterbitkan'
        : 'Artikel dialihkan ke draf';

    AdminSuccessDialog.show(
      context,
      message: message,
    );
  }

  void _handleDeleteArtikel(AdminArticleModel article) {
    AdminConfirmDialog.show(
      context,
      title: 'Hapus Artikel',
      message: 'Apakah Anda yakin ingin menghapus "${article.title}"?',
      confirmLabel: 'Hapus',
      confirmColor: const Color(0xFFEF4444),
      onConfirm: () async {
        if (Backend.useFirebase) {
          try {
            await ArticleService.delete(article.backendId);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal menghapus artikel: $e')),
              );
            }
            return;
          }
        }
        if (!mounted) return;
        setState(() {
          _articles.removeWhere((a) => a.id == article.id);
        });
        AdminSuccessDialog.show(
          context,
          message: 'Artikel berhasil dihapus',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredArticles;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "Manajemen Konten Edukasi"
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 18.0,
                bottom: 12.0,
              ),
              child: const Text(
                'Manajemen Konten Edukasi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            // Subtle divider line
            Container(
              height: 1,
              color: const Color(0xFFEEEEEE),
              margin: const EdgeInsets.only(bottom: 16.0),
            ),

            // Search Bar & "+ Baru" Button Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  // Search Input
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.2,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: darkText,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Cari artikel...',
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14.0,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 12.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // "+ Baru" Button
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _navigateToTambahArtikel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMaroon,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '+ Baru',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Filter Pills: Semua, Diterbitkan, Draf
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18.0,
                            vertical: 7.0,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryMaroon : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? primaryMaroon
                                  : const Color(0xFFE5E7EB),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // Articles List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'Tidak ada artikel dalam status ini'
                              : 'Tidak ditemukan artikel dengan kata kunci "$_searchQuery"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: subText,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final article = filtered[index];
                        return _buildArticleCard(article);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? AdminNavBottom(
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

  Widget _buildArticleCard(AdminArticleModel article) {
    final isDiterbitkan = article.status == ArticleStatus.diterbitkan;

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Judul + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: isDiterbitkan
                      ? const Color(0xFFFFD5C8)
                      : const Color(0xFFFCA5A5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isDiterbitkan ? 'Diterbitkan' : 'Draf',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDiterbitkan
                        ? const Color(0xFFC2410C)
                        : primaryMaroon,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Subtitle: Kategori · Tanggal
          Text(
            '${article.category} · ${article.date}',
            style: const TextStyle(
              fontSize: 12.5,
              color: subText,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          // Deskripsi / Konten
          Text(
            article.content,
            style: const TextStyle(
              fontSize: 13.0,
              color: Color(0xFF555555),
              height: 1.35,
            ),
          ),

          const SizedBox(height: 14),

          // 3 Action Buttons: Edit, Tolak Terbit / Terbitkan, Hapus
          Row(
            children: [
              // 1. Edit
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => _navigateToEditArtikel(article),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD5C8),
                      foregroundColor: const Color(0xFFC2410C),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC2410C),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Tolak Terbit / Terbitkan
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => _handleToggleStatus(article),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFCA5A5),
                      foregroundColor: isDiterbitkan
                          ? const Color(0xFFDC2626)
                          : primaryMaroon,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isDiterbitkan ? 'Tolak Terbit' : 'Terbitkan',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDiterbitkan
                            ? const Color(0xFFDC2626)
                            : primaryMaroon,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 3. Hapus
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => _handleDeleteArtikel(article),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE2E2),
                      foregroundColor: const Color(0xFFEF4444),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Hapus',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
