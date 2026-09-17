import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AdminSuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onOk;

  const AdminSuccessDialog({
    super.key,
    this.title = 'Berhasil',
    required this.message,
    this.onOk,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Berhasil',
    required String message,
    VoidCallback? onOk,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AdminSuccessDialog(
        title: title,
        message: message,
        onOk: onOk,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryMaroon = Color(0xFFA83244);
    const darkText = Color(0xFF1E293B);

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 4,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Checkmark Icon + Title + Close Button
            Row(
              children: [
                // Circular Peach Checkmark Icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD5C8),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      color: Color(0xFFE65100),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title: "Berhasil"
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: darkText,
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

            const SizedBox(height: 14),

            // Message Body
            Text(
              message,
              style: const TextStyle(
                fontSize: 14.0,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.normal,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 20),

            // Action Button: "OK"
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onOk?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryMaroon,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const AdminConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.confirmColor = const Color(0xFFEF4444),
    required this.onConfirm,
    this.icon = LucideIcons.triangleAlert,
    this.iconColor = const Color(0xFFEF4444),
    this.iconBgColor = const Color(0xFFFEE2E2),
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    Color confirmColor = const Color(0xFFEF4444),
    required VoidCallback onConfirm,
    IconData icon = LucideIcons.triangleAlert,
    Color iconColor = const Color(0xFFEF4444),
    Color iconBgColor = const Color(0xFFFEE2E2),
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AdminConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        confirmColor: confirmColor,
        onConfirm: onConfirm,
        icon: icon,
        iconColor: iconColor,
        iconBgColor: iconBgColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkText = Color(0xFF1E293B);

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 4,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
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
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: darkText,
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

            const SizedBox(height: 14),

            // Message Body
            Text(
              message,
              style: const TextStyle(
                fontSize: 14.0,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.normal,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons: Batal & Confirm Button
            Row(
              children: [
                // "Batal"
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

                // Confirm Action Button
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(
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
