enum OrderStatus {
  pending('Pending', 0xFFD97706, 0xFFFEF3C7),
  confirmed('Confirmed', 0xFF2563EB, 0xFFDBEAFE),
  dispatched('Dispatched', 0xFF7C3AED, 0xFFEDE9FE),
  delivered('Delivered', 0xFF059669, 0xFFD1FAE5),
  cancelled('Cancelled', 0xFFDC2626, 0xFFFEE2E2);

  final String label;
  final int textColor;
  final int bgColor;

  const OrderStatus(this.label, this.textColor, this.bgColor);
}

class OrderItem {
  final String title;
  final String brand;
  final double price;
  final int quantity;
  final String specs;

  const OrderItem({
    required this.title,
    required this.brand,
    required this.price,
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
    required this.paymentMethod,
    this.status = OrderStatus.pending,
  });

  String get itemsSummary => items.map((i) => '${i.quantity}x ${i.title}').join(', ');
}
