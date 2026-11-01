import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/services/app_permission_service.dart';

class _PermissionEntry {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  const _PermissionEntry({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });
}

class AppPermissionDialog extends StatefulWidget {
  final VoidCallback? onAllowAll;
  final VoidCallback? onDismiss;

  const AppPermissionDialog({
    super.key,
    this.onAllowAll,
    this.onDismiss,
  });

  /// All required device accesses needed across Siaka Phones.
  static const List<_PermissionEntry> _allPermissions = [
    _PermissionEntry(
      icon: Icons.notifications_active_rounded,
      iconColor: Color(0xFF0066FF),
      iconBg: Color(0xFFEFF6FF),
      title: 'Push Notifications',
      subtitle: 'Live order tracking, manager replies & exclusive deals',
    ),
    _PermissionEntry(
      icon: Icons.location_on_rounded,
      iconColor: Color(0xFF16A34A),
      iconBg: Color(0xFFF0FDF4),
      title: 'Device Location',
      subtitle: 'Live Ghana GPS code autofill, delivery & nearest store',
    ),
    _PermissionEntry(
      icon: Icons.camera_alt_rounded,
      iconColor: Color(0xFFF59E0B),
      iconBg: Color(0xFFFFFBEB),
      title: 'Camera & Photos',
      subtitle: 'Snap photos for phone trade-ins, repairs & Ghana Card ID',
    ),
    _PermissionEntry(
      icon: Icons.perm_media_rounded,
      iconColor: Color(0xFF7C3AED),
      iconBg: Color(0xFFF5F3FF),
      title: 'Videos, Audio & Storage',
      subtitle: 'Upload diagnostic videos/audio & save order invoices',
    ),
    _PermissionEntry(
      icon: Icons.mic_rounded,
      iconColor: Color(0xFFE11D48),
      iconBg: Color(0xFFFFF1F2),
      title: 'Microphone & Voice',
      subtitle: 'Record audio/video diagnostics for repairs & support',
    ),
    _PermissionEntry(
      icon: Icons.phone_in_talk_rounded,
      iconColor: Color(0xFF0D9488),
      iconBg: Color(0xFFF0FDFA),
      title: 'Phone & Direct Calls',
      subtitle: 'One-tap calls to Customer Care, Store Manager & riders',
    ),
    _PermissionEntry(
      icon: Icons.contacts_rounded,
      iconColor: Color(0xFF4F46E5),
      iconBg: Color(0xFFEEF2FF),
      title: 'Contacts Access',
      subtitle: 'Select delivery recipients & BNPL guarantor contacts',
    ),
    _PermissionEntry(
      icon: Icons.calendar_month_rounded,
      iconColor: Color(0xFFEA580C),
      iconBg: Color(0xFFFFF7ED),
      title: 'Calendar & Reminders',
      subtitle: 'Schedule repair bookings & BNPL installment reminders',
    ),
    _PermissionEntry(
      icon: Icons.bluetooth_connected_rounded,
      iconColor: Color(0xFF0284C7),
      iconBg: Color(0xFFF0F9FF),
      title: 'Nearby Devices & Bluetooth',
      subtitle: 'Swap hardware diagnostics, audio pairing & store check-in',
    ),
    _PermissionEntry(
      icon: Icons.fingerprint_rounded,
      iconColor: Color(0xFF059669),
      iconBg: Color(0xFFECFDF5),
      title: 'Biometric & Network Security',
      subtitle: 'Fingerprint / Face unlock for secure sign-in & checkout',
    ),
  ];

  /// Displays the permission dialog immediately on launch when newly installed,
  /// then triggers all native OS permission prompts right after the popup closes.
  static Future<void> showIfNeeded(BuildContext context) async {
    final shouldShow = await AppPermissionService.shouldShowPrompt();
    if (!shouldShow || !context.mounted) return;

    var allowAllRequested = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AppPermissionDialog(
        onAllowAll: () {
          allowAllRequested = true;
          Navigator.of(dialogCtx).pop();
        },
        onDismiss: () async {
          Navigator.of(dialogCtx).pop();
          await AppPermissionService.markPromptCompleted();
        },
      ),
    );

    if (!allowAllRequested) return;

    // Allow dialog close animation to finish on real devices before OS dialogs appear
    final isTestEnv = Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTestEnv) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }

    final statuses = await AppPermissionService.requestAllPermissions();
    if (isTestEnv || !context.mounted || statuses.isEmpty) return;

    final deniedCount = statuses.values.where((granted) => !granted).length;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    if (deniedCount == 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('All required app permissions granted.'),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '$deniedCount permission${deniedCount == 1 ? '' : 's'} still needed for full access.',
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Allow Now',
            textColor: const Color(0xFF60A5FA),
            onPressed: () async {
              final retry = await AppPermissionService.requestAllPermissions();
              if (retry.values.any((granted) => !granted)) {
                await AppPermissionService.openAppPermissionSettings();
              }
            },
          ),
        ),
      );
    }
  }

  @override
  State<AppPermissionDialog> createState() => _AppPermissionDialogState();
}

class _AppPermissionDialogState extends State<AppPermissionDialog> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxDialogHeight =
        (MediaQuery.sizeOf(context).height * 0.88).clamp(380.0, 720.0);

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 16,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: maxDialogHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Security Icon Badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0066FF).withValues(alpha: 0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.security_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Title
                const Text(
                  'Permissions Required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle
                const Text(
                  'Please allow all required accesses below so every Siaka Phones feature works seamlessly right after this popup:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    height: 1.32,
                  ),
                ),
                const SizedBox(height: 12),

                // Scrollable list of ALL required permissions
                Flexible(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(right: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0;
                              i < AppPermissionDialog._allPermissions.length;
                              i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _buildPermissionCard(
                              AppPermissionDialog._allPermissions[i],
                            ),
                          ],
                        ],
                      ),
                    ),
                ),
                ),
                const SizedBox(height: 10),

                // Hint banner for post-popup OS prompts
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(9),
                    border:
                        Border.all(color: const Color(0xFFBFDBFE), width: 0.9),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: Color(0xFF1D4ED8),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'After tapping below, tap "Allow" on each device prompt to enable all accesses.',
                          style: TextStyle(
                            color: Color(0xFF1E40AF),
                            fontSize: 10.8,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Primary Button: "Allow All Permissions"
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    key: const ValueKey('allow_all_permissions_btn'),
                    onPressed: () {
                      if (widget.onAllowAll != null) {
                        widget.onAllowAll!();
                      } else {
                        Navigator.of(context).pop();
                        AppPermissionService.requestAllPermissions();
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
                        Icon(
                          Icons.check_circle_rounded,
                          size: 19,
                          color: Colors.white,
                        ),
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
                const SizedBox(height: 2),

                // Secondary Text Button: "Maybe Later"
                SizedBox(
                  height: 34,
                  child: TextButton(
                    key: const ValueKey('dismiss_permissions_btn'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      if (widget.onDismiss != null) {
                        widget.onDismiss!();
                      } else {
                        AppPermissionService.markPromptCompleted();
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text(
                      'Maybe Later',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildPermissionCard(_PermissionEntry item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Icon(item.icon, color: item.iconColor, size: 19),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1.5),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.8,
                    height: 1.22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Required',
              style: TextStyle(
                color: item.iconColor,
                fontSize: 9.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
