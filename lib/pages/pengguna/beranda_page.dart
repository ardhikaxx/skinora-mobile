import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/consultation_service.dart';
import '../../services/notification_controller.dart';
import '../../services/skin_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_dates.dart';
import 'notifikasi_pengguna_page.dart';
import 'konsultasi_dokter_page.dart';
import 'edukasi_kulit_page.dart';

class BerandaPenggunaPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const BerandaPenggunaPage({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<BerandaPenggunaPage> createState() => _BerandaPenggunaPageState();
}

class _BerandaPenggunaPageState extends State<BerandaPenggunaPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF757575);
  static const Color peachCardBg = Color(0xFFFFD5C3);

  String _userName = Backend.useFirebase ? '' : 'Leonita Yulyta Agustin';
  int _unreadNotif = Backend.useFirebase ? 0 : 2;

  /// Badge lonceng realtime — satu listener bersama (lihat
  /// NotificationController), bukan query ulang setiap halaman dibuka.
  ValueListenable<int>? _unreadListenable;
  StreamSubscription<dynamic>? _profileSub;
  StreamSubscription<dynamic>? _skinCheckSubStream;
  StreamSubscription<dynamic>? _skinDailySubStream;
  StreamSubscription<dynamic>? _skincareSubStream;
  StreamSubscription<dynamic>? _consultSubStream;

  // Ringkasan hari ini — seed hanya mode demo; Firebase → data asli / empty.
  String _skinCheckValue = Backend.useFirebase ? 'Belum' : 'Kombinasi';
  String _skinCheckSub = Backend.useFirebase ? '-' : '2026-08-28';
  String _skinDailyValue = Backend.useFirebase ? 'Belum' : 'Terisi';
  String _skinDailySub = Backend.useFirebase ? '-' : 'Baik';
  String _skincareValue = Backend.useFirebase ? 'Belum' : 'Tercatat';
  String _skincareSub = Backend.useFirebase ? '-' : '5 produk';
  String _chatValue = Backend.useFirebase ? 'Belum' : 'Jadwal';
  String _chatSub = Backend.useFirebase ? '-' : '2026-08-28';

  @override
  void initState() {
    super.initState();
    _subscribeUnreadBadge();
    _subscribeProfileRealtime();
    _subscribeSummaryRealtime();
    _loadFromBackend();
  }

  /// Profil realtime: perubahan nama di edit profil langsung tampil di beranda.
  void _subscribeProfileRealtime() {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    _profileSub = UserService.streamByUid(uid).listen((profile) {
      if (!mounted || profile == null) return;
      final name = (profile.name as String?) ?? '';
      if (name.isNotEmpty && name != _userName) {
        setState(() => _userName = name);
      }
    }, onError: (_) {});
  }

  /// Ringkasan realtime: perubahan skin check, skin daily, skincare, atau konsultasi
  /// langsung memperbarui kartu ringkasan di beranda secara otomatis.
  void _subscribeSummaryRealtime() {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    _skinCheckSubStream?.cancel();
    _skinDailySubStream?.cancel();
    _skincareSubStream?.cancel();
    _consultSubStream?.cancel();

    _skinCheckSubStream =
        SkinService.streamSkinChecks(uid, limit: 5).listen((_) {
      if (mounted) _loadFromBackend();
    }, onError: (_) {});

    _skinDailySubStream = SkinService.streamSkinDailies(uid).listen((_) {
      if (mounted) _loadFromBackend();
    }, onError: (_) {});

    _skincareSubStream = SkinService.streamSkincare(uid).listen((_) {
      if (mounted) _loadFromBackend();
    }, onError: (_) {});

    _consultSubStream =
        ConsultationService.streamForPatient(uid).listen((_) {
      if (mounted) _loadFromBackend();
    }, onError: (_) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Realtime ringkasan: refresh tiap halaman ditampilkan ulang
    // (mis. kembali dari Skin Check / Daily / Routine).
    _loadFromBackend();
  }

  /// Pasang listener unread realtime (dihapus otomatis di dispose).
  void _subscribeUnreadBadge() {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    final listenable =
        NotificationController.unread(uid);
    _unreadListenable = listenable;
    listenable.addListener(_onUnreadChanged);
    _unreadNotif = listenable.value;
  }

  void _onUnreadChanged() {
    final value = _unreadListenable?.value ?? 0;
    if (!mounted || value == _unreadNotif) return;
    setState(() => _unreadNotif = value);
  }

  @override
  void dispose() {
    _unreadListenable?.removeListener(_onUnreadChanged);
    _profileSub?.cancel();
    _skinCheckSubStream?.cancel();
    _skinDailySubStream?.cancel();
    _skincareSubStream?.cancel();
    _consultSubStream?.cancel();
    super.dispose();
  }

  /// Profil + ringkasan hari ini dari Firestore (badge di-handle stream).
  Future<void> _loadFromBackend() async {
    if (!Backend.useFirebase) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    try {
      final results = await Future.wait<Object?>([
        UserService.loadByUid(uid).catchError((_) => null),
        SkinService.listSkinChecks(uid, limit: 5).catchError((_) => <Map<String, dynamic>>[]),
        SkinService.listSkinDailies(uid).catchError((_) => <Map<String, dynamic>>[]),
        SkinService.listSkincare(uid).catchError((_) => <Map<String, dynamic>>[]),
        ConsultationService.listForPatient(uid).catchError((_) => <Map<String, dynamic>>[]),
      ]);
      final profile = results[0] as dynamic;
      final checks = (results[1] as List<Map<String, dynamic>>?) ?? const [];
      final dailies = (results[2] as List<Map<String, dynamic>>?) ?? const [];
      final skincare = (results[3] as List<Map<String, dynamic>>?) ?? const [];
      final consults = (results[4] as List<Map<String, dynamic>>?) ?? const [];

      final todayIso = AppDates.todayIso();
      final localIso = AppDates.iso(DateTime.now());

      // Skin Check: hasil terakhir
      if (checks.isNotEmpty) {
        final latest = checks.first;
        final skinType = (latest['resultSkinType'] as String?) ?? '';
        _skinCheckValue = skinType.isNotEmpty ? skinType : 'Normal';
        final display = (latest['createdDisplay'] as String?) ?? '';
        if (display.isNotEmpty) {
          _skinCheckSub = display.split('•').first.trim();
        } else {
          final ts = latest['createdAt'];
          if (ts != null) {
            try {
              // ignore: avoid_dynamic_calls
              final dt = AppDates.toWib((ts as dynamic).toDate() as DateTime);
              _skinCheckSub = AppDates.short(dt);
            } catch (_) {
              _skinCheckSub = todayIso;
            }
          } else {
            _skinCheckSub = todayIso;
          }
        }
      } else {
        _skinCheckValue = 'Belum';
        _skinCheckSub = '-';
      }

      // Skin Daily: entri hari ini
      final todayDaily = dailies.where((d) {
        final di = (d['dateIso'] as String?) ?? '';
        if (di == todayIso || di == localIso) return true;
        final ts = d['createdAt'];
        if (ts != null) {
          try {
            // ignore: avoid_dynamic_calls
            final dt = AppDates.toWib((ts as dynamic).toDate() as DateTime);
            if (AppDates.iso(dt) == todayIso || AppDates.iso(dt) == localIso) {
              return true;
            }
          } catch (_) {}
        }
        return false;
      }).toList();

      if (todayDaily.isNotEmpty) {
        _skinDailyValue = 'Terisi';
        final symptoms = (todayDaily.first['symptoms'] as List?) ?? const [];
        final symptomStr = symptoms
            .map((s) => s.toString())
            .where((s) => s.isNotEmpty)
            .toList();
        _skinDailySub = SkinService.deriveDailyStatus(symptomStr);
      } else if (dailies.isNotEmpty) {
        final latest = dailies.first;
        final di = (latest['dateIso'] as String?) ?? '';
        if (di == todayIso || di == localIso) {
          _skinDailyValue = 'Terisi';
          final symptoms = (latest['symptoms'] as List?) ?? const [];
          final symptomStr = symptoms
              .map((s) => s.toString())
              .where((s) => s.isNotEmpty)
              .toList();
          _skinDailySub = SkinService.deriveDailyStatus(symptomStr);
        } else {
          _skinDailyValue = 'Belum';
          _skinDailySub = '-';
        }
      } else {
        _skinDailyValue = 'Belum';
        _skinDailySub = '-';
      }

      // Skincare: entri hari ini (realtime)
      final todaySkincare = skincare.where((e) {
        final di = (e['dateIso'] as String?) ?? '';
        if (di == todayIso || di == localIso) return true;
        final ts = e['createdAt'];
        if (ts != null) {
          try {
            // ignore: avoid_dynamic_calls
            final dt = AppDates.toWib((ts as dynamic).toDate() as DateTime);
            if (AppDates.iso(dt) == todayIso || AppDates.iso(dt) == localIso) {
              return true;
            }
          } catch (_) {}
        }
        return false;
      }).toList();

      final skincareSource = todaySkincare.isNotEmpty
          ? todaySkincare
          : (skincare.isNotEmpty &&
                  (((skincare.first['dateIso'] as String?) ?? '') == todayIso ||
                      ((skincare.first['dateIso'] as String?) ?? '') == localIso)
              ? [skincare.first]
              : <Map<String, dynamic>>[]);

      if (skincareSource.isNotEmpty) {
        _skincareValue = 'Tercatat';
        var productCount = 0;
        for (final entry in skincareSource) {
          final morning = (entry['morningSteps'] as List?) ??
              (entry['morning'] as List?) ??
              const [];
          final night = (entry['nightSteps'] as List?) ??
              (entry['night'] as List?) ??
              const [];
          productCount += morning.length + night.length;
        }
        _skincareSub =
            productCount > 0 ? '$productCount produk' : 'Tercatat';
      } else {
        _skincareValue = 'Belum';
        _skincareSub = '-';
      }

      // Chat / konsultasi: evaluasi realtime status konsultasi pasien
      final ongoing = consults.where((c) {
        final st = ((c['status'] as String?) ?? '').toLowerCase();
        return st == 'berlangsung';
      }).toList();

      final upcoming = consults.where((c) {
        final st = ((c['status'] as String?) ?? '').toLowerCase();
        if (st != 'terjadwal') return false;
        final di = (c['dateIso'] as String?) ?? '';
        final sd = (c['scheduleDate'] as String?) ?? '';
        final te = (c['timeEnd'] as String?) ?? '';
        final ts = (c['timeStart'] as String?) ?? '';
        final isPast = (di.isNotEmpty || sd.isNotEmpty) &&
            AppDates.isConsultationExpired(
              dateIso: di,
              scheduleDate: sd,
              timeEnd: te,
              timeStart: ts,
            );
        return !isPast;
      }).toList();

      final finished = consults.where((c) {
        final st = ((c['status'] as String?) ?? '').toLowerCase();
        if (st == 'selesai') return true;
        final di = (c['dateIso'] as String?) ?? '';
        final sd = (c['scheduleDate'] as String?) ?? '';
        final te = (c['timeEnd'] as String?) ?? '';
        final ts = (c['timeStart'] as String?) ?? '';
        final isPast = (di.isNotEmpty || sd.isNotEmpty) &&
            AppDates.isConsultationExpired(
              dateIso: di,
              scheduleDate: sd,
              timeEnd: te,
              timeStart: ts,
            );
        return isPast;
      }).toList();

      bool isConsultToday(Map<String, dynamic> c) {
        final di = (c['dateIso'] as String?) ?? '';
        if (di == todayIso || di == localIso) return true;
        for (final key in ['completedAt', 'updatedAt', 'createdAt']) {
          final ts = c[key];
          if (ts != null) {
            try {
              final dt =
                  ts is DateTime ? ts : (ts as dynamic).toDate() as DateTime;
              final wib = AppDates.toWib(dt);
              final iso = AppDates.iso(wib);
              if (iso == todayIso || iso == localIso) return true;
            } catch (_) {}
          }
        }
        return false;
      }

      final upcomingToday = upcoming.where(isConsultToday).toList();
      final finishedToday = finished.where(isConsultToday).toList();

      String formatConsultSubtitle(Map<String, dynamic> c) {
        final doc = (c['doctorName'] as String?) ?? '';
        final di = (c['dateIso'] as String?) ?? '';
        final ts = (c['timeStart'] as String?) ?? '';
        if (doc.isNotEmpty) {
          return doc;
        }
        if (di.isNotEmpty) {
          return ts.isEmpty ? di : '$di • ${AppDates.formatChatTimeWib(ts)}';
        }
        return (c['scheduleDate'] as String?) ?? '-';
      }

      String formatScheduleSubtitle(Map<String, dynamic> c) {
        final di = (c['dateIso'] as String?) ?? '';
        final ts = (c['timeStart'] as String?) ?? '';
        if (di.isNotEmpty) {
          return ts.isEmpty ? di : '$di • ${AppDates.formatChatTimeWib(ts)}';
        }
        return (c['scheduleDate'] as String?) ?? '-';
      }

      if (ongoing.isNotEmpty) {
        _chatValue = 'Berlangsung';
        _chatSub = formatConsultSubtitle(ongoing.first);
      } else if (upcomingToday.isNotEmpty) {
        _chatValue = 'Jadwal';
        _chatSub = formatScheduleSubtitle(upcomingToday.first);
      } else if (finishedToday.isNotEmpty) {
        _chatValue = 'Selesai';
        _chatSub = formatConsultSubtitle(finishedToday.first);
      } else if (upcoming.isNotEmpty) {
        _chatValue = 'Jadwal';
        _chatSub = formatScheduleSubtitle(upcoming.first);
      } else if (finished.isNotEmpty) {
        _chatValue = 'Selesai';
        _chatSub = formatConsultSubtitle(finished.first);
      } else {
        _chatValue = 'Belum';
        _chatSub = '-';
      }

      if (!mounted) return;
      setState(() {
        _userName = (profile?.name as String?) ?? '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userName = '';
      });
    }
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'P';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryMaroon,
          onRefresh: _loadFromBackend,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            children: [
            // 1. Header Profile & Notification Bell
            _buildHeader(),
            const SizedBox(height: 20),

            // 2. Ringkasan Hari Ini Card
            _buildRingkasanHariIniCard(),
            const SizedBox(height: 20),

            // 3. Menu Cepat Card
            _buildMenuCepatCard(),
            const SizedBox(height: 20),

            // 4. Tips Hari Ini Card
            _buildTipsHariIniCard(),
            const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Top Header: Avatar, Greeting, User Name, and Notification Bell
  /// Dibungkus dalam card putih dengan border rounded sesuai desain image.png
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
          // Avatar Initial (dynamic dari Firebase)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primaryMaroon,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _initials(_userName),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Greeting & Name (dynamic dari Firebase)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppDates.greetingWib()},',
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: subText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userName.isNotEmpty ? _userName : 'Pengguna',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Notification Bell Icon with Badge (dynamic dari Firebase)
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotifikasiPenggunaPage(
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
              if (_unreadNotif > 0)
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
                        '$_unreadNotif',
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

  /// 2. Ringkasan Hari Ini Section (Peach Card containing 4 White Cards)
  Widget _buildRingkasanHariIniCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: peachCardBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RINGKASAN HARI INI',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: darkText,
            ),
          ),
          const SizedBox(height: 14),

          // Row 1: Skin Check & Skin Daily
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: LucideIcons.stethoscope,
                  title: 'Skin Check',
                  value: _skinCheckValue,
                  subtitle: _skinCheckSub,
                  onTap: () => widget.onNavigateTab?.call(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  icon: LucideIcons.bookOpen,
                  title: 'Skin Daily',
                  value: _skinDailyValue,
                  subtitle: _skinDailySub,
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Skincare & Chat
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: LucideIcons.droplets,
                  title: 'Skincare',
                  value: _skincareValue,
                  subtitle: _skincareSub,
                  onTap: () => widget.onNavigateTab?.call(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  icon: LucideIcons.messageSquare,
                  title: 'Chat',
                  value: _chatValue,
                  subtitle: _chatSub,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KonsultasiDokterPenggunaPage(
                          onNavigateTab: widget.onNavigateTab,
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

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: primaryMaroon,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.0,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Menu Cepat Card (White Card with 4-Column Grid)
  Widget _buildMenuCepatCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
              fontSize: 13.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: darkText,
            ),
          ),
          const SizedBox(height: 18),

          // Row 1: Skin Check, Skin Daily, Skincare, Konsultasi Dokter
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.stethoscope,
                  label: 'Skin Check',
                  onTap: () => widget.onNavigateTab?.call(1),
                ),
              ),
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.bookOpen,
                  label: 'Skin Daily',
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
              ),
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.droplets,
                  label: 'Skincare',
                  onTap: () => widget.onNavigateTab?.call(3),
                ),
              ),
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.messageSquare,
                  label: 'Konsultasi\nDokter',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KonsultasiDokterPenggunaPage(
                          onNavigateTab: widget.onNavigateTab,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Edukasi, Profil, and 2 empty placeholders for alignment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.bookMarked,
                  label: 'Edukasi',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EdukasiKulitPenggunaPage(
                          onNavigateTab: widget.onNavigateTab,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: _buildQuickMenuItem(
                  icon: LucideIcons.user,
                  label: 'Profil',
                  onTap: () => widget.onNavigateTab?.call(4),
                ),
              ),
              const Expanded(child: SizedBox()),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMenuItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primaryMaroon,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryMaroon.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                color: darkText,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Tips Hari Ini Card (Maroon Banner with Droplet Icon & Advice)
  Widget _buildTipsHariIniCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: primaryMaroon,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryMaroon.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.droplets,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tips Hari Ini',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Minum air putih minimal 8 gelas sehari untuk menjaga kelembapan kulit Anda.',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
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
