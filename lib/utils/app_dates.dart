import 'package:flutter/material.dart';

/// Helpers untuk format tanggal/waktu Indonesia (WIB, 24 jam, separator jam titik).
/// Contoh: "Jumat, 28 Agustus 2026", "27 Agu 2026", "2026-08-28", "13.00".
class AppDates {
  AppDates._();

  static const Duration _wibOffset = Duration(hours: 7);
  static const int _wibMarkerMicrosecond = 707;

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

  /// Apakah [dt] sudah dalam format WIB wall-clock yang dikenali oleh [AppDates]?
  static bool isWib(DateTime dt) =>
      dt.isUtc && dt.microsecond == _wibMarkerMicrosecond;

  /// Membungkus [dt] sebagai waktu WIB wall-clock yang teridentifikasi.
  static DateTime _asWib(DateTime dt) {
    return DateTime.utc(
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond,
      _wibMarkerMicrosecond,
    );
  }

  /// Waktu sekarang dalam WIB (UTC+7), wall-clock.
  static DateTime nowWib() {
    final utc = DateTime.now().toUtc();
    final shifted = utc.add(_wibOffset);
    return _asWib(shifted);
  }

  /// Konversi DateTime apa pun (lokal/UTC/Firestore Timestamp/sudah WIB) ke wall-clock WIB.
  /// Operasi ini idempoten: jika [dt] sudah WIB, tidak akan bergeser 7 jam lagi.
  static DateTime toWib(DateTime dt) {
    if (isWib(dt)) return dt;
    final utc = dt.isUtc ? dt : dt.toUtc();
    final shifted = utc.add(_wibOffset);
    return _asWib(shifted);
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
    var month = _months.indexWhere(
      (m) => m.toLowerCase() == parts[1].toLowerCase(),
    );
    if (month < 0) {
      month = _monthsShort.indexWhere(
        (m) => m.toLowerCase() == parts[1].toLowerCase(),
      );
    }
    final year = int.tryParse(parts[2]);
    if (day == null || month < 0 || year == null) return null;
    return _asWib(DateTime.utc(year, month + 1, day));
  }

  /// "2026-08-28" -> DateTime?
  static DateTime? tryParseIso(String input) {
    final parts = input.trim().split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return _asWib(DateTime.utc(y, m, d));
  }

  /// yyyy-MM-dd
  static String iso(DateTime d) {
    final w = toWib(d);
    return '${w.year.toString().padLeft(4, '0')}-'
        '${w.month.toString().padLeft(2, '0')}-'
        '${w.day.toString().padLeft(2, '0')}';
  }

  /// "Jumat, 28 Agustus 2026"
  static String display(DateTime d) {
    final w = toWib(d);
    return '${_days[w.weekday - 1]}, ${w.day} ${_months[w.month - 1]} ${w.year}';
  }

  /// "27 Agu 2026"
  static String short(DateTime d) {
    final w = toWib(d);
    return '${w.day} ${_monthsShort[w.month - 1]} ${w.year}';
  }

  static String _hmParts(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}.'
      '${minute.toString().padLeft(2, '0')}';

  static String _hmsParts(int hour, int minute, int second) =>
      '${hour.toString().padLeft(2, '0')}.'
      '${minute.toString().padLeft(2, '0')}.'
      '${second.toString().padLeft(2, '0')}';

  /// "2026-08-28 13.00" (WIB, 24 jam, separator jam titik)
  static String dateTime([DateTime? d]) {
    final w = toWib(d ?? nowWib());
    return '${iso(w)} ${_hmParts(w.hour, w.minute)}';
  }

  /// "28 Agu 2026, 13.00 WIB" atau "28 Agu 2026, 13.00.45 WIB"
  static String dateTimeWib(
    DateTime? d, {
    bool includeSeconds = false,
  }) {
    final w = toWib(d ?? nowWib());
    final time = includeSeconds
        ? _hmsParts(w.hour, w.minute, w.second)
        : _hmParts(w.hour, w.minute);
    return '${w.day} ${_monthsShort[w.month - 1]} ${w.year}, $time WIB';
  }

  /// "Jumat, 28 Agustus 2026 • 13.00 WIB" atau "Jumat, 28 Agustus 2026 • 13.00.45 WIB"
  static String fullDisplayWib(
    DateTime? d, {
    bool includeSeconds = false,
    bool withBullet = true,
  }) {
    final w = toWib(d ?? nowWib());
    final time = includeSeconds
        ? _hmsParts(w.hour, w.minute, w.second)
        : _hmParts(w.hour, w.minute);
    final sep = withBullet ? ' • ' : ', ';
    return '${_days[w.weekday - 1]}, ${w.day} ${_months[w.month - 1]} ${w.year}$sep$time WIB';
  }

