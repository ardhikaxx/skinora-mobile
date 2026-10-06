import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../components/empty_state.dart';
import '../../components/navbottom/admin_navbottom.dart';
import '../../models/admin_doctor_model.dart';
import '../../services/backend.dart';
import '../../services/user_service.dart';
import 'detail_dokter_page.dart';
import 'tambah_dokter_page.dart';

class ManajemenDokterPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const ManajemenDokterPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = false,
    this.initialDoctors,
  });

  final List<AdminDoctorModel>? initialDoctors;

  @override
  State<ManajemenDokterPage> createState() => _ManajemenDokterPageState();
}

class _ManajemenDokterPageState extends State<ManajemenDokterPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E293B);
  static const Color subText = Color(0xFF6B7280);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Pending',
    'Terverifikasi',
    'Ditolak',
    'Ditangguhkan',
  ];

  late final List<AdminDoctorModel> _doctors;

  StreamSubscription<List<AdminDoctorModel>>? _doctorSub;

  @override
  void initState() {
    super.initState();
    _doctors = widget.initialDoctors != null
        ? List.from(widget.initialDoctors!)
        : <AdminDoctorModel>[];
    _loadFromBackend();
  }

  /// Ambil data dokter dari Firestore secara realtime.
  void _loadFromBackend() {
    if (widget.initialDoctors != null) return;
    if (!Backend.useFirebase) return;
    _doctorSub?.cancel();
    _doctorSub = UserService.streamDokter().listen(
      (doctors) {
        if (!mounted) return;
        setState(() => _doctors
          ..clear()
          ..addAll(doctors));
      },
      onError: (_) {
        if (!mounted) return;
        setState(_doctors.clear);
      },
    );
  }

  @override
  void dispose() {
    _doctorSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<AdminDoctorModel> get _filteredDoctors {
    return _doctors.where((doctor) {
      // Filter by category chip
      final matchesFilter = switch (_selectedFilter) {
        'Semua' => true,
        'Pending' => doctor.status == DoctorStatus.menunggu,
        'Terverifikasi' => doctor.status == DoctorStatus.terverifikasi,
        'Ditolak' => doctor.status == DoctorStatus.ditolak,
        'Ditangguhkan' => doctor.status == DoctorStatus.ditangguhkan,
        _ => true,
      };

      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty ||
          doctor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doctor.specialization
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();
  }

  Widget _buildDoctorsEmptyState() {
    if (_doctors.isEmpty) {
      return EmptyStateWidget(
        icon: LucideIcons.stethoscope,
        title: 'Belum ada data dokter',
        description:
            'Dokter spesialis kulit yang didaftarkan akan muncul di sini.',
        actionLabel: 'Tambah Dokter',
        onAction: _navigateToAddDoctor,
      );
    }
    if (_searchQuery.isNotEmpty) {
      return NoSearchResultWidget(
        title: 'Dokter tidak ditemukan',
        description:
            'Tidak ada dokter yang cocok dengan "$_searchQuery". Coba ubah kata kunci.',
        onAction: () => setState(() {
          _searchController.clear();
          _searchQuery = '';
        }),
      );
    }
    return EmptyStateWidget(
      icon: LucideIcons.filter,
      title: 'Tidak ada dokter pada filter ini',
      description: 'Belum ada dokter dengan status "$_selectedFilter".',
      actionLabel: 'Tampilkan Semua',
      onAction: () => setState(() => _selectedFilter = 'Semua'),
    );
  }

  Future<void> _navigateToAddDoctor() async {
    final result = await Navigator.push<AdminDoctorModel>(
      context,
      MaterialPageRoute(
        builder: (context) => TambahDokterPage(
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _doctors.insert(0, result);
      });
      AdminSuccessDialog.show(
        context,
        message: 'Dokter baru berhasil ditambahkan',
      );
    }
  }

  Future<void> _navigateToDoctorDetail(AdminDoctorModel doctor) async {
    final result = await Navigator.push<AdminDoctorModel>(
      context,
      MaterialPageRoute(
        builder: (context) => DetailDokterPage(
          doctor: doctor,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        final index = _doctors.indexWhere((d) => d.id == result.id);
        if (index != -1) {
          _doctors[index] = result;
        }
      });
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
            // Header: Title
            const Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: 12.0,
              ),
              child: Text(
                'Manajemen Dokter',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            // Search Bar + "+ Baru" Button Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  // Search Field
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.1,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        style: const TextStyle(
                          fontSize: 14,
                          color: darkText,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Cari dokter...',
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF9CA3AF),
                          ),
                          prefixIcon: Icon(
                            LucideIcons.search,
                            size: 18,
                            color: Color(0xFF9CA3AF),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // "+ Baru" Button
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _navigateToAddDoctor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMaroon,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.plus, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Baru',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Horizontal Filter Chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryMaroon : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? primaryMaroon
                              : const Color(0xFFE5E7EB),
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Doctors List
            Expanded(
              child: _filteredDoctors.isEmpty
                  ? _buildDoctorsEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: _filteredDoctors.length,
                      itemBuilder: (context, index) {
                        final doctor = _filteredDoctors[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildDoctorCard(doctor),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? AdminNavBottom(
              currentIndex: 1,
              onTap: (index) {
                if (index != 1) {
                  widget.onNavigateTab?.call(index);
                }
              },
            )
          : null,
    );
  }

  /// Individual doctor list card matching Screen 1
  Widget _buildDoctorCard(AdminDoctorModel doctor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDoctorDetail(doctor),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Avatar circle 'd'
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: primaryMaroon,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'd',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Doctor Name and Specialization
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        doctor.specialization,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: subText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Status Badge
                _buildStatusBadge(doctor.status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DoctorStatus status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case DoctorStatus.terverifikasi:
        bgColor = const Color(0xFFFFD5C8);
        textColor = const Color(0xFF9E2A3B);
        break;
      case DoctorStatus.menunggu:
        bgColor = const Color(0xFFFFE5E0);
        textColor = const Color(0xFFD97706);
        break;
      case DoctorStatus.ditolak:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFEF4444);
        break;
      case DoctorStatus.ditangguhkan:
        bgColor = const Color(0xFFFFEDD5);
        textColor = const Color(0xFFC2410C);
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF4B5563);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
