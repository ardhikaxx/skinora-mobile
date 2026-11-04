import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/consultation_service.dart';
import '../../services/schedule_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_dates.dart';
import 'menunggu_konfirmasi_page.dart';

class DoctorScheduleModel {
  final String dayDate;
  final List<String> timeSlots;

  const DoctorScheduleModel({
    required this.dayDate,
    required this.timeSlots,
  });
}

class DoctorProfileDetailModel {
  final String id;
  final String name;
  final String specialization;
  final String experience;
  final String bio;
  final List<DoctorScheduleModel> schedules;

  const DoctorProfileDetailModel({
    required this.id,
    required this.name,
    required this.specialization,
    required this.experience,
    required this.bio,
    required this.schedules,
  });
}

class ProfilDokterPenggunaPage extends StatefulWidget {
  final String? doctorId;
  final String? doctorName;
  final String? specialization;
  final ValueChanged<int>? onNavigateTab;
  final DoctorProfileDetailModel? initialDoctor;
  final List<SlotRecord>? initialSlots;

  const ProfilDokterPenggunaPage({
    super.key,
    this.doctorId,
    this.doctorName,
    this.specialization,
    this.onNavigateTab,
    this.initialDoctor,
    this.initialSlots,
  });

  @override
  State<ProfilDokterPenggunaPage> createState() =>
      _ProfilDokterPenggunaPageState();
}

