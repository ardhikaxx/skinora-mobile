import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../components/navbottom/admin_navbottom.dart';
import '../../services/backend.dart';
import '../../services/specialization_service.dart';
import 'edit_spesialisasi_page.dart';
import 'tambah_spesialisasi_page.dart';

class SpesialisasiModel {
  final String id;
  String name;
  bool isActive;

  SpesialisasiModel({
    required this.id,
    required this.name,
    this.isActive = true,
  });
}

class MasterSpesialisasiPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const MasterSpesialisasiPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<MasterSpesialisasiPage> createState() => _MasterSpesialisasiPageState();
}

class _MasterSpesialisasiPageState extends State<MasterSpesialisasiPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);

  // Button background colors
  static const Color editBtnBg = Color(0xFFFFD5C3);
  static const Color toggleBtnBg = Color(0xFFFCA598);
  static const Color activateBtnBg = Color(0xFFFFD5C3);
  static const Color deleteBtnBg = Color(0xFFFFF0ED);
  static const Color activeBadgeBg = Color(0xFFFFD5C8);
  static const Color inactiveBadgeBg = Color(0xFFFFE5E0);

  /// Seed demo HANYA untuk widget test / mode tanpa Firebase.
  /// Dengan Firebase, daftar diisi dari Firestore (boleh kosong).
  final List<SpesialisasiModel> _specializations = Backend.useFirebase
      ? <SpesialisasiModel>[]
      : <SpesialisasiModel>[
          SpesialisasiModel(id: '1', name: 'Jerawat', isActive: true),
          SpesialisasiModel(id: '2', name: 'Estetika Kulit', isActive: true),
          SpesialisasiModel(id: '3', name: 'Alergi', isActive: true),
          SpesialisasiModel(id: '4', name: 'Anti-Aging', isActive: true),
          SpesialisasiModel(id: '5', name: 'Pigmentasi', isActive: true),
          SpesialisasiModel(id: '6', name: 'Dermatitis', isActive: true),
          SpesialisasiModel(id: '7', name: 'Infeksi Kulit', isActive: false),
        ];

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  /// Ambil master spesialisasi dari Firestore. Tanpa Firebase, daftar demo
  /// tetap dipakai agar UI/tes tidak berubah. Dengan Firebase, hasil backend
  /// selalu menggantikan seed — termasuk saat daftar kosong.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    try {
      final records = await SpecializationService.list();
      if (!mounted) return;
      setState(() => _specializations
        ..clear()
        ..addAll(records.map((r) => SpesialisasiModel(
              id: r.id,
              name: r.name,
              isActive: r.isActive,
            ))));
    } catch (_) {
      // Query gagal → tampilkan kosong, jangan seed palsu di production.
      if (!mounted) return;
      setState(_specializations.clear);
    }
  }

  Future<void> _guard(Future<void> Function() action, String failMessage) async {
    if (!Backend.useFirebase) return;
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$failMessage: $e')),
        );
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title with optional back navigation
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 16.0,
                bottom: 8.0,
              ),
              child: Row(
                children: [
                  if (Navigator.canPop(context)) ...[
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(right: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E5EA),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.chevronLeft,
                            size: 18,
                            color: Color(0xFF4A1A24),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Text(
                    'Master Spesialisasi',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Subtle divider line
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            ),

            // Main scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // "+ Tambah Spesialisasi" Button
                  _buildAddButton(),
                  const SizedBox(height: 16),

                  // List of Specialization Cards
                  ..._specializations.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: _buildSpecializationCard(item),
                    );
                  }),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminNavBottom(
        currentIndex: 0,
        onTap: (index) {
          Navigator.pop(context);
          if (index > 0) {
            widget.onNavigateTab?.call(index);
          }
        },
      ),
    );
  }

  /// "+ Tambah Spesialisasi" Button
  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _onAddSpecialization,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMaroon,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          '+ Tambah Spesialisasi',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  /// Specialization Card
  Widget _buildSpecializationCard(SpesialisasiModel item) {
    return Container(
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: item.isActive ? activeBadgeBg : inactiveBadgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.isActive ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    color: item.isActive
                        ? const Color(0xFF9E2A3B)
                        : const Color(0xFFE55757),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Action Buttons (Edit | Nonaktifkan/Aktifkan | Hapus)
          Row(
            children: [
              // Edit Button
              Expanded(
                flex: 3,
                child: _buildActionButton(
                  label: 'Edit',
                  bgColor: editBtnBg,
                  textColor: const Color(0xFF9E2A3B),
                  onTap: () => _onEditSpecialization(item),
                ),
              ),
              const SizedBox(width: 8),

              // Nonaktifkan / Aktifkan Button
              Expanded(
                flex: 4,
                child: _buildActionButton(
                  label: item.isActive ? 'Nonaktifkan' : 'Aktifkan',
                  bgColor: item.isActive ? toggleBtnBg : activateBtnBg,
                  textColor: const Color(0xFF8B2B38),
                  onTap: () => _onToggleSpecialization(item),
                ),
              ),
              const SizedBox(width: 8),

              // Hapus Button
              Expanded(
                flex: 2,
                child: _buildActionButton(
                  label: 'Hapus',
                  bgColor: deleteBtnBg,
                  textColor: const Color(0xFFE55757),
                  onTap: () => _onDeleteSpecialization(item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Actions & Navigation ---

  Future<void> _onAddSpecialization() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => TambahSpesialisasiPage(
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      try {
        await _guard(
          () => SpecializationService.create(result),
          'Gagal menambah spesialisasi',
        );
      } catch (_) {
        return;
      }
      if (!mounted) return;
      setState(() {
        _specializations.add(
          SpesialisasiModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: result,
            isActive: true,
          ),
        );
      });
      AdminSuccessDialog.show(
        context,
        message: 'Spesialisasi baru berhasil ditambahkan',
      );
    }
  }

  Future<void> _onEditSpecialization(SpesialisasiModel item) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => EditSpesialisasiPage(
          initialName: item.name,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      try {
        await _guard(
          () => SpecializationService.rename(item.id, result),
          'Gagal memperbarui spesialisasi',
        );
      } catch (_) {
        return;
      }
      if (!mounted) return;
      setState(() {
        item.name = result;
      });
      AdminSuccessDialog.show(
        context,
        message: 'Spesialisasi berhasil diperbarui',
      );
    }
  }

  void _onToggleSpecialization(SpesialisasiModel item) {
    if (item.isActive) {
      AdminConfirmDialog.show(
        context,
        title: 'Nonaktifkan Spesialisasi',
        message: 'Nonaktifkan "${item.name}"?',
        confirmLabel: 'Nonaktifkan',
        confirmColor: const Color(0xFFEF4444),
        onConfirm: () async {
          try {
            await _guard(
              () => SpecializationService.setActive(item.id, false),
              'Gagal mengubah status spesialisasi',
            );
          } catch (_) {
            return;
          }
          if (!mounted) return;
          setState(() {
            item.isActive = false;
          });
          AdminSuccessDialog.show(
            context,
            message: 'Status spesialisasi diubah ke inactive',
          );
        },
      );
    } else {
      AdminConfirmDialog.show(
        context,
        title: 'Aktifkan Spesialisasi',
        message: 'Aktifkan "${item.name}"?',
        confirmLabel: 'Aktifkan',
        confirmColor: primaryMaroon,
        onConfirm: () async {
          try {
            await _guard(
              () => SpecializationService.setActive(item.id, true),
              'Gagal mengubah status spesialisasi',
            );
          } catch (_) {
            return;
          }
          if (!mounted) return;
          setState(() {
            item.isActive = true;
          });
          AdminSuccessDialog.show(
            context,
            message: 'Status spesialisasi diubah ke active',
          );
        },
      );
    }
  }

  void _onDeleteSpecialization(SpesialisasiModel item) {
    AdminConfirmDialog.show(
      context,
      title: 'Hapus Spesialisasi',
      message: 'Hapus "${item.name}" secara permanen?',
      confirmLabel: 'Hapus',
      confirmColor: const Color(0xFFEF4444),
      onConfirm: () async {
        try {
          await _guard(
            () => SpecializationService.delete(item.id),
            'Gagal menghapus spesialisasi',
          );
        } catch (_) {
          return;
        }
        if (!mounted) return;
        final name = item.name;
        setState(() {
          _specializations.removeWhere((el) => el.id == item.id);
        });
        AdminSuccessDialog.show(
          context,
          message: 'Spesialisasi "$name" berhasil dihapus',
        );
      },
    );
  }
}
