import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/skin_service.dart';
import '../../utils/app_dates.dart';
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

  DateTime _selectedDate = AppDates.nowWib();

  final Set<String> _selectedLocations = {};
  final Set<String> _selectedSymptoms = {};

  late final TextEditingController _kebiasaanController;
  late final TextEditingController _jamTidurController;
  late final TextEditingController _airController;
  late final TextEditingController _makananController;
  late final TextEditingController _aktivitasController;

  bool _isSkincarePagi = false;
  bool _isSkincareMalam = false;
  int _filledDays = 0;
  bool _justSaved = false;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

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
    _loadProgress();
  }

  @override
  void dispose() {
    _sub?.cancel();
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
        _justSaved = false;
        _selectedDate = picked;
      });
      _applyLogForDate(picked);
    }
  }

  /// Jam tidur memakai clock picker (TimePicker) dan tampil di kolom input.
  Future<void> _pickSleepTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: AppDates.timeOfDayWib(),
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
    if (picked != null && mounted) {
      final raw = '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => _jamTidurController.text = AppDates.formatHm(raw));
    }
  }

  List<Map<String, dynamic>> _dailyLogs = [];

  void _applyLogForDate(DateTime date) {
    final iso = AppDates.iso(date);
    final match = _dailyLogs.where((l) => (l['dateIso'] as String?) == iso);
    if (match.isNotEmpty) {
      final doc = match.first;
      final locs = (doc['locations'] as List?)?.cast<String>() ?? [];
      final syms = (doc['symptoms'] as List?)?.cast<String>() ?? [];
      setState(() {
        _selectedLocations
          ..clear()
          ..addAll(locs);
        _selectedSymptoms
          ..clear()
          ..addAll(syms);
        _kebiasaanController.text = (doc['kebiasaan'] as String?) ?? '';
        _jamTidurController.text = (doc['jamTidur'] as String?) ?? '';
        _airController.text = (doc['air'] as String?) ?? '0';
        _makananController.text = (doc['makanan'] as String?) ?? '';
        _aktivitasController.text = (doc['aktivitas'] as String?) ?? '';
        _isSkincarePagi = doc['skincarePagi'] == true;
        _isSkincareMalam = doc['skincareMalam'] == true;
      });
    }
  }

  /// Hitung progress harian 0/7 s.d. 7/7 secara realtime dari tanggal unik yang terisi.
  void _loadProgress() {
    if (!Backend.useFirebase || AuthService.uid == null) {
      if (mounted) setState(() => _filledDays = 0);
      return;
    }
    _sub?.cancel();
    _sub = SkinService.streamSkinDailies(AuthService.uid!).listen((items) {
      if (!mounted) return;
      _dailyLogs = items;
      final uniq = items
          .map((e) => ((e['dateIso'] as String?) ?? '').trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      setState(() => _filledDays = uniq.length.clamp(0, 7));
      if (!_justSaved) {
        _applyLogForDate(_selectedDate);
      }
    }, onError: (_) {});
  }

  void _resetForm() {
    setState(() {
      _selectedLocations.clear();
      _selectedSymptoms.clear();
      _kebiasaanController.clear();
      _jamTidurController.clear();
      _airController.text = '0';
      _makananController.clear();
      _aktivitasController.clear();
      _isSkincarePagi = false;
      _isSkincareMalam = false;
    });
  }

  Future<void> _saveDailyJournal() async {
    final dateDisplay = _formatIndonesianDate(_selectedDate);
    final dateIso = AppDates.iso(_selectedDate);
    final locations = _selectedLocations.toList();
    final symptoms = _selectedSymptoms.toList();

    if (Backend.useFirebase && AuthService.uid != null) {
      final uid = AuthService.uid!;
      try {
        final profile = await AuthService.loadProfile();
        await SkinService.saveSkinDaily(
          uid: uid,
          name: (profile?.name.isNotEmpty ?? false) ? profile!.name : uid,
          dateDisplay: dateDisplay,
          dateIso: dateIso,
          locations: locations,
          symptoms: symptoms,
          kebiasaan: _kebiasaanController.text.trim(),
          jamTidur: _jamTidurController.text.trim(),
          air: _airController.text.trim(),
          makanan: _makananController.text.trim(),
          aktivitas: _aktivitasController.text.trim(),
          skincarePagi: _isSkincarePagi,
          skincareMalam: _isSkincareMalam,
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan jurnal harian'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() => _justSaved = true);
    _resetForm();
    if (!mounted) return;
    AdminSuccessDialog.show(
      context,
      message: 'Jurnal harian berhasil disimpan',
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

  /// Card 1: PROGRESS Card — berprogress 0/7 s.d. 7/7, insight terbuka setelah 7 hari.
  Widget _buildProgressCard() {
    final progress = (_filledDays.clamp(0, 7)) / 7.0;
    final canSeeInsight = _filledDays >= 7;
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
            children: [
              const Text(
                'PROGRESS',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: darkText,
                ),
              ),
              Text(
                '$_filledDays/7 hari',
                style: const TextStyle(
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
                widthFactor: progress,
                child: Container(
                  color: primaryMaroon,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // "Lihat Insight Kulit ->" Link — aktif setelah 7 hari.
          InkWell(
            onTap: canSeeInsight
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InsightKulitPenggunaPage(
                          onNavigateTab: widget.onNavigateTab,
                        ),
                      ),
                    );
                  }
                : () {
                    AdminSuccessDialog.show(
                      context,
                      title: 'Progress Mingguan',
                      message:
                          'Progress mingguan baru dapat dilihat setelah Anda mengisi jurnal harian selama 7 hari (saat ini $_filledDays/7 hari).',
                    );
                  },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    canSeeInsight
                        ? 'Lihat Insight Kulit'
                        : 'Isi $_filledDays/7 hari — lengkapi 7 hari untuk melihat progress',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: canSeeInsight
                          ? primaryMaroon
                          : const Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    LucideIcons.arrowRight,
                    size: 14,
                    color: canSeeInsight
                        ? primaryMaroon
                        : const Color(0xFF9E9E9E),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card 2: TANGGAL Card — tanggal di dalam kolom + date picker.
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

          // Date Input Box — tanggal tampil di dalam kolom.
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
                children: [
                  const Icon(
                    LucideIcons.calendar,
                    size: 18,
                    color: subText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _formatIndonesianDate(_selectedDate),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: darkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronDown,
                    size: 16,
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
                GestureDetector(
                  onTap: _pickSleepTime,
                  child: SizedBox(
                    height: 46,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _jamTidurController,
                        readOnly: true,
                        style:
                            const TextStyle(fontSize: 14.0, color: darkText),
                        decoration: InputDecoration(
                          hintText: 'Pilih jam (mis. 21.30)',
                          hintStyle: const TextStyle(
                              fontSize: 13, color: Color(0xFF9E9E9E)),
                          suffixIcon: const Icon(LucideIcons.clock,
                              size: 16, color: subText),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 10.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: innerBorder, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: innerBorder, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: primaryMaroon, width: 1.2),
                          ),
                        ),
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
                    activeThumbColor: primaryMaroon,
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
                    activeThumbColor: primaryMaroon,
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