  /// "13.00" (WIB, 24 jam)
  static String hm([DateTime? d]) {
    final w = toWib(d ?? nowWib());
    return _hmParts(w.hour, w.minute);
  }

  /// "13.00 WIB" (WIB, 24 jam)
  static String hmWib([DateTime? d]) {
    final w = toWib(d ?? nowWib());
    return '${_hmParts(w.hour, w.minute)} WIB';
  }

  /// "13.00.45" (WIB, 24 jam dengan detik)
  static String hms([DateTime? d]) {
    final w = toWib(d ?? nowWib());
    return _hmsParts(w.hour, w.minute, w.second);
  }

  /// "13.00.45 WIB" (WIB, 24 jam dengan detik)
  static String hmsWib([DateTime? d]) {
    final w = toWib(d ?? nowWib());
    return '${_hmsParts(w.hour, w.minute, w.second)} WIB';
  }

  /// Format waktu relatif dinamis WIB (mis. "Baru saja", "5 menit yang lalu", "Hari ini, 13.00 WIB", "Kemarin, 19.30 WIB", dll.).
  static String relativeWib(DateTime d) {
    final now = nowWib();
    final target = toWib(d);
    final diff = now.difference(target);

    if (diff.isNegative || diff.inSeconds < 45) {
      return 'Baru saja';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit yang lalu';
    }
    if (diff.inHours < 24 &&
        target.day == now.day &&
        target.month == now.month &&
        target.year == now.year) {
      return 'Hari ini, ${_hmParts(target.hour, target.minute)} WIB';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (target.day == yesterday.day &&
        target.month == yesterday.month &&
        target.year == yesterday.year) {
      return 'Kemarin, ${_hmParts(target.hour, target.minute)} WIB';
    }
    if (target.year == now.year) {
      return '${target.day} ${_monthsShort[target.month - 1]}, ${_hmParts(target.hour, target.minute)} WIB';
    }
    return '${target.day} ${_monthsShort[target.month - 1]} ${target.year}, ${_hmParts(target.hour, target.minute)} WIB';
  }

  /// Konversi aman dari berbagai tipe (Timestamp, DateTime, int epoch millis, String ISO)
  /// ke format tanggal/waktu WIB Indonesia.
  static String formatTimestampWib(
    Object? ts, {
    bool relative = false,
    bool includeSeconds = false,
  }) {
    if (ts == null) return '';
    DateTime dt;
    if (ts is DateTime) {
      dt = ts;
    } else {
      try {
        // ignore: avoid_dynamic_calls
        dt = (ts as dynamic).toDate() as DateTime;
      } catch (_) {
        if (ts is int) {
          dt = DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true);
        } else if (ts is String) {
          final parsed = DateTime.tryParse(ts);
          if (parsed != null) {
            dt = parsed;
          } else {
            return ts;
          }
        } else {
          return ts.toString();
        }
      }
    }
    if (relative) return relativeWib(dt);
    return dateTimeWib(dt, includeSeconds: includeSeconds);
  }

