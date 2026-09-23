import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/navbottom/dokter_navbottom.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/schedule_service.dart';
import '../../services/user_service.dart';

class ScheduleSlotModel {
  final String id;
  final String time;
  final String? patientName;
  final bool isBooked;

  ScheduleSlotModel({
    required this.id,
    required this.time,
    this.patientName,
    required this.isBooked,
  });
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

  const JadwalDokterPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = false,
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

  final TextEditingController _dateController =
      TextEditingController(text: 'Jumat, 28 Agustus 2026');
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  late List<DayScheduleModel> _scheduleDays;

  // Slot asli dari Firestore (id dokumen) untuk persist hapus/availability.
  final Map<String, String> _slotDocIds = {}; // 'dayIndex-slotIndex' -> fsId
  bool _backendLoaded = false;

  @override
  void initState() {
    super.initState();
    _scheduleDays = [
      // 1. Jumat, 28 Agustus 2026
      DayScheduleModel(
        date: 'Jumat, 28 Agustus 2026',
        slots: [
          ScheduleSlotModel(
            id: '1-1',
            time: '09:00 - 09:30',
            patientName: 'Leonita Yulyta Agustin',
            isBooked: true,
          ),
          ScheduleSlotModel(
            id: '1-2',
            time: '09:30 - 10:00',
            patientName: 'Annida Tri Aulia',
            isBooked: false,
          ),
          ScheduleSlotModel(
            id: '1-3',
            time: '10:00 - 10:30',
            patientName: 'Kafi Khaula Yukisa Zailina',
            isBooked: false,
          ),
          ScheduleSlotModel(
            id: '1-4',
            time: '10:30 - 11:00',
            patientName: null,
            isBooked: false,
          ),
          ScheduleSlotModel(
            id: '1-5',
            time: '14:00 - 14:30',
            patientName: 'Kafi Khaula Yukisa Zailina',
            isBooked: false,
          ),
          ScheduleSlotModel(
            id: '1-6',
            time: '14:30 - 15:00',
            patientName: 'Annida Tri Aulia',
            isBooked: false,
          ),
        ],
      ),

      // 2. Sabtu, 29 Agustus 2026
      DayScheduleModel(
        date: 'Sabtu, 29 Agustus 2026',
        slots: [
          ScheduleSlotModel(
            id: '2-1',
            time: '09:00 - 09:30',
            patientName: 'Annida Tri Aulia',
            isBooked: false,
          ),
          ScheduleSlotModel(
            id: '2-2',
            time: '09:30 - 10:00',
            patientName: 'Siti Aisa Nur Apriliana',
            isBooked: true,
          ),
          ScheduleSlotModel(
            id: '2-3',
            time: '10:00 - 10:30',
            patientName: 'Kafi Khaula Yukisa Zailina',
            isBooked: true,
          ),
        ],
      ),

      // 3. Minggu, 30 Agustus 2026
      DayScheduleModel(
        date: 'Minggu, 30 Agustus 2026',
        slots: [
          ScheduleSlotModel(
            id: '3-1',
            time: '14:00 - 14:30',
            patientName: 'Leonita Yulyta Agustin',
            isBooked: true,
          ),
        ],
      ),
    ];
    _loadFromBackend();
  }

