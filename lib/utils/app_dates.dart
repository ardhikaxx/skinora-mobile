/// Helpers untuk format tanggal/waktu Indonesia yang dipakai UI existing
/// (mis. "Jumat, 28 Agustus 2026", "27 Agu 2026", "2026-08-28", "09:01").
class AppDates {
  AppDates._();

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

  /// "2026-08-28 08:15"
  static String dateTime(DateTime d) =>
      '${iso(d)} ${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  /// "09:01"
  static String hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  static String todayDisplay() => display(DateTime.now());

  static String todayIso() => iso(DateTime.now());
}
