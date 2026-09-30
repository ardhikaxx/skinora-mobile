import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/empty_state.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import '../../components/realtime_wib_badge.dart';
import '../../services/active_chat_registry.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/consultation_service.dart';
import '../../utils/app_dates.dart';

class ChatBubbleModel {
  final String id;
  final String text;
  final String time;
  final bool isFromDoctor;

  const ChatBubbleModel({
    required this.id,
    required this.text,
    required this.time,
    required this.isFromDoctor,
  });
}

class RuangChatDokterPage extends StatefulWidget {
  final String patientName;
  final String? consultationId;
  final String? dateTime;
  final String? status;
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;
  final String? scheduleDate;
  final String? scheduleTime;
  final String? dateIso;
  final String? timeStart;
  final String? timeEnd;

  const RuangChatDokterPage({
    super.key,
    this.patientName = '',
    this.consultationId,
    this.dateTime,
    this.status,
    this.onNavigateTab,
    this.showBottomNav = true,
    this.scheduleDate,
    this.scheduleTime,
    this.dateIso,
    this.timeStart,
    this.timeEnd,
  });

  @override
  State<RuangChatDokterPage> createState() => _RuangChatDokterPageState();
}

class _RuangChatDokterPageState extends State<RuangChatDokterPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E1E1E);
  static const Color patientBubbleBg = Color(0xFFFFD5C8);

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<ChatBubbleModel> _messages;
  StreamSubscription<List<Map<String, dynamic>>>? _msgSub;
  StreamSubscription<Map<String, dynamic>?>? _statusSub;
  Timer? _scheduleTicker;
  String _dateIso = '';
  String _scheduleDate = '';
  String _scheduleTime = '';
  String _timeStart = '';
  String _timeEnd = '';
  bool _isExpired = false;
  bool _hasText = false;
  bool _isFinished = false;

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
            _isFinished = true;
          }
        });
      }
      if (past && Backend.useFirebase && widget.consultationId != null && widget.consultationId!.isNotEmpty) {
        ConsultationService.markSelesai(widget.consultationId!);
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
    final status = ((doc['status'] as String?) ?? '').toLowerCase();
    final past = AppDates.isPastSlot(
      dateIso: _dateIso,
      scheduleDate: _scheduleDate,
      timeEnd: _timeEnd.isNotEmpty ? _timeEnd : _scheduleTime,
      timeStart: _timeStart,
    );
    _isExpired = past;
    final finished = status == 'selesai' || past;
    if (finished != _isFinished && mounted) {
      setState(() => _isFinished = finished);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.status?.toLowerCase() == 'selesai') {
      _isFinished = true;
    }
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

    // Pantau jadwal konsultasi tiap detik secara realtime agar saat jam selesai tercapai,
    // input otomatis terkunci dan status berakhir secara real-time.
    _scheduleTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkScheduleStatus();
    });

    _textController.addListener(() {
      final has = _textController.text.trim().isNotEmpty;
      if (has != _hasText && mounted) setState(() => _hasText = has);
    });
    // Anti-spam: pesan masuk di ruang yang sedang dibuka tidak memunculkan
    // native notification (chat realtime sudah memberi feedback visual).
    ActiveChatRegistry.open(widget.consultationId);
    // Seed demo HANYA tanpa Firebase; jam mengikuti waktu real-time WIB terkini.
    final now = AppDates.nowWib();
    final greeting = AppDates.greetingWib();
    _messages = Backend.useFirebase
        ? <ChatBubbleModel>[]
        : <ChatBubbleModel>[
      ChatBubbleModel(
        id: '1',
        text: '$greeting, ${widget.patientName.split(' ').first}. Ada yang bisa saya bantu hari ini?',
        time: AppDates.formatChatTimeWib(now.subtract(const Duration(minutes: 7))),
        isFromDoctor: true,
      ),
      ChatBubbleModel(
        id: '2',
        text: 'Selamat pagi Dok. Saya mau tanya soal flek hitam di pipi kiri saya, sudah sekitar 2 minggu ini muncul.',
        time: AppDates.formatChatTimeWib(now.subtract(const Duration(minutes: 6))),
        isFromDoctor: false,
      ),
      ChatBubbleModel(
        id: '3',
        text: 'Flek hitamnya ukurannya kecil atau sudah melebar? Apakah ada rasa gatal atau perih?',
        time: AppDates.formatChatTimeWib(now.subtract(const Duration(minutes: 5))),
        isFromDoctor: true,
      ),
      ChatBubbleModel(
        id: '4',
        text: 'Kira-kira sebesar koin, tidak gatal tapi agak kering. Saya juga pakai sunscreen setiap hari.',
        time: AppDates.formatChatTimeWib(now.subtract(const Duration(minutes: 4))),
        isFromDoctor: false,
      ),
      ChatBubbleModel(
        id: '5',
        text: 'Baik, kemungkinan ini hiperpigmentasi pasca-inflamasi. Saya sarankan pakai serum Vitamin C di pagi hari dan retinol ringan di malam hari.',
        time: AppDates.formatChatTimeWib(now.subtract(const Duration(minutes: 3))),
        isFromDoctor: true,
      ),
      ChatBubbleModel(
        id: '6',
        text: 'Boleh Dok rekomendasinya? Dan berapa lama biasanya sampai terlihat hasilnya?',
        time: AppDates.formatChatTimeWib(now.subtract(const Duration(minutes: 2))),
        isFromDoctor: false,
      ),
      ChatBubbleModel(
        id: '7',
        text: 'Untuk hasil optimal biasanya butuh 4-6 minggu. Saya akan kirimkan resepnya setelah konsultasi ini selesai ya.',
        time: AppDates.formatChatTimeWib(now.subtract(const Duration(minutes: 1))),
        isFromDoctor: true,
      ),
      ChatBubbleModel(
        id: '8',
        text: 'Baik Dok, terima kasih banyak atas penjelasannya!',
        time: AppDates.formatChatTimeWib(now),
        isFromDoctor: false,
      ),
    ];
    _loadFromBackend();
  }

  /// Streaming pesan dari Firestore. Tanpa Firebase, seed demo tetap
  /// dipakai agar UI/tes tidak berubah.
  void _loadFromBackend() {
    if (!Backend.useFirebase) return;
    final id = widget.consultationId;
    if (id == null || id.isEmpty) {
      _messages = <ChatBubbleModel>[];
      return;
    }
    _msgSub = ConsultationService.messageStream(id).listen(
      (items) {
        if (!mounted) return;
        setState(() {
          _messages = items.map((m) {
            final role = (m['senderRole'] as String?) ?? '';
            final ts = m['createdAt'] ?? m['time'];
            return ChatBubbleModel(
              id: (m['id'] as String?) ?? '',
              text: (m['text'] as String?) ?? '',
              time: AppDates.formatChatTimeWib(ts),
              isFromDoctor: role == 'dokter',
            );
          }).toList();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _messages = <ChatBubbleModel>[]);
      },
    );
    // Cek status saat buka & pantau realtime: jika selesai atau lewat jadwal, kunci input chat.
    ConsultationService.getById(id).then((doc) {
      if (!mounted || doc == null) return;
      _applyConsultationDoc(doc);
    }).catchError((_) {});

    _statusSub = ConsultationService.streamById(id).listen((doc) {
      if (!mounted || doc == null) return;
      _applyConsultationDoc(doc);
    }, onError: (_) {});
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
    if (_isFinished || _isExpired) {
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

    // Persist ke Firestore (stream akan update UI).
    if (Backend.useFirebase) {
      final id = widget.consultationId;
      final uid = AuthService.uid;
      if (id != null && id.isNotEmpty && uid != null) {
        try {
          await ConsultationService.sendMessage(
            consultationId: id,
            senderId: uid,
            senderRole: 'dokter',
            text: text,
            time: timeStr,
          );
          _textController.clear();
          return;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengirim pesan: $e')),
            );
          }
          return;
        }
      }
    }

    setState(() {
      _messages.add(
        ChatBubbleModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          time: timeStr,
          isFromDoctor: true,
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

  /// Screen 3: Dialog "Selesaikan Konsultasi?"
  void _showFinishConfirmationDialog() {
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
                // Header: Warning Icon + Title + Close Button
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.triangleAlert,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Selesaikan Konsultasi?',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
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
                  'Konsultasi akan ditandai selesai.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF4B5563),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons: Batal & Ya, Selesai
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () {
                            // Close confirmation dialog
                            Navigator.pop(dialogContext);
                            // Return true to caller (ChatKonsultasiPage) indicating finished
                            Navigator.pop(context, true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Ya, Selesai',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
          children: [
            // Top Bar: Back icon + Patient Name & Schedule + Live WIB Badge + "Selesai" button
            Padding(
              padding: const EdgeInsets.only(
                left: 14.0,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patientName,
                          style: const TextStyle(
                            fontSize: 16.0,
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
                  const SizedBox(width: 8),

                  // "Selesai" button with check circle icon
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showFinishConfirmationDialog,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 6.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              LucideIcons.circleCheck,
                              size: 16,
                              color: primaryMaroon,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Selesai',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: primaryMaroon,
                              ),
                            ),
                          ],
                        ),
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
            ),

            // Messages List
            Expanded(
              child: _messages.isEmpty
                  ? const ChatEmptyState(
                      title: 'Belum ada pesan',
                      description:
                          'Mulai percakapan dengan pasien dengan mengirim pesan.',
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _buildMessageBubble(msg);
                      },
                    ),
            ),

            // Input bar
            _buildInputBar(),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? DokterNavBottom(
              currentIndex: 2,
              onTap: (index) {
                Navigator.pop(context);
                if (index != 2) {
                  widget.onNavigateTab?.call(index);
                }
              },
            )
          : null,
    );
  }

  /// Single Chat Bubble (Dokter right vs Pasien left)
  Widget _buildMessageBubble(ChatBubbleModel msg) {
    final isDoctor = msg.isFromDoctor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Align(
        alignment: isDoctor ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isDoctor ? primaryMaroon : patientBubbleBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.text,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDoctor ? Colors.white : darkText,
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
                    color: isDoctor
                        ? Colors.white.withValues(alpha: 0.75)
                        : const Color(0xFF757575),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom Input Bar
  Widget _buildInputBar() {
    if (_isFinished || _isExpired) {
      final msg = _scheduleTime.isNotEmpty
          ? 'Sesi konsultasi telah berakhir sesuai jadwal ($_scheduleTime). Anda tidak dapat mengirim pesan lagi.'
          : 'Sesi konsultasi telah selesai. Anda tidak dapat mengirim pesan lagi.';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF0F0F0), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Text field with rounded border
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1.0,
                ),
              ),
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(
                  fontSize: 13.5,
                  color: darkText,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ketik pesan...',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send button — lebih terang saat ada teks diketik.
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hasText ? primaryMaroon : const Color(0xFFF3D5D8),
                shape: BoxShape.circle,
                boxShadow: _hasText
                    ? [
                        BoxShadow(
                          color: primaryMaroon.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  LucideIcons.send,
                  size: 18,
                  color: _hasText
                      ? Colors.white
                      : primaryMaroon.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
