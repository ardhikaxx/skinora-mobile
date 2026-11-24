import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_dates.dart';

/// Modal dialog template untuk melengkapi data diri pasien / pengguna.
/// Wajib dilengkapi (nama, telepon, tanggal lahir, jenis kelamin, alamat)
/// sebelum pengguna dapat masuk dan menggunakan layanan Skinora.
class LengkapiDataDiriDialog extends StatefulWidget {
  final UserProfile profile;
  final bool allowCancel;

  const LengkapiDataDiriDialog({
    super.key,
    required this.profile,
    this.allowCancel = true,
  });

  /// Menampilkan modal dialog pengisian data diri pasien.
  /// Mengembalikan [UserProfile] yang telah diperbarui bila sukses disimpan,
  /// atau `null` jika pengguna membatalkan (dan melakukan sign out).
  static Future<UserProfile?> show(
    BuildContext context, {
    required UserProfile profile,
    bool allowCancel = true,
  }) {
    return showDialog<UserProfile?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => LengkapiDataDiriDialog(
        profile: profile,
        allowCancel: allowCancel,
      ),
    );
  }

  @override
  State<LengkapiDataDiriDialog> createState() => _LengkapiDataDiriDialogState();
}

class _LengkapiDataDiriDialogState extends State<LengkapiDataDiriDialog> {
  static const Color primaryMaroon = Color(0xFFB23A48);
  static const Color darkTextColor = Color(0xFF321417);
  static const Color labelTextColor = Color(0xFF555555);
  static const Color borderColor = Color(0xFFE8E8E8);

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _addressController;

  late String _selectedGender;
  static const List<String> _genderOptions = ['Perempuan', 'Laki-laki'];

  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _birthDateController = TextEditingController(text: widget.profile.birthDate);
    _addressController = TextEditingController(text: widget.profile.address);

    final g = widget.profile.gender.trim();
    if (_genderOptions.contains(g)) {
      _selectedGender = g;
    } else {
      _selectedGender = _genderOptions.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
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
            primary: primaryMaroon,
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
      setState(() {
        _birthDateController.text = isoStr;
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final birthDate = _birthDateController.text.trim();
    final gender = _selectedGender;
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Nama lengkap wajib diisi.');
      return;
    }

    if (phone.isEmpty || phone.length < 8) {
      setState(
          () => _errorMessage = 'Nomor telepon tidak valid (minimal 8 digit).');
      return;
    }

    if (birthDate.isEmpty) {
      setState(() => _errorMessage = 'Tanggal lahir wajib dipilih.');
      return;
    }

    final age = AppDates.calculateAge(birthDate);
    if (age <= 0) {
      setState(
          () => _errorMessage = 'Tanggal lahir tidak valid untuk pasien.');
      return;
    }

    if (address.isEmpty || address.length < 4) {
      setState(
          () => _errorMessage = 'Alamat domisili wajib diisi dengan lengkap.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final uid = widget.profile.uid.isNotEmpty
          ? widget.profile.uid
          : (AuthService.uid ?? '');

      await UserService.updateOwnProfile(
        uid,
        fields: {
          'name': name,
          'phone': phone,
          'birthDate': birthDate,
          'gender': gender,
          'address': address,
        },
      );

      final updated = widget.profile.copyWith(
        name: name,
        phone: phone,
        birthDate: birthDate,
        gender: gender,
        address: address,
      );

      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = 'Gagal menyimpan data: $e';
      });
    }
  }

  Future<void> _handleCancel() async {
    if (_saving) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Kelengkapan Data?'),
        content: const Text(
          'Data profil pasien belum lengkap. Jika dibatalkan, Anda akan keluar dari akun dan belum dapat menggunakan aplikasi.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tetap di Sini'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Batalkan & Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.of(context).pop(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = AppDates.calculateAge(_birthDateController.text.trim());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (widget.allowCancel) {
            _handleCancel();
          }
        }
      },
      child: Dialog(
        backgroundColor: Colors.white,
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22.0),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD5C8),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.userCheck,
                          color: primaryMaroon,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lengkapi Data Diri',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkTextColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Lengkapi data profil pasien agar dapat mengakses konsultasi dan analisis kulit.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.allowCancel)
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        color: Colors.grey.shade400,
                        onPressed: _saving ? null : _handleCancel,
                        tooltip: 'Batal',
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: borderColor),

              // Form fields scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.alertCircle,
                                color: Color(0xFFDC2626),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF991B1B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // NAMA LENGKAP
                      const Text(
                        'NAMA LENGKAP',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: labelTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _buildInputDecoration(
                          hint: 'Nama Lengkap Anda',
                          prefixIcon: LucideIcons.user,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // EMAIL (Read Only)
                      const Text(
                        'EMAIL (TERVERIFIKASI)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: labelTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: _buildInputDecoration(
                          hint: 'Email',
                          prefixIcon: LucideIcons.mail,
                          filledColor: const Color(0xFFF5F5F5),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // NOMOR TELEPON
                      const Text(
                        'NOMOR TELEPON / WA',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: labelTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration(
                          hint: '081234567890',
                          prefixIcon: LucideIcons.phone,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // TANGGAL LAHIR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TANGGAL LAHIR',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: labelTextColor,
                            ),
                          ),
                          if (age > 0)
                            Text(
                              'Usia: $age tahun',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: primaryMaroon,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _saving ? null : _pickBirthDate,
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _birthDateController,
                            decoration: _buildInputDecoration(
                              hint: 'Pilih Tanggal Lahir (YYYY-MM-DD)',
                              prefixIcon: LucideIcons.calendar,
                              suffixIcon: const Icon(
                                LucideIcons.calendarDays,
                                color: primaryMaroon,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // JENIS KELAMIN
                      const Text(
                        'JENIS KELAMIN',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: labelTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: 1.2),
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
                            onChanged: _saving
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setState(() => _selectedGender = val);
                                    }
                                  },
                            items: _genderOptions.map((g) {
                              return DropdownMenuItem<String>(
                                value: g,
                                child: Text(g),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ALAMAT DOMISILI
                      const Text(
                        'ALAMAT LENGKAP',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: labelTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Jl. Melati No. 123, Kelurahan, Kota...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13.5,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: borderColor,
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: primaryMaroon,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer Button
              const Divider(height: 1, thickness: 1, color: borderColor),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryMaroon,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: primaryMaroon.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Simpan & Lanjutkan',
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
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    Color filledColor = Colors.white,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 13.5,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: Colors.grey.shade500,
              size: 16,
            )
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: filledColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryMaroon, width: 1.5),
      ),
    );
  }
}
