import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../admin/admin_main_page.dart';
import '../dokter/dokter_main_page.dart';
import '../pengguna/pengguna_main_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color primaryColor = Color(0xFFB23A48);
  static const Color darkTextColor = Color(0xFF321417);
  static const Color labelTextColor = Color(0xFF555555);
  static const Color borderColor = Color(0xFFE8E8E8);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _restoreSessionIfNeeded();
  }

  /// Session persistence: bila pengguna sudah login, langsung diarahkan
  /// ke shell sesuai role tanpa mengubah tampilan halaman login.
  Future<void> _restoreSessionIfNeeded() async {
    if (!Backend.useFirebase) return;
    final user = AuthService.currentUser;
    if (user == null) return;
    final profile = await AuthService.loadProfile();
    if (!mounted) return;
    if (profile == null || !profile.canLogin) {
      await AuthService.signOut();
      return;
    }
    _routeToHome(profile.role);
  }

  void _routeToHome(String role) {
    Widget home;
    switch (role) {
      case 'admin':
        home = const AdminMainPage();
      case 'dokter':
        home = const DokterMainPage();
      default:
        home = const PenggunaMainPage();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => home),
    );
  }

  /// Login Email & Password via Firebase Authentication.
  /// Role diambil dari `users/{uid}.role` — bukan dari tebakan string input.
  Future<void> _handleLogin() async {
    final input = _emailController.text.trim();
    final email = input.toLowerCase();
    final password = _passwordController.text;

    setState(() {
      _errorMessage = null;
    });

    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Silakan masukkan email / role Anda';
      });
      return;
    }
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Silakan masukkan password Anda';
      });
      return;
    }

    if (!Backend.useFirebase) {
      setState(() {
        _errorMessage = 'Backend Firebase belum terkonfigurasi.';
      });
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthService.signIn(email: email, password: password);
      final profile = await AuthService.loadProfile();
      if (profile == null) {
        await AuthService.signOut();
        setState(() {
          _errorMessage = 'Akun tidak terdaftar. Silakan daftar terlebih dahulu.';
          _busy = false;
        });
        return;
      }
      if (!profile.canLogin) {
        await AuthService.signOut();
        setState(() {
          _errorMessage = 'Akun Anda ditangguhkan. Hubungi administrator.';
          _busy = false;
        });
        return;
      }
      // Log aktivitas login (Firestore) — hanya bila backend aktif.
      await ActivityService.log(
        title: 'Login berhasil',
        tag: 'Login',
        actor: profile.name,
        actorUid: profile.uid,
      );
      _routeToHome(profile.role);
    } catch (e) {
      setState(() {
        _errorMessage = AuthService.describeAuthError(e);
        _busy = false;
      });
    }
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim().toLowerCase();
    if (!Backend.useFirebase) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backend Firebase belum terkonfigurasi.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan email terlebih dahulu untuk reset password.';
      });
      return;
    }
    AuthService.sendPasswordReset(email).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email reset password telah dikirim.'),
          duration: Duration(seconds: 2),
        ),
      );
    }).catchError((Object e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AuthService.describeAuthError(e);
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Icon Box
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.droplets,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Brand Title
                  const Text(
                    'Skinora',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'serif',
                      color: darkTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle
                  const Text(
                    'Kesehatan Kulit Digital',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF706D6E),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Container Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // EMAIL Label
                        const Text(
                          'EMAIL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: labelTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // EMAIL / ROLE TextField
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'contoh@email.com',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            prefixIcon: Center(
                              widthFactor: 2.0,
                              child: Icon(
                                LucideIcons.mail,
                                color: Colors.grey.shade500,
                                size: 16,
                              ),
                            ),
                            errorText: _errorMessage,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: borderColor, width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: primaryColor, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // PASSWORD Label
                        const Text(
                          'PASSWORD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: labelTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // PASSWORD TextField
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Masukkan password',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            prefixIcon: Center(
                              widthFactor: 2.0,
                              child: Icon(
                                LucideIcons.lock,
                                color: Colors.grey.shade500,
                                size: 16,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? LucideIcons.eye
                                    : LucideIcons.eyeOff,
                                color: Colors.grey.shade500,
                                size: 16,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: borderColor, width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: primaryColor, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Ingat saya & Lupa password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: primaryColor,
                                    side: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _rememberMe = val ?? false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ingat saya',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: _handleForgotPassword,
                              child: const Text(
                                'Lupa password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Tombol Masuk ->
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _busy ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: primaryColor.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(LucideIcons.arrowRight, size: 15),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Belum punya akun? Daftar sekarang
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: Text.rich(
                      TextSpan(
                        text: 'Belum punya akun? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Daftar sekarang',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
