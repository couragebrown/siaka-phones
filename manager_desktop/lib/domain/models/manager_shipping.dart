import 'package:flutter/material.dart';

enum ShippingStatus {
  placed('Order Placed', 0xFFD97706, 0xFFFEF3C7),
  processing('Processed & Packed', 0xFF2563EB, 0xFFDBEAFE),
  dispatched('Dispatched with Courier', 0xFF7C3AED, 0xFFEDE9FE),
  outForDelivery('Out for Delivery', 0xFF0284C7, 0xFFE0F2FE),
  delivered('Delivered to Destination', 0xFF059669, 0xFFD1FAE5),
  cancelled('Cancelled', 0xFFDC2626, 0xFFFEE2E2),
  returned('Returned to Store', 0xFF64748B, 0xFFF1F5F9);

  final String label;
  final int textColor;
  final int bgColor;

  const ShippingStatus(this.label, this.textColor, this.bgColor);

  static const ShippingStatus pendingPickup = ShippingStatus.placed;
  static const ShippingStatus inTransit = ShippingStatus.dispatched;
  static const ShippingStatus failedDelivery = ShippingStatus.cancelled;

  String get dbCondition {
    switch (this) {
      case ShippingStatus.placed:
        return 'placed';
      case ShippingStatus.processing:
        return 'processing';
      case ShippingStatus.dispatched:
        return 'shipped';
      case ShippingStatus.outForDelivery:
        return 'outForDelivery';
      case ShippingStatus.delivered:
        return 'delivered';
      case ShippingStatus.cancelled:
      case ShippingStatus.returned:
        return 'cancelled';
    }
  }

  String get defaultLocationHint {
    switch (this) {
      case ShippingStatus.placed:
        return 'Siaka Online Store • Order Placed & Confirmed';
      case ShippingStatus.processing:
        return 'Siaka Accra Hub • Quality Checked & Packaged';
      case ShippingStatus.dispatched:
        return 'Circle Main Hub • Dispatched with Courier En Route';
      case ShippingStatus.outForDelivery:
        return 'Out for Delivery • Courier Rider En Route to Recipient';
      case ShippingStatus.delivered:
        return 'Delivered and Verified with Customer';
      case ShippingStatus.cancelled:
      case ShippingStatus.returned:
        return 'Returned to Store / Cancelled';
    }
  }
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
