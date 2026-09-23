import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/consultation_service.dart';

class ConsultationChatMessage {
  final String id;
  final String text;
  final String time;
  final bool isFromUser;

  const ConsultationChatMessage({
    required this.id,
    required this.text,
    required this.time,
    required this.isFromUser,
  });
}

class RiwayatRuangKonsultasiPage extends StatefulWidget {
  final String doctorName;
  final String status;
  final String? consultationId;
  final ValueChanged<int>? onNavigateTab;

  const RiwayatRuangKonsultasiPage({
    super.key,
    this.doctorName = 'dr. Anita Dewi, Sp.KK',
    this.status = 'Terjadwal',
    this.consultationId,
    this.onNavigateTab,
  });

  @override
  State<RiwayatRuangKonsultasiPage> createState() =>
      _RiwayatRuangKonsultasiPageState();
}

class _RiwayatRuangKonsultasiPageState
    extends State<RiwayatRuangKonsultasiPage> {
  static const Color darkText = Color(0xFF461220);
  static const Color primaryMaroon = Color(0xFFB23A48);
  static const Color doctorBubbleBg = Color(0xFFFCB9B2);
  static const Color doctorBubbleText = Color(0xFF461220);
  static const Color badgeBg = Color(0xFFFED0BB);
  static const Color badgeText = Color(0xFF8B2B38);
  static const Color sendBtnBg = Color(0xFFD89CA3);

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ConsultationChatMessage> _messages = [
    const ConsultationChatMessage(
      id: '1',
      text: 'Selamat pagi, Leonita. Ada yang bisa saya bantu hari ini?',
      time: '09:01',
      isFromUser: false,
    ),
    const ConsultationChatMessage(
      id: '2',
      text:
          'Selamat pagi Dok. Saya mau tanya soal flek hitam di pipi kiri saya, sudah sekitar 2 minggu ini muncul.',
      time: '09:02',
      isFromUser: true,
    ),
    const ConsultationChatMessage(
      id: '3',
      text:
          'Flek hitamnya ukurannya kecil atau sudah melebar? Apakah ada rasa gatal atau perih?',
      time: '09:03',
      isFromUser: false,
    ),
    const ConsultationChatMessage(
      id: '4',
      text:
          'Kira-kira sebesar koin, tidak gatal tapi agak kering. Saya juga pakai sunscreen setiap hari.',
      time: '09:04',
      isFromUser: true,
    ),
    const ConsultationChatMessage(
      id: '5',
      text:
          'Baik, kemungkinan ini hiperpigmentasi pasca-inflamasi. Saya sarankan pakai serum Vitamin C di pagi hari dan retinol ringan di malam hari.',
      time: '09:05',
      isFromUser: false,
    ),
    const ConsultationChatMessage(
      id: '6',
      text:
          'Boleh Dok rekomendasinya? Dan berapa lama biasanya sampai terlihat hasilnya?',
      time: '09:06',
      isFromUser: true,
    ),
    const ConsultationChatMessage(
      id: '7',
      text:
          'Untuk hasil optimal biasanya butuh 4-6 minggu. Saya akan kirimkan resepnya setelah konsultasi ini selesai ya.',
      time: '09:07',
      isFromUser: false,
    ),
    const ConsultationChatMessage(
      id: '8',
      text: 'Baik Dok, terima kasih banyak atas penjelasannya!',
      time: '09:08',
      isFromUser: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  /// Pesan konsultasi dari Firestore. Tanpa Firebase, seed demo tetap
  /// dipakai agar UI/tes tidak berubah.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final consultationId = widget.consultationId;
    if (consultationId == null || consultationId.isEmpty) return;
    if (consultationId.contains(RegExp(r'^\d+$'))) return;
    try {
      final items = await ConsultationService.loadMessages(consultationId);
      if (items.isEmpty || !mounted) return;
      setState(() {
        _messages = items.map((m) {
          final senderRole = (m['senderRole'] as String?) ?? '';
          return ConsultationChatMessage(
            id: (m['id'] as String?) ?? '',
            text: (m['text'] as String?) ?? '',
            time: (m['time'] as String?) ?? '',
            isFromUser: senderRole == 'user',
          );
        }).toList();
      });
    } catch (_) {
      // chat tetap menampilkan seed demo bila query gagal
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final consultationId = widget.consultationId;
    if (Backend.useFirebase &&
        consultationId != null &&
        consultationId.isNotEmpty) {
      try {
        await ConsultationService.sendMessage(
          consultationId: consultationId,
          senderId: AuthService.uid ?? 'user',
          senderRole: 'user',
          text: text,
          time: timeStr,
        );
        _textController.clear();
        return;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim pesan: $e')),
        );
        return;
      }
    }

    setState(() {
      _messages.add(
        ConsultationChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          time: timeStr,
          isFromUser: true,
        ),
      );
      _textController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back icon, Doctor Name, Status Badge
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 20.0,
                top: 14.0,
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
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.doctorName,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.status,
                      style: const TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                        color: badgeText,
                      ),
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
                bottom: 8.0,
              ),
            ),

            // Chat Messages List matching image copy 3.png
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildChatBubble(msg);
                },
              ),
            ),

            // Bottom Input Area
            _buildInputArea(),
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

  Widget _buildChatBubble(ConsultationChatMessage msg) {
    final isUser = msg.isFromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isUser ? primaryMaroon : doctorBubbleBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 13.5,
                color: isUser ? Colors.white : doctorBubbleText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              msg.time,
              style: TextStyle(
                fontSize: 10.5,
                color: isUser
                    ? Colors.white.withValues(alpha: 0.75)
                    : const Color(0xFF7A4A52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF0F0F0), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
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
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Ketik pesan...',
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
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: sendBtnBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.send,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
