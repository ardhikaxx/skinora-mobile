import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../components/empty_state.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import '../../models/doctor_practice_settings.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/schedule_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_dates.dart';

class ScheduleSlotModel {
  final String id;
  final String time;
  final String? patientName;
  final bool isBooked;
  final int quota;
  final int bookedCount;
  final List<String> patientNames;
  final String timeStart;
  final String timeEnd;

  ScheduleSlotModel({
    required this.id,
    required this.time,
    this.patientName,
    required this.isBooked,
    this.quota = 1,
    this.bookedCount = 0,
    this.patientNames = const [],
    this.timeStart = '',
    this.timeEnd = '',
  });

  int get remainingQuota => (quota - bookedCount).clamp(0, quota);
  bool get isFull => isBooked || (bookedCount >= quota && quota > 0);
}

class DayScheduleModel {
  final String date;
  final List<ScheduleSlotModel> slots;

  DayScheduleModel({
    required this.date,
    required this.slots,
  });
}

class JadwalDokterPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;
  final List<DayScheduleModel>? initialScheduleDays;

  const JadwalDokterPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = false,
    this.initialScheduleDays,
  });

  @override
  State<JadwalDokterPage> createState() => _JadwalDokterPageState();
}

class _JadwalDokterPageState extends State<JadwalDokterPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E1E1E);
  static const Color subText = Color(0xFF757575);
  static const Color bookedSlotBg = Color(0xFFFFCDD2);

  bool _isReady = false; // false = "Sibuk", true = "Siap"
  bool _isFormOpen = false;
  String _accountStatus = '';

  late final TextEditingController _dateController;
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _quotaController =
      TextEditingController(text: '2');

  late List<DayScheduleModel> _scheduleDays;

  DoctorPracticeSettings _practiceSettings = const DoctorPracticeSettings();
  StreamSubscription<DoctorPracticeSettings>? _settingsSub;

  // Slot asli dari Firestore (id dokumen) untuk persist hapus/availability.
  bool _backendLoaded = false;
  StreamSubscription<List<SlotRecord>>? _slotSub;

  @override
  void initState() {
    super.initState();
    _dateController =
        TextEditingController(text: AppDates.display(DateTime.now()));
    _scheduleDays = widget.initialScheduleDays != null
        ? List.from(widget.initialScheduleDays!)
        : <DayScheduleModel>[];
    _loadFromBackend();
  }

  /// Stream slot realtime dokter (booking pasien langsung terlihat).
  void _loadFromBackend() {
    if (widget.initialScheduleDays != null) return;
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;

    _slotSub?.cancel();
    _slotSub = ScheduleService.slotStream(uid).listen(
      _applySlots,
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _backendLoaded = true;
          _scheduleDays = <DayScheduleModel>[];
        });
      },
    );

    _settingsSub?.cancel();
    _settingsSub =
        ScheduleService.streamPracticeSettings(uid).listen((settings) {
      if (!mounted) return;
      setState(() {
        _practiceSettings = settings;
        _quotaController.text = settings.quotaPerSession.toString();
      });
    }, onError: (_) {});

    UserService.loadByUid(uid).then((profile) {
      if (!mounted || profile == null) return;
      setState(() {
        _isReady = profile.isAvailable;
        _accountStatus = profile.status;
      });
    }).catchError((_) {});
  }

  void _applySlots(List<SlotRecord> slots) {
    if (!mounted) return;
    setState(() {
      _backendLoaded = true;
      final grouped = <String, List<ScheduleSlotModel>>{};
      for (final s in slots) {
        final day = grouped.putIfAbsent(s.date, () => []);
        day.add(ScheduleSlotModel(
          id: s.id,
          time: AppDates.formatRange(s.time),
          patientName: s.patientName,
          isBooked: s.isBooked,
          quota: s.quota,
          bookedCount: s.bookedCount,
          patientNames: s.patientNames,
          timeStart: s.timeStart,
          timeEnd: s.timeEnd,
        ));
      }
      _scheduleDays = grouped.entries
          .map((e) => DayScheduleModel(date: e.key, slots: e.value))
          .toList();
    });
  }

  @override
  void dispose() {
    _slotSub?.cancel();
    _settingsSub?.cancel();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  void _handleToggleAvailability() {
    if (_accountStatus == 'menunggu') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Akun dokter Anda sedang menunggu verifikasi admin. Jadwal praktik belum dapat diaktifkan.',
          ),
          backgroundColor: Color(0xFFA83244),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() {
      _isReady = !_isReady;
    });
    if (Backend.useFirebase) {
      final uid = AuthService.uid;
      if (uid != null) {
        ScheduleService.setAvailability(uid, _isReady).catchError((_) {});
      }
    }
  }

  Future<void> _handleSaveNewSlot() async {
    if (_accountStatus == 'menunggu') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Akun dokter Anda sedang menunggu verifikasi admin. Pembuatan slot jadwal belum dapat dilakukan.',
          ),
          backgroundColor: Color(0xFFA83244),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    final date = _dateController.text.trim();
    final start = _startTimeController.text.trim();
    final end = _endTimeController.text.trim();
    final quota = int.tryParse(_quotaController.text.trim()) ??
        _practiceSettings.quotaPerSession;

    if (date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal tidak boleh kosong'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (start.isEmpty || end.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam mulai dan jam selesai harus diisi'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (Backend.useFirebase) {
      final uid = AuthService.uid;
      if (uid != null) {
        try {
          await ScheduleService.addSlot(
            doctorUid: uid,
            date: date,
            time: '$start - $end',
            timeStart: start,
            timeEnd: end,
            quota: quota,
          );
          await ActivityService.log(
            title: 'Menambah jadwal $date $start - $end (Limit $quota pasien)',
            tag: 'Jadwal',
            actor: 'Dokter',
            actorUid: uid,
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan slot: $e')),
          );
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _isFormOpen = false;
        _startTimeController.clear();
        _endTimeController.clear();
      });
      if (!mounted) return;
      AdminSuccessDialog.show(
        context,
        message: 'Slot jadwal berhasil disimpan',
      );
      return;
    }

    final newSlot = ScheduleSlotModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      time: '$start - $end',
      patientName: null,
      isBooked: false,
      quota: quota,
      bookedCount: 0,
      timeStart: start,
      timeEnd: end,
    );

    setState(() {
      final dayGroup = _scheduleDays.firstWhere(
        (d) => d.date.toLowerCase() == date.toLowerCase(),
        orElse: () {
          final newDay = DayScheduleModel(date: date, slots: []);
          _scheduleDays.insert(0, newDay);
          return newDay;
        },
      );
      dayGroup.slots.add(newSlot);
      _isFormOpen = false;
      _startTimeController.clear();
      _endTimeController.clear();
    });

    if (!mounted) return;
    AdminSuccessDialog.show(
      context,
      message: 'Slot jadwal berhasil disimpan',
    );
  }

  /// Otomatis membuat sesi-sesi konsultasi berdasarkan rentang jam buka & tutup
  /// yang sudah diatur oleh dokter.
  Future<void> _handleGenerateSessions() async {
    final date = _dateController.text.trim();
    if (date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal terlebih dahulu')),
      );
      return;
    }

    final sessions = _practiceSettings.generateSessions();
    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pengaturan jam praktik tidak valid (jam selesai harus setelah jam buka).',
          ),
        ),
      );
      return;
    }

    if (Backend.useFirebase) {
      final uid = AuthService.uid;
      if (uid != null) {
        try {
          final created = await ScheduleService.generatePracticeSlots(
            doctorUid: uid,
            date: date,
            settings: _practiceSettings,
          );
          if (!mounted) return;
          AdminSuccessDialog.show(
            context,
            message:
                '$created sesi praktik berhasil dibuat untuk $date dengan limit ${_practiceSettings.quotaPerSession} pasien per sesi.',
          );
          return;
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membuat sesi: $e')),
          );
          return;
        }
      }
    }

    // Fallback tanpa Firebase (simulasi/test)
    setState(() {
      final dayGroup = _scheduleDays.firstWhere(
        (d) => d.date.toLowerCase() == date.toLowerCase(),
        orElse: () {
          final newDay = DayScheduleModel(date: date, slots: []);
          _scheduleDays.insert(0, newDay);
          return newDay;
        },
      );
      for (final s in sessions) {
        final key = s.displayRange;
        if (!dayGroup.slots.any((x) => x.time == key)) {
          dayGroup.slots.add(
            ScheduleSlotModel(
              id: '${DateTime.now().millisecondsSinceEpoch}_${s.timeStart}',
              time: s.displayRange,
              quota: s.quota,
              bookedCount: 0,
              isBooked: false,
              timeStart: s.timeStart,
              timeEnd: s.timeEnd,
            ),
          );
        }
      }
    });

    if (!mounted) return;
    AdminSuccessDialog.show(
      context,
      message:
          '${sessions.length} sesi praktik berhasil dibuat untuk $date dengan limit ${_practiceSettings.quotaPerSession} pasien per sesi.',
    );
  }

  /// Dialog pengaturan jam buka, jam selesai, durasi sesi, dan limit kuota
  /// pasien yang diatur sendiri oleh dokter (bukan admin).
  void _openSettingsDialog() {
    final startCtrl =
        TextEditingController(text: _practiceSettings.practiceStartTime);
    final endCtrl =
        TextEditingController(text: _practiceSettings.practiceEndTime);
    int selectedDuration = _practiceSettings.sessionDurationMinutes;
    int selectedQuota = _practiceSettings.quotaPerSession;
    int selectedDailyLimit = _practiceSettings.dailyPatientLimit;
    bool autoCloseVal = _practiceSettings.autoClose;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD5C8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            LucideIcons.settings,
                            size: 20,
                            color: primaryMaroon,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Pengaturan Praktik & Kuota',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Dokter mengatur jam buka, sesi & limit pasien',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: subText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Jam Buka & Jam Selesai
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('JAM BUKA PRAKTIK'),
                              const SizedBox(height: 6),
                              _buildFormTextField(
                                controller: startCtrl,
                                hintText: '09.00',
                                onTap: () => _pickSlotTime(startCtrl),
                                suffixIcon: LucideIcons.clock,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('JAM TUTUP / SELESAI'),
                              const SizedBox(height: 6),
                              _buildFormTextField(
                                controller: endCtrl,
                                hintText: '12.00',
                                onTap: () => _pickSlotTime(endCtrl),
                                suffixIcon: LucideIcons.clock,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Durasi Sesi Konsultasi
                    _buildFormLabel('PEMBAGIAN DURASI SESI'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [15, 20, 30, 45, 60].map((dur) {
                        final isSel = selectedDuration == dur;
                        return ChoiceChip(
                          label: Text('$dur Menit'),
                          selected: isSel,
                          selectedColor: primaryMaroon,
                          backgroundColor: const Color(0xFFF3F4F6),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white : darkText,
                          ),
                          onSelected: (_) {
                            setSheetState(() => selectedDuration = dur);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Limit Pasien per Sesi
                    _buildFormLabel('LIMIT PASIEN PER SESI'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [1, 2, 3, 5].map((q) {
                        final isSel = selectedQuota == q;
                        return ChoiceChip(
                          label: Text('$q Pasien'),
                          selected: isSel,
                          selectedColor: primaryMaroon,
                          backgroundColor: const Color(0xFFF3F4F6),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white : darkText,
                          ),
                          onSelected: (_) {
                            setSheetState(() => selectedQuota = q);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Limit Pasien Harian
                    _buildFormLabel('LIMIT TOTAL PASIEN PER HARI'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [5, 10, 15, 20, 30].map((dl) {
                        final isSel = selectedDailyLimit == dl;
                        return ChoiceChip(
                          label: Text('$dl Pasien'),
                          selected: isSel,
                          selectedColor: primaryMaroon,
                          backgroundColor: const Color(0xFFF3F4F6),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white : darkText,
                          ),
                          onSelected: (_) {
                            setSheetState(() => selectedDailyLimit = dl);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Auto Close Switch
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.clockAlert,
                            size: 18,
                            color: primaryMaroon,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Tutup Otomatis Pas Selesai',
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                                Text(
                                  'Sesi yang melewati jam selesai otomatis ditutup',
                                  style: TextStyle(
                                    fontSize: 11.0,
                                    color: subText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: autoCloseVal,
                            activeThumbColor: primaryMaroon,
                            activeTrackColor: const Color(0xFFFFD5C8),
                            onChanged: (val) {
                              setSheetState(() => autoCloseVal = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Simpan Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () async {
                          final newSettings = DoctorPracticeSettings(
                            practiceStartTime: startCtrl.text.trim().isNotEmpty
                                ? startCtrl.text.trim()
                                : '09.00',
                            practiceEndTime: endCtrl.text.trim().isNotEmpty
                                ? endCtrl.text.trim()
                                : '12.00',
                            sessionDurationMinutes: selectedDuration,
                            quotaPerSession: selectedQuota,
                            dailyPatientLimit: selectedDailyLimit,
                            autoClose: autoCloseVal,
                          );

                          Navigator.pop(bContext);

                          setState(() {
                            _practiceSettings = newSettings;
                            _quotaController.text = selectedQuota.toString();
                          });

                          if (Backend.useFirebase) {
                            final uid = AuthService.uid;
                            if (uid != null) {
                              await ScheduleService.savePracticeSettings(
                                uid,
                                newSettings,
                              );
                            }
                          }

                          if (!mounted) return;
                          AdminSuccessDialog.show(
                            context,
                            message:
                                'Pengaturan jadwal praktik dan kuota berhasil disimpan',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryMaroon,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Simpan Pengaturan Praktik',
                          style: TextStyle(
                            fontSize: 14.0,
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
      },
    );
  }

  /// Tanggal memakai date picker, tampil di dalam kolom input.
  Future<void> _pickSlotDate() async {
    final now = AppDates.nowWib();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primaryMaroon,
            onPrimary: Colors.white,
            onSurface: darkText,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _dateController.text = AppDates.display(picked));
    }
  }

  /// Jam memakai clock picker (TimePicker), tampil di kolom input.
  Future<void> _pickSlotTime(TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: AppDates.timeOfDayWib(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primaryMaroon,
            onPrimary: Colors.white,
            onSurface: darkText,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      final raw = '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => controller.text = AppDates.formatHm(raw));
    }
  }

  void _showDeleteConfirmationDialog(
    DayScheduleModel dayGroup,
    ScheduleSlotModel slot,
  ) {
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
                      'Hapus Slot?',
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
                const Text(
                  'Slot ini akan dihapus dari jadwal Anda.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF4B5563),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
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
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            if (Backend.useFirebase) {
                              final uid = AuthService.uid;
                              if (uid != null && _backendLoaded) {
                                try {
                                  await ScheduleService.deleteSlot(
                                      uid, slot.id);
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Gagal menghapus slot: $e'),
                                    ),
                                  );
                                  return;
                                }
                              }
                            }
                            if (!mounted) return;
                            if (!Backend.useFirebase) {
                              setState(() {
                                dayGroup.slots
                                    .removeWhere((s) => s.id == slot.id);
                              });
                            }
                            _showDeleteSuccessDialog();
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
                            'Ya, Hapus',
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

  void _showDeleteSuccessDialog() {
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
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD5C8),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.check,
                          color: Color(0xFFE65100),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Berhasil',
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
                const Text(
                  'Slot berhasil dihapus',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF4B5563),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryMaroon,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Header (Back chevron + "Jadwal" title)
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
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        widget.onNavigateTab?.call(0);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Jadwal',
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

            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(bottom: 16.0),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  if (_accountStatus == 'menunggu') ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFDE68A),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(LucideIcons.clock, color: Color(0xFFD97706), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verifikasi Diperlukan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Akun Anda berstatus Menunggu Verifikasi. Pengaturan jadwal dan praktik akan aktif otomatis setelah akun disetujui Admin.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFFB45309),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 1. Status Ketersediaan Card (Siap vs Sibuk)
                  _buildStatusKetersediaanCard(),
                  const SizedBox(height: 14),

                  // 2. Card Pengaturan Praktik & Kuota Dokter
                  _buildPracticeSettingsCard(),
                  const SizedBox(height: 16),

                  // 3. "+ Tambah Slot Baru" / "✕ Tutup Form" Button
                  _buildToggleFormButton(),

                  if (_isFormOpen) ...[
                    const SizedBox(height: 14),
                    _buildSlotBaruFormCard(),
                  ],

                  const SizedBox(height: 18),

                  // 4. Grouped Schedule Cards (Days)
                  if (_scheduleDays.isEmpty)
                    const EmptyStateWidget(
                      icon: LucideIcons.calendarDays,
                      title: 'Belum ada jadwal konsultasi',
                      description:
                          'Tambahkan slot jadwal atau terapkan sesi otomatis agar pasien dapat memesan konsultasi dengan Anda.',
                    )
                  else
                    ..._scheduleDays.map((dayGroup) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                        child: _buildDayGroupCard(dayGroup),
                      );
                    }),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? DokterNavBottom(
              currentIndex: 1,
              onTap: (index) {
                Navigator.popUntil(context, (route) => route.isFirst);
                if (index != 1) {
                  widget.onNavigateTab?.call(index);
                }
              },
            )
          : null,
    );
  }

  /// Card Pengaturan Jadwal & Kuota Praktik (diatur langsung oleh dokter)
  Widget _buildPracticeSettingsCard() {
    final isEnded = _practiceSettings.isPracticeEndedNow();

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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD5C8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.clock,
                  size: 16,
                  color: primaryMaroon,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Jadwal & Kuota Praktik',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    Text(
                      'Dikelola langsung oleh dokter',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: subText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Jam Praktik',
                      style: TextStyle(fontSize: 11, color: subText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_practiceSettings.practiceStartTime} - ${_practiceSettings.practiceEndTime}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 26, color: Colors.grey.shade300),
                Column(
                  children: [
                    const Text(
                      'Durasi Sesi',
                      style: TextStyle(fontSize: 11, color: subText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_practiceSettings.sessionDurationMinutes} Menit',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 26, color: Colors.grey.shade300),
                Column(
                  children: [
                    const Text(
                      'Limit Pasien',
                      style: TextStyle(fontSize: 11, color: subText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_practiceSettings.quotaPerSession} Pasien/Sesi',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: _openSettingsDialog,
                    icon: const Icon(
                      LucideIcons.slidersHorizontal,
                      size: 15,
                      color: primaryMaroon,
                    ),
                    label: const Text(
                      'Atur Jam & Kuota',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: primaryMaroon,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryMaroon, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: _handleGenerateSessions,
                    icon: const Icon(
                      LucideIcons.sparkles,
                      size: 15,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Terapkan Sesi',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryMaroon,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Status Ketersediaan Card
  Widget _buildStatusKetersediaanCard() {
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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Status Ketersediaan',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Atur ketersediaan Anda untuk\nkonsultasi',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: subText,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleToggleAvailability,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 9.0,
                ),
                decoration: BoxDecoration(
                  color: _isReady
                      ? const Color(0xFFFFD5C8)
                      : const Color(0xFFFFCDD2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isReady ? LucideIcons.check : LucideIcons.ban,
                      size: 15,
                      color: _isReady
                          ? const Color(0xFFC2410C)
                          : const Color(0xFFE53935),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isReady ? 'Siap' : 'Sibuk',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: _isReady
                            ? const Color(0xFFC2410C)
                            : const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Toggle Form Button ("+ Tambah Slot Baru" vs "✕ Tutup Form")
  Widget _buildToggleFormButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _isFormOpen = !_isFormOpen;
          });
        },
        icon: Icon(
          _isFormOpen ? LucideIcons.x : LucideIcons.plus,
          size: 18,
          color: Colors.white,
        ),
        label: Text(
          _isFormOpen ? 'Tutup Form' : 'Tambah Slot Baru',
          style: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMaroon,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  /// Inline Form Card: "Slot Baru"
  Widget _buildSlotBaruFormCard() {
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
          const Text(
            'Slot Baru',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 14),

          _buildFormLabel('TANGGAL'),
          const SizedBox(height: 6),
          _buildFormTextField(
            controller: _dateController,
            hintText: 'Pilih tanggal',
            onTap: _pickSlotDate,
            suffixIcon: LucideIcons.calendar,
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('JAM MULAI'),
                    const SizedBox(height: 6),
                    _buildFormTextField(
                      controller: _startTimeController,
                      hintText: '09.00',
                      onTap: () => _pickSlotTime(_startTimeController),
                      suffixIcon: LucideIcons.clock,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('JAM SELESAI'),
                    const SizedBox(height: 6),
                    _buildFormTextField(
                      controller: _endTimeController,
                      hintText: '09.30',
                      onTap: () => _pickSlotTime(_endTimeController),
                      suffixIcon: LucideIcons.clock,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildFormLabel('LIMIT PASIEN (KUOTA PER SESI)'),
          const SizedBox(height: 6),
          _buildFormTextField(
            controller: _quotaController,
            hintText: '2',
            suffixIcon: LucideIcons.users,
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _handleSaveNewSlot,
              icon: const Icon(
                LucideIcons.check,
                size: 16,
                color: Colors.white,
              ),
              label: const Text(
                'Simpan Slot',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryMaroon,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11.0,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String hintText,
    VoidCallback? onTap,
    IconData? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      onTap: onTap,
      style: const TextStyle(
        fontSize: 14.0,
        color: darkText,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 13.5,
        ),
        suffixIcon: suffixIcon == null
            ? null
            : Icon(suffixIcon, size: 16, color: const Color(0xFF9CA3AF)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14.0,
          vertical: 11.0,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryMaroon,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  /// Day Group Card (Contains Date Header + Slot Cards)
  Widget _buildDayGroupCard(DayScheduleModel dayGroup) {
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
            blurRadius: 6,
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
                color: primaryMaroon,
              ),
              const SizedBox(width: 8),
              Text(
                dayGroup.date,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...dayGroup.slots.map((slot) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildSlotItem(dayGroup, slot),
            );
          }),
        ],
      ),
    );
  }

  /// Single Slot Card (Booked/Full vs Partial vs Available)
  Widget _buildSlotItem(DayScheduleModel dayGroup, ScheduleSlotModel slot) {
    final hasBookings = slot.bookedCount > 0 || slot.isBooked;
    final isFull = slot.isFull;

    // Pasien names display
    final allNames = slot.patientNames.isNotEmpty
        ? slot.patientNames
        : (slot.patientName != null && slot.patientName!.isNotEmpty
            ? [slot.patientName!]
            : <String>[]);

    if (isFull) {
      // Booked / Full Slot
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: bookedSlotBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 15,
                        color: Color(0xFF3F141E),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        slot.time,
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Penuh (${slot.bookedCount}/${slot.quota})',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB71C1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (allNames.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.user,
                          size: 13,
                          color: subText,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            allNames.join(', '),
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Color(0xFF555555),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Row(
              children: const [
                Icon(
                  LucideIcons.check,
                  size: 14,
                  color: primaryMaroon,
                ),
                SizedBox(width: 4),
                Text(
                  'Terjadwal',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: primaryMaroon,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (hasBookings) {
      // Partially Booked Slot
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 15,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        slot.time,
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Sisa ${slot.remainingQuota}/${slot.quota}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (allNames.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.user,
                          size: 13,
                          color: subText,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            allNames.join(', '),
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Color(0xFF555555),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Terisi Sebagian',
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Unbooked / Available Slot (Hapus button active)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFEEEEEE),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 15,
                        color: subText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        slot.time,
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Limit ${slot.quota} Pasien',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showDeleteConfirmationDialog(dayGroup, slot),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 4.0,
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        LucideIcons.trash2,
                        size: 14,
                        color: Color(0xFFE53935),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Hapus',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
