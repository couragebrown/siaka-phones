import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/order.dart';
import '../../domain/models/cart_item.dart';
import '../mock_data.dart';
import '../services/supabase_service.dart';

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
      shippingAddress: 'House No. 14, Airport Residential Area, Accra',
      paymentMethod: 'MTN Mobile Money (•••• 4092)',
      status: OrderStatus.shipped,
      trackingNumber: 'TRK-GH-883921-SP',
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
      shippingAddress: 'Plot 22, Boundary Road, East Legon, Accra',
      paymentMethod: 'Telecel Cash (•••• 8821)',
      status: OrderStatus.delivered,
      trackingNumber: 'TRK-GH-771024-SP',
    ),
  ];

  List<OrderModel> get orders => List.unmodifiable(_orders);

  OrderModel? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((o) => o.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      final old = _orders[index];
      _orders[index] = OrderModel(
        orderId: old.orderId,
        date: old.date,
        items: old.items,
        subtotal: old.subtotal,
        tax: old.tax,
        shippingFee: old.shippingFee,
        totalAmount: old.totalAmount,
        shippingAddress: old.shippingAddress,
        paymentMethod: old.paymentMethod,
        status: newStatus,
        trackingNumber: old.trackingNumber,
      );
      notifyListeners();
    }
  }

  void advanceOrderStatus(String orderId) {
    final order = getOrderById(orderId);
    if (order == null) return;
    switch (order.status) {
      case OrderStatus.placed:
        updateOrderStatus(orderId, OrderStatus.processing);
        break;
      case OrderStatus.processing:
        updateOrderStatus(orderId, OrderStatus.shipped);
        break;
      case OrderStatus.shipped:
        updateOrderStatus(orderId, OrderStatus.outForDelivery);
        break;
      case OrderStatus.outForDelivery:
        updateOrderStatus(orderId, OrderStatus.delivered);
        break;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        break;
    }
  }

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
      trackingNumber: 'TRK-GH-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}-SP',
    );
    _orders.insert(0, newOrder);
    notifyListeners();

    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      final itemsList = newOrder.items.map((i) {
        final wholesale = i.product.price;
        final retail = i.product.originalPrice > 0 ? i.product.originalPrice : i.product.price;
        final profitPerUnit = (retail - wholesale).abs();
        return {
          'title': i.product.name,
          'brand': i.product.brand,
          'price': i.product.price,
          'retailPrice': retail,
          'wholesalePrice': wholesale,
          'profit': profitPerUnit * i.quantity,
          'quantity': i.quantity,
          'specs': '${i.selectedStorage} • ${i.selectedColor}',
        };
      }).toList();

      final totalProfit = itemsList.fold(0.0, (acc, item) => acc + ((item['profit'] as num?)?.toDouble() ?? 0.0));

      final orderMap = {
        'id': 'ORDER_${newOrder.orderId}',
        'name': newOrder.items.isNotEmpty ? newOrder.items.first.product.name : 'Device Order',
        'brand': newOrder.paymentMethod,
        'category': 'ORDER_RECORD',
        'price': newOrder.totalAmount,
        'original_price': newOrder.subtotal,
        'stock': newOrder.items.fold(0, (sum, i) => sum + i.quantity),
        'specs': jsonEncode({
          'customerName': 'Siaka Customer',
          'customerEmail': 'customer@siakaphones.com',
          'customerPhone': '024 555 0192',
          'deliveryAddress': newOrder.shippingAddress,
          'region': 'Greater Accra',
          'gpsCode': 'GA-183-9021',
          'trackingNumber': newOrder.trackingNumber,
          'totalProfit': totalProfit,
          'items': itemsList,
        }),
        'condition': newOrder.status.name,
        'storage': newOrder.orderId,
        'ram': newOrder.trackingNumber,
        'created_at': newOrder.date.toIso8601String(),
      };

      SupabaseService().upsertRawRecord(orderMap);
    }

    return newOrder;
  }
}
