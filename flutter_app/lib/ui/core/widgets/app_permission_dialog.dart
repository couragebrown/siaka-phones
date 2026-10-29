import 'package:flutter/material.dart';
import '../../../data/services/app_permission_service.dart';

class AppPermissionDialog extends StatelessWidget {
  final VoidCallback? onAllowAll;
  final VoidCallback? onDismiss;

  const AppPermissionDialog({
    super.key,
    this.onAllowAll,
    this.onDismiss,
  });

  /// Displays the permission dialog if the user has not yet seen/responded to it.
  static Future<void> showIfNeeded(BuildContext context) async {
    final shouldShow = await AppPermissionService.shouldShowPrompt();
    if (!shouldShow || !context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AppPermissionDialog(
        onAllowAll: () async {
          Navigator.of(dialogCtx).pop();
          await AppPermissionService.requestAllPermissions();
        },
        onDismiss: () async {
          Navigator.of(dialogCtx).pop();
          await AppPermissionService.markPromptCompleted();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 16,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Icon Badge
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0066FF).withValues(alpha: 0.32),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.security_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                const Text(
                  'Permissions Required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                const Text(
                  'To give you the best shopping, live order tracking, and delivery service, Siaka Phones needs the following permissions:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),

                // Permission Item 1: Notifications
                _buildPermissionCard(
                  icon: Icons.notifications_active_rounded,
                  iconColor: const Color(0xFF0066FF),
                  iconBg: const Color(0xFFEFF6FF),
                  title: 'Push Notifications',
                  subtitle:
                      'Live order tracking, delivery alerts & exclusive deals',
                ),
                const SizedBox(height: 9),

                // Permission Item 2: Location
                _buildPermissionCard(
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFF16A34A),
                  iconBg: const Color(0xFFF0FDF4),
                  title: 'Device Location',
                  subtitle:
                      'Accurate delivery autofill & finding nearest store',
                ),
                const SizedBox(height: 9),

                // Permission Item 3: Camera & Photos
                _buildPermissionCard(
                  icon: Icons.camera_alt_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  iconBg: const Color(0xFFFFFBEB),
                  title: 'Camera & Photos',
                  subtitle:
                      'Snap photos for phone trade-ins & repair diagnostics',
                ),
                const SizedBox(height: 20),

                // Primary Button: "Allow All Permissions"
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    key: const ValueKey('allow_all_permissions_btn'),
                    onPressed: () {
                      if (onAllowAll != null) {
                        onAllowAll!();
                      } else {
                        AppPermissionService.requestAllPermissions();
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D62FE),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor:
                          const Color(0xFF0D62FE).withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 19, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Allow All Permissions',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Secondary Text Button: "Maybe Later"
                TextButton(
                  key: const ValueKey('dismiss_permissions_btn'),
                  onPressed: () {
                    if (onDismiss != null) {
                      onDismiss!();
                    } else {
                      AppPermissionService.markPromptCompleted();
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1.5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Required',
              style: TextStyle(
                color: iconColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
