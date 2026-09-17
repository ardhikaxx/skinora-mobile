import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import 'detail_riwayat_konsultasi_page.dart';

class HistoryChatMessage {
  final String sender; // 'Pasien' or 'Dokter'
  final String message;

  const HistoryChatMessage({
    required this.sender,
    required this.message,
  });
}

class ConsultationHistoryModel {
  final String id;
  final String patientName;
  final String dateTime;
  final String diagnosis;
  final String notes;
  final List<HistoryChatMessage> chatHistory;

  ConsultationHistoryModel({
    required this.id,
    required this.patientName,
    required this.dateTime,
    required this.diagnosis,
    required this.notes,
    this.chatHistory = const [],
  });
}

class DoctorConsultationStore {
  static final DoctorConsultationStore _instance =
      DoctorConsultationStore._internal();
  factory DoctorConsultationStore() => _instance;
  DoctorConsultationStore._internal();

  final List<ConsultationHistoryModel> history = [
    ConsultationHistoryModel(
      id: '1',
      patientName: 'Kafi Khaula Yukisa Zailina',
      dateTime: '2026-08-29 • 10:00 - 10:30',
      diagnosis: 'Dermatitis Kontak Alergi & Dehidrasi Kulit',
      notes:
          'Hentikan penggunaan produk berkandungan alkohol dan fragrance. Gunakan pelembap berbahan dasar ceramide dan soothing gel.',
      chatHistory: const [
        HistoryChatMessage(
          sender: 'Pasien',
          message: 'Halo Dok, kulit saya terasa perih dan kemerahan sejak kemarin.',
        ),
        HistoryChatMessage(
          sender: 'Dokter',
          message: 'Apakah ada pemakaian produk baru sebelum gejala muncul?',
        ),
        HistoryChatMessage(
          sender: 'Pasien',
          message: 'Iya Dok, saya baru coba toner eksfoliasi 3 hari lalu.',
        ),
        HistoryChatMessage(
          sender: 'Dokter',
          message: 'Hentikan pemakaian toner tersebut dan fokus ke hidrasi dasar ya.',
        ),
      ],
    ),
    ConsultationHistoryModel(
      id: '2',
      patientName: 'Kafi Khaula Yukisa Zailina',
      dateTime: '2026-08-28 • 10:00 - 10:30',
      diagnosis: 'Pori-pori tersumbat & Komedo terbuka (Blackheads)',
      notes:
          'Eksfoliasi kimiawi menggunakan BHA/Salicylic acid 2% seminggu 2 kali pada malam hari. Double cleansing secara rutin.',
      chatHistory: const [
        HistoryChatMessage(
          sender: 'Pasien',
          message: 'Dok, di area hidung banyak bintik hitam komedo yang sulit hilang.',
        ),
        HistoryChatMessage(
          sender: 'Dokter',
          message: 'Bisa gunakan pembersih berbahan salicylic acid 2% secara teratur.',
        ),
      ],
    ),
    ConsultationHistoryModel(
      id: '3',
      patientName: 'Annida Tri Aulia',
      dateTime: '2026-08-25 • 10:00 - 10:30',
      diagnosis: 'Acne Vulgaris derajat ringan-sedang',
      notes:
          'Resep obat oles benzoyl peroxide 2.5% pagi hari dan retinoid tipis pada malam hari. Tetap gunakan sunscreen non-komedogenik.',
      chatHistory: const [
        HistoryChatMessage(
          sender: 'Pasien',
          message: 'Dok, jerawat meradang di dahi dan dagu semakin banyak.',
        ),
        HistoryChatMessage(
          sender: 'Dokter',
          message: 'Gunakan benzoyl peroxide untuk jerawat aktif dan jaga kebersihan wajah.',
        ),
      ],
    ),
    ConsultationHistoryModel(
      id: '4',
      patientName: 'Leonita Yulyta Agustin',
      dateTime: '2026-08-15 • 09:00 - 09:30',
      diagnosis: 'Perawatan Pasca Operasi Kulit',
      notes:
          'Hindari paparan matahari langsung selama 2 minggu. Gunakan krim antibiotik yang diresepkan.',
      // Exact chat history shown in image copy 3.png Screen 2
      chatHistory: const [
        HistoryChatMessage(
          sender: 'Pasien',
          message: 'Dok, saya mau tanya soal perawatan kulit setelah operasi kecil',
        ),
        HistoryChatMessage(
          sender: 'Dokter',
          message: 'Tentu, operasi apa yang sudah dilakukan?',
        ),
        HistoryChatMessage(
          sender: 'Pasien',
          message: 'Operasi kecil untuk angkat tahi lalat di pipi kanan',
        ),
        HistoryChatMessage(
          sender: 'Dokter',
          message:
              'Baik, hindari paparan matahari langsung selama 2 minggu. Gunakan krim antibiotik yang sudah saya resepkan.',
        ),
      ],
    ),
  ];

  void addCompletedConsultation({
    required String patientName,
    required String dateTime,
    String diagnosis = 'Hiperpigmentasi Pasca-Inflamasi (PIH)',
    String notes =
        'Rekomendasi serum Vitamin C pagi hari dan retinol ringan malam hari. Evaluasi dalam 4-6 minggu.',
    List<HistoryChatMessage>? chatHistory,
  }) {
    history.insert(
      0,
      ConsultationHistoryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientName: patientName,
        dateTime: dateTime,
        diagnosis: diagnosis,
        notes: notes,
        chatHistory: chatHistory ??
            const [
              HistoryChatMessage(
                sender: 'Dokter',
                message: 'Selamat pagi. Ada yang bisa saya bantu hari ini?',
              ),
              HistoryChatMessage(
                sender: 'Pasien',
                message: 'Selamat pagi Dok, konsultasi perawatan kulit rutin.',
              ),
              HistoryChatMessage(
                sender: 'Dokter',
                message: 'Terima kasih, konsultasi telah selesai.',
              ),
            ],
      ),
    );
  }
}

class RiwayatKonsultasiPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const RiwayatKonsultasiPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = false,
  });

  @override
  State<RiwayatKonsultasiPage> createState() => _RiwayatKonsultasiPageState();
}

class _RiwayatKonsultasiPageState extends State<RiwayatKonsultasiPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E1E1E);
  static const Color subText = Color(0xFF757575);
  static const Color avatarBg = Color(0xFFFFCDD2);
  static const Color completedBadgeBg = Color(0xFFFFD5C8);

  List<ConsultationHistoryModel> get _historyList =>
      DoctorConsultationStore().history;

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
                left: 16.0,
                right: 20.0,
                top: 14.0,
                bottom: 8.0,
              ),
              child: Row(
                children: [
                  if (Navigator.canPop(context)) ...[
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
                  ],
                  const Text(
                    'Riwayat Konsultasi',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
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

            // Main scrollable list of history items matching image copy 3.png
            Expanded(
              child: _historyList.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada riwayat konsultasi',
                        style: TextStyle(
                          fontSize: 14.5,
                          color: subText,
                        ),
                      ),
                    )
                  : ListView.separated(
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
      bottomNavigationBar: widget.showBottomNav
          ? DokterNavBottom(
              currentIndex: 3,
              onTap: (index) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                widget.onNavigateTab?.call(index);
              },
            )
          : null,
    );
  }

  /// Single History Card
  Widget _buildHistoryCard(ConsultationHistoryModel item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailRiwayatKonsultasiPage(
                consultation: item,
                onNavigateTab: widget.onNavigateTab,
                showBottomNav: true,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
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
        ),
      ),
    );
  }
}
