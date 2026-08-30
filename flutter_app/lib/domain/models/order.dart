import 'cart_item.dart';

enum OrderStatus { placed, processing, shipped, outForDelivery, delivered, cancelled }

class OrderModel {
  final String orderId;
  final DateTime date;
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double shippingFee;
  final double totalAmount;
  final String shippingAddress;
  final String paymentMethod;
  final OrderStatus status;
  final String trackingNumber;

  const OrderModel({
    required this.orderId,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shippingFee,
    required this.totalAmount,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.status,
    required this.trackingNumber,
  });

  String get statusDisplay {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
