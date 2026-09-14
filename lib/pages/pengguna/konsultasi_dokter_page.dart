import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';

class DoctorSearchModel {
  final String id;
  final String name;
  final String specialization;
  final String category;
  final bool isVerified;

  const DoctorSearchModel({
    required this.id,
    required this.name,
    required this.specialization,
    required this.category,
    this.isVerified = true,
  });
}

class KonsultasiDokterPenggunaPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const KonsultasiDokterPenggunaPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<KonsultasiDokterPenggunaPage> createState() =>
      _KonsultasiDokterPenggunaPageState();
}

class _KonsultasiDokterPenggunaPageState
    extends State<KonsultasiDokterPenggunaPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color peachAvatarBg = Color(0xFFFFD5C3);
  static const Color verifiedBadgeBg = Color(0xFFFFD5C8);

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Estetika Kulit',
    'Jerawat',
    'Anti-Aging',
  ];

  final List<DoctorSearchModel> _allDoctors = const [
    DoctorSearchModel(
      id: '1',
      name: 'dr. Anita Dewi, Sp.KK',
      specialization: 'Estetika Kulit',
      category: 'Estetika Kulit',
      isVerified: true,
    ),
    DoctorSearchModel(
      id: '2',
      name: 'dr. Andi Pratama, Sp.KK',
      specialization: 'Jerawat',
      category: 'Jerawat',
      isVerified: true,
    ),
    DoctorSearchModel(
      id: '3',
      name: 'dr. Reza Firmansyah, Sp.KK',
      specialization: 'Anti-Aging',
      category: 'Anti-Aging',
      isVerified: true,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DoctorSearchModel> get _filteredDoctors {
    final query = _searchController.text.trim().toLowerCase();
    return _allDoctors.where((doc) {
      final matchesCategory =
          _selectedCategory == 'Semua' || doc.category == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          doc.name.toLowerCase().contains(query) ||
          doc.specialization.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredDoctors;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: "Konsultasi" on the left, "Riwayat >" on the right
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 16.0,
                bottom: 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Konsultasi',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                      letterSpacing: -0.2,
                    ),
                  ),
                  InkWell(
                    onTap: null, // Sesuai instruksi: tidak membuat dialog tanpa halaman
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Riwayat',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: primaryMaroon,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: primaryMaroon,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Subtle divider line
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(bottom: 14.0),
            ),

            // Main Content Area
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 1. Search Box (Centered placeholder per design mockup)
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE5E5EA),
                        width: 1.0,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textAlign: TextAlign.center,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Cari dokter atau spesialisasi...',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF9E9E9E),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 9.0,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryMaroon
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryMaroon
                                      : const Color(0xFFE5E5EA),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF444444),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Doctor Cards List
                  ...filteredList.map((doc) => _buildDoctorCard(doc)),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PenggunaNavBottom(
        currentIndex: 0,
        onTap: (index) {
          Navigator.pop(context);
          if (index != 0) {
            widget.onNavigateTab?.call(index);
          }
        },
      ),
    );
  }

  Widget _buildDoctorCard(DoctorSearchModel doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
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
      child: Row(
        children: [
          // Soft Peach Avatar Container with lowercase "d"
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: peachAvatarBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'd',
                style: TextStyle(
                  color: primaryMaroon,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Doctor Information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Name + Terverifikasi Badge + Right Arrow
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        doctor.name,
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: verifiedBadgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Terverifikasi',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: primaryMaroon,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: Color(0xFF9E9E9E),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Specialization
                Text(
                  doctor.specialization,
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: primaryMaroon,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
