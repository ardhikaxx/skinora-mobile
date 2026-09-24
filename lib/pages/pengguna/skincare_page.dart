import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/skin_service.dart';
import '../../utils/app_dates.dart';
import 'riwayat_skincare_page.dart';

class SkincarePage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const SkincarePage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = false,
  });

  @override
  State<SkincarePage> createState() => _SkincarePageState();
}

class _SkincarePageState extends State<SkincarePage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color cardBorder = Color(0xFFEEEEEE);
  static const Color innerBorder = Color(0xFFE5E5EA);
  static const Color peachIconBg = Color(0xFFFFD5C8);

  DateTime _selectedDate = AppDates.nowWib();

  final Set<String> _selectedMorning = {};
  final Set<String> _selectedNight = {};

  final List<String> _morningOptions = [
    'Cleanser',
    'Facial Wash',
    'Toner',
    'Essence',
    'Serum',
    'Moisturizer',
    'Sunscreen/Day Cream',
    'Face Mist',
  ];

  final List<String> _nightOptions = [
    'Cleanser',
    'Facial Wash',
    'Masker Wajah',
    'Toner',
    'Essence',
    'Serum',
    'Exfoliating',
    'Moisturizer',
    'Night Cream',
    'Sleeping Mask',
    'Eye Cream',
    'Acne Cream',
    'Dark Spot Cream',
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryMaroon,
              onPrimary: Colors.white,
              onSurface: darkText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveRoutine({required bool isMorning}) async {
    if (Backend.useFirebase && AuthService.uid != null) {
      final uid = AuthService.uid!;
      try {
        final profile = await AuthService.loadProfile();
        await SkinService.saveSkincare(
          uid: uid,
          name: (profile?.name.isNotEmpty ?? false) ? profile!.name : uid,
          dateDisplay: _formatIndonesianDate(_selectedDate),
          dateIso: AppDates.iso(_selectedDate),
          morningSteps: isMorning ? _selectedMorning.toList() : null,
          nightSteps: isMorning ? null : _selectedNight.toList(),
          isMorning: isMorning,
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan rutinitas skincare'),
          duration: Duration(seconds: 2),
        ),
        );
        return;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isMorning
              ? 'Morning Routine berhasil disimpan'
              : 'Night Routine berhasil disimpan',
        ),
        backgroundColor: primaryMaroon,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveMorningRoutine() => _saveRoutine(isMorning: true);

  Future<void> _saveNightRoutine() => _saveRoutine(isMorning: false);

  String _formatIndonesianDate(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${days[date.weekday - 1]}, ${date.day} '
        '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: "< Skincare Routine" and "Riwayat >"
            Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
                right: 20.0,
                top: 14.0,
                bottom: 10.0,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        widget.onNavigateTab?.call(0);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(
                        LucideIcons.chevronLeft,
                        size: 22,
                        color: darkText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Skincare Routine',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RiwayatSkincarePage(
                            onNavigateTab: widget.onNavigateTab,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 4.0,
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
              margin: const EdgeInsets.only(bottom: 14.0),
            ),

            // Scrollable Routine Cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 1. TANGGAL Card
                  _buildTanggalCard(),
                  const SizedBox(height: 16),

                  // 2. Morning Routine Card
                  _buildMorningRoutineCard(),
                  const SizedBox(height: 16),

                  // 3. Night Routine Card
                  _buildNightRoutineCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? PenggunaNavBottom(
              currentIndex: 3,
              onTap: (index) {
                widget.onNavigateTab?.call(index);
              },
            )
          : null,
    );
  }

  /// 1. TANGGAL Card
  Widget _buildTanggalCard() {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.0),
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
            'TANGGAL',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),

          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: innerBorder, width: 1.0),
              ),
              child: Row(
                children: const [
                  Icon(
                    LucideIcons.calendar,
                    size: 18,
                    color: subText,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Morning Routine Card
  Widget _buildMorningRoutineCard() {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.0),
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
          // Header: Sun Icon Box + "Morning Routine"
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: peachIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.sun,
                    size: 17,
                    color: primaryMaroon,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Morning Routine',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Items with Checkboxes
          ...List.generate(_morningOptions.length, (index) {
            final item = _morningOptions[index];
            final isChecked = _selectedMorning.contains(item);

            return Container(
              margin: const EdgeInsets.only(bottom: 10.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isChecked) {
                      _selectedMorning.remove(item);
                    } else {
                      _selectedMorning.add(item);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: innerBorder, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: darkText,
                        ),
                      ),
                      const Spacer(),

                      // Checkbox square matching mockup
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isChecked ? primaryMaroon : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isChecked ? primaryMaroon : const Color(0xFFCCCCCC),
                            width: 1.4,
                          ),
                        ),
                        child: isChecked
                            ? const Center(
                                child: Icon(
                                  Icons.check,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 6),

          // Button: "Simpan Pagi"
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _saveMorningRoutine,
              icon: const Icon(LucideIcons.save, size: 16, color: Colors.white),
              label: const Text(
                'Simpan Pagi',
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
        ],
      ),
    );
  }

  /// 3. Night Routine Card
  Widget _buildNightRoutineCard() {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.0),
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
          // Header: Moon Icon Box + "Night Routine"
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: peachIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.moon,
                    size: 17,
                    color: primaryMaroon,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Night Routine',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Items with Checkboxes
          ...List.generate(_nightOptions.length, (index) {
            final item = _nightOptions[index];
            final isChecked = _selectedNight.contains(item);

            return Container(
              margin: const EdgeInsets.only(bottom: 10.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isChecked) {
                      _selectedNight.remove(item);
                    } else {
                      _selectedNight.add(item);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: innerBorder, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: darkText,
                        ),
                      ),
                      const Spacer(),

                      // Checkbox square matching mockup
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isChecked ? primaryMaroon : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isChecked ? primaryMaroon : const Color(0xFFCCCCCC),
                            width: 1.4,
                          ),
                        ),
                        child: isChecked
                            ? const Center(
                                child: Icon(
                                  Icons.check,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 6),

          // Button: "Simpan Malam"
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _saveNightRoutine,
              icon: const Icon(LucideIcons.save, size: 16, color: Colors.white),
              label: const Text(
                'Simpan Malam',
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
        ],
      ),
    );
  }
}
