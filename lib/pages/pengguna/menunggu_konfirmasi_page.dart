import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/consultation_service.dart';
import '../../utils/app_dates.dart';
import 'riwayat_konsultasi_page.dart';
import 'ruang_konsultasi_page.dart';

class MenungguKonfirmasiPage extends StatefulWidget {
  final String? consultationId;
  final String? doctorId;
  final String doctorName;
  final String specialization;
  final String? dateTime;
  final String? status;
  final String? scheduleDate;
  final String? scheduleTime;
  final String? dateIso;
  final String? timeStart;
  final String? timeEnd;
  final ValueChanged<int>? onNavigateTab;
  final bool initialIsConfirmed;

  const MenungguKonfirmasiPage({
    super.key,
    this.consultationId,
    this.doctorId,
    this.doctorName = '',
    this.specialization = '',
    this.dateTime,
    this.status,
    this.scheduleDate,
    this.scheduleTime,
    this.dateIso,
    this.timeStart,
    this.timeEnd,
    this.onNavigateTab,
    this.initialIsConfirmed = false,
  });

  @override
  State<MenungguKonfirmasiPage> createState() => _MenungguKonfirmasiPageState();
}

class _MenungguKonfirmasiPageState extends State<MenungguKonfirmasiPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color cardBorder = Color(0xFFEEEEEE);
  static const Color peachIconBg = Color(0xFFFFD5C8);

  StreamSubscription<Map<String, dynamic>?>? _statusSub;
  Timer? _expirationCheckTimer;
  bool _isConfirmed = false;
  bool _isCancelledOrExpired = false;
  String _cancelReason = '';
  String _liveStatus = '';
  String _liveDateIso = '';
  String _liveScheduleDate = '';
  String _liveTimeStart = '';
  String _liveTimeEnd = '';
  String _liveScheduleTime = '';

  bool get _isUpcoming {
    if (!_isConfirmed) return false;
    final st = (_liveStatus.isNotEmpty ? _liveStatus : widget.status)?.toLowerCase();
    if (st == 'berlangsung') return false;

    final dateIso = _liveDateIso.isNotEmpty ? _liveDateIso : (widget.dateIso ?? '');
    final schedDate = _liveScheduleDate.isNotEmpty ? _liveScheduleDate : widget.scheduleDate;
    final tStart = _liveTimeStart.isNotEmpty ? _liveTimeStart : widget.timeStart;
    final tEnd = _liveTimeEnd.isNotEmpty ? _liveTimeEnd : widget.timeEnd;
    final schedTime = _liveScheduleTime.isNotEmpty ? _liveScheduleTime : widget.scheduleTime;

    return AppDates.isSlotUpcoming(
      dateIso: dateIso,
      scheduleDate: schedDate,
      scheduleTime: schedTime,
      timeStart: tStart,
      timeEnd: tEnd,
    );
  }

  @override
  void initState() {
    super.initState();
    _isConfirmed = widget.initialIsConfirmed;
    _checkTimeExpiration();
    _subscribeStatus();
    _expirationCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _checkTimeExpiration();
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void didUpdateWidget(covariant MenungguKonfirmasiPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIsConfirmed != oldWidget.initialIsConfirmed) {
      setState(() {
        _isConfirmed = widget.initialIsConfirmed;
      });
    }
  }

  void _checkTimeExpiration() {
    if (_isConfirmed || _isCancelledOrExpired) return;
    final isExpired = AppDates.isPastSlot(
      dateIso: widget.dateIso ?? '',
      scheduleDate: widget.scheduleDate,
      timeStart: widget.timeStart,
      timeEnd: widget.timeEnd,
    );
    if (isExpired) {
      final cid = widget.consultationId;
      if (cid != null && cid.isNotEmpty) {
        unawaited(ConsultationService.autoCancelExpiredConsultation(cid));
      }
      if (mounted) {
        setState(() {
          _isCancelledOrExpired = true;
          _isConfirmed = false;
        });
      }
    }
  }

  void _subscribeStatus() {
    final cid = widget.consultationId;
    if (cid == null || cid.isEmpty) {
      _checkTimeExpiration();
      return;
    }

    _statusSub = ConsultationService.streamById(cid).listen((doc) {
      if (!mounted || doc == null) return;
      final st = ((doc['status'] as String?) ?? '').toLowerCase();
      final dateIso = (doc['dateIso'] as String?) ?? widget.dateIso ?? '';
      final schedDate =
          (doc['scheduleDate'] as String?) ?? widget.scheduleDate ?? '';
      final tStart = (doc['timeStart'] as String?) ?? widget.timeStart ?? '';
      final tEnd = (doc['timeEnd'] as String?) ?? widget.timeEnd ?? '';
      final schedTime =
          (doc['scheduleTime'] as String?) ?? widget.scheduleTime ?? '';

      _liveStatus = st;
      _liveDateIso = dateIso;
      _liveScheduleDate = schedDate;
      _liveTimeStart = tStart;
      _liveTimeEnd = tEnd;
      _liveScheduleTime = schedTime;

      final isExpired = AppDates.isPastSlot(
        dateIso: dateIso,
        scheduleDate: schedDate,
        timeStart: tStart,
        timeEnd: tEnd,
      );

      if (st == 'dibatalkan' || (st == 'menunggu_konfirmasi' && isExpired)) {
        if (st == 'menunggu_konfirmasi' && isExpired) {
          unawaited(ConsultationService.autoCancelExpiredConsultation(cid));
        }
        setState(() {
          _isConfirmed = false;
          _isCancelledOrExpired = true;
          _cancelReason = (doc['cancelReason'] as String?) ??
              'Jadwal konsultasi telah kedaluwarsa karena melewati jam konsultasi sebelum diverifikasi oleh dokter. Kuota konsultasi Anda hari ini telah dikembalikan.';
        });
      } else {
        setState(() {
          _isConfirmed = st == 'dikonfirmasi' || st == 'berlangsung' || st == 'terjadwal';
          _isCancelledOrExpired = false;
        });
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _expirationCheckTimer?.cancel();
    super.dispose();
  }

  void _goToChatRoom() {
    if (_isUpcoming) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Konsultasi belum dapat dimulai karena belum memasuki jam jadwal konsultasi.',
          ),
          backgroundColor: primaryMaroon,
        ),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RuangKonsultasiPenggunaPage(
          consultationId: widget.consultationId,
          doctorId: widget.doctorId,
          doctorName: widget.doctorName,
          status: _isConfirmed ? 'Dikonfirmasi' : 'Menunggu Konfirmasi',
          dateTime: widget.dateTime,
          scheduleDate: widget.scheduleDate,
          scheduleTime: widget.scheduleTime,
          dateIso: widget.dateIso,
          timeStart: widget.timeStart,
          timeEnd: widget.timeEnd,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );
  }

  void _goToRiwayat() {
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
    final scheduleDisplay = (widget.dateTime != null && widget.dateTime!.isNotEmpty)
        ? widget.dateTime!
        : ((widget.scheduleDate ?? '') +
            (widget.scheduleTime != null && widget.scheduleTime!.isNotEmpty
                ? ' • ${AppDates.formatRange(widget.scheduleTime!, withWib: true)}'
                : ''));

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Header Top Bar
            Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
                right: 20.0,
                top: 14.0,
                bottom: 10.0,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        _goToRiwayat();
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(
                        LucideIcons.chevronLeft,
                        size: 22,
                        color: darkText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isConfirmed
                        ? 'Jadwal Terverifikasi'
                        : 'Menunggu Verifikasi Dokter',
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 19.0,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _goToRiwayat,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        'Riwayat',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: primaryMaroon,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(bottom: 16.0),
            ),

            // Main Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 1. Doctor Information Card
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder, width: 1.0),
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
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: peachIconBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(
                              LucideIcons.stethoscope,
                              color: primaryMaroon,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.doctorName.isNotEmpty
                                    ? widget.doctorName
                                    : 'Dokter Spesialis Kulit',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.specialization.isNotEmpty
                                    ? widget.specialization
                                    : 'Spesialis Kulit & Kelamin',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: subText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Schedule & Status Banner
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder, width: 1.0),
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
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.calendar,
                              size: 16,
                              color: subText,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                scheduleDisplay.isNotEmpty
                                    ? scheduleDisplay
                                    : 'Jadwal Konsultasi',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: darkText,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isCancelledOrExpired
                                    ? const Color(0xFFFEE2E2)
                                    : (_isConfirmed
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEF3C7)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isCancelledOrExpired
                                    ? 'Kedaluwarsa'
                                    : (_isConfirmed
                                        ? 'Terverifikasi'
                                        : 'Menunggu Verifikasi'),
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  color: _isCancelledOrExpired
                                      ? const Color(0xFFB91C1C)
                                      : (_isConfirmed
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFB45309)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Status Illustration & Description Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 28.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: cardBorder, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Circular Icon Indicator
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _isCancelledOrExpired
                                ? const Color(0xFFFEE2E2)
                                : (_isConfirmed
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFFFBEB)),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isCancelledOrExpired
                                  ? const Color(0xFFFECACA)
                                  : (_isConfirmed
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFFFDE68A)),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _isCancelledOrExpired
                                  ? LucideIcons.calendarX
                                  : (_isConfirmed
                                      ? LucideIcons.circleCheck
                                      : LucideIcons.clock),
                              size: 34,
                              color: _isCancelledOrExpired
                                  ? const Color(0xFFDC2626)
                                  : (_isConfirmed
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFD97706)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          _isCancelledOrExpired
                              ? 'Jadwal Kedaluwarsa'
                              : (_isConfirmed
                                  ? 'Jadwal Telah Diverifikasi'
                                  : 'Menunggu Verifikasi Dokter'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          _isCancelledOrExpired
                              ? (_cancelReason.isNotEmpty
                                  ? _cancelReason
                                  : 'Jadwal konsultasi Anda telah kedaluwarsa karena telah melewati jam mulai konsultasi sebelum dikonfirmasi oleh dokter.\n\nKuota konsultasi Anda hari ini telah dikembalikan. Anda dapat memilih jadwal konsultasi lain sekarang.')
                              : (_isConfirmed
                                  ? (_isUpcoming
                                      ? 'Dokter telah memverifikasi jadwal konsultasi Anda. Mohon menunggu hingga jam jadwal konsultasi dimulai untuk dapat memasuki ruangan chat konsultasi.\n\nTombol mulai konsultasi akan aktif secara otomatis saat jam jadwal dimulai.'
                                      : 'Dokter telah memverifikasi jadwal konsultasi Anda dan jam konsultasi telah dimulai. Anda sekarang dapat memasuki ruangan chat konsultasi.')
                                  : 'Jadwal konsultasi Anda telah berhasil diajukan ke dokter. Mohon menunggu verifikasi dokter sebelum memasuki ruangan chat konsultasi.\n\nNotifikasi akan dikirimkan otomatis setelah dokter memverifikasi jadwal Anda.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.0,
                            color: subText,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Button
                        if (_isCancelledOrExpired) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                LucideIcons.calendar,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Pilih Jadwal Lain',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryMaroon,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton(
                              onPressed: _goToRiwayat,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: primaryMaroon,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Lihat Riwayat Konsultasi',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: primaryMaroon,
                                ),
                              ),
                            ),
                          ),
                        ] else if (_isConfirmed) ...[
                          if (_isUpcoming) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(
                                  LucideIcons.clock,
                                  size: 18,
                                  color: Color(0xFF9CA3AF),
                                ),
                                label: const Text(
                                  'Mulai Konsultasi',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE5E7EB),
                                  disabledBackgroundColor:
                                      const Color(0xFFE5E7EB),
                                  disabledForegroundColor:
                                      const Color(0xFF9CA3AF),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tombol akan aktif otomatis saat jam jadwal konsultasi dimulai',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Color(0xFF8E8E93),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _goToChatRoom,
                                icon: const Icon(
                                  LucideIcons.messageSquare,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Mulai Konsultasi',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryMaroon,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7F8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E5EA),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  LucideIcons.info,
                                  size: 16,
                                  color: subText,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Pesan chat dapat diakses setelah dokter memverifikasi jadwal Anda.',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: subText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton(
                              onPressed: _goToRiwayat,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: primaryMaroon,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Lihat Riwayat Konsultasi',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: primaryMaroon,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
