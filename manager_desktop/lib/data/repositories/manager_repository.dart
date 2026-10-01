import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/models/customer_activity.dart';
import '../../domain/models/customer_message.dart';
import '../../domain/models/manager_bnpl.dart';
import '../../domain/models/manager_notification.dart';
import '../../domain/models/manager_order.dart';
import '../../domain/models/manager_product.dart';
import '../../domain/models/manager_repair.dart';
import '../../domain/models/manager_shipping.dart';
import '../../domain/models/manager_swap.dart';
import '../../domain/models/service_ticket.dart';
import '../../domain/models/advertisement_banner.dart';
import '../mock_manager_data.dart';
import '../services/supabase_service.dart';

class ManagerRepository extends ChangeNotifier {
  Timer? _syncPollTimer;
  List<ManagerProduct> _products = [];
  List<ManagerOrder> _orders = [];
  List<AdvertisementBanner> _advertisements = [];
  List<ManagerBnpl> _bnplApplications = [];
  List<ManagerRepair> _repairs = [];
  List<ManagerSwap> _swaps = [];
  List<CustomerActivity> _customers = [];
  List<CustomerMessage> _sentMessages = [];
  List<ServiceTicket> _serviceTickets = [];
  List<ManagerShippingItem> _shipments = [];
  List<ManagerNotification> _notifications = [];
  Map<String, List<String>> _brandModels = {};
  final List<String> _categories = [
    'Smartphones',
    'Phones',
    'Laptops',
    'Tablets',
    'Smartwatches',
    'Accessories',
    'Audio & Sound',
    'Gaming & Consoles',
  ];

  final SupabaseService _supabase = SupabaseService();
  SupabaseService get supabase => _supabase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 24-Hour Auth Session State
  bool _isAuthenticated = true;
  DateTime? _lastLoginTime = DateTime.now();
  String _managerEmail = 'manager@siakaphones.com';
  String _managerName = 'General Manager';

  String _currentBranch = 'Accra Central (Circle)';
  final List<String> branches = [
    'Accra Central (Circle)',
    'Madina Zongo Junction',
    'Kasoa Main Market',
  ];

  File? _getCacheFile() {
    try {
      final appData = Platform.environment['APPDATA'] ??
          Platform.environment['LOCALAPPDATA'] ??
          Platform.environment['HOME'];
      final baseDir = appData != null
          ? Directory('$appData/SiakaPhonesManager')
          : Directory.systemTemp;
      if (!baseDir.existsSync()) {
        baseDir.createSync(recursive: true);
      }
      return File('${baseDir.path}/cached_products.json');
    } catch (e) {
      debugPrint('Error getting cache file: $e');
      return null;
    }
  }

  void _purgeStaleProductCache() {
    try {
      final file = _getCacheFile();
      if (file != null && file.existsSync()) {
        file.deleteSync();
        debugPrint('🧹 Stale local product cache file purged: ${file.path}');
      }
    } catch (e) {
      debugPrint('Error purging stale product cache: $e');
    }
  }

  void _saveCachedProducts(List<ManagerProduct> products) {
    // No-op: product catalog is sourced directly and purely from live Supabase database
  }

  File? _getManagerStateCacheFile() {
    try {
      final appData = Platform.environment['APPDATA'] ??
          Platform.environment['LOCALAPPDATA'] ??
          Platform.environment['HOME'];
      final baseDir = appData != null
          ? Directory('$appData/SiakaPhonesManager')
          : Directory.systemTemp;
      if (!baseDir.existsSync()) {
        baseDir.createSync(recursive: true);
      }
      return File('${baseDir.path}/cached_manager_state.json');
    } catch (e) {
      debugPrint('Error getting manager state cache file: $e');
      return null;
    }
  }

  void _saveCachedManagerState() {
    try {
      final file = _getManagerStateCacheFile();
      if (file != null) {
        final data = {
          'orders': _orders.map((o) => _orderToMap(o)).toList(),
          'bnpl': _bnplApplications.map((b) => _bnplToMap(b)).toList(),
          'repairs': _repairs.map((r) => _repairToMap(r)).toList(),
        };
        file.writeAsStringSync(jsonEncode(data));
      }
    } catch (e) {
      debugPrint('Error saving manager state: $e');
    }
  }

  void _loadCachedManagerState() {
    try {
      final file = _getManagerStateCacheFile();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);
          if (data['orders'] is List) {
            _orders = (data['orders'] as List)
                .map((m) => _orderFromMap(Map<String, dynamic>.from(m)))
                .where((o) => !o.id.startsWith('SP-88'))
                .toList();
          }
          if (data['bnpl'] is List) {
            _bnplApplications = (data['bnpl'] as List)
                .map((m) => _bnplFromMap(Map<String, dynamic>.from(m)))
                .toList();
          }
          if (data['repairs'] is List) {
            _repairs = (data['repairs'] as List)
                .map((m) => _repairFromMap(Map<String, dynamic>.from(m)))
                .toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading manager state: $e');
    }
  }

  Map<String, dynamic> _orderToMap(ManagerOrder o) => {
    'id': o.id,
    'customerName': o.customerName,
    'customerEmail': o.customerEmail,
    'customerPhone': o.customerPhone,
    'deliveryAddress': o.deliveryAddress,
    'region': o.region,
    'gpsCode': o.gpsCode,
    'date': o.date.toIso8601String(),
    'items': o.items.map((i) => {
      'title': i.title,
      'brand': i.brand,
      'price': i.price,
      'retailPrice': i.retailPrice,
      'wholesalePrice': i.wholesalePrice,
      'profit': i.profit,
      'quantity': i.quantity,
      'specs': i.specs,
    }).toList(),
    'totalAmount': o.totalAmount,
    'profit': o.profit,
    'paymentMethod': o.paymentMethod,
    'status': o.status.name,
  };

