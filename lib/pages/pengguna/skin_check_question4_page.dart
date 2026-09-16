import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import 'skin_check_question5_page.dart';

class SkinCheckQuestion4Page extends StatefulWidget {
  final String age;
  final String gender;
  final String conditionAfterWash;
  final String? initialOilCondition;
  final ValueChanged<int>? onNavigateTab;

  const SkinCheckQuestion4Page({
    super.key,
    required this.age,
    required this.gender,
    required this.conditionAfterWash,
    this.initialOilCondition,
    this.onNavigateTab,
  });

  @override
  State<SkinCheckQuestion4Page> createState() => _SkinCheckQuestion4PageState();
}

class _SkinCheckQuestion4PageState extends State<SkinCheckQuestion4Page> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color selectedPeachBg = Color(0xFFFFD5C3);
  static const Color disabledBtnBg = Color(0xFFDDD5D4);
  static const Color disabledBtnText = Color(0xFF9E9E9E);

  String? _selectedOilCondition;

  final List<String> _options = const [
    'Wajah terasa kering dan hampir tidak berminyak',
    'Sedikit berminyak, terutama di area tertentu',
    'Wajah terlihat mengkilap dan banyak minyak',
  ];

  @override
  void initState() {
    super.initState();
    _selectedOilCondition = widget.initialOilCondition;
  }

  void _goBack() {
    Navigator.pop(context, _selectedOilCondition);
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedOilCondition != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
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
                      onPressed: _goBack,
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
                    // 2. Subtitle: "PERTANYAAN 4/7"
                    const Text(
                      'PERTANYAAN 4/7',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Question Card: Number "4" + Question description
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Number "4" Maroon Squircle
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: primaryMaroon,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                '4',
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
                          const Expanded(
                            child: Text(
                              'Bagaimana kondisi minyak pada wajah Anda beberapa jam setelah mencuci wajah?',
                              style: TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Options List matching image copy 6.png
                    ..._options.map((option) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: _buildOilOptionCard(option),
                      );
                    }),

                    const SizedBox(height: 10),

                    // 5. Action Buttons Row ("< Sebelumnya" & "Selanjutnya >")
                    Row(
                      children: [
                        // Button "Sebelumnya" (Outlined white container)
                        Expanded(
                          child: InkWell(
                            onTap: _goBack,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE5E5EA),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    LucideIcons.chevronLeft,
                                    size: 16,
                                    color: darkText,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Sebelumnya',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                      color: darkText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Button "Selanjutnya"
                        Expanded(
                          child: !hasSelection
                              ? Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: disabledBtnBg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Selanjutnya',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: disabledBtnText,
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SkinCheckQuestion5Page(
                                            age: widget.age,
                                            gender: widget.gender,
                                            conditionAfterWash:
                                                widget.conditionAfterWash,
                                            oilCondition:
                                                _selectedOilCondition!,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          'Selanjutnya',
                                          style: TextStyle(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Icon(
                                          LucideIcons.chevronRight,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ],
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
            Navigator.pop(context); // pop question 4
            Navigator.pop(context); // pop question 3
            Navigator.pop(context); // pop question 2
            Navigator.pop(context); // pop question 1
            if (index != 1) {
              widget.onNavigateTab?.call(index);
            }
          },
        ),
      ),
    );
  }

  Widget _buildOilOptionCard(String option) {
    final isSelected = _selectedOilCondition == option;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? selectedPeachBg : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? primaryMaroon : const Color(0xFFEEEEEE),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            setState(() {
              _selectedOilCondition = option;
            });
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                // Radio Circle
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isSelected ? primaryMaroon : const Color(0xFFD0D0D0),
                      width: isSelected ? 2.0 : 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: primaryMaroon,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Option Text Label
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: darkText,
                    ),
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
