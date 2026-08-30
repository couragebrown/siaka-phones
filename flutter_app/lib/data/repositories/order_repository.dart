import 'package:flutter/foundation.dart';
import '../../domain/models/order.dart';
import '../../domain/models/cart_item.dart';
import '../mock_data.dart';

class OrderRepository extends ChangeNotifier {
  final List<OrderModel> _orders = [
    OrderModel(
      orderId: 'SP-883921',
      date: DateTime.now().subtract(const Duration(days: 2)),
      items: [
        CartItem(
          id: 'c-prev-1',
          product: MockData.products[0],
          selectedColor: 'Titanium Cyber',
          selectedStorage: '512 GB',
          quantity: 1,
        ),
      ],
      subtotal: 1199.99,
      tax: 98.99,
      shippingFee: 0.0,
      totalAmount: 1298.98,
      shippingAddress: '742 Evergreen Terrace, Springfield, OR 97477',
      paymentMethod: 'Siaka Apple Pay (•••• 4092)',
      status: OrderStatus.shipped,
      trackingNumber: 'TRK-902847291-US',
    ),
    OrderModel(
      orderId: 'SP-771024',
      date: DateTime.now().subtract(const Duration(days: 14)),
      items: [
        CartItem(
          id: 'c-prev-2',
          product: MockData.products[3],
          selectedColor: 'Raw Titanium',
          selectedStorage: '32 GB',
          quantity: 1,
        ),
      ],
      subtotal: 349.99,
      tax: 28.87,
      shippingFee: 0.0,
      totalAmount: 378.86,
      shippingAddress: '742 Evergreen Terrace, Springfield, OR 97477',
      paymentMethod: 'Visa (•••• 8821)',
      status: OrderStatus.delivered,
      trackingNumber: 'TRK-881920199-US',
    ),
  ];

  List<OrderModel> get orders => List.unmodifiable(_orders);

  Future<OrderModel> placeOrder({
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double shippingFee,
    required double totalAmount,
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newOrder = OrderModel(
      orderId: 'SP-${100000 + _orders.length * 1111 + DateTime.now().millisecond}',
      date: DateTime.now(),
      items: List.from(items),
      subtotal: subtotal,
      tax: tax,
      shippingFee: shippingFee,
      totalAmount: totalAmount,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      status: OrderStatus.placed,
      trackingNumber: 'TRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}-US',
    );
    _orders.insert(0, newOrder);
    notifyListeners();
    return newOrder;
  }
}