class _ProfilDokterPenggunaPageState extends State<ProfilDokterPenggunaPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF461220);
  static const Color subText = Color(0xFF8E8E93);
  static const Color dateHeaderColor = Color(0xFF6B5E5E);
  static const Color avatarBg = Color(0xFFFCB9B2);
  static const Color timeChipBg = Color(0xFFFED0BB);

  DoctorProfileDetailModel get _currentDoctor {
    if (_liveDoctor != null) return _liveDoctor!;
    return DoctorProfileDetailModel(
      id: widget.doctorId ?? '',
      name: widget.doctorName ?? '-',
      specialization: widget.specialization ?? '-',
      experience: '',
      bio: '',
      schedules: const [],
    );
  }

  DoctorProfileDetailModel? _liveDoctor;
  List<SlotRecord> _availableSlots = const [];
  StreamSubscription<List<SlotRecord>>? _slotSub;
  Map<String, Map<String, dynamic>> _myConsultationsBySlotId = {};
  StreamSubscription<List<Map<String, dynamic>>>? _patientConsultationsSub;

  @override
  void initState() {
    super.initState();
    if (widget.initialDoctor != null) {
      _liveDoctor = widget.initialDoctor;
    }
    if (widget.initialSlots != null) {
      _availableSlots = widget.initialSlots!;
      _applySlotsToDoctor(widget.initialSlots!);
    }
    _loadFromBackend();
    _listenPatientConsultations();
  }

  @override
  void dispose() {
    _slotSub?.cancel();
    _patientConsultationsSub?.cancel();
    super.dispose();
  }

  void _listenPatientConsultations() {
    final patientUid =
        AuthService.uid ?? (Backend.useFirebase ? null : 'user_local');
    if (patientUid == null || patientUid.isEmpty) return;
    _patientConsultationsSub?.cancel();
    _patientConsultationsSub =
        ConsultationService.streamForPatient(patientUid).listen(
      (items) {
        if (!mounted) return;
        final map = <String, Map<String, dynamic>>{};
        final currentDocId = widget.doctorId ?? _liveDoctor?.id ?? '';
        for (final item in items) {
          final docId = item['doctorId'] as String? ?? '';
          if (currentDocId.isEmpty || docId == currentDocId) {
            final slotId = item['slotId'] as String? ?? '';
            final status = (item['status'] as String? ?? '').toLowerCase();
            if (status != 'selesai' && status != 'dibatalkan') {
              if (status == 'menunggu_konfirmasi') {
                final dIso = item['dateIso'] as String? ?? '';
                final sDate = item['scheduleDate'] as String? ?? '';
                final ts = item['timeStart'] as String? ?? '';
                final te = item['timeEnd'] as String? ?? '';
                if (AppDates.isPastSlot(
                  dateIso: dIso,
                  scheduleDate: sDate,
                  timeStart: ts,
                  timeEnd: te,
                )) {
                  final id = item['id'] as String? ?? '';
                  if (id.isNotEmpty) {
                    unawaited(ConsultationService.autoCancelExpiredConsultation(id));
                  }
                  continue;
                }
              }
              if (slotId.isNotEmpty) {
                map[slotId] = item;
              }
              final date = item['scheduleDate'] as String? ?? '';
              final time = item['scheduleTime'] as String? ?? '';
              if (date.isNotEmpty && time.isNotEmpty) {
                map['${date}_$time'] = item;
              }
            }
          }
        }
        setState(() {
          _myConsultationsBySlotId = map;
        });
      },
      onError: (_) {},
    );
  }

  Map<String, dynamic>? _findMyConsultation(
    SlotRecord? slot,
    String time,
    String dayDate,
  ) {
    if (slot != null && _myConsultationsBySlotId.containsKey(slot.id)) {
      return _myConsultationsBySlotId[slot.id];
    }
    final key = '${dayDate}_$time';
    if (_myConsultationsBySlotId.containsKey(key)) {
      return _myConsultationsBySlotId[key];
    }
    final currentUid =
        AuthService.uid ?? (Backend.useFirebase ? null : 'user_local');
    if (currentUid != null && currentUid.isNotEmpty && slot != null) {
      if (slot.patientId == currentUid || slot.patientIds.contains(currentUid)) {
        return _myConsultationsBySlotId[slot.id] ??
            {
              'id': '${slot.id}_$currentUid',
              'slotId': slot.id,
              'doctorId': slot.doctorId,
              'status': 'menunggu_konfirmasi',
              'scheduleDate': slot.date,
              'scheduleTime': slot.time,
            };
      }
    }
    return null;
  }

  /// Profil dokter sekali + stream slot realtime dari Firestore.
  Future<void> _loadFromBackend() async {
    if (widget.initialSlots != null) return;
    if (!Backend.useFirebase) return;
    final doctorId = widget.doctorId;
    if (doctorId == null || doctorId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _liveDoctor = null;
        _availableSlots = const [];
      });
      return;
    }

    _slotSub?.cancel();
    // Membaca semua slot dokter agar pasien dapat melihat pembagian sesi,
    // sisa kuota tiap sesi, maupun status sesi yang sudah penuh/selesai.
    _slotSub = ScheduleService.slotStream(doctorId).listen(
      (slots) {
        if (!mounted) return;
        setState(() {
          _availableSlots = slots;
          _applySlotsToDoctor(slots);
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _availableSlots = const [];
          _applySlotsToDoctor(const []);
        });
      },
    );

    try {
      final profile = await UserService.loadByUid(doctorId);
      if (!mounted) return;
      setState(() {
        final name = profile?.name ?? '';
        final specialization = profile?.specialization ?? '';
        final experience = profile?.experience ?? '';
        final bio = profile?.bio ?? '';
        final currentSchedules = _liveDoctor?.schedules ?? const [];
        _liveDoctor = DoctorProfileDetailModel(
          id: doctorId,
          name: name.isNotEmpty
              ? name
              : (widget.doctorName?.isNotEmpty ?? false
                  ? widget.doctorName!
                  : '-'),
          specialization: specialization.isNotEmpty
              ? specialization
              : (widget.specialization?.isNotEmpty ?? false
                  ? widget.specialization!
                  : '-'),
          experience: experience.isNotEmpty ? 'Pengalaman: $experience' : '',
          bio: bio,
          schedules: currentSchedules,
        );
        _applySlotsToDoctor(_availableSlots);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liveDoctor = null;
        _availableSlots = const [];
      });
    }
  }

  /// Bangun jadwal tampil dengan format pembagian sesi waktu (misal "09.00 - 09.15").
  void _applySlotsToDoctor(List<SlotRecord> slots) {
    final byDate = <String, List<String>>{};
    final order = <String>[];
    for (final s in slots) {
      final display = s.time.isNotEmpty
          ? AppDates.formatRange(s.time)
          : AppDates.formatHm(s.timeStart);
      byDate.putIfAbsent(s.date, () {
        order.add(s.date);
        return <String>[];
      }).add(display);
    }
    final base = _liveDoctor;
    _liveDoctor = DoctorProfileDetailModel(
      id: base?.id ?? widget.doctorId ?? '',
      name: base?.name ?? widget.doctorName ?? '-',
      specialization: base?.specialization ?? widget.specialization ?? '-',
      experience: base?.experience ?? '',
      bio: base?.bio ?? '',
      schedules: [
        for (final date in order)
          DoctorScheduleModel(
            dayDate: date.toUpperCase(),
            timeSlots: byDate[date]!,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = _liveDoctor ?? _currentDoctor;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Back icon and "Profil Dokter" title
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 20.0,
                top: 16.0,
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
                  const SizedBox(width: 8),
                  const Text(
                    'Profil Dokter',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                bottom: 16.0,
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 1. Doctor Info Card
                  _buildDoctorCard(doctor),

                  const SizedBox(height: 20.0),

                  // 2. Section Title: "JADWAL TERSEDIA"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'JADWAL TERSEDIA',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Maks. 1 Konsultasi / Hari',
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14.0),

                  // 4. Schedule Cards
                  if (doctor.schedules.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: const Center(
                        child: Text(
                          'Belum ada jadwal konsultasi yang dibuka oleh dokter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.0,
                            color: subText,
                          ),
                        ),
                      ),
                    )
                  else
                    ...doctor.schedules.map(
                      (schedule) => _buildScheduleCard(schedule, doctor),
                    ),

                  const SizedBox(height: 16.0),
                ],
              ),
            ),
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

  /// Top Doctor Info Card
  Widget _buildDoctorCard(DoctorProfileDetailModel doctor) {
    return Container(
      padding: const EdgeInsets.all(18.0),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: avatarBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    'd',
                    style: TextStyle(
                      color: primaryMaroon,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialization,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: primaryMaroon,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.experience,
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
          if (doctor.bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              doctor.bio,
              style: const TextStyle(
                fontSize: 13.5,
                color: darkText,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Day Schedule Card with Time Slot Chips
  Widget _buildScheduleCard(
    DoctorScheduleModel schedule,
    DoctorProfileDetailModel doctor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      padding: const EdgeInsets.all(18.0),
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
          Text(
            schedule.dayDate,
            style: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: dateHeaderColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14.0),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: schedule.timeSlots.map((time) {
              return _buildTimeChip(time, schedule.dayDate, doctor);
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Single Time Slot Chip (menampilkan sesi waktu misal "09.15 - 09.30" & sisa kuota)
  Widget _buildTimeChip(
    String time,
    String dayDate,
    DoctorProfileDetailModel doctor,
  ) {
    final slot = _findSlot(time, dayDate);
    final myConsultation = _findMyConsultation(slot, time, dayDate);
    final isMyBooking = myConsultation != null;
    final myStatus =
        (myConsultation?['status'] as String? ?? '').toLowerCase();
    final isConfirmed =
        myStatus == 'dikonfirmasi' || myStatus == 'berlangsung';

    final isFull = slot?.isFull ?? false;
    final slotDate = slot?.date.isNotEmpty == true ? slot!.date : dayDate;
    final timeStart = slot?.timeStart.isNotEmpty == true
        ? slot!.timeStart
        : time.split('-').first.trim();
    final timeEnd = slot?.timeEnd.isNotEmpty == true
        ? slot!.timeEnd
        : (time.contains('-') ? time.split('-').last.trim() : '');

    final isPastBooking = AppDates.isSlotPastBooking(
      dateIso: slot?.dateIso ?? '',
      scheduleDate: slotDate,
      timeStart: timeStart,
      timeEnd: timeEnd,
    );
    final isSlotEnded = AppDates.isPastSlot(
      dateIso: slot?.dateIso ?? '',
      scheduleDate: slotDate,
      timeStart: timeStart,
      timeEnd: timeEnd,
    );
    final isExpired = isSlotEnded;
    final remaining = slot?.remainingQuota ?? 1;

    Color bgColor = timeChipBg;
    Color textColor = darkText;
    String statusBadge = 'Sisa $remaining kuota';
    Color statusColor = const Color(0xFFC2410C);

    if (isSlotEnded) {
      // Jadwal sesi sudah berakhir/lewat
      bgColor = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF9CA3AF);
      statusBadge = 'Selesai';
      statusColor = const Color(0xFF9CA3AF);
    } else if (isMyBooking) {
      if (isConfirmed) {
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        statusBadge = 'Terverifikasi';
        statusColor = const Color(0xFF16A34A);
      } else if (isPastBooking) {
        // Belum diverifikasi dokter dan jam mulai konsultasi sudah tiba/lewat
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF9CA3AF);
        statusBadge = 'Selesai';
        statusColor = const Color(0xFF9CA3AF);
      } else {
        bgColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFC2410C);
        statusBadge = 'Menunggu Verifikasi';
        statusColor = const Color(0xFFD97706);
      }
    } else if (isPastBooking) {
      // Belum dibooking, tetapi jam mulai konsultasi sudah tiba/lewat
      bgColor = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF9CA3AF);
      statusBadge = 'Selesai';
      statusColor = const Color(0xFF9CA3AF);
    } else if (isFull) {
      bgColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFB91C1C);
      statusBadge = 'Penuh';
      statusColor = const Color(0xFFB91C1C);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onTimeSlotTapped(time, dayDate, doctor),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14.0,
            vertical: 8.0,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: isMyBooking
                ? Border.all(
                    color: isConfirmed
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFDBA74),
                    width: 1.2,
                  )
                : (isFull || isExpired
                    ? Border.all(
                        color: isFull
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFE5E7EB),
                        width: 1,
                      )
                    : null),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusBadge,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cari slot pada daftar realtime yang cocok dengan chip yang diketuk.
  SlotRecord? _findSlot(String time, String dayDate) {
    for (final s in _availableSlots) {
      final sDate = s.date.toUpperCase();
      final sTime = AppDates.formatHm(
        s.timeStart.isNotEmpty ? s.timeStart : s.time,
      );
      final sRange = s.time.isNotEmpty ? AppDates.formatRange(s.time) : '';
      if (sDate == dayDate &&
          (sTime == time || sRange == time || s.time == time)) {
        return s;
      }
    }
    return null;
  }

  /// Dialog edukatif: Dibatasi 1 pasien hanya bisa konsultasi sekali dalam satu hari
  /// agar pasien lainnya kebagian antrean/jadwal.
  Future<void> _showDailyLimitDialog(String slotDate) {
    return showDialog<void>(
      context: context,
      builder: (dContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD5C8),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.calendarDays,
                      size: 28,
                      color: primaryMaroon,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Batas 1 Konsultasi per Hari',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Anda sudah memiliki jadwal konsultasi pada tanggal $slotDate.\n\n'
                  'Untuk memberikan kesempatan yang adil bagi pasien lainnya, '
                  'setiap pasien dibatasi maksimal 1 kali konsultasi per hari.\n\n'
                  'Silakan pilih tanggal lain atau cek jadwal konsultasi Anda di menu Riwayat.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B5E5E),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryMaroon,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Pilih Tanggal Lain',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  /// Menampilkan dialog menunggu konfirmasi dokter saat booking baru,
  /// atau langsung ke halaman konfirmasi jika slot sudah dibooking.
  Future<void> _onTimeSlotTapped(
    String time,
    String dayDate,
    DoctorProfileDetailModel doctor,
  ) async {
    final slot = _findSlot(time, dayDate);
    final slotDate = slot?.date.isNotEmpty == true ? slot!.date : dayDate;
    final startTime = AppDates.formatHm(
      slot?.timeStart.isNotEmpty == true
          ? slot!.timeStart
          : (slot?.time.split('-').first.trim() ??
              time.split('-').first.trim()),
    );
    final endTime = slot?.timeEnd.isNotEmpty == true
        ? slot!.timeEnd
        : (time.contains('-') ? time.split('-').last.trim() : '');

    final isPastBooking = AppDates.isSlotPastBooking(
      dateIso: slot?.dateIso ?? '',
      scheduleDate: slotDate,
      timeStart: startTime,
      timeEnd: endTime,
    );
    final isSlotEnded = AppDates.isPastSlot(
      dateIso: slot?.dateIso ?? '',
      scheduleDate: slotDate,
      timeStart: startTime,
      timeEnd: endTime,
    );

    final myConsultation = _findMyConsultation(slot, time, dayDate);
    final myStatus =
        (myConsultation?['status'] as String? ?? '').toLowerCase();
    final isConfirmed =
        myStatus == 'dikonfirmasi' || myStatus == 'berlangsung';

    // 1. Validasi sesi sudah lewat/berakhir
    if (isSlotEnded) {
      if (myConsultation != null && myStatus == 'menunggu_konfirmasi') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Jadwal konsultasi sesi $time pada $slotDate sudah kadaluarsa karena telah melewati jam konsultasi. Silakan pilih jadwal lain yang masih tersedia.',
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jadwal sesi $time pada $slotDate sudah berakhir dan tidak dapat dipilih.',
          ),
        ),
      );
      return;
    }

    // 2. Jika pengguna sudah membooking jadwal ini:
    // Jika belum dikonfirmasi dokter dan jam sesi konsultasi sudah lewat (misal lewat jam 09.15 di jam 19.16),
    // batalkan otomatis dan kembalikan kuota harian.
    if (myConsultation != null) {
      if (!isConfirmed && (isSlotEnded || isPastBooking)) {
        final cid = myConsultation['id'] as String?;
        if (cid != null && cid.isNotEmpty) {
          unawaited(ConsultationService.autoCancelExpiredConsultation(cid));
        }
        setState(() {
          _myConsultationsBySlotId.remove(slot?.id);
          _myConsultationsBySlotId.remove('${slotDate}_$time');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Jadwal sesi $time pada $slotDate telah dibatalkan otomatis karena melewati jam konsultasi sebelum diverifikasi oleh dokter. Kuota konsultasi Anda hari ini telah dikembalikan.',
            ),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MenungguKonfirmasiPage(
            doctorId: doctor.id,
            doctorName: doctor.name,
            specialization: doctor.specialization,
            consultationId: myConsultation['id'] as String?,
            onNavigateTab: widget.onNavigateTab,
            dateTime: '$slotDate • $startTime WIB',
            scheduleDate: slotDate,
            scheduleTime: slot?.time.isNotEmpty == true ? slot!.time : time,
            dateIso: slot?.dateIso ?? '',
            timeStart: startTime,
            timeEnd: endTime,
            initialIsConfirmed: isConfirmed,
          ),
        ),
      );
      return;
    }

    // 3. Validasi jam booking sudah lewat (misal sekarang sudah >= jam 15.30):
    // Pasien hanya dapat memilih sebelum jam konsultasi dimulai.
    if (isPastBooking) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jadwal sesi $time pada $slotDate sudah melewati jam mulainya ($startTime WIB). Silakan pilih jadwal sesi lainnya.',
          ),
        ),
      );
      return;
    }

    if (slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Jadwal ini sudah tidak tersedia. Silakan pilih jadwal lain.',
          ),
        ),
      );
      return;
    }

    // 4. Validasi sesi sudah penuh (mencapai batas limit kuota pasien)
    if (slot.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sesi $time sudah penuh (kuota ${slot.quota} pasien telah terpenuhi). Silakan pilih sesi lainnya.',
          ),
        ),
      );
      return;
    }

    // 5. Validasi aturan: Dibatasi 1 pasien hanya bisa konsultasi sekali dalam satu hari
    final currentPatient =
        Backend.useFirebase ? await AuthService.loadProfile() : null;
    final authUser =
        Backend.useFirebase ? FirebaseAuth.instance.currentUser : null;
    final patientUid = (currentPatient?.uid.isNotEmpty == true &&
            currentPatient!.uid != 'user_local')
        ? currentPatient.uid
        : (AuthService.uid ?? authUser?.uid);
    if (patientUid != null && patientUid.isNotEmpty) {
      final alreadyBookedToday =
          await ConsultationService.hasConsultationOnDate(
        patientUid: patientUid,
        dateIso: slot.dateIso,
        scheduleDate: slotDate,
      );
      if (alreadyBookedToday) {
        if (!mounted) return;
        await _showDailyLimitDialog(slotDate);
        return;
      }
    }

    // 6. Tampilkan dialog proses pengajuan booking
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFED0BB),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(primaryMaroon),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Menunggu Konfirmasi Dokter...',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mengajukan jadwal ke ${doctor.name} untuk jadwal $slotDate pukul $startTime WIB. Mohon menunggu konfirmasi dokter.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B5E5E),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    String? consultationId;
    String bookingError = '';
    final effectivePatientUid = patientUid ?? 'user_local';
    final effectivePatientName = (currentPatient?.name.isNotEmpty == true &&
            currentPatient!.name != 'Pasien')
        ? currentPatient.name
        : (authUser?.displayName?.isNotEmpty == true
            ? authUser!.displayName!
            : (currentPatient?.name.isNotEmpty == true
                ? currentPatient!.name
                : 'Pasien'));
    final effectivePatientEmail = (currentPatient?.email.isNotEmpty == true)
        ? currentPatient!.email
        : (authUser?.email ?? 'pasien@skinora.com');

    final patientToBook = UserProfile(
      docId: effectivePatientUid,
      uid: effectivePatientUid,
      name: effectivePatientName,
      email: effectivePatientEmail,
      role: currentPatient?.role.isNotEmpty == true
          ? currentPatient!.role
          : 'pengguna',
    );

    try {
      consultationId = await ConsultationService.book(
        doctorUid: doctor.id,
        doctorName: doctor.name,
        specialization: doctor.specialization,
        slotId: slot.id,
        scheduleDate: slotDate,
        scheduleTime: slot.time,
        patient: patientToBook,
        dateIso: slot.dateIso,
        timeStart: startTime,
        timeEnd: endTime,
      );
    } catch (e) {
      final msg = e.toString();
      final lowered = msg.toLowerCase();
      if (msg.contains('maksimal 1 kali konsultasi') ||
          msg.contains('sudah memiliki jadwal')) {
        bookingError =
            'Anda sudah memiliki jadwal konsultasi pada hari ini. Maksimal 1 konsultasi per hari agar pasien lainnya kebagian jadwal.';
      } else if (msg.contains('penuh') || lowered.contains('penuh')) {
        bookingError =
            'Slot jadwal sudah penuh untuk sesi ini. Silakan pilih sesi lain.';
      } else if (msg.contains('dibooking') ||
          lowered.contains('already booked')) {
        bookingError =
            'Slot sudah dibooking oleh pasien lain. Silakan pilih jadwal lain.';
      } else if (lowered.contains('permission-denied')) {
        bookingError =
            'Gagal memesan jadwal karena akses ditolak. Silakan coba lagi.';
      } else {
        bookingError = 'Gagal memesan jadwal: $msg';
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (bookingError.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bookingError)),
      );
      return;
    }

    final confirmedId = consultationId ?? '${slot.id}_${patientToBook.uid}';
    setState(() {
      final map = {
        'id': confirmedId,
        'slotId': slot.id,
        'status': 'menunggu_konfirmasi',
        'scheduleDate': slotDate,
        'scheduleTime': slot.time,
        'doctorId': doctor.id,
      };
      _myConsultationsBySlotId[slot.id] = map;
      _myConsultationsBySlotId['${slotDate}_$time'] = map;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenungguKonfirmasiPage(
          doctorId: doctor.id,
          doctorName: doctor.name,
          specialization: doctor.specialization,
          consultationId: confirmedId,
          onNavigateTab: widget.onNavigateTab,
          dateTime: '$slotDate • $startTime WIB',
          scheduleDate: slotDate,
          scheduleTime: slot.time.isNotEmpty ? slot.time : time,
          dateIso: slot.dateIso,
          timeStart: startTime,
          timeEnd: endTime,
          initialIsConfirmed: false,
        ),
      ),
    );
  }
}
