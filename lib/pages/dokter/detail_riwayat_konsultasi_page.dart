import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/empty_state.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import '../../services/backend.dart';
import 'riwayat_konsultasi_page.dart';

class DetailRiwayatKonsultasiPage extends StatelessWidget {
  final ConsultationHistoryModel? consultation;
  final String patientName;
  final String dateTime;
  final String status;
  final List<HistoryChatMessage>? chatHistory;
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const DetailRiwayatKonsultasiPage({
    super.key,
    this.consultation,
    this.patientName = '',
    this.dateTime = '',
    this.status = '',
    this.chatHistory,
    this.onNavigateTab,
    this.showBottomNav = true,
  });

  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E1E1E);
  static const Color subText = Color(0xFF757575);
  static const Color patientBubbleBg = Color(0xFFFFD5C8);
  static const Color badgeBg = Color(0xFFFFD5C8);

  String get _name {
    final raw = consultation?.patientName ?? patientName;
    if (raw.isNotEmpty) return raw;
    return Backend.useFirebase ? '-' : 'Leonita Yulyta Agustin';
  }

  String get _date {
    final raw = consultation?.dateTime ?? dateTime;
    if (raw.isNotEmpty) return raw;
    return Backend.useFirebase ? '-' : '2026-08-15 • 09:00 - 09:30';
  }
  String get _statusLabel {
    if (status.isNotEmpty) return status;
    return 'Selesai';
  }

  List<HistoryChatMessage> get _messages {
    if (consultation != null) return consultation!.chatHistory;
    if (chatHistory != null) return chatHistory!;
    if (Backend.useFirebase) return const <HistoryChatMessage>[];
    return const [
      HistoryChatMessage(
        sender: 'Pasien',
        message:
            'Dok, saya mau tanya soal perawatan kulit setelah operasi kecil',
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header: Back chevron + Title "Detail Riwayat"
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
                  const SizedBox(width: 10),
                  const Text(
                    'Detail Riwayat',
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
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                children: [
                  // 2. Patient Header Card
                  _buildPatientHeaderCard(),
                  const SizedBox(height: 16),

                  // 3. Status Card
                  _buildStatusCard(),
                  const SizedBox(height: 16),

                  // 4. Riwayat Chat Card
                  _buildRiwayatChatCard(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? DokterNavBottom(
              currentIndex: 3,
              onTap: (index) {
                Navigator.pop(context);
                if (index != 3) {
                  onNavigateTab?.call(index);
                }
              },
            )
          : null,
    );
  }

  /// Card 1: Patient Header Card
  Widget _buildPatientHeaderCard() {
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
      child: Row(
        children: [
          // Maroon Avatar Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryMaroon,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.user,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name and Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 16.0,
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
                      size: 14,
                      color: subText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _date,
                        style: const TextStyle(
                          fontSize: 12.5,
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
        ],
      ),
    );
  }

  /// Card 2: Status Card
  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUS',
            style: TextStyle(
              fontSize: 11.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 5.0,
            ),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.check,
                  size: 13,
                  color: primaryMaroon,
                ),
                SizedBox(width: 4),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
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

  /// Card 3: Riwayat Chat Card
  Widget _buildRiwayatChatCard(BuildContext context) {
    final messages = _messages;

    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Message Icon + "RIWAYAT CHAT"
          Row(
            children: const [
              Icon(
                LucideIcons.messageSquare,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              SizedBox(width: 8),
              Text(
                'RIWAYAT CHAT',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Empty state
          if (messages.isEmpty)
            const CompactEmptyState(
              icon: LucideIcons.messageCircle,
              title: 'Belum ada riwayat chat',
              description:
                  'Percakapan pada konsultasi ini akan tercatat di sini.',
            ),

          // Messages List
          ...messages.map((item) {
            final isDoctor = item.sender.toLowerCase() == 'dokter';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Align(
                alignment:
                    isDoctor ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: isDoctor ? primaryMaroon : patientBubbleBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sender label
                      Text(
                        item.sender,
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                          color: isDoctor
                              ? Colors.white.withValues(alpha: 0.75)
                              : const Color(0xFF8B2B38),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Message text
                      Text(
                        item.message,
                        style: TextStyle(
                          fontSize: 13.0,
                          color: isDoctor ? Colors.white : darkText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
