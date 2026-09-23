import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/consultation_service.dart';
import 'ruang_chat_dokter_page.dart';
import 'riwayat_konsultasi_page.dart';


class ConsultationItemModel {
  final String id;
  final String patientName;
  final String dateTime;
  String status; // 'Terjadwal' or 'Berlangsung'

  ConsultationItemModel({
    required this.id,
    required this.patientName,
    required this.dateTime,
    required this.status,
  });
}

class ChatKonsultasiPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const ChatKonsultasiPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = false,
  });

  @override
  State<ChatKonsultasiPage> createState() => _ChatKonsultasiPageState();
}

class _ChatKonsultasiPageState extends State<ChatKonsultasiPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E1E1E);
  static const Color subText = Color(0xFF757575);
  static const Color avatarBg = Color(0xFFFFCDD2);
  static const Color scheduledBadgeBg = Color(0xFFFFCDD2);
  static const Color scheduledBadgeText = Color(0xFFA83244);
  static const Color ongoingBadgeBg = Color(0xFFDCFCE7);
  static const Color ongoingBadgeText = Color(0xFF16A34A);

  // Seed demo HANYA untuk widget test / mode tanpa Firebase.
  // Dengan Firebase, daftar diisi dari Firestore (boleh kosong).
  final List<ConsultationItemModel> _consultations = Backend.useFirebase
      ? <ConsultationItemModel>[]
      : <ConsultationItemModel>[
          ConsultationItemModel(
            id: '1',
            patientName: 'Leonita Yulyta Agustin',
            dateTime: '2026-08-28 • 09:00 - 09:30',
            status: 'Terjadwal',
          ),
          ConsultationItemModel(
            id: '2',
            patientName: 'Annida Tri Aulia',
            dateTime: '2026-08-28 • 09:30 - 10:00',
            status: 'Berlangsung',
          ),
          ConsultationItemModel(
            id: '3',
            patientName: 'Annida Tri Aulia',
            dateTime: '2026-08-29 • 09:00 - 09:30',
            status: 'Terjadwal',
          ),
          ConsultationItemModel(
            id: '4',
            patientName: 'Siti Aisa Nur Apriliana',
            dateTime: '2026-08-29 • 09:30 - 10:00',
            status: 'Terjadwal',
          ),
          ConsultationItemModel(
            id: '5',
            patientName: 'Leonita Yulyta Agustin',
            dateTime: '2026-08-30 • 14:00 - 14:30',
            status: 'Terjadwal',
          ),
        ];

  // id Firestore -> data mentah untuk persist aksi status.
  final Map<String, Map<String, dynamic>> _backendMeta = {};

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  String _labelStatus(String raw) {
    switch (raw) {
      case 'berlangsung':
        return 'Berlangsung';
      case 'selesai':
        return 'Selesai';
      case 'terjadwal':
      default:
        return 'Terjadwal';
    }
  }

  /// Konsultasi aktif dokter dari Firestore. Tanpa Firebase, seed demo
  /// tetap dipakai agar UI/tes tidak berubah. Dengan Firebase, hasil
  /// backend selalu menggantikan seed — termasuk saat kosong.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final items = await ConsultationService.listForDoctor(uid);
      if (!mounted) return;
      setState(() {
        _backendMeta.clear();
        _consultations
          ..clear()
          ..addAll(items
              .where((m) => ((m['status'] as String?) ?? '') != 'selesai')
              .map((m) {
        final id = (m['id'] as String?) ?? '';
        _backendMeta[id] = m;
        final date = (m['dateIso'] as String?) ?? '';
        final time = ((m['timeStart'] as String?) ?? '').isNotEmpty
            ? '${m['timeStart']} - ${m['timeEnd']}'
            : (m['scheduleTime'] as String?) ?? '';
        return ConsultationItemModel(
          id: id,
          patientName: (m['patientName'] as String?) ?? 'Pasien',
          dateTime: date.isEmpty
              ? ((m['scheduleDate'] as String?) ?? '')
              : '$date • $time',
          status: _labelStatus((m['status'] as String?) ?? 'terjadwal'),
        );
      }));
      });
    } catch (_) {
      // Query gagal → tampilkan kosong, jangan seed palsu di production.
      if (!mounted) return;
      setState(() {
        _backendMeta.clear();
        _consultations.clear();
      });
    }
  }

  Future<void> _handleConsultationAction(ConsultationItemModel item) async {
    // Persist status "berlangsung" saat dokter membuka ruang chat.
    if (Backend.useFirebase && _backendMeta.containsKey(item.id)) {
      try {
        await ConsultationService.markBerlangsung(item.id);
      } catch (_) {
        // lanjut ke ruang chat walau update status gagal
      }
      if (!mounted) return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RuangChatDokterPage(
          patientName: item.patientName,
          consultationId: item.id,
          dateTime: item.dateTime,
          onNavigateTab: widget.onNavigateTab,
          showBottomNav: true,
        ),
      ),
    );

    // If finished via Screen 3 "Ya, Selesai"
    if (result == true) {
      // Persist selesai ke Firestore (dengan activity log).
      if (Backend.useFirebase && _backendMeta.containsKey(item.id)) {
        final uid = AuthService.uid ?? '';
        try {
          await ConsultationService.complete(
            id: item.id,
            doctorUid: uid,
            doctorName: (_backendMeta[item.id]?['doctorName'] as String?) ??
                'Dokter',
            patientName: item.patientName,
            diagnosis: '',
            notes: '',
          );
          _backendMeta.remove(item.id);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal menyelesaikan konsultasi: $e')),
            );
          }
          return;
        }
      }
      setState(() {
        _consultations.removeWhere((c) => c.id == item.id);
      });
      // Seed lokal utk demo saja. Dengan Firebase, riwayat berasal dari
      // Firestore — jangan tulis diagnosis dummy ke store.
      if (!Backend.useFirebase) {
        DoctorConsultationStore().addCompletedConsultation(
          patientName: item.patientName,
          dateTime: item.dateTime,
          diagnosis: 'Hiperpigmentasi Pasca-Inflamasi (PIH)',
          notes:
              'Rekomendasi serum Vitamin C pagi hari dan retinol ringan malam hari. Evaluasi dalam 4-6 minggu.',
        );
      }
      if (mounted) {
        _showSuccessDialog();
      }
    }
  }

  void _navigateToRiwayat() {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(3); // Pindah ke Tab 3 (Riwayat Konsultasi)
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RiwayatKonsultasiPage(
            onNavigateTab: widget.onNavigateTab,
            showBottomNav: true,
          ),
        ),
      );
    }
  }

  /// Screen 4: Dialog "Berhasil" (Konsultasi telah diselesaikan)
  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 4,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Checkmark Icon + Title + Close Button
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD5C8),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.check,
                          color: Color(0xFFE65100),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Berhasil',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _navigateToRiwayat();
                      },
                      child: const Icon(
                        LucideIcons.x,
                        size: 18,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Body text
                const Text(
                  'Konsultasi telah diselesaikan',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF4B5563),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),

                // OK Button
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _navigateToRiwayat();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryMaroon,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Title "Konsultasi"
            const Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 16.0,
                bottom: 8.0,
              ),
              child: Text(
                'Konsultasi',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            // Subtle divider line
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            ),

            // Main scrollable list of consultations
            Expanded(
              child: _consultations.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: _consultations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = _consultations[index];
                        return _buildConsultationCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? DokterNavBottom(
              currentIndex: 2,
              onTap: (index) {
                if (index != 2) {
                  widget.onNavigateTab?.call(index);
                }
              },
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            LucideIcons.messageSquare,
            size: 48,
            color: Color(0xFFD1D5DB),
          ),
          SizedBox(height: 12),
          Text(
            'Tidak ada konsultasi aktif',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  /// Single Consultation Card
  Widget _buildConsultationCard(ConsultationItemModel item) {
    final isOngoing = item.status == 'Berlangsung';

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
        children: [
          // Row 1: Avatar, Name, Date/Time, Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar (soft peach/pink with maroon user icon)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarBg,
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

              // Patient Name & Date/Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.patientName,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.clock,
                          size: 13,
                          color: subText,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.dateTime,
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: subText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: isOngoing ? ongoingBadgeBg : scheduledBadgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    color: isOngoing ? ongoingBadgeText : scheduledBadgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Action Button ("Mulai Konsultasi" or "Masuk Ruang Chat")
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () => _handleConsultationAction(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryMaroon,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOngoing ? LucideIcons.messageSquare : LucideIcons.phone,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOngoing ? 'Masuk Ruang Chat' : 'Mulai Konsultasi',
                    style: const TextStyle(
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
    );
  }
}
