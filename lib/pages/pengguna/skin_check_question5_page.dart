import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/skin_service.dart';
import '../../services/skin_svm_service.dart';
import '../../services/weather_service.dart';
import '../../services/location_service.dart';
import '../../utils/app_dates.dart';
import 'skin_check_result_page.dart';

class SkinCheckQuestion5Page extends StatefulWidget {
  final String age;
  final String gender;
  final String conditionAfterWash;
  final String oilCondition;
  final String sensitivity;
  final String humidity;
  final String? initialTemperature;
  final ValueChanged<int>? onNavigateTab;

  const SkinCheckQuestion5Page({
    super.key,
    required this.age,
    required this.gender,
    required this.conditionAfterWash,
    required this.oilCondition,
    required this.sensitivity,
    required this.humidity,
    this.initialTemperature,
    this.onNavigateTab,
  });

  @override
  State<SkinCheckQuestion5Page> createState() => _SkinCheckQuestion5PageState();
}

class _SkinCheckQuestion5PageState extends State<SkinCheckQuestion5Page> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color disabledBtnBg = Color(0xFFDDD5D4);
  static const Color disabledBtnText = Color(0xFF9E9E9E);
  static const Color iconColor = Color(0xFF8E8E93);

  late final TextEditingController _tempController;
  bool _checkingWeather = false;
  bool _submitting = false;
  String _weatherInfo = '';

  @override
  void initState() {
    super.initState();
    _tempController =
        TextEditingController(text: widget.initialTemperature ?? '');
  }

  @override
  void dispose() {
    _tempController.dispose();
    super.dispose();
  }

  void _goBack() {
    Navigator.pop(context, _tempController.text.trim());
  }

  /// Ambil suhu realtime dari API gratis Open-Meteo (Jakarta, WIB)
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
        _tempController.text = reading.temperatureLabel;
        _weatherInfo =
            'Realtime ${reading.temperatureLabel} • ${reading.humidityLabel} (WIB, $place)';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat cuaca realtime: $e')),
      );
    } finally {
      if (mounted) setState(() => _checkingWeather = false);
    }
  }

  /// Jalankan klasifikasi RBF-SVM dari dataset, simpan ke Firestore, lalu buka hasil.
  Future<void> _submitSkinCheck() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final temperature = _tempController.text.trim();
      final prediction = await SkinSvmService.predict(
        age: widget.age,
        gender: widget.gender,
        conditionAfterWash: widget.conditionAfterWash,
        oilCondition: widget.oilCondition,
        sensitivity: widget.sensitivity,
        humidity: widget.humidity,
        temperature: temperature,
      );

      final skinType = prediction.skinType;
      final sensitivity = prediction.sensitivity;
      final acneRisk = prediction.acneRisk;
      final now = AppDates.nowWib();
      final createdDisplay = AppDates.fullDisplayWib(now);
      final createdIso = AppDates.iso(now);

      final answers = {
        'age': widget.age,
        'gender': widget.gender,
        'conditionAfterWash': widget.conditionAfterWash,
        'oilCondition': widget.oilCondition,
        'sensitivity': widget.sensitivity,
        'humidity': widget.humidity,
        'temperature': temperature,
      };

      final uid = AuthService.uid;
      if (uid != null) {
        try {
          final profile = await AuthService.loadProfile();
          final name =
              (profile?.name.isNotEmpty ?? false) ? profile!.name : 'Pengguna';
          await SkinService.saveSkinCheck(
            uid: uid,
            name: name,
            answers: answers,
            resultSkinType: skinType,
            resultSensitivity: sensitivity,
            resultAcneRisk: acneRisk,
            svmModel: 'RBF-SVM',
            svmConfidence: prediction.confidence,
            createdDisplay: createdDisplay,
            createdIso: createdIso,
          );
        } catch (_) {
          // hasil tetap ditampilkan bila penyimpanan gagal
        }
      } else {
        // Offline / widget test mode fallback
        await SkinService.saveSkinCheck(
          uid: 'demo_user',
          name: 'Pengguna',
          answers: answers,
          resultSkinType: skinType,
          resultSensitivity: sensitivity,
          resultAcneRisk: acneRisk,
          svmModel: 'RBF-SVM',
          svmConfidence: prediction.confidence,
          createdDisplay: createdDisplay,
          createdIso: createdIso,
        );
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SkinCheckResultPage(
            skinType: skinType,
            sensitivity: sensitivity,
            acneRisk: acneRisk,
            confidence: prediction.confidence,
            createdDisplay: createdDisplay,
            onNavigateTab: widget.onNavigateTab,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menganalisis dengan model SVM: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = _tempController.text.trim().isNotEmpty;

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
                    // 2. Subtitle: "PERTANYAAN 5/5"
                    const Text(
                      'PERTANYAAN 5/5',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Question Card: Number "5" + Question description
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
                          // Number "5" Maroon Squircle
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: primaryMaroon,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                '5',
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
                              'Bagaimana kulit Anda merespons perubahan suhu cuaca di lingkungan Anda saat ini?',
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
                        // Temperature Input Container
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
                                  LucideIcons.thermometer,
                                  size: 18,
                                  color: iconColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _tempController,
                                    keyboardType: TextInputType.text,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: darkText,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '32°C',
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

                        // Button "Cek" — realtime via API cuaca gratis.
                        GestureDetector(
                          onTap: _checkingWeather ? null : _handleCek,
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: _checkingWeather
                                  ? const Color(0xFFD89CA3)
                                  : primaryMaroon,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: _checkingWeather
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Cek',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_weatherInfo.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(LucideIcons.cloudSun,
                              size: 14, color: Color(0xFF8E8E93)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _weatherInfo,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF8E8E93)),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 5. Action Buttons Row ("< Sebelumnya" & "Lihat Hasil >")
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

                        // Button "Lihat Hasil"
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
                                      'Lihat Hasil',
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
                                    onPressed:
                                        _submitting ? null : _submitSkinCheck,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryMaroon,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _submitting
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Text(
                                                'Lihat Hasil',
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
