import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/pengguna_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/consultation_service.dart';
import '../../services/schedule_service.dart';
import '../../services/user_service.dart';
import 'ruang_konsultasi_page.dart';

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

  static final Map<String, DoctorProfileDetailModel> _doctorDatabase = {
    '1': const DoctorProfileDetailModel(
      id: '1',
      name: 'dr. Anita Dewi, Sp.KK',
      specialization: 'Estetika Kulit',
      experience: 'Pengalaman: 8 tahun',
      bio:
          'Dokter spesialis kulit dan kelamin dengan pengalaman 8 tahun di bidang estetika kulit. Lulusan Fakultas Kedokteran Universitas Indonesia.',
      schedules: [
        DoctorScheduleModel(
          dayDate: 'JUMAT, 28 AGUSTUS 2026',
          timeSlots: ['09:30', '10:00', '14:00', '14:30'],
        ),
        DoctorScheduleModel(
          dayDate: 'SABTU, 29 AGUSTUS 2026',
          timeSlots: ['09:00'],
        ),
      ],
    ),
    '2': const DoctorProfileDetailModel(
      id: '2',
      name: 'dr. Andi Pratama, Sp.KK',
      specialization: 'Jerawat',
      experience: 'Pengalaman: 6 tahun',
      bio:
          'Dokter spesialis kulit yang berfokus pada penanganan jerawat aktif, inflamasi, komedo, dan bekas luka jerawat. Lulusan Fakultas Kedokteran Universitas Airlangga.',
      schedules: [
        DoctorScheduleModel(
          dayDate: 'JUMAT, 28 AGUSTUS 2026',
          timeSlots: ['10:00', '11:00', '14:30', '15:00'],
        ),
        DoctorScheduleModel(
          dayDate: 'SABTU, 29 AGUSTUS 2026',
          timeSlots: ['09:30', '10:00'],
        ),
      ],
    ),
    '3': const DoctorProfileDetailModel(
      id: '3',
      name: 'dr. Reza Firmansyah, Sp.KK',
      specialization: 'Anti-Aging',
      experience: 'Pengalaman: 10 tahun',
      bio:
          'Spesialis kulit dan kelamin konsultan estetika medis serta anti-aging. Berpengalaman luas dalam mengatasi garis halus, flek hitam, dan peremajaan skin barrier.',
      schedules: [
        DoctorScheduleModel(
          dayDate: 'JUMAT, 28 AGUSTUS 2026',
          timeSlots: ['09:30', '10:00', '13:30', '14:00'],
        ),
        DoctorScheduleModel(
          dayDate: 'SABTU, 29 AGUSTUS 2026',
          timeSlots: ['10:30', '11:00'],
        ),
      ],
    ),
  };

  DoctorProfileDetailModel get _currentDoctor {
    if (widget.doctorId != null &&
        _doctorDatabase.containsKey(widget.doctorId)) {
      return _doctorDatabase[widget.doctorId]!;
    }
    if (_liveDoctor != null) return _liveDoctor!;
    if (widget.doctorName != null) {
      for (final doc in _doctorDatabase.values) {
        if (doc.name.toLowerCase() == widget.doctorName!.toLowerCase()) {
          return doc;
        }
      }
    }
    // Default to doctor 1 (dr. Anita Dewi, Sp.KK matching design screenshot)
    return _doctorDatabase['1']!;
  }

  DoctorProfileDetailModel? _liveDoctor;
  List<SlotRecord> _availableSlots = const [];

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  /// Profil dokter + slot jadwal dari Firestore. Tanpa Firebase, seed demo
  /// tetap dipakai agar UI/tes tidak berubah.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final doctorId = widget.doctorId;
    if (doctorId == null || doctorId.isEmpty) return;
    try {
      final results = await Future.wait<Object?>([
        UserService.loadByUid(doctorId),
        ScheduleService.listSlots(doctorId),
      ]);
      final profile = results[0] as dynamic;
      final slots = results[1] as List<SlotRecord>?;
      if (!mounted) return;
      setState(() {
        if (profile != null) {
          final seed = _doctorDatabase[doctorId] ??
              (widget.doctorName != null
                  ? _doctorDatabase.values.firstWhere(
                      (d) =>
                          d.name.toLowerCase() ==
                          widget.doctorName!.toLowerCase(),
                      orElse: () => _doctorDatabase['1']!,
                    )
                  : _doctorDatabase['1']!);
          _liveDoctor = DoctorProfileDetailModel(
            id: doctorId,
            name: ((profile.name as String?) ?? '').isNotEmpty
                ? profile.name as String
                : seed.name,
            specialization:
                ((profile.specialization as String?) ?? '').isNotEmpty
                    ? profile.specialization as String
                    : seed.specialization,
            experience: ((profile.experience as String?) ?? '').isNotEmpty
                ? 'Pengalaman: ${profile.experience}'
                : seed.experience,
            bio: ((profile.bio as String?) ?? '').isNotEmpty
                ? profile.bio as String
                : seed.bio,
            schedules: seed.schedules,
          );
        }
        final open = (slots ?? const <SlotRecord>[])
            .where((s) => !s.isBooked && s.date.isNotEmpty)
            .toList();
        if (open.isNotEmpty) {
          _availableSlots = open;
          final byDate = <String, List<String>>{};
          final order = <String>[];
          for (final s in open) {
            final t = s.timeStart.isNotEmpty ? s.timeStart : s.time;
            byDate.putIfAbsent(s.date, () {
              order.add(s.date);
              return <String>[];
            }).add(t);
          }
          _liveDoctor = DoctorProfileDetailModel(
            id: _liveDoctor?.id ?? doctorId,
            name: _liveDoctor?.name ?? _currentDoctor.name,
            specialization:
                _liveDoctor?.specialization ?? _currentDoctor.specialization,
            experience: _liveDoctor?.experience ?? _currentDoctor.experience,
            bio: _liveDoctor?.bio ?? _currentDoctor.bio,
            schedules: [
              for (final date in order)
                DoctorScheduleModel(
                  dayDate: date.toUpperCase(),
                  timeSlots: byDate[date]!,
                ),
            ],
          );
        }
      });
    } catch (_) {
      // profil dokter tetap menampilkan seed demo bila query gagal
    }
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

            // Subtle divider line
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                bottom: 16.0,
              ),
            ),

            // Main scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 1. Doctor Info Card
                  _buildDoctorCard(doctor),

                  const SizedBox(height: 24.0),

                  // 2. Section Title: "JADWAL TERSEDIA"
                  const Text(
                    'JADWAL TERSEDIA',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                      letterSpacing: 0.8,
                    ),
                  ),

                  const SizedBox(height: 14.0),

                  // 3. Schedule Cards
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
              // Soft peach/pink Avatar Container with lowercase "d"
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

              // Name, Specialization, and Experience
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
          const SizedBox(height: 16),

          // Doctor Bio / Description Text
          Text(
            doctor.bio,
            style: const TextStyle(
              fontSize: 13.5,
              color: darkText,
              height: 1.45,
            ),
          ),
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
          // Day and Date header (e.g. "JUMAT, 28 AGUSTUS 2026")
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

          // Available Time Slot Chips
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: schedule.timeSlots.map((time) {
              return _buildTimeChip(time, schedule.dayDate, doctor);
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Single Time Slot Chip
  Widget _buildTimeChip(
    String time,
    String dayDate,
    DoctorProfileDetailModel doctor,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onTimeSlotTapped(time, dayDate, doctor),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 22.0,
            vertical: 10.0,
          ),
          decoration: BoxDecoration(
            color: timeChipBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
        ),
      ),
    );
  }

  /// Menampilkan dialog menunggu dokter selama 3 detik lalu ke ruang konsultasi
  Future<void> _onTimeSlotTapped(
    String time,
    String dayDate,
    DoctorProfileDetailModel doctor,
  ) async {
    SlotRecord? slot;
    for (final s in _availableSlots) {
      final sDate = s.date.toUpperCase();
      final sTime = s.timeStart.isNotEmpty ? s.timeStart : s.time;
      if (sDate == dayDate && sTime == time) {
        slot = s;
        break;
      }
    }

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
                  'Sedang menghubungkan ke ${doctor.name} untuk jadwal $dayDate pukul $time WIB.',
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
    if (Backend.useFirebase && slot != null) {
      try {
        final patient = await AuthService.loadProfile();
        if (patient == null || patient.uid.isEmpty) {
          throw StateError('Sesi pengguna tidak ditemukan. Silakan login ulang.');
        }
        consultationId = await ConsultationService.book(
          doctorUid: doctor.id,
          doctorName: doctor.name,
          specialization: doctor.specialization,
          slotId: slot.id,
          scheduleDate: slot.date,
          scheduleTime: slot.time,
          patient: patient,
          dateIso: slot.dateIso,
          timeStart: slot.timeStart,
          timeEnd: slot.timeEnd,
        );
      } catch (e) {
        bookingError = e.toString();
      }
    }

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (bookingError.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal booking: $bookingError')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RuangKonsultasiPenggunaPage(
          doctorId: doctor.id,
          doctorName: doctor.name,
          status: 'Terjadwal',
          consultationId: consultationId,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );
  }
}
