import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import 'skin_check_question2_page.dart';

class SkinCheckQuestion1Page extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final String? initialAge;

  const SkinCheckQuestion1Page({
    super.key,
    this.onNavigateTab,
    this.initialAge,
  });

  @override
  State<SkinCheckQuestion1Page> createState() => _SkinCheckQuestion1PageState();
}

class _SkinCheckQuestion1PageState extends State<SkinCheckQuestion1Page> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color disabledBtnBg = Color(0xFFDDD5D4);
  static const Color disabledBtnText = Color(0xFF9E9E9E);

  late final TextEditingController _ageController;
  String? _savedGender;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: widget.initialAge ?? '');
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  bool get _isInputValid => _ageController.text.trim().isNotEmpty;

  void _goToNextQuestion() async {
    if (!_isInputValid) return;

    final genderResult = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => SkinCheckQuestion2Page(
          age: _ageController.text.trim(),
          initialGender: _savedGender,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );

    if (genderResult != null) {
      setState(() {
        _savedGender = genderResult;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _isInputValid;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header: Back chevron + "Skin Check"
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
                  // 2. Subtitle: "PERTANYAAN 1/7"
                  const Text(
                    'PERTANYAAN 1/7',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Question Card: Number "1" + "Berapa usia Anda?"
                  Container(
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
                    child: Row(
                      children: [
                        // Number "1" Maroon Squircle
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: primaryMaroon,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Question Text
                        const Text(
                          'Berapa usia Anda?',
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Input Card: Inner input box with Calendar icon + "Tahun"
                  Container(
                    width: double.infinity,
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
                    child: Row(
                      children: [
                        // Inner input field container
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E5EA),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.calendar,
                                  size: 18,
                                  color: Color(0xFF9E9E9E),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _ageController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold,
                                      color: darkText,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Suffix "Tahun"
                        const Text(
                          'Tahun',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Button "Selanjutnya" (Grey when empty, Red/Maroon when filled)
                  if (!isValid)
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: disabledBtnBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'Selanjutnya',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: disabledBtnText,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _goToNextQuestion,
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
                              'Selanjutnya',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
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
          Navigator.pop(context);
          if (index != 1) {
            widget.onNavigateTab?.call(index);
          }
        },
      ),
    );
  }
}
