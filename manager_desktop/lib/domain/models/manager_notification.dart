import 'package:flutter/material.dart';

enum NotificationType {
  order('Customer Order', Icons.shopping_bag_rounded, 0xFF2563EB, 0xFFDBEAFE),
  bnpl('BNPL Credit', Icons.credit_score_rounded, 0xFF7C3AED, 0xFFF3E8FF),
  repair('Repair Service', Icons.build_rounded, 0xFFD97706, 0xFFFEF3C7),
  swap('Device Swap', Icons.swap_horiz_rounded, 0xFF059669, 0xFFDCFCE7),
  shipping('Shipping Update', Icons.local_shipping_rounded, 0xFF0284C7, 0xFFE0F2FE),
  inventory('Inventory & Stock', Icons.inventory_2_rounded, 0xFFEA580C, 0xFFFFEDD5),
  customerMessage('Customer Inquiry', Icons.chat_bubble_rounded, 0xFF4F46E5, 0xFFEEF2FF),
  system('System Notice', Icons.info_outline_rounded, 0xFF475569, 0xFFF1F5F9);

  final String label;
  final IconData icon;
  final int colorValue;
  final int bgColorValue;

  const NotificationType(this.label, this.icon, this.colorValue, this.bgColorValue);
}

enum NotificationSeverity {
  info('Info', 0xFF2563EB),
  success('Success', 0xFF059669),
  warning('Warning', 0xFFD97706),
  critical('Critical', 0xFFDC2626);

  final String label;
  final int colorValue;

  const NotificationSeverity(this.label, this.colorValue);
}

class ManagerNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationSeverity severity;
  final DateTime timestamp;
  bool isRead;
  final String? referenceId;
  final int? actionRouteIndex;

  ManagerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.severity = NotificationSeverity.info,
    required this.timestamp,
    this.isRead = false,
    this.referenceId,
    this.actionRouteIndex,
  });
}