  /// Format tanggal & waktu khusus Skin Check dalam standar Indonesia WIB.
  /// Contoh: "Selasa, 29 September 2026 • 20.30 WIB" atau "Rabu, 30 September 2026 • 08.20 WIB".
  /// Aman dari pergeseran zona waktu ganda ("kebesokkannya") dan mendukung
  /// Timestamp Firestore, DateTime, int epoch millis, ISO string, atau fallback string.
  static String formatSkinCheckDateWib(
    Object? ts, {
    Map<String, dynamic>? doc,
    String? fallbackDisplay,
    bool withBullet = true,
  }) {
    // 1. Prioritaskan fallbackDisplay atau doc['createdDisplay'] bila sudah terformat lengkap
    final displayCandidate = (fallbackDisplay != null && fallbackDisplay.trim().isNotEmpty)
        ? fallbackDisplay.trim()
        : ((doc?['createdDisplay'] as String?)?.trim() ?? '');

    if (displayCandidate.isNotEmpty) {
      if (displayCandidate.toUpperCase().contains('WIB') &&
          (displayCandidate.contains('•') || displayCandidate.contains(',') || displayCandidate.contains('.'))) {
        return displayCandidate;
      }
      // Jika string tanggal saja mis. "2026-08-28" atau "Jumat, 28 Agustus 2026"
      final parsedDate = tryParseDisplay(displayCandidate) ?? tryParseIso(displayCandidate);
      if (parsedDate != null && ts == null && doc?['createdAt'] == null && doc?['createdAtMillis'] == null) {
        return fullDisplayWib(parsedDate, withBullet: withBullet);
      }
    }

    // 2. Evaluasi objek Timestamp / DateTime / millis aktual
    final candidateObj = ts ?? doc?['createdAt'] ?? doc?['createdAtMillis'];
    if (candidateObj != null) {
      DateTime? resolved;
      if (candidateObj is DateTime) {
        resolved = candidateObj;
      } else if (candidateObj is int) {
        resolved = DateTime.fromMillisecondsSinceEpoch(candidateObj, isUtc: true).add(_wibOffset);
      } else {
        try {
          // ignore: avoid_dynamic_calls
          final millis = (candidateObj as dynamic).millisecondsSinceEpoch;
          if (millis is int) {
            resolved = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).add(_wibOffset);
          }
        } catch (_) {}
        if (resolved == null) {
          try {
            // ignore: avoid_dynamic_calls
            final dt = (candidateObj as dynamic).toDate();
            if (dt is DateTime) {
              resolved = dt.isUtc ? dt.add(_wibOffset) : dt.toUtc().add(_wibOffset);
            }
          } catch (_) {}
        }
      }

      if (resolved != null) {
        return fullDisplayWib(_asWib(resolved), withBullet: withBullet);
      }

      if (candidateObj is String && candidateObj.trim().isNotEmpty) {
        final str = candidateObj.trim();
        if (str.toUpperCase().contains('WIB')) return str;
        final parsed = DateTime.tryParse(str);
        if (parsed != null) {
          if (!str.endsWith('Z') && !str.contains('+') && !str.contains('-') || str.length == 10) {
            // Wall-clock string tanpa penanda UTC
            return fullDisplayWib(_asWib(parsed), withBullet: withBullet);
          }
          final wib = parsed.toUtc().add(_wibOffset);
          return fullDisplayWib(_asWib(wib), withBullet: withBullet);
        }
      }
    }

    // 3. Fallback ke displayCandidate jika ada
    if (displayCandidate.isNotEmpty) {
      final parsed = tryParseDisplay(displayCandidate) ?? tryParseIso(displayCandidate);
      if (parsed != null) {
        return fullDisplayWib(parsed, withBullet: withBullet);
      }
      return displayCandidate;
    }

    // 4. Fallback ke doc['createdIso']
    final iso = (doc?['createdIso'] as String?)?.trim() ?? '';
    if (iso.isNotEmpty) {
      final parsed = tryParseIso(iso);
      if (parsed != null) {
        return fullDisplayWib(parsed, withBullet: withBullet);
      }
    }

