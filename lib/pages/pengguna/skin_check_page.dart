import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/location_service.dart';
import '../../services/skin_svm_service.dart';
import '../../services/user_service.dart';
import '../../services/weather_service.dart';
import '../../utils/app_dates.dart';
import 'edit_profil_pengguna_page.dart';
import 'skin_check_question1_page.dart';
import 'riwayat_skin_check_page.dart';

class SkinCheckPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const SkinCheckPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = false,
  });

  @override
  State<SkinCheckPage> createState() => _SkinCheckPageState();
}

class _SkinCheckPageState extends State<SkinCheckPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF757575);
  static const Color peachBg = Color(0xFFFFD5C3);
  static const Color peachIconBg = Color(0xFFFFD5C8);

  /// Lokasi + cuaca device (geolokasi) untuk konteks skin check.
  String _placeLabel = '';
  WeatherReading? _weather;
  bool _loadingWeather = true;

  @override
  void initState() {
    super.initState();
    _loadLocationWeather();
    // Pre-train model RBF-SVM dari dataset agar prediksi instan saat kuesioner selesai.
    SkinSvmService.ensureModel().catchError((_) => throw StateError('ignored'));
  }

  Future<void> _loadLocationWeather() async {
    try {
      final place = await LocationService.displayLocation();
      final reading = await WeatherService.fetchCurrent();
      if (!mounted) return;
      setState(() {
        _placeLabel = place;
        _weather = reading;
        _loadingWeather = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingWeather = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header: "Skin Check" on the left, "Riwayat >" on the right
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 16.0,
                bottom: 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RiwayatSkinCheckPage(
                            onNavigateTab: widget.onNavigateTab,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 2.0,
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
              margin: const EdgeInsets.only(bottom: 16.0),
            ),

            // Main scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 2. Maroon Hero Banner
                  _buildHeroBanner(),
                  const SizedBox(height: 18),

                  // 2b. Lokasi + cuaca device (geolokasi)
                  _buildLocationWeatherCard(),
                  const SizedBox(height: 18),

                  // 3. "YANG ANDA DAPATKAN" Card
                  _buildYangAndaDapatkanCard(),
                  const SizedBox(height: 18),

                  // 4. "DISCLAIMER" Card
                  _buildDisclaimerCard(),
                  const SizedBox(height: 18),

                  // 5. "7 Pertanyaan" Card
                  _buildPertanyaanCard(),
                  const SizedBox(height: 18),

                  // 6. "Mulai Skin Check >" Button
                  _buildMulaiSkinCheckButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? PenggunaNavBottom(
              currentIndex: 1,
              onTap: (index) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                widget.onNavigateTab?.call(index);
              },
            )
          : null,
    );
  }

  /// 2. Maroon Hero Banner with Stethoscope Icon, Title & Description
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: primaryMaroon,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryMaroon.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Translucent Stethoscope Icon Box
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.stethoscope,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Skin Check',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            'Kenali jenis kulit Anda melalui kuesioner berbasis SVM.',
            style: TextStyle(
              fontSize: 13.0,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// 2b. Kartu lokasi + cuaca device (geolokasi) — konteks lingkungan kulit.
  Widget _buildLocationWeatherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
      decoration: BoxDecoration(
        color: peachBg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF4E2D8)),
      ),
      child: _loadingWeather
          ? const Row(
              children: [
                Icon(
                  LucideIcons.mapPin,
                  size: 17,
                  color: primaryMaroon,
                ),
                SizedBox(width: 8),
                Text(
                  'Mendeteksi lokasi & cuaca...',
                  style: TextStyle(fontSize: 12.5, color: subText),
                ),
              ],
            )
          : Row(
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  size: 17,
                  color: primaryMaroon,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _placeLabel.isEmpty ? 'Lokasi Anda' : _placeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                ),
                if (_weather != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_weather!.temperatureLabel} • ${_weather!.humidityLabel}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: primaryMaroon,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  /// 3. "YANG ANDA DAPATKAN" Card with 3 items
  Widget _buildYangAndaDapatkanCard() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YANG ANDA DAPATKAN',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: darkText,
            ),
          ),
          const SizedBox(height: 16),

          // Item 1: Jenis Kulit
          _buildBenefitItem(
            icon: LucideIcons.droplets,
            title: 'Jenis Kulit',
            subtitle: 'Kering, Normal, Kombinasi, atau Berminyak',
          ),
          const SizedBox(height: 14),

          // Item 2: Sensitivitas
          _buildBenefitItem(
            icon: LucideIcons.shield,
            title: 'Sensitivitas',
            subtitle: 'Apakah kulit Anda sensitif',
          ),
          const SizedBox(height: 14),

          // Item 3: Risiko Jerawat
          _buildBenefitItem(
            icon: LucideIcons.triangleAlert,
            title: 'Risiko Jerawat',
            subtitle: 'Tingkat kerentanan jerawat',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        // Peach Squircle Icon Box
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: peachIconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              icon,
              color: primaryMaroon,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Text Information
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: subText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 4. "DISCLAIMER" Peach Card
  Widget _buildDisclaimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: peachBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                LucideIcons.triangleAlert,
                size: 18,
                color: primaryMaroon,
              ),
              SizedBox(width: 8),
              Text(
                'DISCLAIMER',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Hasil bersifat edukatif dan bukan pengganti diagnosis medis. Konsultasikan dengan dokter spesialis kulit.',
            style: TextStyle(
              fontSize: 12.0,
              color: darkText,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// 5. "5 Pertanyaan" Card
  Widget _buildPertanyaanCard() {
    return Container(
      width: double.infinity,
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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                LucideIcons.clock,
                size: 16,
                color: darkText,
              ),
              SizedBox(width: 8),
              Text(
                '5 Pertanyaan',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Kuesioner pilihan ganda. Jawab sesuai kondisi kulit Anda saat ini.',
            style: TextStyle(
              fontSize: 12.0,
              color: subText,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// Memeriksa kelengkapan data pasien sebelum memulai skin check.
  /// Jika tanggal lahir atau jenis kelamin belum lengkap, tampilkan modal peringatan.
  Future<void> _handleStartSkinCheck() async {
    UserProfile? profile;
    final uid = AuthService.uid;
    if (Backend.useFirebase && uid != null && uid.isNotEmpty) {
      profile = await UserService.loadByUid(uid);
    } else {
      profile = await UserService.loadByUid(uid ?? 'demo_user');
      profile ??= await AuthService.loadProfile();
    }

    final birthDate = profile?.birthDate.trim() ?? '';
    final gender = profile?.gender.trim() ?? '';
    final age = AppDates.calculateAge(birthDate);

    final isDataComplete = birthDate.isNotEmpty && gender.isNotEmpty && age > 0;

    if (!isDataComplete) {
      if (!mounted) return;
      _showIncompleteProfileDialog(profile);
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SkinCheckQuestion1Page(
          age: '$age',
          gender: gender,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );
  }

  /// Menampilkan modal template jika data profil pengguna belum lengkap.
  void _showIncompleteProfileDialog(UserProfile? profile) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 4,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: User Warning Icon + Title + Close Button
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD5C8),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.userX,
                          color: primaryMaroon,
                          size: 19,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Data Profil Belum Lengkap',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        child: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Message Body
                const Text(
                  'Untuk melakukan Skin Check, Anda perlu melengkapi data profil terlebih dahulu (Tanggal Lahir dan Jenis Kelamin) agar analisis kondisi kulit akurat.',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.normal,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons: "Nanti Saja" & "Lengkapi Profil"
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Nanti Saja',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfilPenggunaPage(
                                  initialName: profile?.name ?? '',
                                  initialPhone: profile?.phone ?? '',
                                  initialAddress: profile?.address ?? '',
                                  initialBirthDate: profile?.birthDate ?? '',
                                  initialGender: profile?.gender ?? '',
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
                          child: const Text(
                            'Lengkapi Profil',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 6. "Mulai Skin Check >" Button
  Widget _buildMulaiSkinCheckButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _handleStartSkinCheck,
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
              'Mulai Skin Check',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
