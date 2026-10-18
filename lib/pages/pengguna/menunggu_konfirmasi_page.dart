import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/backend.dart';
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
  final String? scheduleDate;
  final String? scheduleTime;
  final String? dateIso;
  final String? timeStart;
  final String? timeEnd;
  final ValueChanged<int>? onNavigateTab;

  const MenungguKonfirmasiPage({
    super.key,
    this.consultationId,
    this.doctorId,
    this.doctorName = '',
    this.specialization = '',
    this.dateTime,
    this.scheduleDate,
    this.scheduleTime,
    this.dateIso,
    this.timeStart,
    this.timeEnd,
    this.onNavigateTab,
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
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _subscribeStatus();
  }

  void _subscribeStatus() {
    final cid = widget.consultationId;
    if (cid == null || cid.isEmpty || !Backend.useFirebase) return;

    _statusSub = ConsultationService.streamById(cid).listen((doc) {
      if (!mounted || doc == null) return;
      final st = ((doc['status'] as String?) ?? '').toLowerCase();
      setState(() {
        _isConfirmed = st == 'dikonfirmasi' || st == 'berlangsung';
      });
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  void _goToChatRoom() {
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
                  const Text(
                    'Status Penjadwalan',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20.0,
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
                                color: _isConfirmed
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isConfirmed
                                    ? 'Dikonfirmasi'
                                    : 'Menunggu Konfirmasi',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  color: _isConfirmed
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFB45309),
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
                            color: _isConfirmed
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFFFBEB),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isConfirmed
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFFDE68A),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _isConfirmed
                                  ? LucideIcons.circleCheck
                                  : LucideIcons.clock,
                              size: 34,
                              color: _isConfirmed
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          _isConfirmed
                              ? 'Jadwal Telah Dikonfirmasi'
                              : 'Menunggu Konfirmasi Dokter',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          _isConfirmed
                              ? 'Dokter telah mengonfirmasi jadwal konsultasi Anda. Anda sekarang dapat masuk ke ruang chat dan berkonsultasi langsung.'
                              : 'Jadwal konsultasi Anda telah berhasil dikirim ke dokter. Mohon menunggu konfirmasi dokter sebelum dapat mengirimkan pesan konsultasi.\n\nNotifikasi akan dikirimkan otomatis setelah dokter mengonfirmasi jadwal Anda.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.0,
                            color: subText,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Button
                        if (_isConfirmed) ...[
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
                                'Mulai Konsultasi Langsung',
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
                                    'Pesan chat belum dapat dikirim sampai dokter mengonfirmasi.',
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
