import '../utils/app_dates.dart';

/// Pengaturan jadwal praktik dan kuota konsultasi yang dikelola langsung
/// oleh dokter (bukan admin).
class DoctorPracticeSettings {
  /// Jam buka praktik (format "13.00").
  final String practiceStartTime;

  /// Jam selesai/tutup praktik (format "15.00").
  final String practiceEndTime;

  /// Durasi setiap sesi konsultasi dalam menit (default 25 menit per pasien).
  final int sessionDurationMinutes;

  /// Durasi jeda istirahat antar sesi dalam menit (default 5 menit).
  final int breakDurationMinutes;

  /// Batas maksimal pasien per sesi konsultasi (default 1 pasien per sesi).
  final int quotaPerSession;

  /// Batas maksimal total pasien konsultasi dalam satu hari.
  final int dailyPatientLimit;

  /// Apakah sesi ditutup otomatis saat jam konsultasi telah berakhir.
  final bool autoClose;

  const DoctorPracticeSettings({
    this.practiceStartTime = '13.00',
    this.practiceEndTime = '15.00',
    this.sessionDurationMinutes = 25,
    this.breakDurationMinutes = 5,
    this.quotaPerSession = 1,
    this.dailyPatientLimit = 10,
    this.autoClose = true,
  });

  /// Factory dari Map Firestore.
  factory DoctorPracticeSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const DoctorPracticeSettings();
    return DoctorPracticeSettings(
      practiceStartTime: AppDates.formatHm(
        (data['practiceStartTime'] as String?) ?? '13.00',
      ),
      practiceEndTime: AppDates.formatHm(
        (data['practiceEndTime'] as String?) ?? '15.00',
      ),
      sessionDurationMinutes:
          (data['sessionDurationMinutes'] as num?)?.toInt() ?? 25,
      breakDurationMinutes:
          (data['breakDurationMinutes'] as num?)?.toInt() ?? 5,
      quotaPerSession: (data['quotaPerSession'] as num?)?.toInt() ?? 1,
      dailyPatientLimit: (data['dailyPatientLimit'] as num?)?.toInt() ?? 10,
      autoClose: (data['autoClose'] as bool?) ?? true,
    );
  }

  /// Serialisasi ke Map untuk Firestore.
  Map<String, dynamic> toMap() => {
        'practiceStartTime': practiceStartTime,
        'practiceEndTime': practiceEndTime,
        'sessionDurationMinutes': sessionDurationMinutes,
        'breakDurationMinutes': breakDurationMinutes,
        'quotaPerSession': quotaPerSession,
        'dailyPatientLimit': dailyPatientLimit,
        'autoClose': autoClose,
      };

  DoctorPracticeSettings copyWith({
    String? practiceStartTime,
    String? practiceEndTime,
    int? sessionDurationMinutes,
    int? breakDurationMinutes,
    int? quotaPerSession,
    int? dailyPatientLimit,
    bool? autoClose,
  }) {
    return DoctorPracticeSettings(
      practiceStartTime: practiceStartTime ?? this.practiceStartTime,
      practiceEndTime: practiceEndTime ?? this.practiceEndTime,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      breakDurationMinutes:
          breakDurationMinutes ?? this.breakDurationMinutes,
      quotaPerSession: quotaPerSession ?? this.quotaPerSession,
      dailyPatientLimit: dailyPatientLimit ?? this.dailyPatientLimit,
      autoClose: autoClose ?? this.autoClose,
    );
  }

  /// Menghasilkan daftar pembagian sesi waktu berdasarkan rentang jam buka
  /// sampai jam tutup dengan durasi [sessionDurationMinutes] dan jeda istirahat [breakDurationMinutes].
  ///
  /// Contoh: Buka 13.00, Tutup 15.00, Durasi 25 menit, Jeda 5 menit:
  /// -> ["13.00 - 13.25", "13.30 - 13.55", "14.00 - 14.25", "14.30 - 14.55"]
  List<TimeRangeSession> generateSessions() {
    final startMin = _parseMinutes(practiceStartTime);
    final endMin = _parseMinutes(practiceEndTime);
    if (endMin <= startMin || sessionDurationMinutes <= 0) return const [];

    final result = <TimeRangeSession>[];
    int current = startMin;
    final step = sessionDurationMinutes + (breakDurationMinutes > 0 ? breakDurationMinutes : 0);
    while (current + sessionDurationMinutes <= endMin) {
      final s = current;
      final e = current + sessionDurationMinutes;
      result.add(
        TimeRangeSession(
          timeStart: _formatMinutes(s),
          timeEnd: _formatMinutes(e),
          quota: quotaPerSession,
        ),
      );
      if (step <= 0) break;
      current += step;
    }
    return result;
  }

  /// Apakah waktu sekarang (WIB) sudah melewati jam selesai praktik hari ini.
  bool isPracticeEndedNow() {
    if (!autoClose) return false;
    final now = AppDates.nowWib();
    final nowMin = now.hour * 60 + now.minute;
    final endMin = _parseMinutes(practiceEndTime);
    return nowMin >= endMin;
  }

  static int _parseMinutes(String hm) {
    final parts = hm.replaceAll(':', '.').split('.');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  static String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h.$m';
  }
}

/// Mewakili satu sesi waktu yang dihasilkan dari pembagian jam dokter.
class TimeRangeSession {
  final String timeStart;
  final String timeEnd;
  final int quota;

  const TimeRangeSession({
    required this.timeStart,
    required this.timeEnd,
    required this.quota,
  });

  /// Format tampil rentang: "09.00 - 09.15"
  String get displayRange => '$timeStart - $timeEnd';
}
