import 'package:flutter/material.dart';

enum ShippingStatus {
  pendingPickup('Pending Pickup', 0xFFD97706, 0xFFFEF3C7),
  inTransit('In Transit', 0xFF2563EB, 0xFFDBEAFE),
  outForDelivery('Out for Delivery', 0xFF7C3AED, 0xFFF3E8FF),
  delivered('Delivered', 0xFF059669, 0xFFD1FAE5),
  failedDelivery('Failed Delivery', 0xFFDC2626, 0xFFFEE2E2),
  returned('Returned to Store', 0xFF64748B, 0xFFF1F5F9);

  final String label;
  final int textColor;
  final int bgColor;

  const ShippingStatus(this.label, this.textColor, this.bgColor);
}

enum ShippingProcessType {
  orderFulfillment('Customer Order', Icons.shopping_bag_outlined, 0xFF2563EB),
  bnplDispatch('BNPL Device', Icons.credit_score_outlined, 0xFF7C3AED),
  repairReturn('Repaired Device Return', Icons.build_outlined, 0xFFD97706),
  swapExchange('Trade-in Exchange', Icons.swap_horiz_rounded, 0xFF059669),
  storeTransfer('Inter-Branch Transfer', Icons.storefront_outlined, 0xFF64748B);

  final String label;
  final IconData icon;
  final int colorValue;

  const ShippingProcessType(this.label, this.icon, this.colorValue);
}

class ShippingCheckpoint {
  final DateTime timestamp;
  final String location;
  final ShippingStatus status;
  final String note;
  final String updatedBy;

  ShippingCheckpoint({
    required this.timestamp,
    required this.location,
    required this.status,
    required this.note,
    this.updatedBy = 'Dispatch Manager',
  });
}

class ManagerShippingItem {
  final String id;
  final String trackingNumber;
  final String orderOrProcessId;
  final ShippingProcessType processType;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String destinationAddress;
  final String destinationCity;
  String courier;
  String dispatchRiderPhone;
  ShippingStatus status;
  final String itemsDescription;
  String lastLocationUpdate;
  DateTime estimatedDelivery;
  DateTime? dispatchedAt;
  DateTime? deliveredAt;
  List<ShippingCheckpoint> statusHistory;
  String managerNotes;

  ManagerShippingItem({
    required this.id,
    required this.trackingNumber,
    required this.orderOrProcessId,
    required this.processType,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.destinationAddress,
    required this.destinationCity,
    required this.courier,
    this.dispatchRiderPhone = '',
    required this.status,
    required this.itemsDescription,
    required this.lastLocationUpdate,
    required this.estimatedDelivery,
    this.dispatchedAt,
    this.deliveredAt,
    List<ShippingCheckpoint>? statusHistory,
    this.managerNotes = '',
  }) : statusHistory = statusHistory ?? [];
}