  /// Muat slot + status ketersediaan dari Firestore. Tanpa Firebase, seed
  /// demo tetap dipakai agar UI/tes tidak berubah.
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final results = await Future.wait<Object?>([
        ScheduleService.listSlots(uid),
        UserService.loadByUid(uid),
      ]);
      final slots = results[0] as List<SlotRecord>?;
      final profile = results[1] as dynamic;
      if (!mounted) return;
      setState(() {
        final available = profile == null ? null : (profile.isAvailable as bool?);
        if (available != null) _isReady = available;
        if (slots == null || slots.isEmpty) return;
        _backendLoaded = true;
        _slotDocIds.clear();
        final grouped = <String, List<ScheduleSlotModel>>{};
        for (final s in slots) {
          final day = grouped.putIfAbsent(s.date, () => []);
          day.add(ScheduleSlotModel(
            id: s.id,
            time: s.time,
            patientName: s.patientName,
            isBooked: s.isBooked,
          ));
        }
        _scheduleDays = grouped.entries
            .map((e) => DayScheduleModel(date: e.key, slots: e.value))
            .toList();
        for (var d = 0; d < _scheduleDays.length; d++) {
          for (var s = 0; s < _scheduleDays[d].slots.length; s++) {
            _slotDocIds['$d-$s'] = _scheduleDays[d].slots[s].id;
          }
        }
      });
    } catch (_) {
      // biarkan seed demo bila query gagal
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  void _handleToggleAvailability() {
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
    final date = _dateController.text.trim();
    final start = _startTimeController.text.trim();
    final end = _endTimeController.text.trim();

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
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan slot: $e')),
          );
          return;
        }
      }
    }

    final newSlot = ScheduleSlotModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      time: '$start - $end',
      patientName: null,
      isBooked: false,
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Slot jadwal berhasil disimpan'),
        duration: Duration(seconds: 2),
      ),
    );
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

                // Body text
                const Text(
                  'Slot ini akan dihapus dari jadwal Anda.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF4B5563),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons: Batal & Ya, Hapus
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
                            setState(() {
                              dayGroup.slots
                                  .removeWhere((s) => s.id == slot.id);
                            });
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
                // Header: Checkmark Icon + Title + Close Button
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

                // Body text
                const Text(
                  'Slot berhasil dihapus',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF4B5563),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),

                // OK Button
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
            // 1. Header (Back chevron + "Jadwal" title)
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

            // Subtle divider line
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(bottom: 16.0),
            ),

            // Main scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 2. Status Ketersediaan Card
                  _buildStatusKetersediaanCard(),
                  const SizedBox(height: 16),

                  // 3. "+ Tambah Slot Baru" / "✕ Tutup Form" Button
                  _buildToggleFormButton(),

                  // Inline Form: Slot Baru (Visible when _isFormOpen == true)
                  if (_isFormOpen) ...[
                    const SizedBox(height: 14),
                    _buildSlotBaruFormCard(),
                  ],

                  const SizedBox(height: 18),

                  // 4. Grouped Schedule Cards (Days)
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

  /// 2. Status Ketersediaan Card
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

          // Status Button "Siap" vs "Sibuk"
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

  /// 3. Toggle Form Button ("+ Tambah Slot Baru" vs "✕ Tutup Form")
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

          // TANGGAL
          _buildFormLabel('TANGGAL'),
          const SizedBox(height: 6),
          _buildFormTextField(
            controller: _dateController,
            hintText: 'Jumat, 28 Agustus 2026',
          ),

          const SizedBox(height: 14),

          // JAM MULAI & JAM SELESAI
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
                      hintText: '09:00',
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
                      hintText: '09:30',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // "✓ Simpan Slot" Button
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
  }) {
    return TextField(
      controller: controller,
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

  /// 4. Day Group Card (Contains Date Header + Slot Cards)
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
          // Date Header
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

          // Slots List
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

  /// Single Slot Card (Booked vs Available/Empty)
  Widget _buildSlotItem(DayScheduleModel dayGroup, ScheduleSlotModel slot) {
    if (slot.isBooked) {
      // Booked Slot (Soft peach background with "Terjadwal")
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: bookedSlotBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
                  ],
                ),
                if (slot.patientName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.user,
                        size: 13,
                        color: subText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        slot.patientName!,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
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
    } else {
      // Unbooked / Available Slot (White with border and "Hapus" button)
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
            Column(
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
                  ],
                ),
                if (slot.patientName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.user,
                        size: 13,
                        color: subText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        slot.patientName!,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: subText,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            // "Hapus" button
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
