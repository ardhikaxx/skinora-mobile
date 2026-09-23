import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/user_service.dart';

class DoctorProfileStore {
  static final DoctorProfileStore _instance = DoctorProfileStore._internal();
  factory DoctorProfileStore() => _instance;
  DoctorProfileStore._internal();

  // Seed demo HANYA untuk widget test / mode tanpa Firebase.
  // Dengan Firebase, field default kosong — diisi dari Firestore.
  String name = Backend.useFirebase ? '' : 'dr. Anita Dewi, Sp.KK';
  String email = Backend.useFirebase ? '' : 'anita@demo.com';
  String phone = Backend.useFirebase ? '' : '081234567800';
  String address = Backend.useFirebase ? '' : 'Jl. Melati No. 10, Jakarta';
  String specialization = Backend.useFirebase ? '' : 'Estetika Kulit';
  String experience = Backend.useFirebase ? '' : '8 tahun';
  String str = Backend.useFirebase ? '' : 'STR-2018-12345';
  String status = Backend.useFirebase ? '' : 'terverifikasi';
  String bio = Backend.useFirebase
      ? ''
      : 'Dokter spesialis kulit dan kelamin berpengalaman dalam perawatan estetika dan peremajaan kulit.';

  void clear() {
    name = '';
    email = '';
    phone = '';
    address = '';
    specialization = '';
    experience = '';
    str = '';
    status = '';
    bio = '';
  }

  String get initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length >= 2) {
      final firstChar = parts[0].replaceAll(RegExp(r'[^a-zA-Z]'), '');
      final secondChar = parts[1].replaceAll(RegExp(r'[^a-zA-Z]'), '');
      if (firstChar.isNotEmpty && secondChar.isNotEmpty) {
        return (firstChar[0] + secondChar[0]).toUpperCase();
      }
    }
    final firstChar = parts[0].replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (firstChar.isNotEmpty) {
      return firstChar[0].toUpperCase();
    }
    return Backend.useFirebase ? '' : 'DA';
  }
}

class EditProfilDokterPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const EditProfilDokterPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = true,
  });

  @override
  State<EditProfilDokterPage> createState() => _EditProfilDokterPageState();
}

