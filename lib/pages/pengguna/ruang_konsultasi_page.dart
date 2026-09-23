import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/consultation_service.dart';
import 'riwayat_konsultasi_page.dart';

class ChatMessageModel {
  final String id;
  final String text;
  final String time;
  final bool isFromUser;

  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.time,
    required this.isFromUser,
  });
}

class RuangKonsultasiPenggunaPage extends StatefulWidget {
  final String? doctorId;
  final String doctorName;
  final String status;
  final String? consultationId;
  final ValueChanged<int>? onNavigateTab;

  const RuangKonsultasiPenggunaPage({
    super.key,
    this.doctorId,
    this.doctorName = 'dr. Anita Dewi, Sp.KK',
    this.status = 'Terjadwal',
    this.consultationId,
    this.onNavigateTab,
  });

  @override
  State<RuangKonsultasiPenggunaPage> createState() =>
      _RuangKonsultasiPenggunaPageState();
}

class _RuangKonsultasiPenggunaPageState
    extends State<RuangKonsultasiPenggunaPage> {
  static const Color darkText = Color(0xFF461220);
  static const Color primaryMaroon = Color(0xFFB23A48);
  static const Color doctorBubbleBg = Color(0xFFFCB9B2);
  static const Color doctorBubbleText = Color(0xFF461220);
  static const Color badgeBg = Color(0xFFFED0BB);
  static const Color badgeText = Color(0xFF8B2B38);
  static const Color sendBtnBg = Color(0xFFD89CA3);

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];
  Stream<List<Map<String, dynamic>>>? _msgSub;

  @override
  void initState() {
    super.initState();
    final consultationId = widget.consultationId;
    if (Backend.useFirebase &&
        consultationId != null &&
        consultationId.isNotEmpty) {
      _msgSub = ConsultationService.messageStream(consultationId);
      _msgSub!.listen(
        (items) {
          if (!mounted) return;
          setState(() {
            _messages
              ..clear()
              ..addAll(items.map((m) {
                final senderRole = (m['senderRole'] as String?) ?? '';
                final timeRaw = (m['time'] as String?) ?? '';
                return ChatMessageModel(
                  id: (m['id'] as String?) ?? '',
                  text: (m['text'] as String?) ?? '',
                  time: timeRaw,
                  isFromUser: senderRole == 'user',
                );
              }));
          });
          _scrollToBottom();
        },
        onError: (_) {},
      );
    }
  }

  void _scrollToBottom() {
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
    final uid = AuthService.uid;
    if (Backend.useFirebase &&
        consultationId != null &&
        consultationId.isNotEmpty &&
        uid != null) {
      try {
        await ConsultationService.sendMessage(
          consultationId: consultationId,
          senderId: uid,
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
        ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          time: timeStr,
          isFromUser: true,
        ),
      );
      _textController.clear();
    });
    _scrollToBottom();
  }

  void _handleExit() {
    // Sesuai instruksi: jika sudah masuk dan ingin keluar maka kembali ke halaman riwayat
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => RiwayatKonsultasiPenggunaPage(
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleExit();
        }
      },
      child: Scaffold(
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
                      onTap: _handleExit,
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

              // Subtle horizontal divider line
              Container(
                height: 1,
                color: const Color(0xFFF0F0F0),
                margin: const EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  bottom: 8.0,
                ),
              ),

              // Chat or Empty State Area
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(),
              ),

              // Bottom Input Box Area
              _buildInputArea(),
            ],
          ),
        ),
        bottomNavigationBar: PenggunaNavBottom(
          currentIndex: -1,
          onTap: (index) {
            _handleExit();
            if (index != 0) {
              widget.onNavigateTab?.call(index);
            }
          },
        ),
      ),
    );
  }

  /// Empty state matching image copy 2.png
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFEBEBEB),
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
            child: const Center(
              child: Icon(
                LucideIcons.messageCircle,
                size: 26,
                color: Color(0xFF6B5E5E),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada pesan',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A4A4A),
            ),
          ),
        ],
      ),
    );
  }

  /// List of messages if any
  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg.isFromUser;
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: isUser ? primaryMaroon : doctorBubbleBg,
              borderRadius: BorderRadius.circular(16),
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
      },
    );
  }

  /// Bottom Text Input Field and Send Button
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
                onSubmitted: (_) {
                  _sendMessage();
                },
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
