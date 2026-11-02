import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/backend.dart';

/// Halaman Splash Screen Skinora.
///
/// Tampil pertama kali setiap kali aplikasi dibuka dengan latar merah maroon
/// brand (#B23A48), logo lingkaran putih dengan ikon droplet maroon, judul
/// "Skinora", dan tagline "Glow up bersama Skinora".
///
/// Melakukan pengecekan status autentikasi:
/// - Bila belum login: diarahkan ke `/login`.
/// - Bila sudah login: langsung diarahkan ke beranda sesuai role
///   (pasien `/pengguna`, dokter `/dokter`, atau admin `/admin`)
///   sampai pengguna logout dari akunnya.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.displayDuration = const Duration(milliseconds: 2000),
  });

  /// Durasi tampilan minimal splash screen sebelum berpindah halaman.
  final Duration displayDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color brandMaroon = Color(0xFFB23A48);

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
    _handleStartupFlow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleStartupFlow() async {
    final completer = Completer<void>();
    _timer = Timer(widget.displayDuration, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    final routeFuture = _determineNextRoute();
    final results = await Future.wait([completer.future, routeFuture]);
    final nextRoute = results[1] as String;

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  Future<String> _determineNextRoute() async {
    if (!Backend.useFirebase) {
      return '/login';
    }

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        return '/login';
      }

      final profile = await AuthService.loadProfile();
      if (profile == null || !profile.canLogin) {
        // Sesi tidak valid / akun ditangguhkan: bersihkan sesi dan ke login
        try {
          await AuthService.signOut();
        } catch (_) {}
        return '/login';
      }

      switch (profile.role) {
        case 'admin':
          return '/admin';
        case 'dokter':
          return '/dokter';
        case 'pengguna':
        default:
          return '/pengguna';
      }
    } catch (e) {
      debugPrint('[SPLASH] Gagal verifikasi sesi pengguna: $e');
      try {
        await AuthService.signOut();
      } catch (_) {}
      return '/login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: brandMaroon,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: brandMaroon,
        body: PopScope(
          canPop: false,
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge Logo: Lingkaran putih dengan logo droplet merah maroon
                    Container(
                      width: 156,
                      height: 156,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo-skinora-white.png',
                          width: 156,
                          height: 156,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback bila asset belum di-cache oleh widget tester
                            return const Center(
                              child: Icon(
                                Icons.water_drop,
                                color: brandMaroon,
                                size: 76,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Judul Brand Skinora (Serif)
                    const Text(
                      'Skinora',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline Skinora
                    const Text(
                      'Glow up bersama Skinora',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
