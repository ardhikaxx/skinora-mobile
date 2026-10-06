import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/empty_state.dart';
import '../../components/navbottom/admin_navbottom.dart';
import '../../models/admin_article_model.dart';
import '../../services/activity_service.dart';
import '../../services/article_service.dart';
import '../../services/backend.dart';
import '../../services/consultation_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_dates.dart';

class ActivityLogModel {
  final String title;
  final String tag;
  final String actor;
  final String time;
  final IconData icon;

  ActivityLogModel({
    required this.title,
    required this.tag,
    required this.actor,
    required this.time,
    required this.icon,
  });
}

class LaporanRiwayatPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final List<ActivityLogModel>? initialActivities;
  final Map<String, String>? initialStats;

  const LaporanRiwayatPage({
    super.key,
    this.onNavigateTab,
    this.initialActivities,
    this.initialStats,
  });

  @override
  State<LaporanRiwayatPage> createState() => _LaporanRiwayatPageState();
}

class _LaporanRiwayatPageState extends State<LaporanRiwayatPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF757575);
  static const Color dateText = Color(0xFF9E9E9E);
  static const Color peachIconBg = Color(0xFFFFD5C8);
  static const Color tagBg = Color(0xFFFFD5C8);

  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<dynamic>? _activitySub;

  late String _ringTotalKonsultasi = widget.initialStats?['totalKonsultasi'] ?? '0';
  late String _ringDokterAktif = widget.initialStats?['dokterAktif'] ?? '0';
  late String _ringPengguna = widget.initialStats?['pengguna'] ?? '0';
  late String _ringArtikel = widget.initialStats?['artikel'] ?? '0';
  late String _statusTerjadwal = widget.initialStats?['terjadwal'] ?? '0';
  late String _statusBerlangsung = widget.initialStats?['berlangsung'] ?? '0';
  late String _statusSelesai = widget.initialStats?['selesai'] ?? '0';
  late String _statusBatal = widget.initialStats?['batal'] ?? '0';
  late String _pctTerjadwal = widget.initialStats?['pctTerjadwal'] ?? '0%';
  late String _pctBerlangsung = widget.initialStats?['pctBerlangsung'] ?? '0%';
  late String _pctSelesai = widget.initialStats?['pctSelesai'] ?? '0%';
  late String _pctBatal = widget.initialStats?['pctBatal'] ?? '0%';
  late String _topLogin = widget.initialStats?['topLogin'] ?? '0';
  late String _topSkinDaily = widget.initialStats?['topSkinDaily'] ?? '0';
  late String _topSkinCheck = widget.initialStats?['topSkinCheck'] ?? '0';
  late String _topSkincare = widget.initialStats?['topSkincare'] ?? '0';

  String _pctOf(int count, int total) {
    if (total <= 0) return '0%';
    return '${((count / total) * 100).round()}%';
  }

  final List<String> _categories = [
    'Semua',
    'Login',
    'Skin Check',
    'Skin Daily',
    'Skincare',
    'Booking',
    'Konsultasi',
    'Review',
    'Verifikasi',
    'Artikel',
  ];

  late List<ActivityLogModel> _allActivities;

  List<ActivityLogModel> get _filteredActivities {
    return _allActivities.where((activity) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          activity.tag.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          activity.actor.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          activity.tag.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _allActivities = widget.initialActivities != null
        ? List.from(widget.initialActivities!)
        : <ActivityLogModel>[];
    _loadFromBackend();
    if (Backend.useFirebase && widget.initialActivities == null) {
      _activitySub = ActivityService.streamAll(limit: 50).listen((_) {
        _loadFromBackend();
      }, onError: (_) {});
    }
  }

  String _fmtTime(Object? ts) {
    if (ts is Timestamp) return AppDates.dateTime(ts.toDate());
    return ts?.toString() ?? '';
  }

  IconData _iconForTag(String tag) {
    switch (tag) {
      case 'Login':
        return LucideIcons.zap;
      case 'Skin Check':
        return LucideIcons.scan;
      case 'Skin Daily':
        return LucideIcons.fileText;
      case 'Skincare':
        return LucideIcons.sparkles;
      case 'Booking':
        return LucideIcons.calendar;
      case 'Konsultasi':
        return LucideIcons.circleCheck;
      case 'Review':
        return LucideIcons.trendingUp;
      case 'Verifikasi':
        return LucideIcons.shieldCheck;
      case 'Artikel':
        return LucideIcons.fileText;
      default:
        return LucideIcons.zap;
    }
  }

  /// Muat statistik + log aktivitas global dari Firestore.
  Future<void> _loadFromBackend() async {
    if (widget.initialActivities != null) return;
    if (!Backend.useFirebase) return;
    try {
      final results = await Future.wait<Object?>([
        ConsultationService.countAll(),
        ConsultationService.countByStatus('terjadwal'),
        ConsultationService.countByStatus('berlangsung'),
        ConsultationService.countByStatus('selesai'),
        ConsultationService.countByStatus('dibatalkan'),
        UserService.countPengguna(),
        UserService.countDokterAktif(),
        ArticleService.listPublished(),
        ActivityService.listAll(),
      ]);

      int? asInt(Object? v) => v is int ? v : null;
      final total = asInt(results[0]);
      final terjadwal = asInt(results[1]);
      final berlangsung = asInt(results[2]);
      final selesai = asInt(results[3]);
      final batal = asInt(results[4]);
      final pengguna = asInt(results[5]);
      final dokter = asInt(results[6]);
      final articles = results[7] as List<AdminArticleModel>?;
      final acts = results[8] as List<Map<String, dynamic>>?;

      if (!mounted) return;
      setState(() {
        if (total != null) _ringTotalKonsultasi = '$total';
        if (terjadwal != null) _statusTerjadwal = '$terjadwal';
        if (berlangsung != null) _statusBerlangsung = '$berlangsung';
        if (selesai != null) _statusSelesai = '$selesai';
        if (batal != null) _statusBatal = '$batal';
        final totalN = total ??
            ((terjadwal ?? 0) +
                (berlangsung ?? 0) +
                (selesai ?? 0) +
                (batal ?? 0));
        _pctTerjadwal = _pctOf(terjadwal ?? 0, totalN);
        _pctBerlangsung = _pctOf(berlangsung ?? 0, totalN);
        _pctSelesai = _pctOf(selesai ?? 0, totalN);
        _pctBatal = _pctOf(batal ?? 0, totalN);
        if (pengguna != null) _ringPengguna = '$pengguna';
        if (dokter != null) _ringDokterAktif = '$dokter';
        if (articles != null) _ringArtikel = '${articles.length}';

        _allActivities
          ..clear()
          ..addAll((acts ?? <Map<String, dynamic>>[]).map((m) {
            final tag = (m['tag'] as String?) ?? 'Login';
            return ActivityLogModel(
              title: (m['title'] as String?) ?? '',
              tag: tag,
              actor: (m['actor'] as String?) ?? '',
              time: _fmtTime(m['createdAt']),
              icon: _iconForTag(tag),
            );
          }));

        int countTag(String tag) =>
            _allActivities.where((a) => a.tag == tag).length;
        _topLogin = '${countTag('Login')}';
        _topSkinDaily = '${countTag('Skin Daily')}';
        _topSkinCheck = '${countTag('Skin Check')}';
        _topSkincare = '${countTag('Skincare')}';
      });
    } catch (_) {
      // Query gagal → reset angka '0' & log kosong, jangan seed palsu.
      if (!mounted) return;
      setState(() {
        _ringTotalKonsultasi = '0';
        _ringDokterAktif = '0';
        _ringPengguna = '0';
        _ringArtikel = '0';
        _statusTerjadwal = '0';
        _statusBerlangsung = '0';
        _statusSelesai = '0';
        _statusBatal = '0';
        _pctTerjadwal = '0%';
        _pctBerlangsung = '0%';
        _pctSelesai = '0%';
        _pctBatal = '0%';
        _topLogin = '0';
        _topSkinDaily = '0';
        _topSkinCheck = '0';
        _topSkincare = '0';
        _allActivities.clear();
      });
    }
  }

  @override
  void dispose() {
    _activitySub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 16.0,
                bottom: 8.0,
              ),
              child: Row(
                children: [
                  if (Navigator.canPop(context)) ...[
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(right: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E5EA),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.chevronLeft,
                            size: 18,
                            color: Color(0xFF4A1A24),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Text(
                    'Laporan & Riwayat',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Subtle divider line
            Container(
              height: 1,
              color: const Color(0xFFF0F0F0),
              margin: const EdgeInsets.only(top: 8.0, bottom: 12.0),
            ),

            // Main scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // 1. Ringkasan Platform Card
                  _buildRingkasanPlatformCard(),
                  const SizedBox(height: 20),

                  // 2. Status Konsultasi Section
                  _buildStatusKonsultasiSection(),
                  const SizedBox(height: 16),

                  // 3. Summary metrics (Total Konsultasi & Artikel Dipublikasi)
                  _buildSummaryMetricsRow(),
                  const SizedBox(height: 20),

                  // 4. Aktivitas Teratas Section
                  _buildAktivitasTeratasSection(),
                  const SizedBox(height: 20),

                  // 5. Riwayat Aktivitas Section
                  _buildRiwayatAktivitasSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminNavBottom(
        currentIndex: 0,
        onTap: (index) {
          Navigator.pop(context);
          if (index > 0) {
            widget.onNavigateTab?.call(index);
          }
        },
      ),
    );
  }

  /// 1. Ringkasan Platform Card
  Widget _buildRingkasanPlatformCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: primaryMaroon,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryMaroon.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header inside card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ringkasan Platform',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    AppDates.short(AppDates.nowWib()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Stats in row
          Row(
            children: [
              Expanded(
                child: _buildRingkasanItem(
                  count: _ringTotalKonsultasi,
                  label: 'Total\nKonsultasi',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRingkasanItem(
                  count: _ringDokterAktif,
                  label: 'Dokter\nAktif',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRingkasanItem(
                  count: _ringPengguna,
                  label: 'Total\nPengguna',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasanItem({required String count, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11.0,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Status Konsultasi Section
  Widget _buildStatusKonsultasiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'STATUS KONSULTASI',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: Color(0xFF555555),
              ),
            ),
            Text(
              '$_ringTotalKonsultasi total',
              style: const TextStyle(
                fontSize: 11.5,
                color: dateText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                icon: LucideIcons.messageSquare,
                percentage: _pctTerjadwal,
                count: _statusTerjadwal,
                label: 'Terjadwal',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                icon: LucideIcons.timer,
                percentage: _pctBerlangsung,
                count: _statusBerlangsung,
                label: 'Berlangsung',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                icon: LucideIcons.circleCheck,
                percentage: _pctSelesai,
                count: _statusSelesai,
                label: 'Selesai',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                icon: LucideIcons.circleX,
                percentage: _pctBatal,
                count: _statusBatal,
                label: 'Dibatalkan',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String percentage,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.0),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: peachIconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: primaryMaroon),
              ),
              Text(
                percentage,
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: subText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: subText,
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Summary Metrics Row (Total Konsultasi & Artikel Dipublikasi)
  Widget _buildSummaryMetricsRow() {
    return Row(
      children: [
        // Total Konsultasi
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEEEE), width: 1.0),
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: peachIconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.trendingUp,
                        size: 16,
                        color: primaryMaroon,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Total Konsultasi',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                 Text(
                  _ringTotalKonsultasi,
                  style: const TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Artikel Dipublikasi
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEEEE), width: 1.0),
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: peachIconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.fileText,
                        size: 16,
                        color: primaryMaroon,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Artikel\nDipublikasi',
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF555555),
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _ringArtikel,
                      style: const TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 4. Aktivitas Teratas Section
  Widget _buildAktivitasTeratasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AKTIVITAS TERATAS',
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTopActivityCard(
                icon: LucideIcons.zap,
                count: _topLogin,
                label: 'Login',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTopActivityCard(
                icon: LucideIcons.fileText,
                count: _topSkinDaily,
                label: 'Skin Daily',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTopActivityCard(
                icon: LucideIcons.scan,
                count: _topSkinCheck,
                label: 'Skin Check',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTopActivityCard(
                icon: LucideIcons.sparkles,
                count: _topSkincare,
                label: 'Skincare',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopActivityCard({
    required IconData icon,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: peachIconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: primaryMaroon),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.0,
                  color: subText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 5. Riwayat Aktivitas Section
  Widget _buildRiwayatAktivitasSection() {
    final filtered = _filteredActivities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RIWAYAT AKTIVITAS',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: Color(0xFF555555),
              ),
            ),
            Text(
              '${filtered.length} entri',
              style: const TextStyle(
                fontSize: 11.5,
                color: dateText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Input
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 1.0),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            style: const TextStyle(fontSize: 13.0),
            decoration: InputDecoration(
              hintText: 'Cari aktivitas...',
              hintStyle: const TextStyle(fontSize: 13.0, color: dateText),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 12.0,
              ),
              border: InputBorder.none,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Filter Chips Row
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = cat == _selectedCategory;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryMaroon : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isSelected ? primaryMaroon : const Color(0xFFE5E5EA),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : const Color(0xFF4A1A24),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // List of Activities
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: _searchQuery.isNotEmpty
                ? NoSearchResultWidget(
                    compact: true,
                    title: 'Aktivitas tidak ditemukan',
                    description:
                        'Tidak ada aktivitas yang cocok dengan "$_searchQuery".',
                    onAction: () => setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    }),
                  )
                : const EmptyStateWidget(
                    compact: true,
                    icon: LucideIcons.history,
                    title: 'Belum ada aktivitas sistem',
                    description:
                        'Log aktivitas dokter, pengguna, dan artikel akan muncul di sini.',
                  ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = filtered[index];
              return _buildActivityCard(item);
            },
          ),
      ],
    );
  }

  Widget _buildActivityCard(ActivityLogModel item) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: peachIconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 18, color: primaryMaroon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.tag,
                        style: const TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          color: primaryMaroon,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.actor,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: subText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.time,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: dateText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
