import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/specialization_service.dart';
import 'login_page.dart';

class RegisterDokterPage extends StatefulWidget {
  const RegisterDokterPage({super.key});

  @override
  State<RegisterDokterPage> createState() => _RegisterDokterPageState();
}

class _RegisterDokterPageState extends State<RegisterDokterPage> {
  static const Color primaryColor = Color(0xFFB23A48);
  static const Color darkTextColor = Color(0xFF321417);
  static const Color labelTextColor = Color(0xFF555555);
  static const Color borderColor = Color(0xFFE8E8E8);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _strController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedSpecialization;
  List<String> _specializations = const [
    'Dermatologi & Venereologi',
    'Estetika & Anti-Aging',
    'Dermatologi Anak',
    'Dermatologi Bedah',
    'Alergi & Imunologi Kulit',
  ];

  bool _obscurePassword = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selectedSpecialization = _specializations.first;
    _loadSpecializations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strController.dispose();
    _experienceController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecializations() async {
    if (!Backend.useFirebase) return;
    try {
      final names = await SpecializationService.listActiveNames();
      if (!mounted) return;
      if (names.isNotEmpty) {
        setState(() {
          _specializations = names;
          if (!_specializations.contains(_selectedSpecialization)) {
            _selectedSpecialization = _specializations.first;
          }
        });
      }
    } catch (_) {
      // Abaikan bila offline / belum ada master spesialisasi di Firestore
    }
  }

  Future<void> _handleRegisterDoctor() async {
    final name = _nameController.text.trim();
    final specialization = _selectedSpecialization ?? '';
    final str = _strController.text.trim();
    final experience = _experienceController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final bio = _bioController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      _showWarning('Silahkan masukkan nama lengkap dan gelar dokter.');
      return;
    }
    if (specialization.isEmpty) {
      _showWarning('Silahkan pilih spesialisasi kedokteran.');
      return;
    }
    if (str.isEmpty) {
      _showWarning('Silahkan masukkan nomor Surat Tanda Registrasi (STR).');
      return;
    }
    if (experience.isEmpty) {
      _showWarning('Silahkan masukkan lama pengalaman praktik Anda.');
      return;
    }
    if (phone.isEmpty) {
      _showWarning('Silahkan masukkan nomor telepon / WhatsApp aktif.');
      return;
    }
    if (phone.length < 8) {
      _showWarning('Nomor telepon minimal 8 digit.');
      return;
    }
    if (address.isEmpty) {
      _showWarning('Silahkan masukkan alamat atau tempat praktik Anda.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showWarning('Silahkan masukkan format email yang valid.');
      return;
    }
    if (password.length < 6) {
      _showWarning('Password minimal 6 karakter.');
      return;
    }

    if (!Backend.useFirebase) {
      _showWarning('Backend Firebase belum terkonfigurasi.');
      return;
    }

    setState(() => _busy = true);
    try {
      final cred = await AuthService.registerDoctor(
        name: name,
        email: email,
        phone: phone,
        password: password,
        specialization: specialization,
        str: str,
        experience: experience,
        address: address,
        bio: bio,
      );

      final uid = cred.user?.uid ?? '';
      await ActivityService.log(
        title: 'Pendaftaran dokter baru: $name',
        tag: 'Dokter',
        actor: name,
        actorUid: uid,
      ).catchError((_) {});

      // Sign out agar tidak langsung membuka dashboard sebelum terverifikasi
      await AuthService.signOut();

      if (!mounted) return;
      setState(() => _busy = false);

      AdminSuccessDialog.show(
        context,
        message:
            'Pendaftaran akun dokter berhasil dikirim!\n\nStatus akun Anda saat ini "Menunggu Verifikasi". Tim Admin Skinora akan meninjau data dan STR Anda. Anda baru dapat masuk (login) ke aplikasi setelah akun Anda diverifikasi oleh admin.',
        onOk: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      final msg = AuthService.describeAuthError(e);
      _showWarning(msg);
    }
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: labelTextColor,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 13.5,
      ),
      prefixIcon: Center(
        widthFactor: 2.0,
        child: Icon(prefixIcon, color: Colors.grey.shade500, size: 16),
      ),
      suffixIcon: suffixIcon,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.arrowLeft, color: darkTextColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(height: 16),

              // Title Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.stethoscope,
                        color: primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Pendaftaran Dokter',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darkTextColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bergabung bersama tim medis Skinora untuk memberikan konsultasi kulit terpercaya.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF706D6E),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Info Banner: Verifikasi STR & Medis
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.shieldCheck,
                      color: Color(0xFF16A34A),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Verifikasi Medis Skinora',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Akun dokter baru akan berstatus "Menunggu Verifikasi". Admin Skinora akan meninjau STR Anda sebelum praktik konsultasi aktif.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF166534),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NAMA LENGKAP & GELAR
                    _buildFieldLabel('NAMA LENGKAP & GELAR *'),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        hintText: 'dr. Sarah Wijaya, Sp.D.V.E.',
                        prefixIcon: LucideIcons.user,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SPESIALISASI
                    _buildFieldLabel('SPESIALISASI *'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSpecialization,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        hintText: 'Pilih Spesialisasi',
                        prefixIcon: LucideIcons.stethoscope,
                      ),
                      icon: const Icon(LucideIcons.chevronDown, size: 16),
                      items: _specializations.map((spec) {
                        return DropdownMenuItem<String>(
                          value: spec,
                          child: Text(
                            spec,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: darkTextColor,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSpecialization = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // NOMOR STR
                    _buildFieldLabel('NOMOR STR (SURAT TANDA REGISTRASI) *'),
                    TextField(
                      controller: _strController,
                      decoration: _inputDecoration(
                        hintText: 'Contoh: 31.1.1.100.1.20.123456',
                        prefixIcon: LucideIcons.fileBadge,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PENGALAMAN PRAKTIK
                    _buildFieldLabel('PENGALAMAN PRAKTIK *'),
                    TextField(
                      controller: _experienceController,
                      decoration: _inputDecoration(
                        hintText: 'Contoh: 5 Tahun',
                        prefixIcon: LucideIcons.briefcase,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TELEPON
                    _buildFieldLabel('NOMOR TELEPON / WHATSAPP *'),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        hintText: '081234567890',
                        prefixIcon: LucideIcons.phone,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ALAMAT / TEMPAT PRAKTIK
                    _buildFieldLabel('ALAMAT / TEMPAT PRAKTIK *'),
                    TextField(
                      controller: _addressController,
                      decoration: _inputDecoration(
                        hintText: 'RS Hermina / Klinik Skinora Jakarta',
                        prefixIcon: LucideIcons.mapPin,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // BIO SINGKAT (OPSIONAL)
                    _buildFieldLabel('BIO SINGKAT (OPSIONAL)'),
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Ceritakan fokus klinis atau pengalaman spesifik Anda...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13.5,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: borderColor, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // EMAIL
                    _buildFieldLabel('EMAIL *'),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        hintText: 'dokter@skinora.com',
                        prefixIcon: LucideIcons.mail,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PASSWORD
                    _buildFieldLabel('PASSWORD *'),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        hintText: 'Minimal 6 karakter',
                        prefixIcon: LucideIcons.lock,
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
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _handleRegisterDoctor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: primaryColor.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Daftar Sebagai Dokter',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(LucideIcons.arrowRight, size: 16),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Footer: Kembali ke Login
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text.rich(
                    TextSpan(
                      text: 'Sudah punya akun dokter? ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Masuk di sini',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
