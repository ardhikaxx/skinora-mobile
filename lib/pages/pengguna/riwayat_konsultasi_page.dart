import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/consultation_service.dart';
import 'riwayat_ruang_konsultasi_page.dart';

enum ConsultationStatus {
  terjadwal,
  selesai,
}

class UserConsultationHistoryModel {
  final String id;
  final String doctorName;
  final String specialization;
  final String dateTime;
  final ConsultationStatus status;
  final String? diagnosis;
  final String? notes;

  const UserConsultationHistoryModel({
    required this.id,
    required this.doctorName,
    required this.specialization,
    required this.dateTime,
    required this.status,
    this.diagnosis,
    this.notes,
  });
}

class RiwayatKonsultasiPenggunaPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const RiwayatKonsultasiPenggunaPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<RiwayatKonsultasiPenggunaPage> createState() =>
      _RiwayatKonsultasiPenggunaPageState();
}

class _RiwayatKonsultasiPenggunaPageState
    extends State<RiwayatKonsultasiPenggunaPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF9B8F8C);
  static const Color avatarBg = Color(0xFFF8A5A5);
  static const Color badgeTerjadwalBg = Color(0xFFFED3BF);
  static const Color badgeTerjadwalText = Color(0xFF8B2B38);
  static const Color badgeSelesaiBg = Color(0xFFFCFAF9);
  static const Color badgeSelesaiText = Color(0xFF6B5E5E);
  static const Color badgeSelesaiBorder = Color(0xFFE5E5EA);

  List<UserConsultationHistoryModel> _historyList = const [
    UserConsultationHistoryModel(
      id: '1',
      doctorName: 'dr. Anita Dewi, Sp.KK',
      specialization: 'Estetika Kulit',
      dateTime: '2026-08-28 - 09:00 - 09:30',
      status: ConsultationStatus.terjadwal,
      notes:
          'Konsultasi daring mengenai perawatan kulit wajah dan evaluasi kemerahan pada pipi.',
    ),
    UserConsultationHistoryModel(
      id: '2',
      doctorName: 'dr. Andi Pratama, Sp.KK',
      specialization: 'Jerawat & Masalah Pori',
      dateTime: '2026-08-20 - 14:00 - 14:30',
      status: ConsultationStatus.selesai,
      diagnosis: 'Acne Vulgaris derajat ringan & komedo tertutup',
      notes:
          'Gunakan pembersih wajah lembut, serum Salicylic Acid 2% secara berkala, dan pelembap berbasis gel.',
    ),
    UserConsultationHistoryModel(
      id: '3',
      doctorName: 'dr. Anita Dewi, Sp.KK',
      specialization: 'Estetika Kulit',
      dateTime: '2026-08-15 - 09:00 - 09:30',
      status: ConsultationStatus.selesai,
      diagnosis: 'Skin barrier sensitif dengan kecenderungan dehidrasi',
      notes:
          'Hindari scrub atau eksfoliasi fisik berlebih. Gunakan krim pelembap yang mengandung Ceramide dan Hyaluronic Acid.',
    ),
    UserConsultationHistoryModel(
      id: '4',
      doctorName: 'dr. Andi Pratama, Sp.KK',
      specialization: 'Jerawat & Masalah Pori',
      dateTime: '2026-08-28 - 11:00 - 11:30',
      status: ConsultationStatus.terjadwal,
      notes:
          'Sesi konsultasi evaluasi progres pemakaian skincare mingguan dan rekomendasi penyesuaian produk.',
    ),
    UserConsultationHistoryModel(
      id: '5',
      doctorName: 'dr. Reza Firmansyah, Sp.KK',
      specialization: 'Anti-Aging & Peremajaan Kulit',
      dateTime: '2026-08-28 - 09:30 - 10:00',
      status: ConsultationStatus.selesai,
      diagnosis: 'Garis halus ringan dan hiperpigmentasi ringan akibat sinar UV',
      notes:
          'Disarankan rutin mengaplikasikan sunscreen SPF 50+ PA++++ setiap 3-4 jam dan serum vitamin C pada pagi hari.',
    ),
    UserConsultationHistoryModel(
      id: '6',
      doctorName: 'dr. Anita Dewi, Sp.KK',
      specialization: 'Estetika Kulit',
      dateTime: '2026-08-30 - 14:00 - 14:30',
      status: ConsultationStatus.terjadwal,
      notes:
          'Sesi konsultasi tindak lanjut persiapan perawatan rutin bulanan.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  /// Riwayat konsultasi milik pasien dari Firestore. Tanpa Firebase, seed
  /// demo tetap dipakai agar UI/tes tidak berubah.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final items = await ConsultationService.listForPatient(uid);
      if (items.isEmpty || !mounted) return;
      setState(() {
        _historyList = items.map((m) {
          final rawDate = (m['scheduleDate'] as String?) ?? '';
          final rawTime = (m['scheduleTime'] as String?) ?? '';
          final dateIso = (m['dateIso'] as String?) ?? '';
          final datePart =
              rawDate.isNotEmpty ? rawDate : (dateIso.isNotEmpty ? dateIso : '-');
          final status = ((m['status'] as String?) ?? '') == 'selesai'
              ? ConsultationStatus.selesai
              : ConsultationStatus.terjadwal;
          return UserConsultationHistoryModel(
            id: (m['id'] as String?) ?? '',
            doctorName: (m['doctorName'] as String?) ?? '',
            specialization: (m['specialization'] as String?) ?? '',
            dateTime: rawTime.isEmpty
                ? datePart
                : '$datePart - $rawTime',
            status: status,
            diagnosis: m['diagnosis'] as String?,
            notes: m['notes'] as String?,
          );
        }).toList();
      });
    } catch (_) {
      // riwayat tetap menampilkan seed demo bila query gagal
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
            // Header: Back icon and "Riwayat" title
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 20.0,
                top: 16.0,
                bottom: 12.0,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        LucideIcons.chevronLeft,
                        size: 22,
                        color: darkText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Riwayat',
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
              margin: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                bottom: 16.0,
              ),
            ),

            // Consultation History List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: _historyList.length,
                itemBuilder: (context, index) {
                  final item = _historyList[index];
                  return _buildHistoryCard(item);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PenggunaNavBottom(
        currentIndex: -1,
        onTap: (index) {
          Navigator.popUntil(context, (route) => route.isFirst);
          if (index != 0) {
            widget.onNavigateTab?.call(index);
          }
        },
      ),
    );
  }

  Widget _buildHistoryCard(UserConsultationHistoryModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RiwayatRuangKonsultasiPage(
                  doctorName: item.doctorName,
                  status: item.status == ConsultationStatus.terjadwal
                      ? 'Terjadwal'
                      : 'Selesai',
                  consultationId: item.id,
                  onNavigateTab: widget.onNavigateTab,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Soft pink/coral avatar container with lowercase "d"
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'd',
                      style: TextStyle(
                        color: primaryMaroon,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Doctor Information and status badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.doctorName,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(item.status),
                          const SizedBox(width: 8),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: Color(0xFF8E8E93),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.dateTime,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: subText,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ConsultationStatus status) {
    if (status == ConsultationStatus.terjadwal) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: 3.5,
        ),
        decoration: BoxDecoration(
          color: badgeTerjadwalBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Terjadwal',
          style: TextStyle(
            fontSize: 11.0,
            fontWeight: FontWeight.w600,
            color: badgeTerjadwalText,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: 3.5,
        ),
        decoration: BoxDecoration(
          color: badgeSelesaiBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badgeSelesaiBorder,
            width: 1.0,
          ),
        ),
        child: const Text(
          'Selesai',
          style: TextStyle(
            fontSize: 11.0,
            fontWeight: FontWeight.w600,
            color: badgeSelesaiText,
          ),
        ),
      );
    }
  }
}

