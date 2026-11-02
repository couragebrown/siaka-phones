import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/order.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/product.dart';
import '../mock_data.dart';
import '../services/order_id_service.dart';
import '../services/supabase_service.dart';
import 'customer_notification_repository.dart';
import 'user_repository.dart';

class OrderRepository extends ChangeNotifier {
  Timer? _syncPollTimer;
  StreamSubscription? _orderStreamSub;
  HttpClient? _localSseClient;
  bool _isDisposed = false;

  final List<OrderModel> _orders = [];
  final Map<String, String> _legacyRemoteIdMap = {};

  OrderRepository({List<OrderModel>? initialOrders}) {
    if (initialOrders != null) {
      _orders.addAll(initialOrders);
    }
    _initSupabaseSync();
  }

  static List<OrderModel> get sampleOrders => [
    OrderModel(
      orderId: 'ORD-000002',
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
      trackingNumber: 'TRK-GH-000002-SP',
    ),
    OrderModel(
      orderId: 'ORD-000001',
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
      trackingNumber: 'TRK-GH-000001-SP',
    ),
  ];

  void _initSupabaseSync() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _fetchLocalManagerOrders();
    _fetchRemoteOrders();
    _startRealtimeOrderStream();
    _listenLocalOrderEvents();
    _syncPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchLocalManagerOrders();
      if (!SupabaseService.isQuotaRestricted) {
        _fetchRemoteOrders();
      }
    });
  }

  void _listenLocalOrderEvents() async {
    if (_isDisposed) return;
    try {
      final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      _localSseClient?.close(force: true);
      _localSseClient = HttpClient()..connectionTimeout = const Duration(seconds: 2);
      final request = await _localSseClient!.getUrl(Uri.parse('http://$host:8088/api/events'));
      request.headers.set('Accept', 'text/event-stream');
      final response = await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        response.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
          if (line.startsWith('data:')) {
            try {
              final jsonStr = line.substring(5).trim();
              if (jsonStr.startsWith('{')) {
                final data = jsonDecode(jsonStr) as Map<String, dynamic>;
                _handleInboundOrderUpdate(data);
              }
            } catch (_) {}
          }
        }, onDone: () {
          if (!_isDisposed) {
            Future.delayed(const Duration(seconds: 3), _listenLocalOrderEvents);
          }
        }, onError: (_) {
          if (!_isDisposed) {
            Future.delayed(const Duration(seconds: 3), _listenLocalOrderEvents);
          }
        });
      } else {
        if (!_isDisposed) {
          Future.delayed(const Duration(seconds: 4), _listenLocalOrderEvents);
        }
      }
    } catch (_) {
      if (!_isDisposed) {
        Future.delayed(const Duration(seconds: 4), _listenLocalOrderEvents);
      }
    }
  }

  void _handleInboundOrderUpdate(Map<String, dynamic> data) {
    try {
      final rawId = (data['orderId'] ?? data['id'] ?? '').toString();
      if (rawId.isEmpty) return;
      final canonicalId = _normalizeOrAssignOrderId(rawId);
      final cleanDigits = canonicalId.replaceFirst('ORD-', '');
      final idx = _orders.indexWhere((o) {
        final oClean = o.orderId.replaceFirst('ORD-', '');
        return o.orderId == canonicalId || oClean == cleanDigits || o.orderId == rawId;
      });

      if (idx != -1) {
        final existing = _orders[idx];
        final newStatus = data['status'] != null ? _parseOrderStatus(data['status'].toString()) : existing.status;
        final newCourier = data['courier']?.toString() ?? existing.courierName;
        final newRiderPhone = data['riderPhone']?.toString() ?? existing.riderPhone;
        final newLoc = data['lastLocationUpdate']?.toString() ?? existing.lastLocationUpdate;
        final newTracking = data['trackingNumber']?.toString() ?? existing.trackingNumber;
        final newEst = data['estimatedDelivery'] != null
            ? DateTime.tryParse(data['estimatedDelivery'].toString()) ?? existing.estimatedDelivery
            : existing.estimatedDelivery;

        _orders[idx] = existing.copyWith(
          orderId: canonicalId,
          status: newStatus,
          courierName: newCourier,
          riderPhone: newRiderPhone,
          lastLocationUpdate: newLoc,
          trackingNumber: newTracking,
          estimatedDelivery: newEst,
        );
        notifyListeners();
      } else {
        // Trigger immediate fetch to pull down the order details
        _fetchLocalManagerOrders();
      }
    } catch (_) {}
  }

  Future<void> refreshOrdersNow() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    await _fetchLocalManagerOrders();
    if (!SupabaseService.isQuotaRestricted) {
      await _fetchRemoteOrders();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _syncPollTimer?.cancel();
    _localSseClient?.close(force: true);
    _orderStreamSub?.cancel();
    super.dispose();
  }

  CartItem _buildCartItemFromMap(Map<String, dynamic> itemMap, String orderId, int idx) {
    final title = itemMap['title']?.toString() ?? 'Device';
    final brand = itemMap['brand']?.toString() ?? 'Apple';
    final price = (itemMap['price'] as num?)?.toDouble() ?? 0.0;
    final qty = (itemMap['quantity'] as num?)?.toInt() ?? 1;
    final specsStr = itemMap['specs']?.toString() ?? '';
    final specParts = specsStr.split('•').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final storage = specParts.isNotEmpty ? specParts.first : '256 GB';
    final color = specParts.length > 1 ? specParts[1] : 'Natural Titanium';

    Product? matched;
    for (final p in MockData.products) {
      if (p.name.toLowerCase() == title.toLowerCase() ||
          p.name.toLowerCase().contains(title.toLowerCase()) ||
          title.toLowerCase().contains(p.name.toLowerCase())) {
        matched = p;
        break;
      }
    }
    final product = matched ??
        Product(
          id: 'ord-prod-$orderId-$idx',
          name: title,
          brand: brand,
          category: 'Smartphones',
          price: price,
          originalPrice: price,
          rating: 4.8,
          reviewCount: 24,
          description: title,
          images: const [],
          colors: [color],
          storageOptions: [storage],
          specs: const {},
        );

    return CartItem(
      id: 'ci-$orderId-$idx',
      product: product,
      selectedColor: color,
      selectedStorage: storage,
      quantity: qty > 0 ? qty : 1,
    );
  }

  Future<void> _fetchLocalManagerOrders() async {
    try {
      final profile = UserRepository.instance.profile;
      final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      final knownIds = _orders.map((o) => o.orderId).where((id) => id.isNotEmpty).join(',');
      final queryParams = <String, String>{
        'email': profile.email,
        'phone': profile.phone,
        'name': profile.name,
      };
      if (knownIds.isNotEmpty) {
        queryParams['orderIds'] = knownIds;
      }
      final uri = Uri.parse('http://$host:8088/api/orders').replace(
        queryParameters: queryParams,
      );
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 900);
      final req = await client.getUrl(uri);
      final resp = await req.close().timeout(const Duration(milliseconds: 900));
      if (resp.statusCode != HttpStatus.ok) return;
      final body = await resp.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! List) return;

      bool hasChanges = false;
      for (final raw in decoded) {
        final m = Map<String, dynamic>.from(raw as Map);
        final rawId = (m['orderId'] ?? m['id'] ?? '').toString();
        if (rawId.isEmpty) continue;
        final canonicalId = _normalizeOrAssignOrderId(rawId);
        final status = _parseOrderStatus(m['status']?.toString());
        final courier = m['courier']?.toString() ?? 'Circle Express Logistics';
        final riderPhone = m['riderPhone']?.toString() ?? '';
        final lastLoc = m['lastLocationUpdate']?.toString() ?? '';
        final trackingNum = m['trackingNumber']?.toString() ?? 'TRK-GH-${canonicalId.replaceFirst('ORD-', '')}-SP';
        final estDelivery = m['estimatedDelivery'] != null
            ? DateTime.tryParse(m['estimatedDelivery'].toString())
            : null;

        final idx = _orders.indexWhere((o) => o.orderId == canonicalId || o.orderId == rawId);
        if (idx != -1) {
          final existing = _orders[idx];
          if (existing.status != status ||
              existing.orderId != canonicalId ||
              existing.courierName != courier ||
              existing.riderPhone != riderPhone ||
              existing.lastLocationUpdate != lastLoc ||
              existing.trackingNumber != trackingNum ||
              existing.estimatedDelivery != estDelivery) {
            _orders[idx] = existing.copyWith(
              orderId: canonicalId,
              status: status,
              courierName: courier,
              riderPhone: riderPhone,
              lastLocationUpdate: lastLoc,
              trackingNumber: trackingNum,
              estimatedDelivery: estDelivery,
            );
            hasChanges = true;
          }
        } else {
          final rawItems = (m['items'] as List?) ?? const [];
          final cartItems = <CartItem>[];
          for (var i = 0; i < rawItems.length; i++) {
            cartItems.add(
              _buildCartItemFromMap(Map<String, dynamic>.from(rawItems[i] as Map), canonicalId, i),
            );
          }
          final totalAmt = (m['totalAmount'] as num?)?.toDouble() ?? 0.0;
          final parsedDate =
              DateTime.tryParse((m['date'] ?? '').toString())?.toLocal() ?? DateTime.now();
          _orders.add(
            OrderModel(
              orderId: canonicalId,
              date: parsedDate,
              items: cartItems,
              subtotal: totalAmt,
              tax: 0.0,
              shippingFee: 0.0,
              totalAmount: totalAmt,
              shippingAddress: m['deliveryAddress']?.toString() ?? 'Accra, Ghana',
              paymentMethod: m['paymentMethod']?.toString() ?? 'Mobile Money',
              status: status,
              trackingNumber: trackingNum,
              courierName: courier,
              riderPhone: riderPhone,
              lastLocationUpdate: lastLoc,
              estimatedDelivery: estDelivery,
            ),
          );
          OrderIdService.observeOrderId(canonicalId);
          hasChanges = true;
        }
      }
      if (hasChanges) {
        _orders.sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      }
    } catch (_) {}
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

  String _normalizeOrAssignOrderId(String rawOrderId) {
    final seq = OrderIdService.extractOrderSeq(rawOrderId);
    if (seq != null && seq > 0) {
      return OrderIdService.formatOrderId(seq);
    }
    final clean = rawOrderId.replaceFirst('ORDER_', '').trim();
    if (clean.isNotEmpty && _legacyRemoteIdMap.containsKey(clean)) {
      return _legacyRemoteIdMap[clean]!;
    }
    int maxSeq = 0;
    for (final o in _orders) {
      final s = OrderIdService.extractOrderSeq(o.orderId);
      if (s != null && s > maxSeq) maxSeq = s;
    }
    for (final mapped in _legacyRemoteIdMap.values) {
      final s = OrderIdService.extractOrderSeq(mapped);
      if (s != null && s > maxSeq) maxSeq = s;
    }
    final assigned = OrderIdService.formatOrderId(maxSeq + 1);
    if (clean.isNotEmpty) {
      _legacyRemoteIdMap[clean] = assigned;
    }
    return assigned;
  }

  void _applyRemoteOrders(List<Map<String, dynamic>> records) {
    bool hasChanges = false;
    final sortedRecords = List<Map<String, dynamic>>.from(records)
      ..sort((a, b) {
        final da = DateTime.tryParse((a['created_at'] ?? '').toString()) ?? DateTime(2000);
        final db = DateTime.tryParse((b['created_at'] ?? '').toString()) ?? DateTime(2000);
        return da.compareTo(db);
      });

    for (final map in sortedRecords) {
      final rawId = map['id']?.toString() ?? '';
      final stripped = rawId.startsWith('ORDER_') ? rawId.substring(6) : rawId;
      final condition = map['condition']?.toString() ?? '';
      final newStatus = _parseOrderStatus(condition);

      final mappedExisting = _legacyRemoteIdMap[stripped];
      final directSeq = OrderIdService.extractOrderSeq(stripped);
      final lookupId = directSeq != null
          ? OrderIdService.formatOrderId(directSeq)
          : (mappedExisting ?? stripped);

      final idx = _orders.indexWhere(
        (o) => o.orderId == lookupId || o.orderId == stripped || 'ORDER_${o.orderId}' == rawId,
      );
      if (idx != -1) {
        if (_orders[idx].status != newStatus) {
          _orders[idx] = _orders[idx].copyWith(status: newStatus);
          hasChanges = true;
        }
      } else {
        final parsed = _orderFromSupabaseMap(map, stripped, newStatus);
        if (parsed != null) {
          final canonicalId = _normalizeOrAssignOrderId(stripped);
          final normalizedOrder = parsed.orderId == canonicalId
              ? parsed
              : OrderModel(
                  orderId: canonicalId,
                  date: parsed.date,
                  items: parsed.items,
                  subtotal: parsed.subtotal,
                  tax: parsed.tax,
                  shippingFee: parsed.shippingFee,
                  totalAmount: parsed.totalAmount,
                  shippingAddress: parsed.shippingAddress,
                  paymentMethod: parsed.paymentMethod,
                  status: parsed.status,
                  trackingNumber: parsed.trackingNumber,
                );
          _orders.add(normalizedOrder);
          OrderIdService.observeOrderId(canonicalId);
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
    final cond = (condition ?? '')
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('&', '')
        .replaceAll('-', '');
    if (cond.contains('deliv')) return OrderStatus.delivered;
    if (cond.contains('outfor')) return OrderStatus.outForDelivery;
    if (cond.contains('dispatch') ||
        cond.contains('courier') ||
        cond.contains('ship') ||
        cond.contains('transit')) {
      return OrderStatus.shipped;
    }
    if (cond.contains('process') || cond.contains('pack')) return OrderStatus.processing;
    if (cond.contains('cancel')) return OrderStatus.cancelled;
    return OrderStatus.placed;
  }

  OrderModel? _orderFromSupabaseMap(
    Map<String, dynamic> map,
    String orderId,
    OrderStatus status,
  ) {
    try {
      Map<String, dynamic> specs = {};
      if (map['specs'] != null) {
        final specsStr = map['specs'].toString();
        if (specsStr.startsWith('{')) {
          specs = jsonDecode(specsStr);
        }
      }

      final customerId = specs['customerId']?.toString();
      final currentUserId = UserRepository.instance.profile.id;
      if (customerId == null || customerId.isEmpty || customerId != currentUserId) {
        return null;
      }

      final rawItems = (specs['items'] as List?) ?? const [];
      final cartItems = <CartItem>[];
      for (var i = 0; i < rawItems.length; i++) {
        cartItems.add(
          _buildCartItemFromMap(Map<String, dynamic>.from(rawItems[i] as Map), orderId, i),
        );
      }

      final date = map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now();
      final total = (map['price'] as num?)?.toDouble() ?? 0.0;
      final subtotal = (map['original_price'] as num?)?.toDouble() ?? total;
      final address = specs['deliveryAddress']?.toString() ?? 'Accra, Ghana';
      final paymentMethod = map['brand']?.toString() ?? 'Mobile Money';
      final trackingNumber =
          specs['trackingNumber']?.toString() ?? (map['ram']?.toString() ?? 'TRK-GH-$orderId-SP');

      return OrderModel(
        orderId: orderId,
        date: date,
        items: cartItems,
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
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final nextOrderId = await OrderIdService.generateNextOrderId(
      existingOrderIds: _orders.map((o) => o.orderId),
    );
    final seqDigits = nextOrderId.replaceFirst('ORD-', '');

    final newOrder = OrderModel(
      orderId: nextOrderId,
      date: DateTime.now(),
      items: List.from(items),
      subtotal: subtotal,
      tax: tax,
      shippingFee: shippingFee,
      totalAmount: totalAmount,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      status: OrderStatus.placed,
      trackingNumber: 'TRK-GH-$seqDigits-SP',
    );
    _orders.insert(0, newOrder);
    notifyListeners();

    CustomerNotificationRepository.instance.addOrderPlacedNotification(
      orderId: newOrder.orderId,
      totalAmount: newOrder.totalAmount,
    );

    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      final profile = UserRepository.instance.profile;
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

      final totalProfit = itemsList.fold(
        0.0,
        (acc, item) => acc + ((item['profit'] as num?)?.toDouble() ?? 0.0),
      );

      final orderMap = {
        'id': 'ORDER_${newOrder.orderId}',
        'name': newOrder.items.isNotEmpty ? newOrder.items.first.product.name : 'Device Order',
        'brand': newOrder.paymentMethod,
        'category': 'ORDER_RECORD',
        'price': newOrder.totalAmount,
        'original_price': newOrder.subtotal,
        'stock': newOrder.items.fold(0, (sum, i) => sum + i.quantity),
        'specs': jsonEncode({
          'customerId': profile.id,
          'customerName': profile.name,
          'customerEmail': profile.email,
          'customerPhone': profile.phone,
          'deliveryAddress': newOrder.shippingAddress,
          'region': profile.region.isNotEmpty ? profile.region : 'Greater Accra',
          'gpsCode': profile.gpsCode.isNotEmpty ? profile.gpsCode : 'GA-183-9021',
          'trackingNumber': newOrder.trackingNumber,
          'totalProfit': totalProfit,
          'items': itemsList,
        }),
        'condition': newOrder.status.name,
        'storage': newOrder.orderId,
        'ram': newOrder.trackingNumber,
        'created_at': newOrder.date.toIso8601String(),
      };

      // 1. Sync order to Supabase
      SupabaseService().upsertRawRecord(orderMap);

      // 2. Sync notification to Supabase for manager desktop
      SupabaseService().upsertNotificationRaw({
        'id': 'NOTIF_ORDER_${newOrder.orderId}',
        'title': 'New Customer Order Placed',
        'message':
            'Order #${newOrder.orderId} for GH₵${newOrder.totalAmount.toStringAsFixed(2)} placed by customer',
        'type': 'order',
        'target': 'manager',
        'reference_id': newOrder.orderId,
        'is_read': false,
        'created_at': newOrder.date.toIso8601String(),
      });

      // 3. Post directly to local PC Manager if available on network
      () async {
        try {
          final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
          final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1000);
          final req = await client.postUrl(Uri.parse('http://$host:8088/api/orders'));
          req.headers.contentType = ContentType.json;
          req.write(jsonEncode(orderMap));
          final resp = await req.close();
          if (resp.statusCode == HttpStatus.ok) {
            final body = await resp.transform(utf8.decoder).join();
            final json = jsonDecode(body) as Map<String, dynamic>;
            final assigned = json['orderId']?.toString();
            if (assigned != null && assigned.isNotEmpty) {
              await OrderIdService.observeOrderId(assigned);
              if (assigned != newOrder.orderId) {
                final idx = _orders.indexWhere((o) => o.orderId == newOrder.orderId);
                if (idx != -1) {
                  _orders[idx] = OrderModel(
                    orderId: assigned,
                    date: _orders[idx].date,
                    items: _orders[idx].items,
                    subtotal: _orders[idx].subtotal,
                    tax: _orders[idx].tax,
                    shippingFee: _orders[idx].shippingFee,
                    totalAmount: _orders[idx].totalAmount,
                    shippingAddress: _orders[idx].shippingAddress,
                    paymentMethod: _orders[idx].paymentMethod,
                    status: _orders[idx].status,
                    trackingNumber: 'TRK-GH-${assigned.replaceFirst('ORD-', '')}-SP',
                  );
                  notifyListeners();
                }
              }
            }
          }
        } catch (_) {}

        try {
          final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
          final notifClient = HttpClient()..connectionTimeout = const Duration(milliseconds: 1000);
          final notifReq =
              await notifClient.postUrl(Uri.parse('http://$host:8088/api/notifications'));
          notifReq.headers.contentType = ContentType.json;
          notifReq.write(jsonEncode({
            'id': 'NOTIF_ORDER_${newOrder.orderId}',
            'title': 'New Customer Order Placed',
            'message':
                'Order #${newOrder.orderId} for GH₵${newOrder.totalAmount.toStringAsFixed(2)} placed by customer',
            'type': 'order',
            'target': 'manager',
            'orderId': newOrder.orderId,
          }));
          await notifReq.close();
        } catch (_) {}
      }();
    }

    return newOrder;
  }
}
