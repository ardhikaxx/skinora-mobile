import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/buttons/google_auth_button.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../components/dialogs/lengkapi_data_diri_dialog.dart';
import '../../models/user_profile.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/user_service.dart';
import '../dokter/dokter_main_page.dart';
import '../pengguna/pengguna_main_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color primaryColor = Color(0xFFB23A48);
  static const Color darkTextColor = Color(0xFF321417);
  static const Color labelTextColor = Color(0xFF555555);
  static const Color borderColor = Color(0xFFE8E8E8);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedGender = 'Perempuan';
  static const List<String> _genders = ['Perempuan', 'Laki-laki'];

  bool _obscurePassword = true;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    DateTime initial = DateTime(2000, 1, 1);
    final iso = _birthDateController.text.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(iso)) {
      final p = DateTime.tryParse(iso);
      if (p != null) initial = p;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            onSurface: darkTextColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      final isoStr =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => _birthDateController.text = isoStr);
    }
  }

  /// Registrasi via Firebase Authentication Email & Password.
  /// Hanya untuk pengguna (dan dokter yang sudah di-provision admin).
  /// Admin tidak bisa register; dokter baru mewarisi role dari provision.
  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final birthDate = _birthDateController.text.trim();
    final gender = _selectedGender;
    final password = _passwordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        birthDate.isEmpty ||
        gender.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silahkan lengkapi semua kolom pendaftaran (termasuk tanggal lahir dan jenis kelamin).',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password minimal 4 karakter.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!Backend.useFirebase && AuthService.mockRegisterHandler == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backend Firebase belum terkonfigurasi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        birthDate: birthDate,
        gender: gender,
      );
      UserProfile? profile = await AuthService.loadProfile();
      final role = profile?.role ?? 'pengguna';

      await ActivityService.log(
        title: 'Pendaftaran berhasil',
        tag: 'Register',
        actor: name,
        actorUid: profile?.uid ?? '',
      );
      // Notifikasi broadcast role:admin hanya boleh dibuat admin (rules).
      // Pendaftar baru cukup tercatat di activity + muncul di daftar pengguna.

      if (!mounted) return;
      // Registrasi berhasil -> tampilkan dialog dulu, navigasi di onOk
      // (hanya pengguna & dokter; admin tidak bisa register).
      if (role == 'dokter' && profile?.status != 'terverifikasi') {
        // Dokter baru (baik mandiri maupun provision admin) berstatus 'menunggu'
        // -> tidak bisa langsung masuk, wajib menunggu verifikasi admin.
        await AuthService.signOut();
        if (!mounted) return;
        setState(() => _busy = false);
        AdminSuccessDialog.show(
          context,
          title: 'Menunggu Verifikasi',
          message:
              'Pendaftaran akun dokter berhasil!\n\nStatus akun Anda saat ini "Menunggu Verifikasi". Tim Admin Skinora akan meninjau data Anda. Anda baru dapat masuk (login) ke aplikasi setelah akun Anda diverifikasi oleh admin.',
          onOk: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          },
        );
        return;
      }

      // Khusus role pengguna: wajib melengkapi data diri (termasuk alamat) via modal template
      if (role == 'pengguna' && profile != null && !profile.isPatientProfileComplete) {
        if (mounted) setState(() => _busy = false);
        final updated = await LengkapiDataDiriDialog.show(
          context,
          profile: profile,
        );
        if (updated == null) {
          // Batal melengkapi data diri (sudah sign out di dalam dialog)
          return;
        }
        profile = updated;
      }

      if (!mounted) return;

      final Widget home = role == 'dokter'
          ? const DokterMainPage()
          : const PenggunaMainPage();
      setState(() => _busy = false);
      AdminSuccessDialog.show(
        context,
        message: 'Pendaftaran berhasil! Selamat datang, ${profile?.name ?? name}.',
        onOk: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => home),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.describeAuthError(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Pendaftaran dengan Google — Dikhususkan HANYA untuk pasien / role pengguna.
  /// Jika akun sudah terdaftar sebagai dokter atau admin, pendaftaran ditolak
  /// dan diarahkan untuk login di halaman LoginPage.
  Future<void> _handleGoogleRegister() async {
    setState(() => _busy = true);
    try {
      final credential = await AuthService.signInWithGoogle();
      if (credential == null || credential.user == null) {
        // Pengguna membatalkan dialog pemilihan akun Google
        if (mounted) setState(() => _busy = false);
        return;
      }

      final profile = await UserService.handleGoogleSignIn(
        preferredRole: 'pengguna',
      );

      // Validasi: Register dengan Google hanya untuk pasien / pengguna.
      if (profile.role == 'dokter' || profile.role == 'admin') {
        await AuthService.signOut();
        if (!mounted) return;
        setState(() => _busy = false);
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Akun Khusus',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Email ini terdaftar sebagai ${profile.role}. Pendaftaran pasien tidak dapat menggunakan akun dokter/admin.\n\nSilakan masuk melalui halaman login.',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text('Ke Halaman Login'),
              ),
            ],
          ),
        );
        return;
      }

      // Wajib melengkapi data diri pasien jika belum lengkap
      UserProfile currentProfile = profile;
      if (!profile.isPatientProfileComplete) {
        if (!mounted) return;
        setState(() => _busy = false);
        final updated = await LengkapiDataDiriDialog.show(
          context,
          profile: profile,
        );
        if (updated == null) {
          // Batal melengkapi data diri (sudah sign out di dalam dialog)
          return;
        }
        currentProfile = updated;
      }

      await ActivityService.log(
        title: 'Pendaftaran Google berhasil',
        tag: 'Register',
        actor: currentProfile.name,
        actorUid: currentProfile.uid,
      );

      if (!mounted) return;
      setState(() => _busy = false);
      AdminSuccessDialog.show(
        context,
        message:
            'Pendaftaran berhasil! Selamat datang, ${currentProfile.name}.',
        onOk: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PenggunaMainPage()),
          );
        },
      );
    } catch (e) {
      debugPrint('[REGISTER] Google Register gagal: ${e.runtimeType} → $e');
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.describeAuthError(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
                    'Daftar Skinora',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'serif',
                      color: darkTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle
                  const Text(
                    'Buat akun baru untuk memulai',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF706D6E),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 28),

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
                        // NAMA LENGKAP Label
                        const Text(
                          'NAMA LENGKAP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: labelTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // NAMA LENGKAP TextField
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'Nama Anda',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
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
                        const SizedBox(height: 16),

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

                        // EMAIL TextField
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'contoh@email.com',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
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
                        const SizedBox(height: 16),

                        // TELEPON Label
                        const Text(
                          'TELEPON',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: labelTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // TELEPON TextField
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '081234567890',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
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
                        const SizedBox(height: 16),

                        // TANGGAL LAHIR Label
                        const Text(
                          'TANGGAL LAHIR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: labelTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // TANGGAL LAHIR TextField (Read-only + DatePicker)
                        GestureDetector(
                          onTap: _pickBirthDate,
                          child: AbsorbPointer(
                            child: TextField(
                              controller: _birthDateController,
                              decoration: InputDecoration(
                                hintText: 'Pilih Tanggal Lahir (YYYY-MM-DD)',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                                suffixIcon: const Icon(
                                  LucideIcons.calendarDays,
                                  color: primaryColor,
                                  size: 18,
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
                          ),
                        ),
                        const SizedBox(height: 16),

                        // JENIS KELAMIN Label
                        const Text(
                          'JENIS KELAMIN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: labelTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // JENIS KELAMIN Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: borderColor,
                              width: 1.2,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedGender,
                              isExpanded: true,
                              icon: const Icon(
                                LucideIcons.chevronDown,
                                size: 18,
                                color: Color(0xFF6B7280),
                              ),
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: darkTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedGender = val;
                                  });
                                }
                              },
                              items: _genders.map((g) {
                                return DropdownMenuItem<String>(
                                  value: g,
                                  child: Text(g),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

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
                            hintText: 'Minimal 4 karakter',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
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
                        const SizedBox(height: 24),

                        // Tombol Daftar ->
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _busy ? null : _handleRegister,
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
                                  'Daftar',
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
                        const SizedBox(height: 18),

                        // Divider "atau daftar dengan"
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: borderColor, thickness: 1),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'atau daftar dengan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: borderColor, thickness: 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Tombol Daftar dengan Google
                        GoogleAuthButton(
                          text: 'Daftar dengan Google',
                          busy: _busy,
                          onPressed: _busy ? null : _handleGoogleRegister,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sudah punya akun? Masuk
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      }
                    },
                    child: Text.rich(
                      TextSpan(
                        text: 'Sudah punya akun? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Masuk',
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
