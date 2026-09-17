import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import 'detail_patient_insight_page.dart';

class PatientInsightModel {
  final String id;
  final String name;
  final String consultationCount;
  final String skinType;
  final String primaryConcern;
  final String lastConsultation;

  PatientInsightModel({
    required this.id,
    required this.name,
    required this.consultationCount,
    required this.skinType,
    required this.primaryConcern,
    required this.lastConsultation,
  });
}

class PatientInsightPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const PatientInsightPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<PatientInsightPage> createState() => _PatientInsightPageState();
}

class _PatientInsightPageState extends State<PatientInsightPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF757575);
  static const Color coralIconBg = Color(0xFFFFB2A6);

  final List<PatientInsightModel> _patients = [
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back chevron and title
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
                  ),
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

            // Scrollable list of patients
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // Header text: PILIH PASIEN
                  const Text(
                    'PILIH PASIEN',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle: Lihat data kesehatan kulit dari pasien yang pernah berkonsultasi
                  const Text(
                    'Lihat data kesehatan kulit dari pasien yang\npernah berkonsultasi',
                    style: TextStyle(
                      fontSize: 13.0,
                      color: subText,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Patient Cards
                  ..._patients.map((patient) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildPatientCard(patient),
                    );
                  }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DokterNavBottom(
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

  Widget _buildPatientCard(PatientInsightModel patient) {
    return Container(
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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPatientInsightPage(
                  patient: patient,
                  onNavigateTab: widget.onNavigateTab,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Row(
              children: [
                // Avatar container in soft coral/peach with maroon user icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: coralIconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.user,
                      color: primaryMaroon,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Consultation count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        patient.consultationCount,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: subText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right arrow icon (→)
                const Icon(
                  LucideIcons.arrowRight,
                  color: Color(0xFF9E9E9E),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
