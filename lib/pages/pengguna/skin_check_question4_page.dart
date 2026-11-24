import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/weather_service.dart';
import '../../services/location_service.dart';
import 'skin_check_question5_page.dart';

class SkinCheckQuestion4Page extends StatefulWidget {
  final String age;
  final String gender;
  final String conditionAfterWash;
  final String oilCondition;
  final String sensitivity;
  final String? initialHumidity;
  final ValueChanged<int>? onNavigateTab;

  const SkinCheckQuestion4Page({
    super.key,
    required this.age,
    required this.gender,
    required this.conditionAfterWash,
    required this.oilCondition,
    required this.sensitivity,
    this.initialHumidity,
    this.onNavigateTab,
  });

  @override
  State<SkinCheckQuestion4Page> createState() => _SkinCheckQuestion4PageState();
}

class _SkinCheckQuestion4PageState extends State<SkinCheckQuestion4Page> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color disabledBtnBg = Color(0xFFDDD5D4);
  static const Color disabledBtnText = Color(0xFF9E9E9E);
  static const Color iconColor = Color(0xFF8E8E93);

  late final TextEditingController _humidityController;
  bool _checkingWeather = false;
  String _weatherInfo = '';

  @override
  void initState() {
    super.initState();
    _humidityController =
        TextEditingController(text: widget.initialHumidity ?? '');
  }

  @override
  void dispose() {
    _humidityController.dispose();
    super.dispose();
  }

  void _goBack() {
    Navigator.pop(context, _humidityController.text.trim());
  }

  /// Ambil kelembapan realtime dari API gratis Open-Meteo (Jakarta, WIB)
  /// lalu inputkan otomatis ke kolom.
  Future<void> _handleCek() async {
    if (_checkingWeather) return;
    setState(() {
      _checkingWeather = true;
      _weatherInfo = '';
    });
    try {
      final reading = await WeatherService.fetchCurrent();
      final place = await LocationService.displayLocation();
      if (!mounted) return;
      setState(() {
        _humidityController.text = reading.humidityLabel;
        _weatherInfo =
            'Realtime ${reading.humidityLabel} • ${reading.temperatureLabel} (WIB, $place)';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _weatherInfo = '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat cuaca realtime: $e')),
      );
    } finally {
      if (mounted) setState(() => _checkingWeather = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = _humidityController.text.trim().isNotEmpty;

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
                    // 2. Subtitle: "PERTANYAAN 4/5"
                    const Text(
                      'PERTANYAAN 4/5',
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
                              'Berapa tingkat kelembapan udara di lokasi Anda saat melakukan pemeriksaan?',
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
                    const SizedBox(height: 20),

                    // 4. Input Row with "Cek" button
                    Row(
                      children: [
                        // Humidity Input Container
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE5E5EA),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.wind,
                                  size: 18,
                                  color: iconColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _humidityController,
                                    keyboardType: TextInputType.text,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: darkText,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '74%',
                                      hintStyle: TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 14.0,
                                      ),
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
                        const SizedBox(width: 12),

                        // Button "Cek" (Peach background)
                        InkWell(
                          onTap: _checkingWeather ? null : _handleCek,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD5C8),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: _checkingWeather
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          primaryMaroon,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Cek',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: primaryMaroon,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_weatherInfo.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          _weatherInfo,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: primaryMaroon,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Helper/Disclaimer note card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            LucideIcons.info,
                            size: 16,
                            color: primaryMaroon,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tekan "Cek" untuk mendeteksi kelembapan udara otomatis di lokasi Anda secara realtime, atau masukkan secara manual.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF6B7280),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 5. Action Buttons Row ("< Sebelumnya" & "Selanjutnya >")
                    Row(
                      children: [
                        // Button "Sebelumnya"
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
                          child: !hasValue
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
                                            oilCondition: widget.oilCondition,
                                            sensitivity: widget.sensitivity,
                                            humidity: _humidityController.text
                                                .trim(),
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
                                            color: Colors.white,
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: PenggunaNavBottom(
          currentIndex: 1,
          onTap: (index) {
            Navigator.popUntil(context, (route) => route.isFirst);
            widget.onNavigateTab?.call(index);
          },
        ),
      ),
    );
  }
}
