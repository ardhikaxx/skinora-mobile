import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/empty_state.dart';
import '../../models/admin_doctor_model.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/consultation_service.dart';
import '../../services/notification_controller.dart';
import '../../services/user_service.dart';
import '../../utils/app_dates.dart';
import '../../components/realtime_wib_badge.dart';
import 'notifikasi_admin_page.dart';
import 'master_spesialisasi_page.dart';
import 'laporan_riwayat_page.dart';

class BerandaAdminPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final List<Map<String, String>>? initialActivities;
  final Map<String, String>? initialStats;

  const BerandaAdminPage({
    super.key,
    this.onNavigateTab,
    this.initialActivities,
    this.initialStats,
  });

  @override
  State<BerandaAdminPage> createState() => _BerandaAdminPageState();
}

class _BerandaAdminPageState extends State<BerandaAdminPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF8E8E93);
  static const Color statSectionBg = Color(0xFFFFD5C3);
  static const Color peachIconBg = Color(0xFFFFE3D8);
  static const Color activityIconBg = Color(0xFFFFD9CC);

  late String _statTerjadwal = widget.initialStats?['terjadwal'] ?? '0';
  late String _statSelesai = widget.initialStats?['selesai'] ?? '0';
  late String _statPengguna = widget.initialStats?['pengguna'] ?? '0';
  late String _statDokter = widget.initialStats?['dokter'] ?? '0';
  late String _unreadNotif = widget.initialStats?['unread'] ?? '0';

  /// Badge lonceng realtime (shared listener — lihat NotificationController).
  ValueListenable<int>? _unreadListenable;

  /// Nama admin realtime (mirip pengguna/beranda_page.dart).
  String _adminName = '';
  StreamSubscription<dynamic>? _profileSub;

  late List<Map<String, String>> _activities;

  @override
  void initState() {
    super.initState();
    _activities = widget.initialActivities != null
        ? List.from(widget.initialActivities!)
        : const <Map<String, String>>[];
    _subscribeUnreadBadge();
    _subscribeProfileRealtime();
    _loadFromBackend();
  }

  /// Profil realtime: perubahan nama admin langsung tampil di beranda.
  void _subscribeProfileRealtime() {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    _profileSub = UserService.streamByUid(uid).listen((profile) {
      if (!mounted || profile == null) return;
      final name = (profile.name as String?) ?? '';
      if (name.isNotEmpty && name != _adminName) {
        setState(() => _adminName = name);
      }
    }, onError: (_) {});
  }

  /// Badge notifikasi per-admin (`audience = user:{uid}`) agar state baca
  /// per admin benar — bukan `role:admin` yang menjadi satu tumpukan bersama.
  void _subscribeUnreadBadge() {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    final listenable =
        NotificationController.unread(uid);
    _unreadListenable = listenable;
    listenable.addListener(_onUnreadChanged);
    _unreadNotif = '${listenable.value}';
  }

  void _onUnreadChanged() {
    final value = '${_unreadListenable?.value ?? 0}';
    if (!mounted || value == _unreadNotif) return;
    setState(() => _unreadNotif = value);
  }

  StreamSubscription<dynamic>? _activitySub;
  StreamSubscription<dynamic>? _userSub;
  StreamSubscription<dynamic>? _doctorSub;
  StreamSubscription<dynamic>? _consultSub;

  @override
  void dispose() {
    _unreadListenable?.removeListener(_onUnreadChanged);
    _profileSub?.cancel();
    _activitySub?.cancel();
    _userSub?.cancel();
    _doctorSub?.cancel();
    _consultSub?.cancel();
    super.dispose();
  }

  String _fmtTime(Object? ts) {
    return AppDates.formatTimestampWib(ts);
  }

  /// Ambil statistik + aktivitas terbaru dari Firestore secara realtime.
  void _loadFromBackend() {
    if (widget.initialActivities != null) return;
    if (!Backend.useFirebase) return;
    _activitySub?.cancel();
    _activitySub = ActivityService.streamAll(limit: 6).listen(
      (acts) {
        if (!mounted) return;
        setState(() {
          _activities = acts
              .map((a) => <String, String>{
                    'title': (a['title'] as String?) ?? '',
                    'time': _fmtTime(a['createdAt']),
                  })
              .toList();
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _activities = <Map<String, String>>[]);
      },
    );

    _userSub?.cancel();
    _userSub = UserService.streamPengguna().listen((users) {
      if (!mounted) return;
      setState(() => _statPengguna = '${users.length}');
    });

    _doctorSub?.cancel();
    _doctorSub = UserService.streamDokter().listen((doctors) {
      if (!mounted) return;
      final aktif = doctors.where((d) => d.status == DoctorStatus.terverifikasi).length;
      setState(() => _statDokter = '$aktif');
    });

    _consultSub?.cancel();
    _consultSub = ConsultationService.streamAllConsultations().listen((consults) {
      if (!mounted) return;
      final terjadwal = consults.where((c) => c['status'] == 'terjadwal').length;
      final selesai = consults.where((c) => c['status'] == 'selesai').length;
      setState(() {
        _statTerjadwal = '$terjadwal';
        _statSelesai = '$selesai';
      });
    });
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
              // Header: Admin Dashboard & Notification Button
              _buildHeader(context),
              const SizedBox(height: 20),

              // Section 1: STATISTIK
              _buildStatistikSection(),
              const SizedBox(height: 18),

              // Section 2: MENU CEPAT
              _buildMenuCepatSection(context),
              const SizedBox(height: 18),

              // Section 3: AKTIVITAS TERBARU
              _buildAktivitasTerbaruSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Header with Title, Subtitle, and Notification Bell with Badge
  /// Dibungkus dalam card putih dengan border rounded sesuai desain.
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E5EA),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _adminName.isEmpty
                      ? 'Kelola aplikasi Skinora'
                      : 'Halo, $_adminName',
                  style: const TextStyle(
                    fontSize: 14,
                    color: subText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Notification bell with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotifikasiAdminPage(
                        onNavigateTab: widget.onNavigateTab,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE5E5EA),
                      width: 1.2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.bell,
                      size: 22,
                      color: Color(0xFF4A1A24),
                    ),
                  ),
                ),
              ),
              // Red badge with count (only when unread > 0)
              if (_unreadNotif != '0' && _unreadNotif.isNotEmpty)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: primaryMaroon,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        _unreadNotif,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
      ),
    );
  }

  /// Section 1: STATISTIK (peach box with 2x2 white cards)
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'STATISTIK SISTEM',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: darkText,
                ),
              ),
              RealtimeWibBadge(
                style: RealtimeWibStyle.pill,
                compact: true,
                includeSeconds: true,
                backgroundColor: Colors.white,
                borderColor: Color(0xFFFFD4D8),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.messageSquare,
                  count: _statTerjadwal,
                  label: 'Terjadwal',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.circleCheck,
                  count: _statSelesai,
                  label: 'Selesai',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.users,
                  count: _statPengguna,
                  label: 'Pengguna',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.stethoscope,
                  count: _statDokter,
                  label: 'Dokter',
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
                size: 19,
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

  /// Section 2: MENU CEPAT
  Widget _buildMenuCepatSection(BuildContext context) {
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
            'MENU CEPAT',
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 16),
          // Row 1: Dokter, Pengguna, Edukasi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.stethoscope,
                  title: 'Dokter',
                  subtitle: 'Kelola verifikasi',
                  onTap: () => widget.onNavigateTab?.call(1),
                ),
              ),
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.users,
                  title: 'Pengguna',
                  subtitle: 'Kelola pengguna',
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
              ),
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.fileText,
                  title: 'Edukasi',
                  subtitle: 'Kelola artikel',
                  onTap: () => widget.onNavigateTab?.call(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Row 2: Spesialisasi, Laporan, Spacer
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.stethoscope,
                  title: 'Spesialisasi',
                  subtitle: 'Kelola spesialisasi',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MasterSpesialisasiPage(
                          onNavigateTab: widget.onNavigateTab,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.messageSquare,
                  title: 'Laporan',
                  subtitle: 'Analitik & riwayat',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LaporanRiwayatPage(
                          onNavigateTab: widget.onNavigateTab,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Expanded(
                child: SizedBox(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: peachIconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: primaryMaroon,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                color: subText,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section 3: AKTIVITAS TERBARU
  Widget _buildAktivitasTerbaruSection() {
    final activities = _activities;

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
          Row(
            children: const [
              Icon(
                LucideIcons.clock,
                size: 16,
                color: Color(0xFF757575),
              ),
              SizedBox(width: 8),
              Text(
                'AKTIVITAS TERBARU',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            const CompactEmptyState(
              icon: LucideIcons.history,
              title: 'Belum ada aktivitas',
              description:
                  'Aktivitas admin, dokter, dan pengguna akan muncul di sini.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = activities[index];
                return _buildActivityItem(
                  title: item['title']!,
                  time: item['time']!,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: activityIconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(
              LucideIcons.circleCheck,
              color: primaryMaroon,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11.0,
                  color: subText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


}
