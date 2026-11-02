import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../models/doctor_practice_settings.dart';
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

  const ProfilDokterPenggunaPage({
    super.key,
    this.doctorId,
    this.doctorName,
    this.specialization,
    this.onNavigateTab,
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
  DoctorPracticeSettings _practiceSettings = const DoctorPracticeSettings();

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  @override
  void dispose() {
    _slotSub?.cancel();
    super.dispose();
  }

  /// Profil dokter sekali + stream slot realtime dari Firestore.
  Future<void> _loadFromBackend() async {
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

    ScheduleService.getPracticeSettings(doctorId).then((settings) {
      if (!mounted) return;
      setState(() => _practiceSettings = settings);
    }).catchError((_) {});

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

                  // 2. Banner Informasi Praktik & Pembagian Sesi Dokter
                  _buildPracticeInfoBanner(),

                  const SizedBox(height: 20.0),

                  // 3. Section Title: "JADWAL TERSEDIA"
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

  /// Banner Ringkasan Praktik & Kuota Dokter
  Widget _buildPracticeInfoBanner() {
    final isEnded = _practiceSettings.isPracticeEndedNow();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.clock,
                  size: 16,
                  color: Color(0xFFC2410C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jam Praktik: ${_practiceSettings.practiceStartTime} - ${_practiceSettings.practiceEndTime} WIB',
                  style: const TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9A3412),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isEnded
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isEnded ? 'Tutup Otomatis' : 'Praktik Buka',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isEnded
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Pembagian sesi: ${_practiceSettings.sessionDurationMinutes} Menit / sesi\n'
            '• Limit pasien: ${_practiceSettings.quotaPerSession} Pasien / sesi (Maks. ${_practiceSettings.dailyPatientLimit} pasien/hari)',
            style: const TextStyle(
              fontSize: 12.0,
              color: Color(0xFF7C2D12),
              height: 1.4,
            ),
          ),
        ],
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
    final isFull = slot?.isFull ?? false;
    final isExpired = slot != null &&
        slot.timeEnd.isNotEmpty &&
        AppDates.isPastSlot(
          dateIso: slot.dateIso,
          scheduleDate: slot.date,
          timeStart: slot.timeStart,
          timeEnd: slot.timeEnd,
        );
    final remaining = slot?.remainingQuota ?? 1;

    Color bgColor = timeChipBg;
    Color textColor = darkText;
    String statusBadge = 'Sisa $remaining kuota';
    Color statusColor = const Color(0xFFC2410C);

    if (isExpired) {
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
            border: isFull || isExpired
                ? Border.all(
                    color: isFull
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  )
                : null,
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

  /// Peringatan ramah jika jadwal konsultasi belum masuk jamnya.
  Future<void> _showNotYetAvailableDialog(
    String doctorName,
    String dayDate,
    String startTime,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
                    color: Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.clock,
                      size: 28,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Belum Waktunya Konsultasi',
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
                  'Jadwal konsultasi bersama $doctorName tersedia pada '
                  '$dayDate pukul $startTime WIB.\n\n'
                  'Anda belum dapat memulai konsultasi sebelum jam tersebut. '
                  'Jadwal tetap tersimpan — silakan kembali pada waktu yang '
                  'ditentukan.',
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
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryMaroon,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Mengerti',
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

  /// Menampilkan dialog menunggu dokter selama 3 detik lalu ke ruang konfirmasi
  Future<void> _onTimeSlotTapped(
    String time,
    String dayDate,
    DoctorProfileDetailModel doctor,
  ) async {
    final slot = _findSlot(time, dayDate);
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

    final slotDate = slot.date.isNotEmpty ? slot.date : dayDate;
    final startTime = AppDates.formatHm(
      slot.timeStart.isNotEmpty
          ? slot.timeStart
          : slot.time.split('-').first.trim(),
    );

    // 1. Validasi sesi sudah penuh (mencapai batas limit kuota pasien)
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

    // 2. Validasi sesi sudah lewat waktu sekarang (tutup otomatis)
    final isPast = slot.timeEnd.isNotEmpty &&
        AppDates.isPastSlot(
          dateIso: slot.dateIso,
          scheduleDate: slot.date,
          timeStart: slot.timeStart,
          timeEnd: slot.timeEnd,
        );
    if (isPast) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jadwal sesi $time pada $slotDate sudah berakhir (tutup otomatis).',
          ),
        ),
      );
      return;
    }

    // 3. Validasi belum masuk jam konsultasi (upcoming)
    if (ScheduleService.availabilityOf(slot) == SlotAvailability.upcoming) {
      await _showNotYetAvailableDialog(doctor.name, slotDate, startTime);
      return;
    }

    // 4. Validasi aturan: Dibatasi 1 pasien hanya bisa konsultasi sekali dalam satu hari
    if (Backend.useFirebase) {
      final patient = await AuthService.loadProfile();
      if (patient != null && patient.uid.isNotEmpty) {
        final alreadyBookedToday =
            await ConsultationService.hasConsultationOnDate(
          patientUid: patient.uid,
          dateIso: slot.dateIso,
          scheduleDate: slotDate,
        );
        if (alreadyBookedToday) {
          if (!mounted) return;
          await _showDailyLimitDialog(slotDate);
          return;
        }
      }
    }

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
                  'Menunggu Dokter...',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sedang menghubungkan ke ${doctor.name} untuk jadwal $slotDate pukul $startTime WIB.',
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
    if (Backend.useFirebase) {
      try {
        final patient = await AuthService.loadProfile();
        if (patient == null || patient.uid.isEmpty) {
          throw StateError(
            'Sesi pengguna tidak ditemukan. Silahkan login ulang.',
          );
        }
        consultationId = await ConsultationService.book(
          doctorUid: doctor.id,
          doctorName: doctor.name,
          specialization: doctor.specialization,
          slotId: slot.id,
          scheduleDate: slotDate,
          scheduleTime: slot.time,
          patient: patient,
          dateIso: slot.dateIso,
          timeStart: slot.timeStart.isNotEmpty ? slot.timeStart : startTime,
          timeEnd: slot.timeEnd,
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
    }

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (bookingError.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bookingError)),
      );
      return;
    }

    if (Backend.useFirebase &&
        (consultationId == null || consultationId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memesan jadwal. Silakan coba lagi.'),
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
          consultationId: consultationId,
          onNavigateTab: widget.onNavigateTab,
          dateTime: '$slotDate • $startTime',
          scheduleDate: slotDate,
          scheduleTime: slot.time.isNotEmpty ? slot.time : time,
          dateIso: slot.dateIso,
          timeStart: slot.timeStart.isNotEmpty ? slot.timeStart : startTime,
          timeEnd: slot.timeEnd,
        ),
      ),
    );
  }
}
