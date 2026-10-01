enum OrderStatus {
  placed('Order Placed', 0xFFD97706, 0xFFFEF3C7),
  processing('Processed & Packed', 0xFF2563EB, 0xFFDBEAFE),
  shipped('Dispatched with Courier', 0xFF7C3AED, 0xFFEDE9FE),
  outForDelivery('Out for Delivery', 0xFF0284C7, 0xFFE0F2FE),
  delivered('Delivered to Destination', 0xFF059669, 0xFFD1FAE5),
  cancelled('Cancelled', 0xFFDC2626, 0xFFFEE2E2);

  final String label;
  final int textColor;
  final int bgColor;

  const OrderStatus(this.label, this.textColor, this.bgColor);

  static const OrderStatus pending = OrderStatus.placed;
  static const OrderStatus confirmed = OrderStatus.processing;
  static const OrderStatus dispatched = OrderStatus.shipped;
}

class OrderItem {
  final String title;
  final String brand;
  final double price;
  final double retailPrice;
  final double wholesalePrice;
  final double profit;
  final int quantity;
  final String specs;

  const OrderItem({
    required this.title,
    required this.brand,
    required this.price,
    this.retailPrice = 0.0,
    this.wholesalePrice = 0.0,
    this.profit = 0.0,
    required this.quantity,
    this.specs = '',
  });

  double get subtotal => price * quantity;
}

class ManagerOrder {
  final String id;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String deliveryAddress;
  final String region;
  final String gpsCode;
  final DateTime date;
  final List<OrderItem> items;
  final double totalAmount;
  final double profit;
  final String paymentMethod;
  OrderStatus status;

  ManagerOrder({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.region,
    required this.gpsCode,
    required this.date,
    required this.items,
    required this.totalAmount,
    this.profit = 0.0,
    required this.paymentMethod,
    this.status = OrderStatus.placed,
  });

  String get itemsSummary => items.map((i) => '${i.quantity}x ${i.title}').join(', ');
}
