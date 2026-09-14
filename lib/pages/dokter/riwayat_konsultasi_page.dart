import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ConsultationHistoryModel {
  final String id;
  final String patientName;
  final String dateTime;
  final String diagnosis;
  final String notes;

  ConsultationHistoryModel({
    required this.id,
    required this.patientName,
    required this.dateTime,
    required this.diagnosis,
    required this.notes,
  });
}

class RiwayatKonsultasiPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const RiwayatKonsultasiPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<RiwayatKonsultasiPage> createState() => _RiwayatKonsultasiPageState();
}

class _RiwayatKonsultasiPageState extends State<RiwayatKonsultasiPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color avatarBg = Color(0xFFFFB2A6);
  static const Color completedBadgeBg = Color(0xFFFFD5C8);

  final List<ConsultationHistoryModel> _historyList = [
    ConsultationHistoryModel(
      id: '1',
      patientName: 'Kafi Khaula Yukisa Zailina',
      dateTime: '2026-08-29 • 10:00 - 10:30',
      diagnosis: 'Dermatitis Kontak Alergi & Dehidrasi Kulit',
      notes:
          'Hentikan penggunaan produk berkandungan alkohol dan fragrance. Gunakan pelembap berbahan dasar ceramide dan soothing gel.',
    ),
    ConsultationHistoryModel(
      id: '2',
      patientName: 'Nur Alisa Qiroati Sholeha',
      dateTime: '2026-08-28 • 10:00 - 10:30',
      diagnosis: 'Pori-pori tersumbat & Komedo terbuka (Blackheads)',
      notes:
          'Eksfoliasi kimiawi menggunakan BHA/Salicylic acid 2% seminggu 2 kali pada malam hari. Double cleansing secara rutin.',
    ),
    ConsultationHistoryModel(
      id: '3',
      patientName: 'Annida Tri Aulia',
      dateTime: '2026-08-25 • 10:00 - 10:30',
      diagnosis: 'Acne Vulgaris derajat ringan-sedang',
      notes:
          'Resep obat oles benzoyl peroxide 2.5% pagi hari dan retinoid tipis pada malam hari. Tetap gunakan sunscreen non-komedogenik.',
    ),
    ConsultationHistoryModel(
      id: '4',
      patientName: 'Leonita Yulyta Agustin',
      dateTime: '2026-08-15 • 09:00 - 09:30',
      diagnosis: 'Skin barrier terganggu dengan eritema ringan',
      notes:
          'Fokus hidrasi dan perbaikan skin barrier dengan hyaluronic acid dan centella asiatica. Re-evaluasi setelah 2 minggu.',
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
            // 1. Header: Title "Riwayat Konsultasi"
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 16.0,
                bottom: 8.0,
              ),
              child: const Text(
                'Riwayat Konsultasi',
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

            // Main scrollable list of history items
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: _historyList.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = _historyList[index];
                  return _buildHistoryCard(item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Single History Card
  Widget _buildHistoryCard(ConsultationHistoryModel item) {
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar (soft peach/coral with maroon user icon)
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
                    maxLines: 2,
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

            // Status Badge "Selesai"
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: completedBadgeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    LucideIcons.check,
                    size: 12,
                    color: primaryMaroon,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Selesai',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: primaryMaroon,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
