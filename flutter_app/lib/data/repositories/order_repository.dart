import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/order.dart';
import '../../domain/models/cart_item.dart';
import '../mock_data.dart';
import '../services/supabase_service.dart';

class OrderRepository extends ChangeNotifier {
  Timer? _syncPollTimer;
  StreamSubscription? _orderStreamSub;

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

  OrderRepository() {
    _initSupabaseSync();
  }

  void _initSupabaseSync() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _fetchRemoteOrders();
    _startRealtimeOrderStream();
    _syncPollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchRemoteOrders());
  }

  @override
  void dispose() {
    _syncPollTimer?.cancel();
    _orderStreamSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchRemoteOrders() async {
    try {
      final records = await SupabaseService().fetchOrderRecords();
      if (records != null && records.isNotEmpty) {
        _applyRemoteOrders(records);
      }
    } catch (_) {}
  }

  void _startRealtimeOrderStream() {
    try {
      final stream = SupabaseService().streamOrderRecords();
      if (stream != null) {
        _orderStreamSub = stream.listen((records) {
          _applyRemoteOrders(records);
        }, onError: (_) {});
      }
    } catch (_) {}
  }

  void _applyRemoteOrders(List<Map<String, dynamic>> records) {
    bool hasChanges = false;
    for (final map in records) {
      final rawId = map['id']?.toString() ?? '';
      final orderId = rawId.startsWith('ORDER_') ? rawId.substring(6) : rawId;
      final condition = map['condition']?.toString() ?? '';
      final newStatus = _parseOrderStatus(condition);

      final idx = _orders.indexWhere((o) => o.orderId == orderId || 'ORDER_${o.orderId}' == rawId);
      if (idx != -1) {
        if (_orders[idx].status != newStatus) {
          _orders[idx] = _orders[idx].copyWith(status: newStatus);
          hasChanges = true;
        }
      } else {
        final parsed = _orderFromSupabaseMap(map, orderId, newStatus);
        if (parsed != null) {
          _orders.add(parsed);
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      _orders.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  static OrderStatus _parseOrderStatus(String? condition) {
    final cond = (condition ?? '').toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('&', '').replaceAll('-', '');
    if (cond.contains('deliv')) return OrderStatus.delivered;
    if (cond.contains('outfor')) return OrderStatus.outForDelivery;
    if (cond.contains('dispatch') || cond.contains('courier') || cond.contains('ship') || cond.contains('transit')) {
      return OrderStatus.shipped;
    }
    if (cond.contains('process') || cond.contains('pack')) return OrderStatus.processing;
    if (cond.contains('cancel')) return OrderStatus.cancelled;
    return OrderStatus.placed;
  }

  OrderModel? _orderFromSupabaseMap(Map<String, dynamic> map, String orderId, OrderStatus status) {
    try {
      Map<String, dynamic> specs = {};
      if (map['specs'] != null) {
        final specsStr = map['specs'].toString();
        if (specsStr.startsWith('{')) {
          specs = jsonDecode(specsStr);
        }
      }

      final date = map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now();
      final total = (map['price'] as num?)?.toDouble() ?? 0.0;
      final subtotal = (map['original_price'] as num?)?.toDouble() ?? total;
      final address = specs['deliveryAddress']?.toString() ?? 'Accra, Ghana';
      final paymentMethod = map['brand']?.toString() ?? 'Mobile Money';
      final trackingNumber = specs['trackingNumber']?.toString() ?? (map['ram']?.toString() ?? 'TRK-GH-$orderId-SP');

      return OrderModel(
        orderId: orderId,
        date: date,
        items: [],
        subtotal: subtotal,
        tax: 0.0,
        shippingFee: 0.0,
        totalAmount: total,
        shippingAddress: address,
        paymentMethod: paymentMethod,
        status: status,
        trackingNumber: trackingNumber,
      );
    } catch (_) {
      return null;
    }
  }

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