    // 5. Fallback ke waktu sekarang WIB
    return fullDisplayWib(nowWib(), withBullet: withBullet);
  }

  /// Stream waktu realtime WIB yang memancarkan waktu setiap detik (atau interval yang dipilih).
  static Stream<DateTime> realtimeWibStream({
    Duration interval = const Duration(seconds: 1),
  }) {
    return Stream<DateTime>.periodic(interval, (_) => nowWib()).asBroadcastStream();
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
  static String formatRange(String raw, {bool withWib = false}) {
    final normalized = raw.trim().replaceAll(':', '.');
    final suffix = withWib ? ' WIB' : '';
    if (!normalized.contains('-')) return '${formatHm(normalized)}$suffix';
    final ends = normalized.split('-');
    if (ends.length != 2) return '$normalized$suffix';
    final a = formatHm(ends[0]);
    final b = formatHm(ends[1]);
    return '$a - $b$suffix';
  }

  /// Format jam chat konsisten 24 jam WIB Indonesia (mis. "14.30 WIB").
  /// Menerima DateTime, Timestamp Firestore, ISO String, atau jam "14:30"/"14.30".
  /// Bila [fallback] atau [raw] adalah Timestamp/DateTime, waktu server aktual tersebut
  /// akan diprioritaskan sehingga jam chat selalu real-time akurat dalam zona WIB.
  static String formatChatTimeWib(Object? raw, [Object? fallback]) {
    // Cari objek bertipe Timestamp atau DateTime terlebih dahulu (antara raw atau fallback)
    DateTime? resolvedDt;
    for (final candidate in [raw, fallback]) {
      if (candidate == null) continue;
      if (candidate is DateTime) {
        resolvedDt = candidate;
        break;
      }
      try {
        // ignore: avoid_dynamic_calls
        final dt = (candidate as dynamic).toDate();
        if (dt is DateTime) {
          resolvedDt = dt;
          break;
        }
      } catch (_) {}
    }

    if (resolvedDt != null) {
      return hmWib(resolvedDt);
    }

    // Jika keduanya bukan Timestamp/DateTime, gunakan string yang valid
    final candidateStr = (raw != null && raw.toString().trim().isNotEmpty)
        ? raw.toString().trim()
        : (fallback != null ? fallback.toString().trim() : '');

    if (candidateStr.isEmpty) {
      return hmWib(nowWib());
    }

    if (candidateStr.contains('T') || (candidateStr.contains('-') && candidateStr.length >= 10)) {
      final parsed = DateTime.tryParse(candidateStr);
      if (parsed != null) {
        return hmWib(parsed);
      }
    }
    if (candidateStr.toUpperCase().contains('WIB')) {
      final body = candidateStr.toUpperCase().replaceAll('WIB', '').trim();
      return '${formatHm(body)} WIB';
    }
    return '${formatHm(candidateStr)} WIB';
  }

  /// Slot sudah lewat (tanggal/jam WIB lampau)?
  /// Menerima dateIso ("yyyy-MM-dd"), [scheduleDate], atau jam "HH:mm"/"HH.mm"/"HH.mm - HH.mm WIB".
  static bool isPastSlot({
    required String dateIso,
    String? scheduleDate,
    String? timeEnd,
    String? timeStart,
  }) {
    DateTime? date;
    final trimmedIso = dateIso.trim();
    if (trimmedIso.isNotEmpty) {
      final cleanIso = trimmedIso.contains('•')
          ? trimmedIso.split('•').first.trim()
          : (trimmedIso.contains(' - ') && !trimmedIso.startsWith('202')
              ? trimmedIso.split(' - ').first.trim()
              : (trimmedIso.length >= 10 ? trimmedIso.substring(0, 10).trim() : trimmedIso));
      date = tryParseIso(cleanIso) ?? tryParseDisplay(cleanIso) ?? tryParseIso(trimmedIso) ?? tryParseDisplay(trimmedIso);
    }
    if (date == null && scheduleDate != null && scheduleDate.trim().isNotEmpty) {
      date = tryParseDisplay(scheduleDate) ?? tryParseIso(scheduleDate);
    }
    if (date == null) return false;
    final now = nowWib();
    final wallNow = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final wallDate = DateTime(date.year, date.month, date.day);
    if (wallDate.isBefore(DateTime(now.year, now.month, now.day))) return true;
    if (wallDate.isAfter(DateTime(now.year, now.month, now.day))) return false;

    // Hari ini sama dengan tanggal jadwal, cek jamnya
    var raw = (timeEnd != null && timeEnd.trim().isNotEmpty)
        ? timeEnd
        : ((timeStart != null && timeStart.trim().isNotEmpty)
            ? timeStart
            : '');
    if (raw.isEmpty) {
      if (dateIso.contains('•')) {
        raw = dateIso.split('•').last.trim();
      } else if (scheduleDate != null && scheduleDate.contains('•')) {
        raw = scheduleDate.split('•').last.trim();
      } else if (dateIso.contains(' - ') && !dateIso.startsWith('202')) {
        raw = dateIso.split(' - ').sublist(1).join(' - ').trim();
      } else if (scheduleDate != null && scheduleDate.contains(' - ') && !scheduleDate.startsWith('202')) {
        raw = scheduleDate.split(' - ').sublist(1).join(' - ').trim();
      }
    }
    if (raw.isEmpty) return false;
    final clean = raw.toUpperCase().replaceAll('WIB', '').trim();
    final parts = clean.replaceAll(':', '.').split('-');
    final normalized = parts.length > 1 ? parts.last.trim() : parts.first.trim();
    final hm = normalized.split('.');
    final h = int.tryParse(hm[0].trim());
    final m = hm.length > 1 ? int.tryParse(hm[1].trim()) : 0;
    if (h == null) return false;
    final wallEnd = DateTime(
      date.year,
      date.month,
      date.day,
      h,
      m ?? 0,
    );
    return !wallNow.isBefore(wallEnd);
  }

  /// Apakah slot konsultasi sedang aktif berlangsung saat ini (dalam rentang jam WIB)?
  static bool isSlotActive({
    required String dateIso,
    String? scheduleDate,
    String? timeStart,
    String? timeEnd,
  }) {
    DateTime? date;
    final trimmedIso = dateIso.trim();
    if (trimmedIso.isNotEmpty) {
      final cleanIso = trimmedIso.contains('•')
          ? trimmedIso.split('•').first.trim()
          : (trimmedIso.length >= 10 ? trimmedIso.substring(0, 10).trim() : trimmedIso);
      date = tryParseIso(cleanIso) ?? tryParseDisplay(cleanIso) ?? tryParseIso(trimmedIso);
    }
    if (date == null && scheduleDate != null && scheduleDate.trim().isNotEmpty) {
      date = tryParseDisplay(scheduleDate) ?? tryParseIso(scheduleDate);
    }
    if (date == null) return false;
    final now = nowWib();
    final wallNow = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final today = DateTime(now.year, now.month, now.day);
    final slotDay = DateTime(date.year, date.month, date.day);
    if (today != slotDay) return false;

    final rawStart = (timeStart != null && timeStart.isNotEmpty) ? timeStart : '';
    final rawEnd = (timeEnd != null && timeEnd.isNotEmpty) ? timeEnd : '';
    if (rawStart.isEmpty || rawEnd.isEmpty) return false;

    final cleanStart = rawStart.toUpperCase().replaceAll('WIB', '').trim();
    final cleanEnd = rawEnd.toUpperCase().replaceAll('WIB', '').trim();
    final startParts = cleanStart.replaceAll(':', '.').split('-').first.trim().split('.');
    final endParts = (cleanEnd.contains('-') ? cleanEnd.split('-').last : cleanEnd).replaceAll(':', '.').trim().split('.');
    final sh = int.tryParse(startParts[0].trim());
    final sm = startParts.length > 1 ? int.tryParse(startParts[1].trim()) : 0;
    final eh = int.tryParse(endParts[0].trim());
    final em = endParts.length > 1 ? int.tryParse(endParts[1].trim()) : 0;
    if (sh == null || eh == null) return false;

    final startDt = DateTime(date.year, date.month, date.day, sh, sm ?? 0);
    final endDt = DateTime(date.year, date.month, date.day, eh, em ?? 0);

    return !wallNow.isBefore(startDt) && wallNow.isBefore(endDt);
  }

  /// Apakah slot konsultasi belum dimulai (jadwal di masa depan)?
  static bool isSlotUpcoming({
    required String dateIso,
    String? scheduleDate,
    String? timeStart,
  }) {
    DateTime? date;
    final trimmedIso = dateIso.trim();
    if (trimmedIso.isNotEmpty) {
      final cleanIso = trimmedIso.contains('•')
          ? trimmedIso.split('•').first.trim()
          : (trimmedIso.length >= 10 ? trimmedIso.substring(0, 10).trim() : trimmedIso);
      date = tryParseIso(cleanIso) ?? tryParseDisplay(cleanIso) ?? tryParseIso(trimmedIso);
    }
    if (date == null && scheduleDate != null && scheduleDate.trim().isNotEmpty) {
      date = tryParseDisplay(scheduleDate) ?? tryParseIso(scheduleDate);
    }
    if (date == null) return false;
    final now = nowWib();
    final wallNow = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final today = DateTime(now.year, now.month, now.day);
    final slotDay = DateTime(date.year, date.month, date.day);
    if (slotDay.isAfter(today)) return true;
    if (slotDay.isBefore(today)) return false;

    final rawStart = (timeStart != null && timeStart.isNotEmpty) ? timeStart : '';
    if (rawStart.isEmpty) return false;
    final cleanStart = rawStart.toUpperCase().replaceAll('WIB', '').trim();
    final startParts = cleanStart.replaceAll(':', '.').split('-').first.trim().split('.');
    final sh = int.tryParse(startParts[0].trim());
    final sm = startParts.length > 1 ? int.tryParse(startParts[1].trim()) : 0;
    if (sh == null) return false;
    final startDt = DateTime(date.year, date.month, date.day, sh, sm ?? 0);
    return wallNow.isBefore(startDt);
  }

  /// Alias jelas untuk mengecek apakah sesi konsultasi sudah kadaluarsa berdasarkan jadwal.
  static bool isConsultationExpired({
    required String dateIso,
    String? scheduleDate,
    String? timeEnd,
    String? timeStart,
  }) {
    return isPastSlot(
      dateIso: dateIso,
      scheduleDate: scheduleDate,
      timeEnd: timeEnd,
      timeStart: timeStart,
    );
  }

  /// Sapaan waktu WIB: pagi/siang/sore/malam (tanpa koma di akhir).
  static String greetingWib() {
    final h = nowWib().hour;
    if (h < 4) return 'Selamat malam';
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  /// Waktu saat ini dalam WIB sebagai [TimeOfDay] Flutter.
  static TimeOfDay timeOfDayWib() {
    final now = nowWib();
    return TimeOfDay(hour: now.hour, minute: now.minute);
  }

  static String todayDisplay() => display(nowWib());

  static String todayDisplayWib() => '${display(nowWib())} WIB';

  static String todayIso() => iso(nowWib());
}
