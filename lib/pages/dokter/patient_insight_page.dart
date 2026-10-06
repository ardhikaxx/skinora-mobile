import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/empty_state.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/consultation_service.dart';
import '../../services/skin_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_dates.dart';
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
  final List<PatientInsightModel>? initialPatients;

  const PatientInsightPage({
    super.key,
    this.onNavigateTab,
    this.initialPatients,
  });

  @override
  State<PatientInsightPage> createState() => _PatientInsightPageState();
}

class _PatientInsightPageState extends State<PatientInsightPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF757575);
  static const Color coralIconBg = Color(0xFFFFB2A6);

  late final List<PatientInsightModel> _patients = widget.initialPatients != null
      ? List.from(widget.initialPatients!)
      : <PatientInsightModel>[];

  StreamSubscription? _consultSub;

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
    if (Backend.useFirebase) {
      final uid = AuthService.uid;
      if (uid != null) {
        _consultSub = ConsultationService.streamForDoctor(uid).listen((_) {
          _loadFromBackend();
        });
      }
    }
  }

  @override
  void dispose() {
    _consultSub?.cancel();
    super.dispose();
  }

  /// Daftar pasien dari konsultasi dokter secara realtime dari Firestore.
  Future<void> _loadFromBackend() async {
    if (widget.initialPatients != null) return;
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final consults = await ConsultationService.listForDoctor(
        uid,
        includeFinished: true,
      );
      final counts = <String, int>{};
      final lastSeen = <String, String>{};
      for (final c in consults) {
        final pid = (c['patientId'] as String?) ?? '';
        if (pid.isEmpty) continue;
        counts[pid] = (counts[pid] ?? 0) + 1;
        if (!lastSeen.containsKey(pid)) {
          final date = (c['dateIso'] as String?) ?? '';
          if (date.isNotEmpty) {
            final parsed = AppDates.tryParseIso(date);
            if (parsed != null) lastSeen[pid] = AppDates.short(parsed);
          }
        }
      }

      final entries = <MapEntry<String, PatientInsightModel>>[];
      for (final e in counts.entries) {
        final profile = await UserService.loadByUid(e.key);
        if (profile == null || profile.name.isEmpty) continue;
        var skinType = '-';
        var primaryConcern = '-';
        try {
          final checks =
              await SkinService.listSkinChecks(e.key, limit: 1);
          if (checks.isNotEmpty) {
            final m = checks.first;
            final st = (m['resultSkinType'] as String?) ?? '';
            if (st.isNotEmpty) skinType = st;
            final locs = (m['locations'] as List?)?.cast<String>() ??
                const <String>[];
            if (locs.isNotEmpty) primaryConcern = locs.join(', ');
          }
        } catch (_) {
          // skin check kosong/gagal → biarkan '-'
        }
        entries.add(MapEntry(
          e.key,
          PatientInsightModel(
            id: e.key,
            name: profile.name,
            consultationCount: '${e.value} konsultasi',
            skinType: skinType,
            primaryConcern: primaryConcern,
            lastConsultation: lastSeen[e.key] ?? '-',
          ),
        ));
      }
      if (!mounted) return;
      setState(() {
        _patients
          ..clear()
          ..addAll(entries.map((e) => e.value));
      });
    } catch (_) {
      // Query gagal → tampilkan kosong, jangan seed palsu di production.
      if (!mounted) return;
      setState(_patients.clear);
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
                  if (_patients.isEmpty)
                    const EmptyStateWidget(
                      icon: LucideIcons.users,
                      title: 'Belum ada data pasien',
                      description:
                          'Data insight kulit pasien yang pernah berkonsultasi dengan Anda akan muncul di sini.',
                    )
                  else
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
                  initialPatients: _patients,
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
