import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import 'patient_insight_page.dart';

class DetailPatientInsightPage extends StatefulWidget {
  final PatientInsightModel? patient;
  final ValueChanged<int>? onNavigateTab;

  const DetailPatientInsightPage({
    super.key,
    this.patient,
    this.onNavigateTab,
  });

  @override
  State<DetailPatientInsightPage> createState() =>
      _DetailPatientInsightPageState();
}

class _DetailPatientInsightPageState extends State<DetailPatientInsightPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF757575);
  static const Color cardBorder = Color(0xFFEEEEEE);

  late PatientInsightModel _currentPatient;

  final List<PatientInsightModel> _allPatients = [
    PatientInsightModel(
      id: '1',
      name: 'Annida Tri Aulia',
      consultationCount: '3 konsultasi',
      skinType: 'Berminyak & Acne-prone',
      primaryConcern: 'Jerawat aktif & bekas noda jerawat',
      lastConsultation: '27 Agu 2026',
    ),
    PatientInsightModel(
      id: '2',
      name: 'Leonita Yulyta Agustin',
      consultationCount: '3 konsultasi',
      skinType: 'Kombinasi',
      primaryConcern: 'Skin barrier rusak & kemerahan',
      lastConsultation: '26 Agu 2026',
    ),
    PatientInsightModel(
      id: '3',
      name: 'Kafi Khaula Yukisa Zailina',
      consultationCount: '2 konsultasi',
      skinType: 'Kering & Sensitif',
      primaryConcern: 'Kulit bersisik & dehidrasi',
      lastConsultation: '22 Agu 2026',
    ),
    PatientInsightModel(
      id: '4',
      name: 'Siti Aisa Nur Apriliana',
      consultationCount: '2 konsultasi',
      skinType: 'Normal ke Kering',
      primaryConcern: 'Hiperpigmentasi & flek hitam',
      lastConsultation: '19 Agu 2026',
    ),
    PatientInsightModel(
      id: '5',
      name: 'Nur Alisa Qiroati Sholeha',
      consultationCount: '3 konsultasi',
      skinType: 'Berminyak',
      primaryConcern: 'Pori-pori besar & komedo',
      lastConsultation: '15 Agu 2026',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.patient ??
        _allPatients.firstWhere(
          (p) => p.name == 'Leonita Yulyta Agustin',
          orElse: () => _allPatients[1],
        );
  }

  void _showGantiPasienModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Pasien',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _allPatients.length,
                    itemBuilder: (context, index) {
                      final p = _allPatients[index];
                      final isSelected = p.name == _currentPatient.name;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryMaroon
                                : const Color(0xFFFFD5C8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.user,
                              color: isSelected ? Colors.white : primaryMaroon,
                              size: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected ? primaryMaroon : darkText,
                          ),
                        ),
                        subtitle: Text(
                          p.consultationCount,
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: subText,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check,
                                color: primaryMaroon,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _currentPatient = p;
                          });
                          Navigator.pop(modalContext);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Back button + Title "Patient Insight"
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
                  const SizedBox(width: 8),
                  const Text(
                    'Patient Insight',
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
              margin: const EdgeInsets.only(bottom: 16.0),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 1. Patient Profile Card with "Ganti" Button
                  _buildPatientCard(),
                  const SizedBox(height: 20),

                  // 2. Section: RINGKASAN INSIGHT
                  _buildSectionHeader(
                    icon: LucideIcons.barChart2,
                    title: 'RINGKASAN INSIGHT',
                  ),
                  const SizedBox(height: 10),
                  _buildKondisiKulitTeratasCard(),
                  const SizedBox(height: 12),
                  _buildStatCardsRow(),
                  const SizedBox(height: 12),
                  _buildInsightNotesCard(),
                  const SizedBox(height: 22),

                  // 3. Section: SKIN CHECK
                  _buildSectionHeader(
                    icon: LucideIcons.search,
                    title: 'SKIN CHECK',
                  ),
                  const SizedBox(height: 10),
                  _buildSkinCheckSection(),
                  const SizedBox(height: 22),

                  // 4. Section: SKIN DAILY
                  _buildSectionHeader(
                    icon: LucideIcons.clipboardList,
                    title: 'SKIN DAILY',
                  ),
                  const SizedBox(height: 10),
                  _buildSkinDailySection(),
                  const SizedBox(height: 22),

                  // 5. Section: SKINCARE ROUTINE
                  _buildSectionHeader(
                    icon: LucideIcons.sparkles,
                    title: 'SKINCARE ROUTINE',
                  ),
                  const SizedBox(height: 10),
                  _buildSkincareRoutineSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DokterNavBottom(
        currentIndex: 0,
        onTap: (index) {
          Navigator.popUntil(context, (route) => route.isFirst);
          if (index > 0) {
            widget.onNavigateTab?.call(index);
          }
        },
      ),
    );
  }

  /// Section Header helper
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  /// 1. Patient Profile Card
  Widget _buildPatientCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
      child: Row(
        children: [
          // Maroon square avatar with white user icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryMaroon,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.user,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name and consultation count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentPatient.name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _currentPatient.consultationCount,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: subText,
                  ),
                ),
              ],
            ),
          ),

          // "Ganti" text button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showGantiPasienModal,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  'Ganti',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: primaryMaroon,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Kondisi Kulit Teratas Card
  Widget _buildKondisiKulitTeratasCard() {
    final conditions = [
      {'name': 'Berminyak', 'count': '2x'},
      {'name': 'Jerawat', 'count': '2x'},
      {'name': 'Kemerahan', 'count': '2x'},
    ];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          const Text(
            'KONDISI KULIT TERATAS',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...conditions.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['name']!,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  Text(
                    item['count']!,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: primaryMaroon,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 3 Stat Cards Row (Maroon)
  Widget _buildStatCardsRow() {
    return Row(
      children: [
        // 1. Gelas/Hari
        Expanded(
          child: _buildMaroonStatCard(
            icon: LucideIcons.droplets,
            value: '6.6',
            label: 'Gelas/Hari',
          ),
        ),
        const SizedBox(width: 10),

        // 2. Jam Tidur
        Expanded(
          child: _buildMaroonStatCard(
            icon: LucideIcons.moon,
            value: '0',
            label: 'Jam Tidur',
          ),
        ),
        const SizedBox(width: 10),

        // 3. Skincare
        Expanded(
          child: _buildMaroonStatCard(
            icon: LucideIcons.sparkles,
            value: '57%',
            label: 'Skincare',
          ),
        ),
      ],
    );
  }

  Widget _buildMaroonStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  /// Insight Notes Card
  Widget _buildInsightNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          const Text(
            'INSIGHT',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),

          // Bullet 1: Kepatuhan Skincare
          _buildInsightBullet(
            icon: LucideIcons.circleAlert,
            iconColor: const Color(0xFFE53935),
            text:
                'Pasien memiliki kepatuhan skincare 57% dalam 7 hari terakhir',
          ),
          const SizedBox(height: 12),

          // Bullet 2: Konsumsi Air
          _buildInsightBullet(
            icon: LucideIcons.droplets,
            iconColor: const Color(0xFF757575),
            text: 'Rata-rata konsumsi air: 6.6 gelas per hari',
          ),
          const SizedBox(height: 12),

          // Bullet 3: Tidur
          _buildInsightBullet(
            icon: LucideIcons.moon,
            iconColor: const Color(0xFF757575),
            text: 'Rata-rata tidur: 0 jam per malam',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightBullet({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.0,
              color: Color(0xFF555555),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  /// 3. SKIN CHECK Section
  Widget _buildSkinCheckSection() {
    return Column(
      children: [
        // Check 1: 2026-08-28 (Kombinasi, Sensitif, Rentan)
        _buildSkinCheckCard(
          date: '2026-08-28',
          tipeKulit: 'Kombinasi',
          sensitivitas: 'Sensitif',
          jerawat: 'Rentan',
        ),
        const SizedBox(height: 12),

        // Check 2: 2026-08-10 (Normal, Non-Sensitif, Tidak Rentan)
        _buildSkinCheckCard(
          date: '2026-08-10',
          tipeKulit: 'Normal',
          sensitivitas: 'Non-\nSensitif',
          jerawat: 'Tidak\nRentan',
        ),
      ],
    );
  }

  Widget _buildSkinCheckCard({
    required String date,
    required String tipeKulit,
    required String sensitivitas,
    required String jerawat,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Text(
            date,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSkinCheckParamBox('Tipe Kulit', tipeKulit),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSkinCheckParamBox('Sensitivitas', sensitivitas),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSkinCheckParamBox('Jerawat', jerawat),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkinCheckParamBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// 4. SKIN DAILY Section
  Widget _buildSkinDailySection() {
    final entries = [
      {
        'date': '2026-08-28',
        'badge': 'Baik',
        'badgeBg': const Color(0xFFFFD5C8),
        'badgeColor': const Color(0xFFC2410C),
        'gejala': 'Letak Gejala: Hidung, Dahi',
        'kondisi': 'Kondisi: Berminyak, Komedo',
        'tidur': 'Tidur: 23:00',
        'air': 'Air: 8 gelas',
        'makan': 'Makan: Nasi, ayam panggang, salad, buah',
        'pagiOk': true,
        'malamOk': false,
      },
      {
        'date': '2026-08-26',
        'badge': 'Sedang',
        'badgeBg': const Color(0xFFFFE0B2),
        'badgeColor': const Color(0xFFE65100),
        'gejala': 'Letak Gejala: Pipi Kanan, Dahi',
        'kondisi': 'Kondisi: Jerawat, Kemerahan',
        'tidur': 'Tidur: 01:00',
        'air': 'Air: 5 gelas',
        'makan': 'Makan: Nasi goreng, mie instan',
        'pagiOk': true,
        'malamOk': true,
      },
      {
        'date': '2026-08-25',
        'badge': 'Baik',
        'badgeBg': const Color(0xFFFFD5C8),
        'badgeColor': const Color(0xFFC2410C),
        'gejala': null,
        'kondisi': 'Kondisi: Normal',
        'tidur': 'Tidur: 22:30',
        'air': 'Air: 8 gelas',
        'makan': 'Makan: Nasi, ikan bakar, sayur',
        'pagiOk': true,
        'malamOk': true,
      },
      {
        'date': '2026-08-24',
        'badge': 'Baik',
        'badgeBg': const Color(0xFFFFD5C8),
        'badgeColor': const Color(0xFFC2410C),
        'gejala': 'Letak Gejala: Pipi Kanan, Dahi',
        'kondisi': 'Kondisi: Berminyak',
        'tidur': 'Tidur: 23:30',
        'air': 'Air: 7 gelas',
        'makan': 'Makan: Nasi, ayam goreng, sup',
        'pagiOk': true,
        'malamOk': true,
      },
      {
        'date': '2026-08-23',
        'badge': 'Buruk',
        'badgeBg': const Color(0xFFFFCDD2),
        'badgeColor': const Color(0xFFD32F2F),
        'gejala': 'Letak Gejala: Pipi Kanan, Dahi',
        'kondisi': 'Kondisi: Jerawat, Kemerahan, Beruntusan',
        'tidur': 'Tidur: 02:00',
        'air': 'Air: 3 gelas',
        'makan': 'Makan: Junk food, es krim, kopi',
        'pagiOk': false,
        'malamOk': false,
      },
      {
        'date': '2026-08-22',
        'badge': 'Sedang',
        'badgeBg': const Color(0xFFFFE0B2),
        'badgeColor': const Color(0xFFE65100),
        'gejala': 'Letak Gejala: Pipi Kanan, Dahi',
        'kondisi': 'Kondisi: Kusam',
        'tidur': 'Tidur: 00:00',
        'air': 'Air: 5 gelas',
        'makan': 'Makan: Nasi, tempe, sayur',
        'pagiOk': true,
        'malamOk': false,
      },
    ];

    return Column(
      children: entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
              // Date & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry['date'] as String,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: entry['badgeBg'] as Color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      entry['badge'] as String,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: entry['badgeColor'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Gejala (if any)
              if (entry['gejala'] != null) ...[
                Text(
                  entry['gejala'] as String,
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 2),
              ],

              // Kondisi
              Text(
                entry['kondisi'] as String,
                style: const TextStyle(
                  fontSize: 13.0,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 4),

              // Sleep & Water Info
              Row(
                children: [
                  const Icon(
                    LucideIcons.moon,
                    size: 13,
                    color: Color(0xFF757575),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry['tidur'] as String,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                    child: Text(
                      '•',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                  const Icon(
                    LucideIcons.droplets,
                    size: 13,
                    color: Color(0xFF757575),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry['air'] as String,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Makan Info
              Text(
                entry['makan'] as String,
                style: const TextStyle(
                  fontSize: 13.0,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 10),

              // Routine Pills: Pagi & Malam
              Row(
                children: [
                  _buildRoutinePill(
                    isMorning: true,
                    isDone: entry['pagiOk'] as bool,
                  ),
                  const SizedBox(width: 8),
                  _buildRoutinePill(
                    isMorning: false,
                    isDone: entry['malamOk'] as bool,
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoutinePill({
    required bool isMorning,
    required bool isDone,
  }) {
    final label = isMorning ? 'Pagi' : 'Malam';
    final icon = isMorning ? LucideIcons.sun : LucideIcons.moon;
    final symbol = isDone ? '✓' : '✕';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCDD2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: const Color(0xFFC2410C),
          ),
          const SizedBox(width: 4),
          Text(
            '$label $symbol',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC2410C),
            ),
          ),
        ],
      ),
    );
  }

  /// 5. SKINCARE ROUTINE Section
  Widget _buildSkincareRoutineSection() {
    return Column(
      children: [
        // Routine 1: 2026-08-28
        _buildSkincareRoutineCard(
          date: '2026-08-28',
          morningItems: [
            'Cleanser',
            'Toner',
            'Serum',
            'Moisturizer',
            'Sunscreen',
          ],
          nightItems: [
            'Cleanser',
            'Toner',
            'Serum',
            'Moisturizer',
            'Night Cream',
          ],
        ),
        const SizedBox(height: 12),

        // Routine 2: 2026-08-27
        _buildSkincareRoutineCard(
          date: '2026-08-27',
          morningItems: [
            'Cleanser',
            'Toner',
            'Serum',
            'Moisturizer',
            'Sunscreen',
          ],
          nightItems: [
            'Cleanser',
            'Toner',
            'Moisturizer',
            'Sleeping Mask',
          ],
        ),
      ],
    );
  }

  Widget _buildSkincareRoutineCard({
    required String date,
    required List<String> morningItems,
    required List<String> nightItems,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Text(
            date,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PAGI
              Expanded(
                child: _buildRoutineBox(
                  isMorning: true,
                  title: 'PAGI',
                  items: morningItems,
                ),
              ),
              const SizedBox(width: 12),

              // MALAM
              Expanded(
                child: _buildRoutineBox(
                  isMorning: false,
                  title: 'MALAM',
                  items: nightItems,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineBox({
    required bool isMorning,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMorning ? LucideIcons.sun : LucideIcons.moon,
                size: 13,
                color: const Color(0xFF757575),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Text(
                '• $item',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF333333),
                  height: 1.3,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
