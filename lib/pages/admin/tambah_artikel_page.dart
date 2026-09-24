import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/admin_navbottom.dart';
import '../../models/admin_article_model.dart';
import '../../services/article_service.dart';
import '../../services/backend.dart';
import '../../utils/app_dates.dart';

class TambahArtikelPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const TambahArtikelPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<TambahArtikelPage> createState() => _TambahArtikelPageState();
}

class _TambahArtikelPageState extends State<TambahArtikelPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E293B);
  static const Color subText = Color(0xFF6B7280);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  ArticleStatus _selectedStatus = ArticleStatus.draf;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    final category = _categoryController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul artikel tidak boleh kosong'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (category.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori artikel tidak boleh kosong'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final dateStr = AppDates.iso(AppDates.nowWib());

    var newArticle = AdminArticleModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      date: dateStr,
      content: content.isEmpty ? 'Tidak ada deskripsi konten.' : content,
      status: _selectedStatus,
    );

    if (Backend.useFirebase) {
      try {
        newArticle = await ArticleService.create(newArticle);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan artikel: $e')),
        );
        return;
      }
    }

    if (!mounted) return;
    Navigator.pop(context, newArticle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Header: Chevron Left + Title
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 20.0,
                top: 16.0,
                bottom: 12.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      size: 22,
                      color: darkText,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Artikel Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                children: [
                  // JUDUL
                  _buildLabel('JUDUL'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _titleController,
                    hintText: 'Judul artikel...',
                  ),

                  const SizedBox(height: 18),

                  // KATEGORI
                  _buildLabel('KATEGORI'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _categoryController,
                    hintText: 'Kategori artikel...',
                  ),

                  const SizedBox(height: 18),

                  // STATUS
                  _buildLabel('STATUS'),
                  const SizedBox(height: 8),
                  _buildStatusToggle(),

                  const SizedBox(height: 18),

                  // KONTEN
                  _buildLabel('KONTEN'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _contentController,
                    hintText: 'Tulis konten artikel...',
                    minLines: 8,
                    maxLines: 12,
                  ),

                  const SizedBox(height: 28),

                  // Buat Artikel Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMaroon,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Buat Artikel',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminNavBottom(
        currentIndex: 3,
        onTap: (index) {
          Navigator.popUntil(context, (route) => route.isFirst);
          if (index != 3) {
            widget.onNavigateTab?.call(index);
          }
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: subText,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14.0,
        color: darkText,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 14.0,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 14.0,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryMaroon,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusToggle() {
    final isDraf = _selectedStatus == ArticleStatus.draf;
    final isDiterbitkan = _selectedStatus == ArticleStatus.diterbitkan;

    return Row(
      children: [
        // Draf button
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedStatus = ArticleStatus.draf;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDraf ? primaryMaroon : Colors.white,
                foregroundColor: isDraf ? Colors.white : darkText,
                elevation: 0,
                side: BorderSide(
                  color: isDraf ? primaryMaroon : const Color(0xFFE5E7EB),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Draf',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: isDraf ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Diterbitkan button
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedStatus = ArticleStatus.diterbitkan;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDiterbitkan ? primaryMaroon : Colors.white,
                foregroundColor: isDiterbitkan ? Colors.white : darkText,
                elevation: 0,
                side: BorderSide(
                  color: isDiterbitkan ? primaryMaroon : const Color(0xFFE5E7EB),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Diterbitkan',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: isDiterbitkan ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
