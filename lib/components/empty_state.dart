import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Empty state reusable untuk Skinora.
/// Hanya dirender ketika dataset benar-benar kosong — tidak menyentuh
/// UI yang data-nya sudah ada.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.noResult = false,
    this.color = const Color(0xFF8B2B38),
    this.backgroundColor = const Color(0xFFFFD5C8),
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Ukuran lebih kecil untuk empty state di dalam card / section / chat.
  final bool compact;

  /// Variasi copy untuk no-search-result (bukan first-time).
  final bool noResult;

  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 36.0 : 56.0;
    final iconBox = compact ? 64.0 : 88.0;
    final titleSize = compact ? 14.0 : 16.0;
    final descSize = compact ? 12.0 : 13.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16.0 : 28.0,
          vertical: compact ? 20.0 : 40.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(compact ? 16 : 24),
              ),
              child: Icon(icon, size: iconSize, color: color),
            ),
            SizedBox(height: compact ? 12 : 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3F141E),
                height: 1.3,
              ),
            ),
            if (description != null && description!.isNotEmpty) ...[
              SizedBox(height: compact ? 6 : 8),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: descSize,
                  color: const Color(0xFF8E8E93),
                  height: 1.4,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 14 : 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 22,
                    vertical: compact ? 10 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: TextStyle(
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// No-result state untuk search/filter yang tidak menemukan data.
/// Berbeda dari first-time empty state.
class NoSearchResultWidget extends StatelessWidget {
  const NoSearchResultWidget({
    super.key,
    required this.title,
    this.description,
    this.actionLabel = 'Hapus pencarian',
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: LucideIcons.searchX,
      title: title,
      description: description,
      actionLabel: onAction != null ? actionLabel : null,
      onAction: onAction,
      compact: compact,
      noResult: true,
      color: const Color(0xFF757575),
      backgroundColor: const Color(0xFFF0F0F0),
    );
  }
}

/// Compact empty state untuk section/card di dashboard.
class CompactEmptyState extends StatelessWidget {
  const CompactEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: icon,
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
      compact: true,
    );
  }
}

/// Empty state ringan di dalam area chat (tidak ambil banyak ruang).
class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({
    super.key,
    this.title = 'Belum ada pesan',
    this.description = 'Mulai percakapan dengan mengirim pesan.',
    this.icon = LucideIcons.messageCircle,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD5C8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 26, color: const Color(0xFF8B2B38)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3F141E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