class _EditProfilDokterPageState extends State<EditProfilDokterPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E1E1E);
  static const Color labelColor = Color(0xFF6B7280);

  late TextEditingController _nameController;
  late TextEditingController _specializationController;
  late TextEditingController _experienceController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;

  String _currentInitials = Backend.useFirebase ? '' : 'DA';
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    final store = DoctorProfileStore();
    _nameController = TextEditingController(text: store.name);
    _specializationController =
        TextEditingController(text: store.specialization);
    _experienceController = TextEditingController(text: store.experience);
    _phoneController = TextEditingController(text: store.phone);
    _addressController = TextEditingController(text: store.address);
    _bioController = TextEditingController(text: store.bio);

    _currentInitials = store.initials;
    _nameController.addListener(_updateInitials);
    _loadFromBackend();
  }

  void _applyStoreToControllers() {
    final store = DoctorProfileStore();
    _nameController.text = store.name;
    _specializationController.text = store.specialization;
    _experienceController.text = store.experience;
    _phoneController.text = store.phone;
    _addressController.text = store.address;
    _bioController.text = store.bio;
    _currentInitials = store.initials;
  }

  /// Isi form dari Firestore bila sesi aktif. Tanpa Firebase, seed demo
  /// tetap dipakai agar UI/tes tidak berubah. Dengan Firebase, hasil backend
  /// selalu diterapkan — dan kegagalan mengosongkan form (bukan seed).
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) {
      // Tanpa sesi → jangan biarkan seed tertulis ke Firestore.
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        DoctorProfileStore().clear();
        _applyStoreToControllers();
      });
      return;
    }
    try {
      final profile = await UserService.loadByUid(uid);
      if (!mounted) return;
      final store = DoctorProfileStore();
      if (profile == null) {
        _loadFailed = true;
        store.clear();
      } else {
        _loadFailed = false;
        // Selalu terapkan field dari profile (bukan hanya isNotEmpty).
        store.name = profile.name;
        store.email = profile.email;
        store.specialization = profile.specialization;
        store.experience = profile.experience;
        store.phone = profile.phone;
        store.address = profile.address;
        store.bio = profile.bio;
        store.str = profile.str;
        store.status = profile.status;
      }
      setState(_applyStoreToControllers);
    } catch (_) {
      // Query gagal → kosongkan, jangan biarkan seed.
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        DoctorProfileStore().clear();
        _applyStoreToControllers();
      });
    }
  }

  void _updateInitials() {
    final tempName = _nameController.text.trim();
    final parts = tempName.split(' ').where((p) => p.isNotEmpty).toList();
    String newInitials = Backend.useFirebase ? '' : 'DA';
    if (parts.length >= 2) {
      final first = parts[0].replaceAll(RegExp(r'[^a-zA-Z]'), '');
      final second = parts[1].replaceAll(RegExp(r'[^a-zA-Z]'), '');
      if (first.isNotEmpty && second.isNotEmpty) {
        newInitials = (first[0] + second[0]).toUpperCase();
      }
    } else if (parts.isNotEmpty) {
      final first = parts[0].replaceAll(RegExp(r'[^a-zA-Z]'), '');
      if (first.isNotEmpty) {
        newInitials = first[0].toUpperCase();
      }
    }
    if (newInitials != _currentInitials) {
      setState(() {
        _currentInitials = newInitials;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateInitials);
    _nameController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama tidak boleh kosong'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Dengan Firebase, data awal gagal dimuat → jangan menulis apa pun
    // (mencegah seed/sampah masuk ke Firestore).
    if (Backend.useFirebase && _loadFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil belum dimuat, periksa koneksi lalu coba lagi'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final store = DoctorProfileStore();
    store.name = name;
    store.specialization = _specializationController.text.trim();
    store.experience = _experienceController.text.trim();
    store.phone = _phoneController.text.trim();
    store.address = _addressController.text.trim();
    store.bio = _bioController.text.trim();

    if (Backend.useFirebase) {
      final uid = AuthService.uid;
      if (uid != null) {
        try {
          await UserService.updateOwnProfile(
            uid,
            fields: {
              'name': store.name,
              'specialization': store.specialization,
              'experience': store.experience,
              'phone': store.phone,
              'address': store.address,
              'bio': store.bio,
              'str': store.str,
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
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
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
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Edit Profil',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
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
            ),

            // Scrollable Form
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 20.0,
                ),
                children: [
                  // Center Avatar with Initials (e.g. "DA")
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: primaryMaroon,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: primaryMaroon.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _currentInitials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // NAMA
                  _buildFieldLabel('NAMA'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Nama lengkap dokter...',
                  ),
                  const SizedBox(height: 16),

                  // SPESIALISASI
                  _buildFieldLabel('SPESIALISASI'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _specializationController,
                    hintText: 'Spesialisasi...',
                  ),
                  const SizedBox(height: 16),

                  // PENGALAMAN
                  _buildFieldLabel('PENGALAMAN'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _experienceController,
                    hintText: 'Pengalaman (contoh: 8 tahun)...',
                  ),
                  const SizedBox(height: 16),

                  // TELEPON
                  _buildFieldLabel('TELEPON'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _phoneController,
                    hintText: 'Nomor telepon...',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // ALAMAT
                  _buildFieldLabel('ALAMAT'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _addressController,
                    hintText: 'Alamat lengkap...',
                    minLines: 2,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // BIO
                  _buildFieldLabel('BIO'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _bioController,
                    hintText: 'Bio singkat...',
                    minLines: 3,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  // Button "Simpan Perubahan"
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _handleSave,
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
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMaroon,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? DokterNavBottom(
              currentIndex: 4,
              onTap: (index) {
                Navigator.pop(context);
                if (index != 4) {
                  widget.onNavigateTab?.call(index);
                }
              },
            )
          : null,
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11.0,
        fontWeight: FontWeight.w700,
        color: labelColor,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int minLines = 1,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: darkText,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 13.5,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryMaroon,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
