/// Helpers untuk format tanggal/waktu Indonesia (WIB, 24 jam, separator jam titik).
/// Contoh: "Jumat, 28 Agustus 2026", "27 Agu 2026", "2026-08-28", "13.00".
class AppDates {
  AppDates._();

  static const Duration _wibOffset = Duration(hours: 7);

  static const List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Waktu sekarang dalam WIB (UTC+7), wall-clock.
  static DateTime nowWib() =>
      DateTime.now().toUtc().add(_wibOffset);

  /// Konversi DateTime apa pun (lokal/UTC/Firestore Timestamp) ke wall-clock WIB.
  static DateTime toWib(DateTime dt) {
    final utc = dt.isUtc ? dt : dt.toUtc();
    return utc.add(_wibOffset);
  }

  /// "Jumat, 28 Agustus 2026" / "28 Agustus 2026" -> DateTime?
  static DateTime? tryParseDisplay(String input) {
    final cleaned = input.trim();
    var body = cleaned;
    if (body.contains(',')) {
      body = body.split(',').skip(1).join(',').trim();
    }
    final parts = body.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length < 3) return null;
    final day = int.tryParse(parts[0]);
    final month = _months.indexWhere(
      (m) => m.toLowerCase() == parts[1].toLowerCase(),
    );
    final year = int.tryParse(parts[2]);
    if (day == null || month < 0 || year == null) return null;
    return DateTime(year, month + 1, day);
  }

  /// "2026-08-28" -> DateTime?
  static DateTime? tryParseIso(String input) {
    final parts = input.trim().split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// yyyy-MM-dd
  static String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// "Jumat, 28 Agustus 2026"
  static String display(DateTime d) =>
      '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

  /// "27 Agu 2026"
  static String short(DateTime d) =>
      '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';

  static String _hmParts(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}.'
      '${minute.toString().padLeft(2, '0')}';

  /// "2026-08-28 13.00" (WIB, 24 jam, separator jam titik)
  static String dateTime(DateTime d) {
    final w = toWib(d);
    return '${iso(w)} ${_hmParts(w.hour, w.minute)}';
  }

  /// "13.00" (WIB, 24 jam)
  static String hm(DateTime d) {
    final w = toWib(d);
    return _hmParts(w.hour, w.minute);
  }

  /// Normalisasi jam apa pun ("13:00", "9:00", "13.00") → "13.00".
  static String formatHm(String raw) {
    final t = raw.trim().replaceAll(':', '.');
    final parts = t.split('.');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return t;
    return _hmParts(h, m);
  }

  /// "09:00 - 09:30" / "09.00 - 09.30" → "09.00 - 09.30"
  static String formatRange(String raw) {
    final normalized = raw.trim().replaceAll(':', '.');
    if (!normalized.contains('-')) return formatHm(normalized);
    final ends = normalized.split('-');
    if (ends.length != 2) return normalized;
    final a = formatHm(ends[0]);
    final b = formatHm(ends[1]);
    return '$a - $b';
  }

  /// Slot sudah lewat (tanggal/jam WIB lampau)? dateIso "yyyy-MM-dd", jam "HH:mm"/"HH.mm".
  static bool isPastSlot({
    required String dateIso,
    String? timeEnd,
    String? timeStart,
  }) {
    final date = tryParseIso(dateIso);
    if (date == null) return false;
    final now = nowWib();
    final wallNow = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final wallDate = DateTime(date.year, date.month, date.day);
    if (wallDate.isBefore(DateTime(now.year, now.month, now.day))) return true;
    if (wallDate.isAfter(DateTime(now.year, now.month, now.day))) return false;
    final raw = (timeEnd != null && timeEnd.isNotEmpty)
        ? timeEnd
        : (timeStart ?? '');
    if (raw.isEmpty) return false;
    final normalized = raw.replaceAll(':', '.').split('-').first.trim();
    final hm = normalized.split('.');
    final h = int.tryParse(hm[0]);
    final m = hm.length > 1 ? int.tryParse(hm[1]) : 0;
    if (h == null) return false;
    final wallEnd = DateTime(
      date.year,
      date.month,
      date.day,
      h,
      m ?? 0,
    );
    return wallEnd.isBefore(wallNow);
  }

  /// Sapaan waktu WIB: pagi/siang/sore/malam.
  static String greetingWib() {
    final h = nowWib().hour;
    if (h < 4) return 'Selamat malam,';
    if (h < 11) return 'Selamat pagi,';
    if (h < 15) return 'Selamat siang,';
    if (h < 19) return 'Selamat sore,';
    return 'Selamat malam,';
  }

  static String todayDisplay() => display(nowWib());

  static String todayIso() => iso(nowWib());
}
