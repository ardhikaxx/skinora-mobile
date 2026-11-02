import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/admin_account_model.dart';
import '../../models/admin_user_model.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/user_service.dart';

class TambahAdminPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const TambahAdminPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<TambahAdminPage> createState() => _TambahAdminPageState();
}

class _TambahAdminPageState extends State<TambahAdminPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E293B);
  static const Color subText = Color(0xFF6B7280);

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthDateController = TextEditingController();

  String _selectedGender = 'Perempuan';
  final List<String> _genders = ['Perempuan', 'Laki-laki'];

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primaryMaroon,
            onPrimary: Colors.white,
            onSurface: darkText,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _birthDateController.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama lengkap wajib diisi'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email valid wajib diisi'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    var newAdmin = AdminAccountModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      birthDate: _birthDateController.text.trim(),
      gender: _selectedGender,
      status: UserStatus.aktif,
    );

    // Tulis ke Firestore (pre-provision atau upgrade akun pengguna yang sudah ada)
    if (Backend.useFirebase) {
      try {
        newAdmin = await UserService.createAdmin(newAdmin);
        await ActivityService.log(
          title: 'Menambah admin baru $name',
          tag: 'Admin',
          actor: 'Admin',
          actorUid: AuthService.uid ?? 'admin',
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambah admin: $e')),
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context, newAdmin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Header: Chevron Left + Title
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 20.0,
                top: 16.0,
                bottom: 12.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      size: 22,
                      color: darkText,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tambah Admin Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                ],
              ),
            ),

            // Form Fields
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFEDD5),
                          width: 1.0,
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.shieldAlert,
                            size: 18,
                            color: Color(0xFFC2410C),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Admin baru akan memiliki hak akses penuh ke seluruh menu manajemen platform. Pastikan email yang dimasukkan adalah email resmi yang valid.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9A3412),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Nama Lengkap
                    _buildLabel('Nama Lengkap *'),
                    _buildTextField(
                      controller: _nameController,
                      hintText: 'Contoh: dr. Sarah Wijaya / Ahmad Admin',
                      icon: LucideIcons.user,
                    ),

                    const SizedBox(height: 16),

                    // Email
                    _buildLabel('Email Admin *'),
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'contoh@skinora.id',
                      icon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // Nomor Telepon
                    _buildLabel('Nomor Telepon'),
                    _buildTextField(
                      controller: _phoneController,
                      hintText: '08123456789',
                      icon: LucideIcons.phone,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 16),

                    // Jenis Kelamin
                    _buildLabel('Jenis Kelamin'),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGender,
                          isExpanded: true,
                          icon: const Icon(
                            LucideIcons.chevronDown,
                            size: 18,
                            color: subText,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: darkText,
                          ),
                          items: _genders.map((g) {
                            return DropdownMenuItem<String>(
                              value: g,
                              child: Text(g),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedGender = val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tanggal Lahir
                    _buildLabel('Tanggal Lahir'),
                    InkWell(
                      onTap: _pickBirthDate,
                      child: IgnorePointer(
                        child: _buildTextField(
                          controller: _birthDateController,
                          hintText: 'Pilih tanggal lahir (YYYY-MM-DD)',
                          icon: LucideIcons.calendar,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Alamat
                    _buildLabel('Alamat'),
                    _buildTextField(
                      controller: _addressController,
                      hintText: 'Alamat lengkap admin',
                      icon: LucideIcons.mapPin,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 28),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryMaroon,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor:
                              primaryMaroon.withValues(alpha: 0.6),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Simpan Admin',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 14,
          color: darkText,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF9CA3AF),
          ),
          prefixIcon: Icon(
            icon,
            size: 18,
            color: const Color(0xFF9CA3AF),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
