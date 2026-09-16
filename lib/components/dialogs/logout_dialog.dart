import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LogoutDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onConfirm;

  const LogoutDialog({
    super.key,
    this.title = 'Logout',
    this.message = 'Apakah Anda yakin ingin keluar?',
    this.onConfirm,
  });

  /// Static helper to display the logout dialog
  static Future<void> show(
    BuildContext context, {
    String title = 'Logout',
    String message = 'Apakah Anda yakin ingin keluar?',
    VoidCallback? onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => LogoutDialog(
        title: title,
        message: message,
        onConfirm: onConfirm ??
            () {
              Navigator.pop(dialogContext);
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 4,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Warning Icon + Title + Close Button
            Row(
              children: [
                // Circular Warning Icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.triangleAlert,
                      color: Color(0xFFEF4444),
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title "Logout"
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.2,
                  ),
                ),

                const Spacer(),

                // Close Button "X"
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    child: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Message: "Apakah Anda yakin ingin keluar?"
            Text(
              message,
              style: const TextStyle(
                fontSize: 14.5,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.normal,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 22),

            // Action Buttons: Batal & Logout
            Row(
              children: [
                // "Batal" button
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // "Logout" button
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onConfirm ??
                          () {
                            Navigator.pop(context);
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
