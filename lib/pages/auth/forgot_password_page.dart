import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';

/// Halaman mandiri Lupa Kata Sandi (Reset Password).
/// Mengirimkan tautan pengaturan ulang kata sandi ke email pengguna melalui Firebase Authentication.
class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordPage({
    super.key,
    this.initialEmail = '',
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const Color primaryColor = Color(0xFFB23A48);
  static const Color darkTextColor = Color(0xFF321417);
  static const Color labelTextColor = Color(0xFF555555);
  static const Color borderColor = Color(0xFFE8E8E8);

  late final TextEditingController _emailController;
  final FocusNode _emailFocusNode = FocusNode();
  late String _previousText;

  bool _busy = false;
  bool _isSuccess = false;
  String _sentEmail = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _previousText = widget.initialEmail.trim();
    _emailController = TextEditingController(text: _previousText);
    _emailController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_emailController.text != _previousText) {
      _previousText = _emailController.text;
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_onTextChanged);
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  Future<void> _handleSendResetLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Alamat email wajib diisi.';
      });
      _emailFocusNode.requestFocus();
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Format email tidak valid. Contoh: nama@domain.com';
      });
      _emailFocusNode.requestFocus();
      return;
    }

    if (!Backend.useFirebase) {
      setState(() {
        _errorMessage = 'Backend Firebase belum terkonfigurasi pada aplikasi ini.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      await AuthService.sendPasswordReset(email);

      if (!mounted) return;
      setState(() {
        _busy = false;
        _isSuccess = true;
        _sentEmail = email;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMessage = AuthService.describePasswordResetError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar (Tombol Kembali)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.arrowLeft, color: darkTextColor),
                    tooltip: 'Kembali',
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Kembali ke Masuk',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: darkTextColor,
                    ),
                  ),
                ],
              ),
            ),

            // Konten Tengah
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon Box Utama
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: _isSuccess ? const Color(0xFF16A34A) : primaryColor,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: (_isSuccess ? const Color(0xFF16A34A) : primaryColor)
                                    .withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _isSuccess ? LucideIcons.mailCheck : LucideIcons.keyRound,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Judul Halaman
                        Text(
                          _isSuccess ? 'Email Terkirim!' : 'Lupa Kata Sandi?',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'serif',
                            color: darkTextColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subtitle
                        Text(
                          _isSuccess
                              ? 'Petunjuk pengaturan ulang telah dikirim'
                              : 'Atur ulang kata sandi akun Skinora Anda',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF706D6E),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Card Form / Success Container
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22.0,
                            vertical: 26.0,
                          ),
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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _isSuccess
                                ? _buildSuccessContent()
                                : _buildFormContent(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tautan bawah
                        if (!_isSuccess)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Ingat kata sandi Anda? ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tampilan Form Input Email
  Widget _buildFormContent() {
    return Column(
      key: const ValueKey('form_content'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Penjelasan
        Text(
          'Masukkan alamat email yang terdaftar pada akun Skinora Anda. Kami akan mengirimkan tautan untuk membuat kata sandi baru.',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 20),

        // Banner Error jika ada
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.alertCircle,
                  color: Color(0xFFDC2626),
                  size: 17,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Label Email
        const Text(
          'EMAIL AKUN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: labelTextColor,
          ),
        ),
        const SizedBox(height: 8),

        // Input Field Email
        TextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofocus: widget.initialEmail.isEmpty,
          onSubmitted: (_) => _handleSendResetLink(),
          enabled: !_busy,
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
            suffixIcon: _emailController.text.isNotEmpty && !_busy
                ? IconButton(
                    icon: const Icon(LucideIcons.xCircle, size: 16),
                    color: Colors.grey.shade400,
                    onPressed: () {
                      _emailController.clear();
                      setState(() {});
                    },
                  )
                : null,
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: borderColor, width: 1.0),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Tombol Kirim Email Reset
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _busy ? null : _handleSendResetLink,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Kirim Email Reset',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Tampilan Berhasil Dikirim
  Widget _buildSuccessContent() {
    return Column(
      key: const ValueKey('success_content'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Badge Penerima Email
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.mail,
                size: 16,
                color: Color(0xFF475569),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _sentEmail,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: darkTextColor,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Instruksi Langkah
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    color: Colors.amber.shade900,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Langkah Selanjutnya:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '1. Buka kotak masuk (Inbox) atau folder Spam/Junk pada email Anda.\n'
                '2. Klik tautan reset kata sandi dari Skinora.\n'
                '3. Buat kata sandi baru pada halaman web yang terbuka.\n'
                '4. Masuk kembali ke aplikasi dengan kata sandi baru.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Tombol Kembali ke Login
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Kembali ke Halaman Masuk',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tombol Kirim Ulang jika belum terima
        TextButton(
          onPressed: () {
            setState(() {
              _isSuccess = false;
            });
          },
          child: const Text(
            'Kirim ulang atau ubah email',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
