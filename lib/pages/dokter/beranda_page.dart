import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/consultation_service.dart';
import '../../services/notification_service.dart';
import '../../services/schedule_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_dates.dart';
import 'patient_insight_page.dart';
import 'notifikasi_dokter_page.dart';

class BerandaDokterPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const BerandaDokterPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<BerandaDokterPage> createState() => _BerandaDokterPageState();
}

class _BerandaDokterPageState extends State<BerandaDokterPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color statSectionBg = Color(0xFFFFD5C3);
  static const Color bookedSlotBg = Color(0xFFFFBCAE);

  String _greetingName = 'dr. Anita Dewi, Sp.KK';
  String _specialization = 'Estetika Kulit';
  int _unreadNotif = 1;

  String _statHariIni = '2';
  String _statMenunggu = '1';
  String _statSelesai = '1';

  List<Map<String, String>> _todaySlots = const [
    {'time': '09:00 - 09:30', 'status': 'Tersedia', 'badge': 'Kosong', 'booked': 'false'},
    {'time': '09:30 - 10:00', 'status': 'Terjadwal', 'badge': 'Terjadwal', 'booked': 'true', 'bookedBy': 'Dibooking oleh user-4'},
    {'time': '10:00 - 10:30', 'status': 'Terjadwal', 'badge': 'Terjadwal', 'booked': 'true', 'bookedBy': 'Dibooking oleh user-3'},
  ];

  ValueChanged<int>? get onNavigateTab => widget.onNavigateTab;

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final results = await Future.wait<Object?>([
        UserService.loadByUid(uid),
        ConsultationService.listForDoctor(uid),
        ScheduleService.listSlots(uid),
        NotificationService.countUnread(NotificationService.userAudience(uid)),
      ]);
      final profile = results[0] as dynamic;
      final consults = results[1] as List<Map<String, dynamic>>?;
      final slots = results[2] as List<SlotRecord>?;
      final unread = results[3] as int?;

      if (!mounted) return;
      setState(() {
        if (profile != null) {
          final name = (profile.name as String?) ?? '';
          if (name.isNotEmpty) _greetingName = name;
          final spec = (profile.specialization as String?) ?? '';
          if (spec.isNotEmpty) _specialization = spec;
        }
        if (unread != null && unread > 0) _unreadNotif = unread;
        if (consults != null) {
          final todayIso = AppDates.todayIso();
          final todayCount = consults
              .where((c) => ((c['dateIso'] as String?) ?? '') == todayIso)
              .length;
          final menunggu = consults
              .where((c) => ((c['status'] as String?) ?? '') == 'terjadwal')
              .length;
          final selesai = consults
              .where((c) => ((c['status'] as String?) ?? '') == 'selesai')
              .length;
          if (todayCount > 0) _statHariIni = '$todayCount';
          if (menunggu > 0) _statMenunggu = '$menunggu';
          if (selesai > 0) _statSelesai = '$selesai';
        }
        if (slots != null && slots.isNotEmpty) {
          final todayIso = AppDates.todayIso();
          final today = slots
              .where((s) => s.dateIso == todayIso)
              .take(3)
              .map((s) => {
                    'time': s.time,
                    'status': s.isBooked ? 'Terjadwal' : 'Tersedia',
                    'badge': s.isBooked ? 'Terjadwal' : 'Kosong',
                    'booked': s.isBooked.toString(),
                    if (s.isBooked && s.patientName != null)
                      'bookedBy': 'Dibooking oleh ${s.patientName}',
                  })
              .toList();
          if (today.isNotEmpty) _todaySlots = today;
        }
      });
    } catch (_) {
      // dashboard tetap menampilkan data demo bila query gagal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with greeting and notification bell
              _buildHeader(context),
              const SizedBox(height: 20),

              // 2. Section STATISTIK HARI INI
              _buildStatistikSection(),
              const SizedBox(height: 18),

              // 3. Section AKSES CEPAT
              _buildAksesCepatSection(context),
              const SizedBox(height: 18),

              // 4. Section JADWAL HARI INI
              _buildJadwalHariIniSection(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Header (Greeting + Doctor Name + Specialization + Notification Bell)
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat siang,',
              style: TextStyle(
                fontSize: 13.5,
                color: subText,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _greetingName,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkText,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _specialization,
              style: const TextStyle(
                fontSize: 13.0,
                color: subText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),

        // Notification button with badge "1"
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotifikasiDokterPage(
                      onNavigateTab: onNavigateTab,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE5E5EA),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.bell,
                    size: 20,
                    color: Color(0xFF4A1A24),
                  ),
                ),
              ),
            ),
            // Red badge with unread count
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: primaryMaroon,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    '$_unreadNotif',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 2. Section STATISTIK HARI INI
  Widget _buildStatistikSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: statSectionBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATISTIK HARI INI',
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: darkText,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.messageSquare,
                  count: _statHariIni,
                  label: 'Hari Ini',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.clock,
                  count: _statMenunggu,
                  label: 'Menunggu',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.circleCheck,
                  count: _statSelesai,
                  label: 'Selesai',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primaryMaroon,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Section AKSES CEPAT (Jadwal | Konsultasi | Insight)
  Widget _buildAksesCepatSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            'AKSES CEPAT',
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Jadwal
              Expanded(
                child: _buildAksesCepatItem(
                  icon: LucideIcons.calendar,
                  label: 'Jadwal',
                  onTap: () => onNavigateTab?.call(1),
                ),
              ),
              // Konsultasi
              Expanded(
                child: _buildAksesCepatItem(
                  icon: LucideIcons.messageSquare,
                  label: 'Konsultasi',
                  onTap: () => onNavigateTab?.call(2),
                ),
              ),
              // Insight
              Expanded(
                child: _buildAksesCepatItem(
                  icon: LucideIcons.users,
                  label: 'Insight',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientInsightPage(
                          onNavigateTab: onNavigateTab,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAksesCepatItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primaryMaroon,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. Section JADWAL HARI INI
  Widget _buildJadwalHariIniSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            'JADWAL HARI INI',
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 14),

          // Dynamic slots for today (demo seed when backend empty)
          ..._todaySlots.asMap().entries.map((entry) {
            final slot = entry.value;
            final isBooked = slot['booked'] == 'true';
            if (isBooked) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildBookedSlotCard(
                  time: slot['time'] ?? '',
                  bookedBy: slot['bookedBy'] ?? 'Dibooking oleh pasien',
                  status: slot['status'] ?? 'Terjadwal',
                  onTap: () => onNavigateTab?.call(2),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildAvailableSlotCard(
                time: slot['time'] ?? '',
                status: slot['status'] ?? 'Tersedia',
                badgeText: slot['badge'] ?? 'Kosong',
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Available schedule slot card (White with thin border & "Kosong" badge)
  Widget _buildAvailableSlotCard({
    required String time,
    required String status,
    required String badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: subText,
                ),
              ),
            ],
          ),
          // Pill badge "Kosong"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1.0,
              ),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Booked schedule slot card (Peach/coral background with "Terjadwal")
  Widget _buildBookedSlotCard({
    required String time,
    required String bookedBy,
    required String status,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3F141E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    bookedBy,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: primaryMaroon,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
