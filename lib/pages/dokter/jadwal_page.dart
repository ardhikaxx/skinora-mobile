import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  const JadwalDokterPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<JadwalDokterPage> createState() => _JadwalDokterPageState();
}

class _JadwalDokterPageState extends State<JadwalDokterPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF757575);
  static const Color bookedSlotBg = Color(0xFFFFB2A6);

  bool _isReady = true;

  late List<DayScheduleModel> _scheduleDays;

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
                  ),
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

                  // 3. "+ Tambah Slot Baru" Button
                  _buildTambahSlotButton(),
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
          Column(
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

          // Status Button "Siap" / "Tidak Siap"
          InkWell(
            onTap: () {
              setState(() {
                _isReady = !_isReady;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isReady
                        ? 'Status ketersediaan: Siap untuk konsultasi'
                        : 'Status ketersediaan: Tidak aktif / istirahat',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: _isReady ? bookedSlotBg : const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isReady ? LucideIcons.check : LucideIcons.x,
                    size: 16,
                    color: _isReady ? primaryMaroon : const Color(0xFF757575),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isReady ? 'Siap' : 'Sibuk',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: _isReady ? primaryMaroon : const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. "+ Tambah Slot Baru" Button
  Widget _buildTambahSlotButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMaroon,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(LucideIcons.plus, size: 18, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Tambah Slot Baru',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ],
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
            InkWell(
              onTap: () => _deleteSlot(dayGroup, slot),
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
                      color: primaryMaroon,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Hapus',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: primaryMaroon,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _deleteSlot(DayScheduleModel dayGroup, ScheduleSlotModel slot) {
    setState(() {
      dayGroup.slots.removeWhere((s) => s.id == slot.id);
    });
  }
}
