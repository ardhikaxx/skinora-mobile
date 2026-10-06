import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/empty_state.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../components/realtime_wib_badge.dart';
import '../../services/active_chat_registry.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/consultation_service.dart';
import '../../utils/app_dates.dart';
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
  final String? dateTime;
  final String? scheduleDate;
  final String? scheduleTime;
  final String? dateIso;
  final String? timeStart;
  final String? timeEnd;
  final ValueChanged<int>? onNavigateTab;
  final List<ChatMessageModel>? initialMessages;

  const RuangKonsultasiPenggunaPage({
    super.key,
    this.doctorId,
    this.doctorName = '',
    this.status = '',
    this.consultationId,
    this.dateTime,
    this.scheduleDate,
    this.scheduleTime,
    this.dateIso,
    this.timeStart,
    this.timeEnd,
    this.onNavigateTab,
    this.initialMessages,
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

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];
  StreamSubscription<List<Map<String, dynamic>>>? _msgSub;
  StreamSubscription<Map<String, dynamic>?>? _statusSub;
  Timer? _scheduleTicker;
  String _statusLabel = '';
  String _dateIso = '';
  String _timeStart = '';
  String _timeEnd = '';
  String _scheduleDate = '';
  String _scheduleTime = '';
  bool _isExpired = false;
  bool _hasText = false;

  /// Format jam chat konsisten WIB Indonesia 24 jam: "13.00 WIB".
  String _formatChatTimeWib(String raw) => AppDates.formatChatTimeWib(raw);

  void _parseScheduleString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return;
    if (raw.contains('•')) {
      final parts = raw.split('•');
      final datePart = parts.first.trim();
      final timePart = parts.last.trim();
      _dateIso = datePart;
      _scheduleTime = AppDates.formatRange(timePart, withWib: true);
      final rangeParts = timePart.replaceAll(':', '.').split('-');
      if (rangeParts.isNotEmpty) _timeStart = rangeParts.first.trim();
      if (rangeParts.length > 1) _timeEnd = rangeParts.last.trim();
    } else if (raw.contains(' - ') && !raw.startsWith('202')) {
      final parts = raw.split(' - ');
      final datePart = parts.first.trim();
      final timePart = parts.sublist(1).join(' - ').trim();
      _scheduleDate = datePart;
      _scheduleTime = AppDates.formatRange(timePart, withWib: true);
      final rangeParts = timePart.replaceAll(':', '.').split('-');
      if (rangeParts.isNotEmpty) _timeStart = rangeParts.first.trim();
      if (rangeParts.length > 1) _timeEnd = rangeParts.last.trim();
    } else {
      _scheduleDate = raw;
    }
  }

  void _checkScheduleStatus() {
    if (_dateIso.isEmpty && _scheduleDate.isEmpty) return;
    final past = AppDates.isPastSlot(
      dateIso: _dateIso,
      scheduleDate: _scheduleDate,
      timeEnd: _timeEnd.isNotEmpty ? _timeEnd : _scheduleTime,
      timeStart: _timeStart,
    );
    if (past != _isExpired) {
      if (mounted) {
        setState(() {
          _isExpired = past;
          if (past) {
            _statusLabel = 'Selesai';
          }
        });
      }
    }
  }

  void _applyConsultationDoc(Map<String, dynamic> doc) {
    _dateIso = (doc['dateIso'] as String?) ?? _dateIso;
    _timeStart = (doc['timeStart'] as String?) ?? _timeStart;
    _timeEnd = (doc['timeEnd'] as String?) ?? _timeEnd;
    _scheduleDate = (doc['scheduleDate'] as String?) ?? _scheduleDate;
    final rawSt = (doc['scheduleTime'] as String?) ?? '';
    if (_timeStart.isNotEmpty && _timeEnd.isNotEmpty) {
      _scheduleTime =
          '${AppDates.formatHm(_timeStart)} - ${AppDates.formatHm(_timeEnd)} WIB';
    } else if (rawSt.isNotEmpty) {
      _scheduleTime = AppDates.formatRange(rawSt, withWib: true);
    }
    final raw = (doc['status'] as String?) ?? '';
    final past = (_dateIso.isNotEmpty || _scheduleDate.isNotEmpty) &&
        AppDates.isPastSlot(
          dateIso: _dateIso,
          scheduleDate: _scheduleDate,
          timeEnd: _timeEnd.isNotEmpty ? _timeEnd : _scheduleTime,
          timeStart: _timeStart,
        );
    _isExpired = past;
    final label = (raw.toLowerCase() == 'selesai' || past)
        ? 'Selesai'
        : (raw.toLowerCase() == 'berlangsung' ? 'Berlangsung' : 'Terjadwal');
    if (label != _statusLabel && mounted) {
      setState(() => _statusLabel = label);
    }
  }

  @override
  void initState() {
    super.initState();
    _statusLabel = widget.status;
    _dateIso = widget.dateIso ?? '';
    _scheduleDate = widget.scheduleDate ?? '';
    _timeStart = widget.timeStart ?? '';
    _timeEnd = widget.timeEnd ?? '';
    if (widget.scheduleTime != null && widget.scheduleTime!.isNotEmpty) {
      _scheduleTime = AppDates.formatRange(widget.scheduleTime!, withWib: true);
    } else if (_timeStart.isNotEmpty && _timeEnd.isNotEmpty) {
      _scheduleTime =
          '${AppDates.formatHm(_timeStart)} - ${AppDates.formatHm(_timeEnd)} WIB';
    }
    if (widget.dateTime != null && widget.dateTime!.isNotEmpty) {
      _parseScheduleString(widget.dateTime);
    }
    _checkScheduleStatus();

    _textController.addListener(() {
      final has = _textController.text.trim().isNotEmpty;
      if (has != _hasText && mounted) setState(() => _hasText = has);
    });

    // Pantau jadwal konsultasi secara realtime tiap detik agar saat jam berakhir
    // sesi otomatis ditandai selesai secara real-time.
    _scheduleTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkScheduleStatus();
    });

    // Anti-spam: pesan masuk di ruang yang sedang dibuka tidak memunculkan
    // native notification (chat realtime sudah memberi feedback visual).
    ActiveChatRegistry.open(widget.consultationId);

    if (widget.initialMessages != null) {
      _messages.addAll(widget.initialMessages!);
    }

    final consultationId = widget.consultationId;
    if (Backend.useFirebase &&
        consultationId != null &&
        consultationId.isNotEmpty) {
      ConsultationService.getById(consultationId).then((doc) {
        if (!mounted || doc == null) return;
        _applyConsultationDoc(doc);
      }).catchError((_) {});

      _msgSub = ConsultationService.messageStream(consultationId).listen(
        (items) {
          if (!mounted) return;
          setState(() {
            _messages
              ..clear()
              ..addAll(items.map((m) {
                final senderRole = (m['senderRole'] as String?) ?? '';
                final ts = m['createdAt'] ?? m['time'];
                final timeRaw = AppDates.formatChatTimeWib(ts);
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
      // Badge status live: terjadwal → berlangsung → selesai.
      _statusSub = ConsultationService.streamById(consultationId).listen(
        (doc) {
          if (!mounted || doc == null) return;
          _applyConsultationDoc(doc);
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
    _scheduleTicker?.cancel();
    _msgSub?.cancel();
    _statusSub?.cancel();
    ActiveChatRegistry.close(widget.consultationId);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    // Sesi selesai atau jadwal telah berakhir -> tolak pengiriman.
    if (_statusLabel.toLowerCase() == 'selesai' || _isExpired) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi konsultasi telah berakhir sesuai jadwal. Anda tidak dapat mengirim pesan lagi.'),
        ),
      );
      return;
    }
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Jam kirim selalu WIB 24 jam Indonesia ("13.00 WIB").
    final timeStr = AppDates.formatChatTimeWib(AppDates.nowWib());

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
              // Header: Back icon, Doctor Name, Realtime WIB Badge, Status Badge
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.doctorName,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 17.0,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_scheduleTime.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Jadwal: $_scheduleTime',
                              style: const TextStyle(
                                fontSize: 11.0,
                                color: Color(0xFF8E8E93),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const RealtimeWibBadge(
                      style: RealtimeWibStyle.minimal,
                      includeSeconds: true,
                      showDate: false,
                    ),
                    const SizedBox(width: 6),
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
                        _statusLabel,
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

  /// Empty state ringan di area chat.
  Widget _buildEmptyState() {
    return const ChatEmptyState(
      title: 'Belum ada pesan',
      description: 'Mulai percakapan dengan dokter dengan mengirim pesan.',
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
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _formatChatTimeWib(msg.time),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.75)
                          : const Color(0xFF7A4A52),
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

  /// Bottom Text Input Field and Send Button
  Widget _buildInputArea() {
    final finished = _statusLabel.toLowerCase() == 'selesai' || _isExpired;
    if (finished) {
      final msg = _scheduleTime.isNotEmpty
          ? 'Sesi konsultasi telah berakhir sesuai jadwal ($_scheduleTime). Anda tidak dapat mengirim pesan lagi.'
          : 'Sesi konsultasi telah selesai. Anda tidak dapat mengirim pesan lagi.';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFF0F0F0), width: 1.0),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF8E8E93)),
          ),
        ),
      );
    }
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                // Lebih terang saat ada teks diketik.
                color: _hasText ? primaryMaroon : const Color(0xFFE8C5C8),
                borderRadius: BorderRadius.circular(14),
                boxShadow: _hasText
                    ? [
                        BoxShadow(
                          color: primaryMaroon.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  LucideIcons.send,
                  size: 20,
                  color: _hasText
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