  ManagerOrder _orderFromMap(Map<String, dynamic> m) {
    final itemsList = (m['items'] as List? ?? []).map((i) => OrderItem(
      title: i['title']?.toString() ?? '',
      brand: i['brand']?.toString() ?? '',
      price: (i['price'] as num?)?.toDouble() ?? 0.0,
      retailPrice: (i['retailPrice'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (i['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
      profit: (i['profit'] as num?)?.toDouble() ?? 0.0,
      quantity: (i['quantity'] as num?)?.toInt() ?? 1,
      specs: i['specs']?.toString() ?? '',
    )).toList();

    OrderStatus status = OrderStatus.pending;
    final statusStr = m['status']?.toString().toLowerCase() ?? '';
    for (final s in OrderStatus.values) {
      if (s.name.toLowerCase() == statusStr) {
        status = s;
        break;
      }
    }

    final totalAmt = (m['totalAmount'] as num?)?.toDouble() ?? 0.0;
    double profitVal = (m['profit'] as num?)?.toDouble() ?? 0.0;
    if (profitVal <= 0) {
      for (final it in itemsList) {
        profitVal += it.profit;
      }
    }

    return ManagerOrder(
      id: m['id']?.toString() ?? '',
      customerName: m['customerName']?.toString() ?? '',
      customerEmail: m['customerEmail']?.toString() ?? '',
      customerPhone: m['customerPhone']?.toString() ?? '',
      deliveryAddress: m['deliveryAddress']?.toString() ?? '',
      region: m['region']?.toString() ?? 'Greater Accra',
      gpsCode: m['gpsCode']?.toString() ?? '',
      date: DateTime.tryParse(m['date']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      items: itemsList,
      totalAmount: totalAmt,
      profit: profitVal,
      paymentMethod: m['paymentMethod']?.toString() ?? 'Mobile Money',
      status: status,
    );
  }

  Map<String, dynamic> _bnplToMap(ManagerBnpl b) => {
    'id': b.id,
    'applicantName': b.applicantName,
    'phone': b.phone,
    'email': b.email,
    'nationalId': b.nationalId,
    'location': b.location,
    'employer': b.employer,
    'monthlySalary': b.monthlySalary,
    'requestedPhone': b.requestedPhone,
    'phonePrice': b.phonePrice,
    'downPayment': b.downPayment,
    'monthlyInstallment': b.monthlyInstallment,
    'tenureMonths': b.tenureMonths,
    'applicationDate': b.applicationDate.toIso8601String(),
    'status': b.status.name,
    'managerNotes': b.managerNotes,
  };

  ManagerBnpl _bnplFromMap(Map<String, dynamic> m) {
    BnplStatus status = BnplStatus.pending;
    final statusStr = m['status']?.toString().toLowerCase() ?? '';
    for (final s in BnplStatus.values) {
      if (s.name.toLowerCase() == statusStr) {
        status = s;
        break;
      }
    }

    return ManagerBnpl(
      id: m['id']?.toString() ?? '',
      applicantName: m['applicantName']?.toString() ?? '',
      phone: m['phone']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
      nationalId: m['nationalId']?.toString() ?? '',
      location: m['location']?.toString() ?? 'Greater Accra, Ghana',
      employer: m['employer']?.toString() ?? 'Self Employed',
      monthlySalary: (m['monthlySalary'] as num?)?.toDouble() ?? 0.0,
      requestedPhone: m['requestedPhone']?.toString() ?? '',
      phonePrice: (m['phonePrice'] as num?)?.toDouble() ?? 0.0,
      downPayment: (m['downPayment'] as num?)?.toDouble() ?? 0.0,
      monthlyInstallment: (m['monthlyInstallment'] as num?)?.toDouble() ?? 0.0,
      tenureMonths: (m['tenureMonths'] as num?)?.toInt() ?? 6,
      applicationDate: DateTime.tryParse(m['applicationDate']?.toString() ?? '') ?? DateTime.now(),
      status: status,
      managerNotes: m['managerNotes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> _repairToMap(ManagerRepair r) => {
    'id': r.id,
    'customerName': r.customerName,
    'customerPhone': r.customerPhone,
    'deviceModel': r.deviceModel,
    'reportedIssue': r.reportedIssue,
    'bookedDate': r.bookedDate.toIso8601String(),
    'stage': r.stage.name,
    'estimatedCost': r.estimatedCost,
    'technicianNotes': r.technicianNotes,
  };

  ManagerRepair _repairFromMap(Map<String, dynamic> m) {
    RepairStage stage = RepairStage.received;
    final stageStr = m['stage']?.toString().toLowerCase() ?? '';
    for (final s in RepairStage.values) {
      if (s.name.toLowerCase() == stageStr) {
        stage = s;
        break;
      }
    }

    return ManagerRepair(
      id: m['id']?.toString() ?? '',
      customerName: m['customerName']?.toString() ?? '',
      customerPhone: m['customerPhone']?.toString() ?? '',
      deviceModel: m['deviceModel']?.toString() ?? '',
      reportedIssue: m['reportedIssue']?.toString() ?? '',
      bookedDate: DateTime.tryParse(m['bookedDate']?.toString() ?? '') ?? DateTime.now(),
      stage: stage,
      estimatedCost: (m['estimatedCost'] as num?)?.toDouble() ?? 0.0,
      technicianNotes: m['technicianNotes']?.toString() ?? '',
    );
  }

  ManagerOrder _orderFromSupabase(ManagerProduct p) {
    Map<String, dynamic> extra = {};
    try {
      if (p.specs.isNotEmpty && p.specs.startsWith('{')) {
        extra = jsonDecode(p.specs);
      }
    } catch (_) {}

    final List itemsJson = extra['items'] as List? ?? [];
    final items = itemsJson.map((item) {
      final title = item['title']?.toString() ?? p.name;
      final price = (item['price'] as num?)?.toDouble() ?? p.price;
      final retail = (item['retailPrice'] as num?)?.toDouble() ??
          (item['retail_price'] as num?)?.toDouble() ??
          0.0;
      final wholesale = (item['wholesalePrice'] as num?)?.toDouble() ??
          (item['wholesale_price'] as num?)?.toDouble() ??
          0.0;
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;

      double itemProfit = (item['profit'] as num?)?.toDouble() ?? 0.0;
      if (itemProfit <= 0) {
        // Find product in catalog to get retail vs wholesale
        final catalogProd = _products.cast<ManagerProduct?>().firstWhere(
          (cp) => cp != null && cp.isMerchandise && (
            cp.name.trim().toLowerCase() == title.trim().toLowerCase() ||
            cp.name.toLowerCase().contains(title.toLowerCase()) ||
            title.toLowerCase().contains(cp.name.toLowerCase())
          ),
          orElse: () => null,
        );
        if (catalogProd != null) {
          final diff = (catalogProd.retailPrice - catalogProd.wholesalePrice).abs();
          if (diff > 0) {
            itemProfit = diff * qty;
          }
        } else if (retail > 0 && wholesale > 0) {
          itemProfit = (retail - wholesale).abs() * qty;
        }
      }

      return OrderItem(
        title: title,
        brand: item['brand']?.toString() ?? 'Siaka Devices',
        price: price,
        retailPrice: retail,
        wholesalePrice: wholesale,
        profit: itemProfit,
        quantity: qty,
        specs: item['specs']?.toString() ?? '',
      );
    }).toList();

    OrderStatus status = OrderStatus.placed;
    final cond = p.condition.toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('&', '').replaceAll('-', '');
    if (cond.contains('deliv')) {
      status = OrderStatus.delivered;
    } else if (cond.contains('outfor')) {
      status = OrderStatus.outForDelivery;
    } else if (cond.contains('dispatch') || cond.contains('courier') || cond.contains('ship') || cond.contains('transit')) {
      status = OrderStatus.shipped;
    } else if (cond.contains('process') || cond.contains('pack') || cond.contains('confirm')) {
      status = OrderStatus.processing;
    } else if (cond.contains('cancel')) {
      status = OrderStatus.cancelled;
    } else {
      status = OrderStatus.placed;
    }

    final orderId = p.id.startsWith('ORDER_') ? p.id.substring(6) : p.id;
    final totalAmount = p.price > 0
        ? p.price
        : items.fold(0.0, (acc, item) => acc + (item.price * item.quantity));

    // Calculate overall order profit from items or wholesale vs retail
    double totalOrderProfit = (extra['totalProfit'] as num?)?.toDouble() ?? 0.0;
    if (totalOrderProfit <= 0) {
      for (final it in items) {
        totalOrderProfit += it.profit;
      }
    }
    if (totalOrderProfit <= 0) {
      final catalogProd = _products.cast<ManagerProduct?>().firstWhere(
        (cp) => cp != null && cp.isMerchandise && (
          cp.name.trim().toLowerCase() == p.name.trim().toLowerCase() ||
          cp.name.toLowerCase().contains(p.name.toLowerCase()) ||
          p.name.toLowerCase().contains(cp.name.toLowerCase())
        ),
        orElse: () => null,
      );
      if (catalogProd != null) {
        final diff = (catalogProd.retailPrice - catalogProd.wholesalePrice).abs();
        if (diff > 0) {
          totalOrderProfit = diff * (p.stock > 0 ? p.stock : 1);
        }
      } else if (p.originalPrice > 0 && p.price > 0 && (p.originalPrice - p.price).abs() > 0) {
        totalOrderProfit = (p.originalPrice - p.price).abs();
      }
    }

    return ManagerOrder(
      id: orderId,
      customerName: extra['customerName']?.toString() ?? (p.name.isNotEmpty ? p.name : 'Customer'),
      customerEmail: extra['customerEmail']?.toString() ?? 'customer@siakaphones.com',
      customerPhone: extra['customerPhone']?.toString() ?? '024 555 0192',
      deliveryAddress: extra['deliveryAddress']?.toString() ?? 'Accra, Ghana',
      region: extra['region']?.toString() ?? 'Greater Accra',
      gpsCode: extra['gpsCode']?.toString() ?? 'GA-183-9021',
      date: (p.createdAt ?? DateTime.now()).toLocal(),
      items: items.isNotEmpty ? items : [
        OrderItem(
          title: p.name,
          brand: p.brand,
          price: totalAmount,
          profit: totalOrderProfit,
          quantity: p.stock > 0 ? p.stock : 1,
        ),
      ],
      totalAmount: totalAmount,
      profit: totalOrderProfit,
      paymentMethod: p.brand.isNotEmpty && p.brand != 'ORDER_RECORD' ? p.brand : 'Mobile Money',
      status: status,
    );
  }

  ManagerBnpl _bnplFromSupabase(ManagerProduct p) {
    Map<String, dynamic> extra = {};
    try {
      if (p.specs.isNotEmpty && p.specs.startsWith('{')) {
        extra = jsonDecode(p.specs);
      }
    } catch (_) {}

    BnplStatus status = BnplStatus.pending;
    final cond = p.condition.toLowerCase();
    if (cond.contains('approv')) {
      status = BnplStatus.approved;
    } else if (cond.contains('reject') || cond.contains('declin')) {
      status = BnplStatus.rejected;
    } else {
      status = BnplStatus.pending;
    }

    final bnplId = p.id.replaceFirst('BNPL_', '');
    final tenure = p.stock > 0 ? p.stock : 6;
    final brandModel = extra['modelName']?.toString() ?? p.name;
    return ManagerBnpl(
      id: bnplId,
      applicantName: extra['customerName']?.toString() ?? p.name,
      phone: extra['customerPhone']?.toString() ?? '024 555 0192',
      email: extra['email']?.toString() ?? 'applicant@gmail.com',
      nationalId: extra['nationalId']?.toString() ?? 'GHA-729104820-1',
      location: extra['location']?.toString() ?? 'Greater Accra, Ghana',
      employer: extra['employer']?.toString() ?? 'Self Employed / Trader',
      monthlySalary: (extra['monthlySalary'] as num?)?.toDouble() ?? 3500.0,
      requestedPhone: brandModel,
      phonePrice: p.price > 0 ? p.price : 2800.0,
      downPayment: p.price > 0 ? p.price * 0.3 : 840.0,
      monthlyInstallment: p.price > 0 ? (p.price * 0.7) / tenure : 326.0,
      tenureMonths: tenure,
      applicationDate: p.createdAt ?? DateTime.now(),
      status: status,
      managerNotes: extra['notes']?.toString() ?? '',
    );
  }

  ManagerRepair _repairFromSupabase(ManagerProduct p) {
    Map<String, dynamic> extra = {};
    try {
      if (p.specs.isNotEmpty && p.specs.startsWith('{')) {
        extra = jsonDecode(p.specs);
      }
    } catch (_) {}

    RepairStage stage = RepairStage.received;
    final cond = p.condition.toLowerCase();
    if (cond.contains('diag')) {
      stage = RepairStage.diagnosing;
    } else if (cond.contains('part')) {
      stage = RepairStage.awaitingParts;
    } else if (cond.contains('ready') || cond.contains('pickup')) {
      stage = RepairStage.readyForPickup;
    } else if (cond.contains('complete')) {
      stage = RepairStage.completed;
    } else {
      stage = RepairStage.received;
    }

    final repairId = p.id.replaceFirst('REPAIR_', '');
    return ManagerRepair(
      id: repairId,
      customerName: extra['customerName']?.toString() ?? p.name,
      customerPhone: extra['customerPhone']?.toString() ?? '024 555 0192',
      deviceModel: extra['deviceModel']?.toString() ?? p.brand,
      reportedIssue: extra['issueType']?.toString() ?? 'Hardware Diagnostic',
      bookedDate: p.createdAt ?? DateTime.now(),
      stage: stage,
      estimatedCost: p.price,
      technicianNotes: extra['description']?.toString() ?? '',
    );
  }

  ManagerRepository() {
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (isTest) {
      _products = MockManagerData.getInitialProducts();
      _orders = MockManagerData.getInitialOrders();
      _bnplApplications = MockManagerData.getInitialBnplApplications();
      _repairs = MockManagerData.getInitialRepairs();
      _isLoading = false;
    } else {
      _products = [];
      _orders = [];
      _bnplApplications = [];
      _repairs = [];
      _isLoading = true;
      _purgeStaleProductCache();
      _loadCachedManagerState();
      // Initial balance is 0.0 — orders start empty until real customer purchases are made/synced
      if (_bnplApplications.isEmpty) {
        _bnplApplications = MockManagerData.getInitialBnplApplications();
      }
      if (_repairs.isEmpty) {
        _repairs = MockManagerData.getInitialRepairs();
      }
    }
    _swaps = MockManagerData.getInitialSwaps();
    _customers = MockManagerData.getInitialCustomerActivities();
    _sentMessages = MockManagerData.getInitialCustomerMessages();
    _serviceTickets = MockManagerData.getInitialServiceTickets();
    _shipments = MockManagerData.getInitialShipments();
    _syncOrdersWithShipments();
    _notifications = MockManagerData.getInitialNotifications();
    _advertisements = MockManagerData.getInitialAdvertisements();
    _initSupabaseSync();
    _brandModels = {
      'Apple': [
        'iPhone 16 Pro Max',
        'iPhone 16 Pro',
        'iPhone 16 Plus',
        'iPhone 16',
        'iPhone 15 Pro Max',
        'iPhone 15 Pro',
        'iPhone 15 Plus',
        'iPhone 15',
        'iPhone 14 Pro Max',
        'iPhone 14 Pro',
        'iPhone 14',
        'iPhone 13 Pro Max',
        'iPhone 13 Pro',
        'iPhone 13',
        'iPhone 12 Pro Max',
        'iPhone 12',
        'iPhone 11',
      ],
      'Samsung': [
        'Galaxy S24 Ultra',
        'Galaxy S24+',
        'Galaxy S24',
        'Galaxy S23 Ultra',
        'Galaxy S23+',
        'Galaxy S23',
        'Galaxy Z Fold 6',
        'Galaxy Z Flip 6',
        'Galaxy Z Fold 5',
        'Galaxy A55 5G',
        'Galaxy A35 5G',
        'Galaxy A25 5G',
        'Galaxy A15',
      ],
      'Tecno': [
        'Camon 30 Premier 5G',
        'Camon 30 Pro 5G',
        'Camon 30 5G',
        'Spark 20 Pro+',
        'Spark 20 Pro',
        'Spark 20',
        'Phantom V Fold 2',
        'Phantom V Flip 2',
        'Pova 6 Pro 5G',
      ],
      'Infinix': [
        'Note 40 Pro+ 5G',
        'Note 40 Pro 5G',
        'Note 40',
        'Hot 40 Pro',
        'Hot 40',
        'GT 20 Pro 5G',
        'Zero 30 5G',
        'Smart 8 Pro',
      ],
      'Google': [
        'Pixel 9 Pro XL',
        'Pixel 9 Pro',
        'Pixel 9',
        'Pixel 8 Pro',
        'Pixel 8',
        'Pixel 7a',
        'Pixel 7 Pro',
      ],
      'Xiaomi': [
        'Xiaomi 14 Ultra',
        'Xiaomi 14',
        'Redmi Note 13 Pro+ 5G',
        'Redmi Note 13 Pro',
        'Redmi Note 13',
        'Poco X6 Pro 5G',
        'Poco F6 Pro',
      ],
      'Oraimo': [
        'FreePods 4 ANC Earbuds',
        'FreePods Pro TWS',
        'Watch 4 Plus Smartwatch',
        'Watch Nova V AMOLED',
        'Toast 10 Byte 10000mAh Power Bank',
        'PowerBox 300 30000mAh Heavy Duty',
      ],
      'Other / Custom': [
        'Custom / Unlisted Model',
      ],
    };
  }

  // Getters
  List<ManagerProduct> get products =>
      List.unmodifiable(_products.where((p) => p.isMerchandise));
  List<ManagerOrder> get orders => List.unmodifiable(_orders);
  List<ManagerBnpl> get bnplApplications => List.unmodifiable(_bnplApplications);
  List<ManagerRepair> get repairs => List.unmodifiable(_repairs);
  List<ManagerSwap> get swaps => List.unmodifiable(_swaps);
  List<CustomerActivity> get customers => List.unmodifiable(_customers);
  List<CustomerMessage> get sentMessages => List.unmodifiable(_sentMessages);
  List<ServiceTicket> get serviceTickets => List.unmodifiable(_serviceTickets);
  List<ManagerShippingItem> get shipments => List.unmodifiable(_shipments);
  List<ManagerNotification> get notifications => List.unmodifiable(_notifications);
  List<AdvertisementBanner> get advertisements => List.unmodifiable(_advertisements);
  Map<String, List<String>> get brandModels => _brandModels;
  List<String> get categories => List.unmodifiable(_categories);
  String get currentBranch => _currentBranch;

  // Authentication & Session Getters
  bool get isAuthenticated => _isAuthenticated;
  DateTime? get lastLoginTime => _lastLoginTime;
  String get managerEmail => _managerEmail;
  String get managerName => _managerName;

  int get unreadServiceTicketsCount =>
      _serviceTickets.where((t) => t.unreadCountForManager > 0).length;

  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  int get activeShipmentsCount => _shipments.where((s) =>
      s.status == ShippingStatus.inTransit ||
      s.status == ShippingStatus.outForDelivery ||
      s.status == ShippingStatus.pendingPickup).length;

  int get activeAdvertisementsCount =>
      _advertisements.where((a) => a.isActive).length;

  int get totalAdImpressions =>
      _advertisements.fold(0, (sum, a) => sum + a.impressionsCount);

  int get totalAdClicks =>
      _advertisements.fold(0, (sum, a) => sum + a.clicksCount);

  void selectBranch(String branch) {
    _currentBranch = branch;
    notifyListeners();
  }

  // Analytics
  // Total Revenue: calculated dynamically from customer purchases.
  // Initial balance is 0.0. When a customer purchases an item, wholesale minus retail is calculated to get the profit,
  // which is directly added to the overview revenue balance.
  double get totalRevenue =>
      _orders.where((o) => o.status != OrderStatus.cancelled).fold(0.0, (acc, o) => acc + o.profit);

  // Total Gross Sales (total amount paid by customers)
  double get totalGrossSales =>
      _orders.where((o) => o.status != OrderStatus.cancelled).fold(0.0, (acc, o) => acc + o.totalAmount);

  int get todayOrdersCount {
    final now = DateTime.now();
    return _orders.where((o) {
      final d = o.date.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;
  }

  double get todayRevenue {
    final now = DateTime.now();
    return _orders.where((o) {
      if (o.status == OrderStatus.cancelled) return false;
      final d = o.date.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).fold(0.0, (acc, o) => acc + o.profit);
  }

  double get todayProfit => todayRevenue;

  double get totalProfitEarned => totalRevenue;

  int get onlineCustomersCount =>
      _customers.where((c) => c.isOnline || DateTime.now().difference(c.lastLogin).inMinutes < 45).length;

  int get pendingOrdersCount =>
      _orders.where((o) => o.status == OrderStatus.pending).length;

  int get pendingBnplCount =>
      _bnplApplications.where((b) => b.status == BnplStatus.pending).length;

  int get activeRepairsCount =>
      _repairs.where((r) => r.stage != RepairStage.completed).length;

  int get lowStockProductsCount =>
      _products.where((p) => p.lowStock).length;

  // Order Actions
  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx].status = newStatus;

      // Keep linked shipment in _shipments synchronized
      final cleanOrderId = orderId.replaceFirst('ORD-', '').replaceFirst('ORDER_', '');
      final shipIdx = _shipments.indexWhere((s) {
        final sClean = s.orderOrProcessId.replaceFirst('ORD-', '').replaceFirst('ORDER_', '');
        return sClean == cleanOrderId || s.id == 'SHIP-$cleanOrderId' || s.id == 'SHIP-$orderId';
      });

      if (shipIdx != -1) {
        final shipment = _shipments[shipIdx];
        switch (newStatus) {
          case OrderStatus.placed:
            shipment.status = ShippingStatus.placed;
            break;
          case OrderStatus.processing:
            shipment.status = ShippingStatus.processing;
            break;
          case OrderStatus.shipped:
            shipment.status = ShippingStatus.dispatched;
            shipment.dispatchedAt ??= DateTime.now();
            break;
          case OrderStatus.outForDelivery:
            shipment.status = ShippingStatus.outForDelivery;
            break;
          case OrderStatus.delivered:
            shipment.status = ShippingStatus.delivered;
            shipment.deliveredAt = DateTime.now();
            break;
          case OrderStatus.cancelled:
            shipment.status = ShippingStatus.cancelled;
            break;
        }
        shipment.lastLocationUpdate = shipment.status.defaultLocationHint;
      }
      _saveCachedManagerState();
      notifyListeners();
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        _supabase.updateRecordCondition('ORDER_$cleanOrderId', newStatus.name);
      }
    }
  }

  void _sortProductsList(List<ManagerProduct> list) {
    list.sort((a, b) {
      if (a.createdAt != null && b.createdAt != null) {
        return b.createdAt!.compareTo(a.createdAt!);
      }
      if (a.createdAt != null) return -1;
      if (b.createdAt != null) return 1;
      return b.id.compareTo(a.id);
    });
  }

  // Product Actions
  void addProduct(ManagerProduct product) {
    product.createdAt ??= DateTime.now();
    _products.insert(0, product);
    _sortProductsList(_products);
    _saveCachedProducts(_products);
    notifyListeners();
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _supabase.upsertProduct(product);
    }
  }

  void updateProduct(ManagerProduct product) {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = product;
      _saveCachedProducts(_products);
      notifyListeners();
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        _supabase.upsertProduct(product);
      }
    }
  }

  void deleteProduct(String productId) {
    _products.removeWhere((p) => p.id == productId);
    _saveCachedProducts(_products);
    notifyListeners();
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _supabase.deleteProduct(productId);
    }
  }

  void updateStock(String productId, int newStock) {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _products[idx].stock = newStock;
      _saveCachedProducts(_products);
      notifyListeners();
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        _supabase.upsertProduct(_products[idx]);
      }
    }
  }

