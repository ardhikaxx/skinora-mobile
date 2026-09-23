import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/user_service.dart';

class EditProfilPenggunaPage extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String initialAddress;
  final ValueChanged<int>? onNavigateTab;

  const EditProfilPenggunaPage({
    super.key,
    this.initialName = 'Leonita Yulyta Agustin',
    this.initialPhone = '081234567890',
    this.initialAddress = '',
    this.onNavigateTab,
  });

  @override
  State<EditProfilPenggunaPage> createState() => _EditProfilPenggunaPageState();
}

class _EditProfilPenggunaPageState extends State<EditProfilPenggunaPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color labelColor = Color(0xFF555555);
  static const Color avatarBg = Color(0xFF9E2A3B);
  static const Color borderColor = Color(0xFFE5E5EA);
  static const Color cardBorder = Color(0xFFEEEEEE);

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _addressController = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final updatedName = _nameController.text.trim();
    final updatedPhone = _phoneController.text.trim();
    final updatedAddress = _addressController.text.trim();

    if (Backend.useFirebase && AuthService.uid != null) {
      try {
        await UserService.updateOwnProfile(
          AuthService.uid!,
          fields: {
            if (updatedName.isNotEmpty) 'name': updatedName,
            if (updatedPhone.isNotEmpty) 'phone': updatedPhone,
            'address': updatedAddress,
          },
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan profil: $e')),
        );
        return;
      }
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perubahan profil berhasil disimpan'),
        backgroundColor: primaryMaroon,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context, {
      'name': updatedName.isNotEmpty ? updatedName : widget.initialName,
      'phone': updatedPhone.isNotEmpty ? updatedPhone : widget.initialPhone,
      'address': updatedAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header: Back button + Title "Edit Profil"
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
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Edit Profil',
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
                  // 2. White Card Container matching image copy 2.png
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: cardBorder,
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
                        // Avatar & "Foto profil" label
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  color: avatarBg,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Center(
                                  child: Text(
                                    'LY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Foto profil',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: subText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Field 1: NAMA
                        const Text(
                          'NAMA',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: borderColor,
                              width: 1.0,
                            ),
                          ),
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                              color: darkText,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Nama lengkap Anda',
                              hintStyle: TextStyle(
                                fontSize: 13.5,
                                color: subText,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Field 2: TELEPON
                        const Text(
                          'TELEPON',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: borderColor,
                              width: 1.0,
                            ),
                          ),
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                              color: darkText,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Nomor telepon Anda',
                              hintStyle: TextStyle(
                                fontSize: 13.5,
                                color: subText,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Field 3: ALAMAT (Multiline tall box matching mockup)
                        const Text(
                          'ALAMAT',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: borderColor,
                              width: 1.0,
                            ),
                          ),
                          child: TextField(
                            controller: _addressController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                              color: darkText,
                              height: 1.4,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Alamat domisili Anda',
                              hintStyle: TextStyle(
                                fontSize: 13.5,
                                color: subText,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Button "Simpan Perubahan" matching image copy 2.png
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(
                        LucideIcons.save,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMaroon,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: primaryMaroon.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PenggunaNavBottom(
        currentIndex: 4,
        onTap: (index) {
          Navigator.popUntil(context, (route) => route.isFirst);
          if (index != 4) {
            widget.onNavigateTab?.call(index);
          }
        },
      ),
    );
  }
}
