import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import 'riwayat_skin_daily_page.dart';
import 'insight_kulit_pengguna_page.dart';

class SkinDailyPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const SkinDailyPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = false,
  });

  @override
  State<SkinDailyPage> createState() => _SkinDailyPageState();
}

class _SkinDailyPageState extends State<SkinDailyPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color cardBorder = Color(0xFFEEEEEE);
  static const Color innerBorder = Color(0xFFE5E5EA);

  DateTime _selectedDate = DateTime(2026, 8, 30);

  final Set<String> _selectedLocations = {};
  final Set<String> _selectedSymptoms = {};

  late final TextEditingController _kebiasaanController;
  late final TextEditingController _jamTidurController;
  late final TextEditingController _airController;
  late final TextEditingController _makananController;
  late final TextEditingController _aktivitasController;

  bool _isSkincarePagi = false;
  bool _isSkincareMalam = false;

  final List<String> _locationOptions = [
    'T-Zone',
    'Pipi Kiri',
    'Pipi Kanan',
    'Dagu',
    'Dahi',
    'Hidung',
  ];

  final List<String> _symptomOptions = [
    'Jerawat',
    'Berminyak',
    'Kering',
    'Kemerahan',
    'Flek/Noda',
    'Kusam',
    'Komedo',
    'Beruntusan',
    'Normal',
    'Pori-pori Besar',
    'Keriput',
    'Kerutan',
  ];

  @override
  void initState() {
    super.initState();
    _kebiasaanController = TextEditingController();
    _jamTidurController = TextEditingController();
    _airController = TextEditingController(text: '0');
    _makananController = TextEditingController();
    _aktivitasController = TextEditingController();
  }

  @override
  void dispose() {
    _kebiasaanController.dispose();
    _jamTidurController.dispose();
    _airController.dispose();
    _makananController.dispose();
    _aktivitasController.dispose();
    super.dispose();
  }

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

    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

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

  void _saveDailyJournal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Jurnal harian berhasil disimpan'),
        backgroundColor: primaryMaroon,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: "< Skin Daily" on the left, "Riwayat >" on the right
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
                    'Skin Daily',
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
                          builder: (context) => RiwayatSkinDailyPage(
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

            // Main scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 1. PROGRESS Card
                  _buildProgressCard(),
                  const SizedBox(height: 16),

                  // 2. TANGGAL Card
                  _buildTanggalCard(),
                  const SizedBox(height: 16),

                  // 3. LOKASI GEJALA Card
                  _buildLokasiGejalaCard(),
                  const SizedBox(height: 16),

                  // 4. GEJALA KULIT Card
                  _buildGejalaKulitCard(),
                  const SizedBox(height: 16),

                  // 5. KEBIASAAN HARIAN Card
                  _buildKebiasaanHarianCard(),
                  const SizedBox(height: 16),

                  // 6. JAM TIDUR & AIR (GELAS) Card
                  _buildTidurDanAirCard(),
                  const SizedBox(height: 16),

                  // 7. MAKANAN Card
                  _buildMakananCard(),
                  const SizedBox(height: 16),

                  // 8. AKTIVITAS Card
                  _buildAktivitasCard(),
                  const SizedBox(height: 16),

                  // 9. SKINCARE ROUTINE Card
                  _buildSkincareRoutineCard(),
                  const SizedBox(height: 20),

                  // 10. SIMPAN Button matching image.png
                  _buildSimpanButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? PenggunaNavBottom(
              currentIndex: 2,
              onTap: (index) {
                widget.onNavigateTab?.call(index);
              },
            )
          : null,
    );
  }

  /// Card 1: PROGRESS Card
  Widget _buildProgressCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'PROGRESS',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: darkText,
                ),
              ),
              Text(
                '7 hari',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 7,
              width: double.infinity,
              color: const Color(0xFFF2F2F7),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 1.0, // 7 days full progress matching mockup
                child: Container(
                  color: primaryMaroon,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // "Lihat Insight Kulit ->" Link
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InsightKulitPenggunaPage(
                    onNavigateTab: widget.onNavigateTab,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Lihat Insight Kulit',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: primaryMaroon,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    LucideIcons.arrowRight,
                    size: 14,
                    color: primaryMaroon,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card 2: TANGGAL Card
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

          // Date Input Box
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
          const SizedBox(height: 8),

          // Date Text Below Box
          Text(
            _formatIndonesianDate(_selectedDate),
            style: const TextStyle(
              fontSize: 12.0,
              color: subText,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Card 3: LOKASI GEJALA Card
  Widget _buildLokasiGejalaCard() {
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
            'LOKASI GEJALA',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),

          // 6 Location Rows with Checkboxes
          ...List.generate(_locationOptions.length, (index) {
            final loc = _locationOptions[index];
            final isChecked = _selectedLocations.contains(loc);
            final isLast = index == _locationOptions.length - 1;

            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 10.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isChecked) {
                      _selectedLocations.remove(loc);
                    } else {
                      _selectedLocations.add(loc);
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
                        loc,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: darkText,
                        ),
                      ),
                      const Spacer(),

                      // Rounded Checkbox Box matching mockup
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
        ],
      ),
    );
  }

  /// Card 4: GEJALA KULIT Card
  Widget _buildGejalaKulitCard() {
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
            'GEJALA KULIT',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),

          // Multi-select Chips Wrap
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _symptomOptions.map((symptom) {
              final isSelected = _selectedSymptoms.contains(symptom);

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSymptoms.remove(symptom);
                    } else {
                      _selectedSymptoms.add(symptom);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFCF4F4) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? primaryMaroon : const Color(0xFFE0E0E0),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    symptom,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? primaryMaroon : const Color(0xFF4A4A4A),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Card 5: KEBIASAAN HARIAN Card
  Widget _buildKebiasaanHarianCard() {
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
            'KEBIASAAN HARIAN',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),

          // Multi-line Text Area
          TextField(
            controller: _kebiasaanController,
            maxLines: 4,
            minLines: 3,
            style: const TextStyle(fontSize: 13.5, color: darkText),
            decoration: InputDecoration(
              hintText: 'Ceritakan kebiasaan harian Anda hari ini...',
              hintStyle: const TextStyle(
                fontSize: 13.0,
                color: Color(0xFF9E9E9E),
              ),
              contentPadding: const EdgeInsets.all(14.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: innerBorder, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: innerBorder, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryMaroon, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card 6: Side-by-side JAM TIDUR & AIR (GELAS) Card
  Widget _buildTidurDanAirCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: JAM TIDUR
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
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
                  'JAM TIDUR',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 46,
                  child: TextField(
                    controller: _jamTidurController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14.0, color: darkText),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 10.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: innerBorder, width: 1.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: innerBorder, width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryMaroon, width: 1.2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Right: AIR (GELAS)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
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
                  'AIR (GELAS)',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 46,
                  child: TextField(
                    controller: _airController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14.0, color: darkText),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 10.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: innerBorder, width: 1.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: innerBorder, width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryMaroon, width: 1.2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Card 7: MAKANAN Card
  Widget _buildMakananCard() {
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
            'MAKANAN',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _makananController,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(fontSize: 13.5, color: darkText),
            decoration: InputDecoration(
              hintText: 'Apa saja yang Anda makan hari ini?',
              hintStyle: const TextStyle(
                fontSize: 13.0,
                color: Color(0xFF9E9E9E),
              ),
              contentPadding: const EdgeInsets.all(14.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: innerBorder, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: innerBorder, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryMaroon, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card 8: AKTIVITAS Card
  Widget _buildAktivitasCard() {
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
            'AKTIVITAS',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _aktivitasController,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(fontSize: 13.5, color: darkText),
            decoration: InputDecoration(
              hintText: 'Aktivitas apa yang Anda lakukan hari ini?',
              hintStyle: const TextStyle(
                fontSize: 13.0,
                color: Color(0xFF9E9E9E),
              ),
              contentPadding: const EdgeInsets.all(14.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: innerBorder, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: innerBorder, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryMaroon, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card 9: SKINCARE ROUTINE Card
  Widget _buildSkincareRoutineCard() {
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
            'SKINCARE ROUTINE',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),

          // 1. Skincare Pagi
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: innerBorder, width: 1.0),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.sun,
                  size: 18,
                  color: Color(0xFFE65100),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Skincare Pagi',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
                const Spacer(),
                Transform.scale(
                  scale: 0.82,
                  child: Switch(
                    value: _isSkincarePagi,
                    onChanged: (val) {
                      setState(() {
                        _isSkincarePagi = val;
                      });
                    },
                    activeColor: primaryMaroon,
                    activeTrackColor: primaryMaroon.withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFE5E5EA),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Skincare Malam
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: innerBorder, width: 1.0),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.moon,
                  size: 18,
                  color: Color(0xFF5E35B1),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Skincare Malam',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
                const Spacer(),
                Transform.scale(
                  scale: 0.82,
                  child: Switch(
                    value: _isSkincareMalam,
                    onChanged: (val) {
                      setState(() {
                        _isSkincareMalam = val;
                      });
                    },
                    activeColor: primaryMaroon,
                    activeTrackColor: primaryMaroon.withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFE5E5EA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 10. SIMPAN Button
  Widget _buildSimpanButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _saveDailyJournal,
        icon: const Icon(LucideIcons.save, size: 18, color: Colors.white),
        label: const Text(
          'Simpan',
          style: TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.2,
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
    );
  }
}
