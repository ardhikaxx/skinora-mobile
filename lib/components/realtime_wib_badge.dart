import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../utils/app_dates.dart';

/// Style tampilan badge waktu realtime WIB.
enum RealtimeWibStyle {
  /// Capsule / Pill dengan background lembut dan border tipis (cocok di header).
  pill,

  /// Card berlatar putih dengan bayangan halus.
  card,

  /// Hanya teks waktu dan tanggal tanpa kontainer.
  minimal,
}

/// Widget penunjuk tanggal dan jam Waktu Indonesia Barat (WIB) yang berdetik realtime.
///
/// Menggunakan timer periodik yang dihentikan saat dispose sehingga hemat baterai
/// dan aman dari kebocoran memori.
class RealtimeWibBadge extends StatefulWidget {
  final RealtimeWibStyle style;
  final bool showDate;
  final bool includeSeconds;
  final bool compact;
  final Color? textColor;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const RealtimeWibBadge({
    super.key,
    this.style = RealtimeWibStyle.pill,
    this.showDate = true,
    this.includeSeconds = true,
    this.compact = true,
    this.textColor,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  State<RealtimeWibBadge> createState() => _RealtimeWibBadgeState();
}

class _RealtimeWibBadgeState extends State<RealtimeWibBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    final interval = widget.includeSeconds
        ? const Duration(seconds: 1)
        : const Duration(seconds: 10);
    _timer = Timer.periodic(interval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(RealtimeWibBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.includeSeconds != widget.includeSeconds) {
      _timer?.cancel();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const defaultPrimary = Color(0xFF8B2B38);
    const defaultDarkText = Color(0xFF3F141E);
    const defaultSubText = Color(0xFF6B7280);

    final now = AppDates.nowWib();
    final dateText = widget.compact ? AppDates.short(now) : AppDates.display(now);
    final timeText = widget.includeSeconds
        ? AppDates.hmsWib(now)
        : AppDates.hmWib(now);

    final label = widget.showDate ? '$dateText • $timeText' : timeText;

    if (widget.style == RealtimeWibStyle.minimal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.clock,
            size: widget.compact ? 13 : 15,
            color: widget.iconColor ?? defaultPrimary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: widget.compact ? 11.5 : 13.0,
              fontWeight: FontWeight.w600,
              color: widget.textColor ?? defaultDarkText,
              letterSpacing: -0.1,
            ),
          ),
        ],
      );
    }

    if (widget.style == RealtimeWibStyle.card) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.borderColor ?? const Color(0xFFEEEEEE),
            width: 1,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFFDE8EA),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  LucideIcons.clock,
                  size: 15,
                  color: widget.iconColor ?? defaultPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showDate)
                  Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: widget.textColor ?? defaultSubText,
                    ),
                  ),
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: widget.textColor ?? defaultDarkText,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Default: Pill
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 10 : 12,
        vertical: widget.compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.borderColor ?? const Color(0xFFFFD4D8),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.clock,
            size: widget.compact ? 12 : 14,
            color: widget.iconColor ?? defaultPrimary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: widget.compact ? 11.5 : 12.5,
              fontWeight: FontWeight.w600,
              color: widget.textColor ?? defaultPrimary,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