  Future<void> _initSupabaseSync() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _isLoading = false;
      return;
    }
    try {
      await _supabase.initialize();
      final remoteProducts = await _supabase.fetchProducts();
      if (remoteProducts != null) {
        _applyRemoteData(remoteProducts);
      }

      // Realtime stream listener
      _supabase.streamProducts()?.listen((liveProducts) {
        _applyRemoteData(liveProducts);
      }, onError: (e) {
        debugPrint('Supabase products stream error: $e');
      });

      // Continuous 3-second auto-poll guarantees live purchases in customer app are immediately fetched
      _syncPollTimer?.cancel();
      _syncPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        try {
          final live = await _supabase.fetchProducts();
          if (live != null) {
            _applyRemoteData(live);
          }
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('ℹ️ Supabase sync deferred: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyRemoteData(List<ManagerProduct> list) {
    final items = list.where((p) => p.isMerchandise).toList();
    _sortProductsList(items);
    _products = items;

    for (final p in items) {
      if (p.category.trim().isNotEmpty) {
        addCategory(p.category, syncRemote: false);
      }
    }

    final remoteOrderProducts = list.where((p) =>
        p.id.startsWith('ORDER_') ||
        p.category.toUpperCase() == 'ORDER_RECORD' ||
        p.id.startsWith('SP-')).toList();
    if (remoteOrderProducts.isNotEmpty) {
      for (final p in remoteOrderProducts) {
        final parsedOrder = _orderFromSupabase(p);
        final idx = _orders.indexWhere((o) => o.id == parsedOrder.id);
        if (idx != -1) {
          _orders[idx] = parsedOrder;
        } else {
          _orders.add(parsedOrder);
        }
      }
      _orders.sort((a, b) => b.date.compareTo(a.date));
      _syncOrdersWithShipments();
    }

    final remoteBnplProducts = list.where((p) =>
        p.id.startsWith('BNPL_') ||
        p.category.toUpperCase() == 'BNPL_RECORD').toList();
    if (remoteBnplProducts.isNotEmpty) {
      for (final p in remoteBnplProducts) {
        final parsedBnpl = _bnplFromSupabase(p);
        final idx = _bnplApplications.indexWhere((b) => b.id == parsedBnpl.id);
        if (idx != -1) {
          _bnplApplications[idx] = parsedBnpl;
        } else {
          _bnplApplications.add(parsedBnpl);
        }
      }
      _bnplApplications.sort((a, b) => b.applicationDate.compareTo(a.applicationDate));
    }

    final remoteRepairProducts = list.where((p) =>
        p.id.startsWith('REPAIR_') ||
        p.category.toUpperCase() == 'REPAIR_RECORD').toList();
    if (remoteRepairProducts.isNotEmpty) {
      for (final p in remoteRepairProducts) {
        final parsedRepair = _repairFromSupabase(p);
        final idx = _repairs.indexWhere((r) => r.id == parsedRepair.id);
        if (idx != -1) {
          _repairs[idx] = parsedRepair;
        } else {
          _repairs.add(parsedRepair);
        }
      }
      _repairs.sort((a, b) => b.bookedDate.compareTo(a.bookedDate));
    }

    _saveCachedManagerState();
    notifyListeners();
  }

  // BNPL Actions
  void updateBnplStatus(String id, BnplStatus status, {String notes = ''}) {
    final idx = _bnplApplications.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _bnplApplications[idx].status = status;
      if (notes.isNotEmpty) {
        _bnplApplications[idx].managerNotes = notes;
      }
      _saveCachedManagerState();
      notifyListeners();
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        _supabase.updateRecordCondition('BNPL_$id', status.name);
      }
    }
  }

  // Repair Actions
  void updateRepairStage(String id, RepairStage stage, {String? notes, double? cost}) {
    final idx = _repairs.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _repairs[idx].stage = stage;
      if (notes != null && notes.isNotEmpty) {
        _repairs[idx].technicianNotes = notes;
      }
      if (cost != null) {
        _repairs[idx].estimatedCost = cost;
      }
      _saveCachedManagerState();
      notifyListeners();
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        _supabase.updateRecordCondition('REPAIR_$id', stage.name);
      }
    }
  }

  // Swap Actions
  void updateSwapStatus(String id, SwapEvaluationStatus status, {String? notes}) {
    final idx = _swaps.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _swaps[idx].status = status;
      if (notes != null && notes.isNotEmpty) {
        _swaps[idx].inspectionNotes = notes;
      }
      notifyListeners();
    }
  }

  CustomerActivity? _activeMessagingCustomer;
  CustomerActivity? get activeMessagingCustomer => _activeMessagingCustomer;

  String? _initialMessagingSubject;
  String? get initialMessagingSubject => _initialMessagingSubject;

  String? _initialMessagingBody;
  String? get initialMessagingBody => _initialMessagingBody;

  MessageCategory? _initialMessagingCategory;
  MessageCategory? get initialMessagingCategory => _initialMessagingCategory;

  void clearInitialMessagingDraft() {
    _initialMessagingSubject = null;
    _initialMessagingBody = null;
    _initialMessagingCategory = null;
  }

  void setMessagingCustomer(CustomerActivity customer) {
    _activeMessagingCustomer = customer;
    notifyListeners();
  }

  void selectCustomerForMessaging({
    required String customerName,
    String? phone,
    String? email,
    String? initialSubject,
    String? initialBody,
    MessageCategory? initialCategory,
  }) {
    _initialMessagingSubject = initialSubject;
    _initialMessagingBody = initialBody;
    _initialMessagingCategory = initialCategory;

    final match = _customers.cast<CustomerActivity?>().firstWhere(
      (c) =>
          c != null &&
          (c.fullName.trim().toLowerCase() == customerName.trim().toLowerCase() ||
              (phone != null && c.phone.replaceAll(' ', '') == phone.replaceAll(' ', ''))),
      orElse: () => null,
    );

    if (match != null) {
      if (email != null && email.isNotEmpty && (match.email.isEmpty || match.email.contains('@example.com'))) {
        final updated = CustomerActivity(
          id: match.id,
          fullName: match.fullName,
          phone: match.phone,
          email: email,
          signupDate: match.signupDate,
          loginCount: match.loginCount,
          lastLogin: match.lastLogin,
          primaryDevice: match.primaryDevice,
          status: match.status,
          totalSpend: match.totalSpend,
        );
        final idx = _customers.indexOf(match);
        if (idx != -1) {
          _customers[idx] = updated;
          _activeMessagingCustomer = updated;
        } else {
          _activeMessagingCustomer = match;
        }
      } else {
        _activeMessagingCustomer = match;
      }
    } else {
      final newCustomer = CustomerActivity(
        id: 'CUST-${DateTime.now().millisecondsSinceEpoch}',
        fullName: customerName,
        phone: phone ?? '+233 24 000 0000',
        email: email ?? '${customerName.toLowerCase().replaceAll(' ', '.')}@gmail.com',
        signupDate: DateTime.now(),
        loginCount: 1,
        lastLogin: DateTime.now(),
        primaryDevice: 'Mobile App User',
        status: 'Active',
        totalSpend: 0.0,
      );
      _customers.insert(0, newCustomer);
      _activeMessagingCustomer = newCustomer;
    }
    notifyListeners();
  }

  // Customer Messaging Actions (Outbound & Inbound Simulation)
  void sendCustomerMessage(CustomerMessage message) {
    _sentMessages.insert(0, message);
    notifyListeners();
  }

  void addIncomingCustomerReply(String customerId, String replyText, {MessageChannel channel = MessageChannel.inApp}) {
    final cust = _customers.firstWhere(
      (c) => c.id == customerId,
      orElse: () => CustomerActivity(
        id: customerId,
        fullName: 'Customer',
        phone: '+233 24 000 0000',
        email: 'customer@gmail.com',
        signupDate: DateTime.now(),
        loginCount: 1,
        lastLogin: DateTime.now(),
        primaryDevice: 'Mobile App',
        status: 'Active',
        totalSpend: 0.0,
      ),
    );

    final newMsg = CustomerMessage(
      id: 'MSG-IN-${DateTime.now().millisecondsSinceEpoch}',
      customerId: cust.id,
      customerName: cust.fullName,
      customerPhone: cust.phone,
      customerEmail: cust.email,
      channel: channel,
      category: MessageCategory.general,
      subject: 'Inbound Customer Reply',
      message: replyText,
      sentAt: DateTime.now(),
      sentBy: cust.fullName,
      status: MessageDeliveryStatus.read,
      isFromCustomer: true,
    );
    _sentMessages.insert(0, newMsg);
    notifyListeners();
  }

  // Service Center Actions (Inbound Customer Chat & Support Desk)
  void replyToServiceTicket(String ticketId, String replyText) {
    final idx = _serviceTickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      final ticket = _serviceTickets[idx];
      final newMsg = ServiceMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        senderType: ServiceSenderType.manager,
        senderName: 'Store Manager',
        text: replyText,
        timestamp: DateTime.now(),
        isRead: true,
      );
      ticket.messages.add(newMsg);
      ticket.status = ServiceTicketStatus.waitingCustomer;
      notifyListeners();
    }
  }

  void updateServiceTicketStatus(String ticketId, ServiceTicketStatus newStatus) {
    final idx = _serviceTickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      _serviceTickets[idx].status = newStatus;
      notifyListeners();
    }
  }

  void markTicketAsRead(String ticketId) {
    final idx = _serviceTickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      for (final msg in _serviceTickets[idx].messages) {
        msg.isRead = true;
      }
      notifyListeners();
    }
  }

  void addIncomingCustomerMessage(String ticketId, String customerText) {
    final idx = _serviceTickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      final ticket = _serviceTickets[idx];
      final newMsg = ServiceMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        senderType: ServiceSenderType.customer,
        senderName: ticket.customerName,
        text: customerText,
        timestamp: DateTime.now(),
        isRead: false,
      );
      ticket.messages.add(newMsg);
      ticket.status = ServiceTicketStatus.open;
      notifyListeners();
    }
  }

  // Category Actions
  void addCategory(String category, {bool syncRemote = true}) {
    final clean = category.trim();
    if (clean.isEmpty) return;
    final upper = clean.toUpperCase();
    if (upper == 'ORDER_RECORD' ||
        upper == 'BNPL_RECORD' ||
        upper == 'REPAIR_RECORD' ||
        upper == 'SWAP_RECORD' ||
        upper == 'CATEGORY' ||
        upper.startsWith('ORDER_') ||
        upper.startsWith('BNPL_') ||
        upper.startsWith('REPAIR_')) {
      return;
    }
    if (!_categories.any((c) => c.toLowerCase() == clean.toLowerCase())) {
      _categories.add(clean);
      notifyListeners();
      if (syncRemote && !Platform.environment.containsKey('FLUTTER_TEST')) {
        final catToken = ManagerProduct(
          id: 'CAT_${clean.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}',
          name: clean,
          brand: 'Category',
          category: clean,
          price: 0,
          originalPrice: 0,
          stock: 0,
          specs: 'Category Definition',
          condition: 'Category',
        );
        _supabase.upsertProduct(catToken);
      }
    }
  }

  // Device Model Actions
  void addDeviceModel({String? brand, required String modelName, String? category}) {
    final cleanModel = modelName.trim();
    if (cleanModel.isEmpty) return;

    String cleanBrand = (brand ?? '').trim();
    if (cleanBrand.isEmpty) {
      final lower = cleanModel.toLowerCase();
      if (lower.startsWith('iphone') || lower.startsWith('ipad') || lower.startsWith('macbook') || lower.startsWith('apple')) {
        cleanBrand = 'Apple';
      } else if (lower.startsWith('samsung') || lower.startsWith('galaxy')) {
        cleanBrand = 'Samsung';
      } else if (lower.startsWith('tecno') || lower.startsWith('camon') || lower.startsWith('phantom') || lower.startsWith('spark')) {
        cleanBrand = 'Tecno';
      } else if (lower.startsWith('infinix') || lower.startsWith('zero') || lower.startsWith('note') || lower.startsWith('hot')) {
        cleanBrand = 'Infinix';
      } else if (lower.startsWith('google') || lower.startsWith('pixel')) {
        cleanBrand = 'Google';
      } else if (lower.startsWith('xiaomi') || lower.startsWith('redmi') || lower.startsWith('poco')) {
        cleanBrand = 'Xiaomi';
      } else if (lower.startsWith('oneplus')) {
        cleanBrand = 'OnePlus';
      } else if (lower.startsWith('oraimo')) {
        cleanBrand = 'Oraimo';
      } else {
        cleanBrand = 'Other / Custom';
      }
    }

    if (!_brandModels.containsKey(cleanBrand)) {
      _brandModels[cleanBrand] = [];
    }

    if (!_brandModels[cleanBrand]!.contains(cleanModel)) {
      _brandModels[cleanBrand]!.insert(0, cleanModel);
    }

    if (category != null && category.trim().isNotEmpty) {
      addCategory(category.trim());
    }

    notifyListeners();
  }

  // 24-Hour Auth Session Actions
  bool checkSessionValid() {
    if (!_isAuthenticated || _lastLoginTime == null) {
      return false;
    }
    final diff = DateTime.now().difference(_lastLoginTime!);
    return diff.inHours < 24;
  }

  Future<void> loadSavedSession() async {
    try {
      final sessionFile = File('siaka_manager_session.json');
      if (await sessionFile.exists()) {
        final content = await sessionFile.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final isLoggedIn = data['isLoggedIn'] as bool? ?? false;
        final timestampStr = data['lastLoginTime'] as String?;
        final email = data['email'] as String? ?? 'manager@siakaphones.com';
        final name = data['name'] as String? ?? 'General Manager';

        if (isLoggedIn && timestampStr != null) {
          final timestamp = DateTime.tryParse(timestampStr);
          if (timestamp != null) {
            final diff = DateTime.now().difference(timestamp);
            if (diff.inHours < 24) {
              _isAuthenticated = true;
              _lastLoginTime = timestamp;
              _managerEmail = email;
              _managerName = name;
              notifyListeners();
              return;
            }
          }
        }
      }
    } catch (_) {}
    _isAuthenticated = false;
    _lastLoginTime = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password, {bool remember24Hours = true}) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.isEmpty) {
      return false;
    }
    _isAuthenticated = true;
    _lastLoginTime = DateTime.now();
    _managerEmail = cleanEmail;
    final prefix = cleanEmail.contains('@') ? cleanEmail.split('@').first : cleanEmail;
    _managerName = prefix.isNotEmpty ? '${prefix[0].toUpperCase()}${prefix.substring(1)}' : 'General Manager';

    if (remember24Hours) {
      try {
        final sessionFile = File('siaka_manager_session.json');
        await sessionFile.writeAsString(jsonEncode({
          'isLoggedIn': true,
          'lastLoginTime': _lastLoginTime!.toIso8601String(),
          'email': _managerEmail,
          'name': _managerName,
        }));
      } catch (_) {}
    }

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _lastLoginTime = null;
    try {
      final sessionFile = File('siaka_manager_session.json');
      if (await sessionFile.exists()) {
        await sessionFile.delete();
      }
    } catch (_) {}
    notifyListeners();
  }

  // Shipping Actions
  void updateShippingStatus(
    String shipmentId,
    ShippingStatus status, {
    String? locationUpdate,
    String? notes,
    String? courier,
    String? riderPhone,
  }) {
    final idx = _shipments.indexWhere((s) => s.id == shipmentId);
    if (idx != -1) {
      final shipment = _shipments[idx];
      shipment.status = status;
      if (locationUpdate != null && locationUpdate.trim().isNotEmpty) {
        shipment.lastLocationUpdate = locationUpdate.trim();
      } else {
        shipment.lastLocationUpdate = status.defaultLocationHint;
      }
      if (notes != null && notes.trim().isNotEmpty) {
        shipment.managerNotes = notes.trim();
      }
      if (courier != null && courier.trim().isNotEmpty) {
        shipment.courier = courier.trim();
      }
      if (riderPhone != null && riderPhone.trim().isNotEmpty) {
        shipment.dispatchRiderPhone = riderPhone.trim();
      }
      if (status == ShippingStatus.delivered) {
        shipment.deliveredAt = DateTime.now();
      } else if (status == ShippingStatus.dispatched) {
        shipment.dispatchedAt ??= DateTime.now();
      }

      shipment.statusHistory.add(
        ShippingCheckpoint(
          timestamp: DateTime.now(),
          location: shipment.lastLocationUpdate,
          status: status,
          note: notes ?? 'Status updated to ${status.label}',
          updatedBy: 'Store Manager',
        ),
      );

      addNotification(
        ManagerNotification(
          id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Shipment #${shipment.trackingNumber} Updated',
          message: 'Status: ${status.label} for ${shipment.customerName} (${shipment.destinationCity})',
          type: NotificationType.shipping,
          severity: status == ShippingStatus.delivered
              ? NotificationSeverity.success
              : (status == ShippingStatus.cancelled || status == ShippingStatus.failedDelivery
                  ? NotificationSeverity.critical
                  : NotificationSeverity.info),
          timestamp: DateTime.now(),
          referenceId: shipment.id,
          actionRouteIndex: 11,
        ),
      );

      // Keep linked customer order synchronized if updated from shipping
      final cleanShipmentOrderId = shipment.orderOrProcessId.replaceFirst('ORD-', '').replaceFirst('ORDER_', '');
      final orderIdx = _orders.indexWhere((o) {
        final cleanO = o.id.replaceFirst('ORD-', '').replaceFirst('ORDER_', '');
        return cleanO == cleanShipmentOrderId;
      });

      OrderStatus mappedOrderStatus = OrderStatus.placed;
      switch (status) {
        case ShippingStatus.placed:
          mappedOrderStatus = OrderStatus.placed;
          break;
        case ShippingStatus.processing:
          mappedOrderStatus = OrderStatus.processing;
          break;
        case ShippingStatus.dispatched:
          mappedOrderStatus = OrderStatus.shipped;
          break;
        case ShippingStatus.outForDelivery:
          mappedOrderStatus = OrderStatus.outForDelivery;
          break;
        case ShippingStatus.delivered:
          mappedOrderStatus = OrderStatus.delivered;
          break;
        case ShippingStatus.cancelled:
        case ShippingStatus.returned:
          mappedOrderStatus = OrderStatus.cancelled;
          break;
      }

      if (orderIdx != -1) {
        _orders[orderIdx].status = mappedOrderStatus;
      }

      _saveCachedManagerState();
      notifyListeners();

      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        final orderDocId = 'ORDER_$cleanShipmentOrderId';
        _supabase.updateRecordCondition(orderDocId, status.dbCondition);
        if (shipment.orderOrProcessId != cleanShipmentOrderId) {
          _supabase.updateRecordCondition('ORDER_${shipment.orderOrProcessId}', status.dbCondition);
        }
      }
    }
  }

  void _syncOrdersWithShipments() {
    for (final order in _orders) {
      final cleanOrderId = order.id.replaceFirst('ORD-', '').replaceFirst('ORDER_', '');
      final idx = _shipments.indexWhere((s) {
        final sClean = s.orderOrProcessId.replaceFirst('ORD-', '').replaceFirst('ORDER_', '');
        return sClean == cleanOrderId || s.id == 'SHIP-$cleanOrderId' || s.id == 'SHIP-${order.id}';
      });

      ShippingStatus shippingStatus = ShippingStatus.placed;
      switch (order.status) {
        case OrderStatus.placed:
          shippingStatus = ShippingStatus.placed;
          break;
        case OrderStatus.processing:
          shippingStatus = ShippingStatus.processing;
          break;
        case OrderStatus.shipped:
          shippingStatus = ShippingStatus.dispatched;
          break;
        case OrderStatus.outForDelivery:
          shippingStatus = ShippingStatus.outForDelivery;
          break;
        case OrderStatus.delivered:
          shippingStatus = ShippingStatus.delivered;
          break;
        case OrderStatus.cancelled:
          shippingStatus = ShippingStatus.cancelled;
          break;
      }

      if (idx != -1) {
        _shipments[idx].status = shippingStatus;
      } else {
        final cleanGps = order.gpsCode.replaceAll('-', '');
        _shipments.add(
          ManagerShippingItem(
            id: 'SHIP-${order.id}',
            trackingNumber: 'SP-GH-$cleanOrderId-$cleanGps',
            orderOrProcessId: order.id,
            processType: ShippingProcessType.orderFulfillment,
            customerName: order.customerName,
            customerPhone: order.customerPhone,
            customerEmail: order.customerEmail,
            destinationAddress: order.deliveryAddress,
            destinationCity: '${order.region} (${order.gpsCode})',
            courier: 'Circle Express Logistics',
            dispatchRiderPhone: '+233 24 555 7788',
            status: shippingStatus,
            itemsDescription: order.itemsSummary,
            lastLocationUpdate: shippingStatus.defaultLocationHint,
            estimatedDelivery: order.date.add(const Duration(days: 2)),
            dispatchedAt: (order.status == OrderStatus.shipped || order.status == OrderStatus.outForDelivery || order.status == OrderStatus.delivered) ? order.date : null,
            deliveredAt: order.status == OrderStatus.delivered ? order.date.add(const Duration(hours: 4)) : null,
            managerNotes: 'Customer order (${order.paymentMethod}). Total: GH₵ ${order.totalAmount.toStringAsFixed(2)}',
            statusHistory: [
              ShippingCheckpoint(
                timestamp: order.date,
                location: 'Circle Main Store',
                status: ShippingStatus.placed,
                note: 'Order placed and confirmed by customer.',
              ),
              if (order.status != OrderStatus.placed)
                ShippingCheckpoint(
                  timestamp: order.date.add(const Duration(minutes: 30)),
                  location: 'Siaka Accra Hub',
                  status: ShippingStatus.processing,
                  note: 'Order processed and packed.',
                ),
              if (order.status == OrderStatus.shipped || order.status == OrderStatus.outForDelivery || order.status == OrderStatus.delivered)
                ShippingCheckpoint(
                  timestamp: order.date.add(const Duration(hours: 2)),
                  location: 'Circle Main Hub',
                  status: ShippingStatus.dispatched,
                  note: 'Dispatched with courier.',
                ),
              if (order.status == OrderStatus.outForDelivery || order.status == OrderStatus.delivered)
                ShippingCheckpoint(
                  timestamp: order.date.add(const Duration(hours: 3, minutes: 30)),
                  location: order.deliveryAddress,
                  status: ShippingStatus.outForDelivery,
                  note: 'Out for delivery to destination.',
                ),
              if (order.status == OrderStatus.delivered)
                ShippingCheckpoint(
                  timestamp: order.date.add(const Duration(hours: 4)),
                  location: order.deliveryAddress,
                  status: ShippingStatus.delivered,
                  note: 'Successfully delivered to customer.',
                ),
            ],
          ),
        );
      }
    }

    // Sort all shipments with the newest records on top
    _shipments.sort((a, b) {
      final timeA = a.dispatchedAt ?? a.statusHistory.firstOrNull?.timestamp ?? a.estimatedDelivery;
      final timeB = b.dispatchedAt ?? b.statusHistory.firstOrNull?.timestamp ?? b.estimatedDelivery;
      return timeB.compareTo(timeA);
    });
  }

  void addShippingRecord(ManagerShippingItem item) {
    _shipments.insert(0, item);
    addNotification(
      ManagerNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Dispatch Created',
        message: 'Tracking #${item.trackingNumber} for ${item.customerName} (${item.itemsDescription})',
        type: NotificationType.shipping,
        severity: NotificationSeverity.info,
        timestamp: DateTime.now(),
        referenceId: item.id,
        actionRouteIndex: 11,
      ),
    );
    notifyListeners();
  }

  // Notification Actions
  void markNotificationAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    bool changed = false;
    for (final n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void addNotification(ManagerNotification notif) {
    _notifications.insert(0, notif);
    notifyListeners();
  }

  // Advertisement Banner Operations
  void addAdvertisement(AdvertisementBanner ad) {
    _advertisements.add(ad);
    notifyListeners();
  }

  void updateAdvertisement(AdvertisementBanner ad) {
    final index = _advertisements.indexWhere((a) => a.id == ad.id);
    if (index != -1) {
      _advertisements[index] = ad;
      notifyListeners();
    }
  }

  void deleteAdvertisement(String id) {
    _advertisements.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void toggleAdvertisementStatus(String id) {
    final index = _advertisements.indexWhere((a) => a.id == id);
    if (index != -1) {
      final current = _advertisements[index];
      _advertisements[index] = current.copyWith(isActive: !current.isActive);
      notifyListeners();
    }
  }

  void reorderAdvertisement(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _advertisements.length || newIndex < 0 || newIndex >= _advertisements.length) {
      return;
    }
    final item = _advertisements.removeAt(oldIndex);
    _advertisements.insert(newIndex, item);
    for (int i = 0; i < _advertisements.length; i++) {
      _advertisements[i] = _advertisements[i].copyWith(displayOrder: i + 1);
    }
    notifyListeners();
  }
}
