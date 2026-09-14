import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  const ChatKonsultasiPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<ChatKonsultasiPage> createState() => _ChatKonsultasiPageState();
}

class _ChatKonsultasiPageState extends State<ChatKonsultasiPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color avatarBg = Color(0xFFFFB2A6);
  static const Color scheduledBadgeBg = Color(0xFFFFD5C8);
  static const Color ongoingBadgeBg = Color(0xFFDCFCE7);
  static const Color ongoingBadgeText = Color(0xFF059669);

  late List<ConsultationItemModel> _consultations;

  @override
  void initState() {
    super.initState();
    _consultations = [
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
        patientName: 'Nur Alisa Qiroati Sholeha',
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
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 16.0,
                bottom: 8.0,
              ),
              child: const Text(
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
              child: ListView.separated(
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
              // Avatar (soft peach with maroon user icon)
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
                        fontSize: 14.5,
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
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.dateTime,
                            style: const TextStyle(
                              fontSize: 11.5,
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
                    color: isOngoing ? ongoingBadgeText : const Color(0xFF9E2A3B),
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
              onPressed: () {
                if (!isOngoing) {
                  setState(() {
                    item.status = 'Berlangsung';
                  });
                }
              },
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
                    isOngoing
                        ? LucideIcons.messageSquare
                        : LucideIcons.stethoscope,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOngoing ? 'Masuk Ruang Chat' : 'Mulai Konsultasi',
                    style: const TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
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
