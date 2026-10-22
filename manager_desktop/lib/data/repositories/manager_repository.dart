import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, Icons;

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
import '../../domain/models/banner_playlist.dart';
import '../mock_manager_data.dart';
import '../services/supabase_service.dart';
import '../services/local_sync_server.dart';

class ManagerRepository extends ChangeNotifier {
  Timer? _syncPollTimer;
  int _categoryRevenueSyncTick = 0;
  List<ManagerProduct> _products = [];
  List<ManagerOrder> _orders = [];
  List<AdvertisementBanner> _advertisements = [];
  List<BannerPlaylist> _bannerPlaylists = [];
  List<ManagerBnpl> _bnplApplications = [];
  List<ManagerRepair> _repairs = [];
  List<ManagerSwap> _swaps = [];
  List<CustomerActivity> _customers = [];
  List<CustomerMessage> _sentMessages = [];
  List<ServiceTicket> _serviceTickets = [];
  List<ManagerShippingItem> _shipments = [];
  List<ManagerNotification> _notifications = [];
  List<Map<String, dynamic>> _customerNotifications = [];
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

  bool _isCategoryRevenueDbSynced = false;
  bool get isCategoryRevenueDbSynced => _isCategoryRevenueDbSynced;
  bool get isDatabaseQuotaExceeded => _supabase.isQuotaExceeded;

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

  void _saveCachedProducts(List<ManagerProduct> products) {
    try {
      final file = _getCacheFile();
      if (file != null) {
        final list = products
            .where((p) => p.isMerchandise)
            .map((p) => SupabaseService.productToMap(p))
            .toList();
        file.writeAsStringSync(jsonEncode(list));
      }
    } catch (e) {
      debugPrint('Error saving cached products: $e');
    }
  }

  List<ManagerProduct> _loadCachedProducts() {
    try {
      final file = _getCacheFile();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.trim().isNotEmpty) {
          final list = jsonDecode(content) as List;
          final seenIds = <String>{};
          final items = <ManagerProduct>[];
          for (final m in list) {
            final p = SupabaseService.productFromMap(Map<String, dynamic>.from(m));
            if (p.isMerchandise && !p.id.startsWith('prod_sort_') && !p.id.startsWith('test_')) {
              if (seenIds.add(p.id)) {
                items.add(p);
              }
            }
          }
          return items;
        }
      }
    } catch (e) {
      debugPrint('Error loading cached products: $e');
    }
    return [];
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

  File? _getCategoryRevenueCacheFile() {
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
      return File('${baseDir.path}/cached_category_revenue.json');
    } catch (e) {
      debugPrint('Error getting category revenue cache file: $e');
      return null;
    }
  }

  void _saveCachedCategoryRevenue(List<Map<String, dynamic>> list) {
    try {
      final f = _getCategoryRevenueCacheFile();
      if (f != null) {
        final toSave = list.map((item) => {
          'category': item['category'],
          'amount': item['amount'],
          'units': item['units'],
          'percentage': item['percentage'],
          'updated_at': DateTime.now().toIso8601String(),
        }).toList();
        f.writeAsStringSync(jsonEncode(toSave));
      }
    } catch (e) {
      debugPrint('Error saving cached category revenue: $e');
    }
  }

  List<Map<String, dynamic>> _loadCachedCategoryRevenue() {
    try {
      final f = _getCategoryRevenueCacheFile();
      if (f != null && f.existsSync()) {
        final str = f.readAsStringSync();
        if (str.trim().isNotEmpty) {
          final decoded = jsonDecode(str) as List;
          return decoded.map((d) => Map<String, dynamic>.from(d as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading cached category revenue: $e');
    }
    return [];
  }

  void _saveCachedManagerState() {
    try {
      final file = _getManagerStateCacheFile();
      if (file != null) {
        final data = {
          'orders': _orders.map((o) => _orderToMap(o)).toList(),
          'bnpl': _bnplApplications.map((b) => _bnplToMap(b)).toList(),
          'repairs': _repairs.map((r) => _repairToMap(r)).toList(),
          'swaps': _swaps.map((s) => s.toMap()).toList(),
          'bannerPlaylists': _bannerPlaylists.map((b) => b.toJson()).toList(),
          'customerNotifications': _customerNotifications,
          'sentMessages': _sentMessages.map((m) => m.toJson()).toList(),
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
            final loaded = (data['orders'] as List)
                .map((m) => _orderFromMap(Map<String, dynamic>.from(m)))
                .where((o) =>
                    !o.id.startsWith('SP-88') &&
                    !o.id.startsWith('NOTIF_') &&
                    !o.id.startsWith('CUSTOMER_'))
                .toList();
            final seenCleanIds = <String>{};
            _orders = [];
            for (final o in loaded) {
              final clean = o.id.replaceFirst('ORDER_', '');
              if (seenCleanIds.add(clean)) {
                _orders.add(o);
              }
            }
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
          if (data['swaps'] is List) {
            _swaps = (data['swaps'] as List)
                .map((m) => ManagerSwap.fromMap(Map<String, dynamic>.from(m)))
                .toList();
          }
          if (data['bannerPlaylists'] is List) {
            _bannerPlaylists = (data['bannerPlaylists'] as List)
                .map((m) => BannerPlaylist.fromJson(Map<String, dynamic>.from(m)))
                .map(_sanitizePlaylistImages)
                .toList();
          }
          if (data['customerNotifications'] is List) {
            _customerNotifications = (data['customerNotifications'] as List)
                .map((m) => Map<String, dynamic>.from(m))
                .toList();
          }
          if (data['sentMessages'] is List) {
            final cachedMsgs = (data['sentMessages'] as List)
                .map((m) => CustomerMessage.fromJson(Map<String, dynamic>.from(m)))
                .toList();
            if (cachedMsgs.isNotEmpty) {
              for (final cm in cachedMsgs) {
                if (!_sentMessages.any((m) => m.id == cm.id)) {
                  _sentMessages.add(cm);
                }
              }
            }
          }
        }
      }
      final cachedRev = _loadCachedCategoryRevenue();
      if (cachedRev.isNotEmpty) {
        debugPrint('Loaded ${cachedRev.length} cached category revenue records.');
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

  Map<String, dynamic> _bnplToMap(ManagerBnpl b) => b.toMap();

  ManagerBnpl _bnplFromMap(Map<String, dynamic> m) {
    Map<String, dynamic> extra = {};
    if (m['specs'] != null) {
      if (m['specs'] is Map) {
        extra = Map<String, dynamic>.from(m['specs'] as Map);
      } else if (m['specs'] is String && m['specs'].toString().trim().startsWith('{')) {
        try {
          extra = jsonDecode(m['specs'].toString()) as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    BnplStatus status = BnplStatus.pending;
    final statusStr = (m['status'] ?? extra['status'] ?? m['condition'] ?? '').toString().toLowerCase();
    for (final s in BnplStatus.values) {
      if (s.name.toLowerCase() == statusStr || s.label.toLowerCase() == statusStr) {
        status = s;
        break;
      }
    }

    final rawId = m['id']?.toString() ?? '';
    final cleanId = rawId.replaceFirst('BNPL_', '');

    ManagerBnpl? mockFallback;
    try {
      mockFallback = MockManagerData.getInitialBnplApplications()
          .where((b) => b.id == cleanId || b.id == rawId)
          .firstOrNull;
    } catch (_) {}

    String brand = (extra['brand'] ?? m['brand'] ?? '').toString();
    String modelName = (extra['modelName'] ?? m['modelName'] ?? '').toString();
    String storage = (extra['storage'] ?? m['storage'] ?? '').toString();
    String ram = (extra['ram'] ?? m['ram'] ?? '').toString();
    String deviceCondition = (extra['condition'] ?? m['deviceCondition'] ?? m['condition'] ?? '').toString();
    String preferredColor = (extra['preferredColor'] ?? m['preferredColor'] ?? m['color'] ?? '').toString();
    String customerNotes = (extra['notes'] ?? m['customerNotes'] ?? m['notes'] ?? '').toString();
    String preferredBranch = (extra['preferredBranch'] ?? m['preferredBranch'] ?? m['branch'] ?? '').toString();

    if (mockFallback != null) {
      if (brand.isEmpty) brand = mockFallback.brand;
      if (modelName.isEmpty) modelName = mockFallback.modelName;
      if (storage.isEmpty) storage = mockFallback.storage;
      if (ram.isEmpty) ram = mockFallback.ram;
      if (deviceCondition.isEmpty) deviceCondition = mockFallback.deviceCondition;
      if (preferredColor.isEmpty) preferredColor = mockFallback.preferredColor;
      if (customerNotes.isEmpty) customerNotes = mockFallback.customerNotes;
      if (preferredBranch.isEmpty) preferredBranch = mockFallback.preferredBranch;
    }

    String reqPhone = m['requestedPhone']?.toString() ?? '';
    if (reqPhone.isEmpty) {
      if (brand.isNotEmpty || modelName.isNotEmpty) {
        reqPhone = '$brand $modelName'.trim();
      } else {
        reqPhone = m['name']?.toString() ?? 'Financed Device';
      }
    }

    if (brand.isEmpty) {
      final lower = reqPhone.toLowerCase();
      if (lower.contains('iphone')) {
        brand = 'iPhone';
      } else if (lower.contains('samsung')) {
        brand = 'Samsung';
      } else if (lower.contains('tecno')) {
        brand = 'Tecno';
      } else if (lower.contains('infinix')) {
        brand = 'Infinix';
      } else {
        brand = 'Samsung';
      }
    }
    if (modelName.isEmpty) {
      modelName = reqPhone.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    }
    if (storage.isEmpty) {
      final match = RegExp(r'(\d+\s*(?:GB|TB))', caseSensitive: false).firstMatch(reqPhone);
      if (match != null) {
        storage = match.group(1)!.toUpperCase().replaceAll(RegExp(r'(\d+)(GB|TB)'), r'$1 $2');
      } else {
        storage = '256 GB';
      }
    }
    if (ram.isEmpty) ram = '8 GB';
    if (deviceCondition.isEmpty) deviceCondition = 'Brand New (Sealed)';
    if (preferredColor.isEmpty) preferredColor = 'Any Available Color';
    if (preferredBranch.isEmpty) preferredBranch = 'Siaka Phones Circle';
    if (customerNotes.isEmpty) customerNotes = 'Customer submitted online financing application.';

    final price = (m['phonePrice'] as num?)?.toDouble() ??
        (m['price'] as num?)?.toDouble() ??
        (extra['price'] as num?)?.toDouble() ??
        2800.0;
    final tenure = (m['tenureMonths'] as num?)?.toInt() ??
        (m['stock'] as num?)?.toInt() ??
        (extra['tenureMonths'] as num?)?.toInt() ??
        6;
    final downPayment = (m['downPayment'] as num?)?.toDouble() ??
        (extra['downPayment'] as num?)?.toDouble() ??
        (price * 0.3);
    final monthlyInstallment = (m['monthlyInstallment'] as num?)?.toDouble() ??
        (extra['monthlyInstallment'] as num?)?.toDouble() ??
        ((price - downPayment) / (tenure > 0 ? tenure : 6));

    return ManagerBnpl(
      id: cleanId.isEmpty ? 'BNPL-${DateTime.now().millisecondsSinceEpoch % 10000}' : cleanId,
      applicantName: extra['customerName']?.toString() ?? m['applicantName']?.toString() ?? m['customerName']?.toString() ?? m['name']?.toString() ?? 'Customer',
      phone: extra['customerPhone']?.toString() ?? m['phone']?.toString() ?? m['customerPhone']?.toString() ?? '024 555 0192',
      email: extra['email']?.toString() ?? m['email']?.toString() ?? m['customerEmail']?.toString() ?? 'applicant@gmail.com',
      nationalId: extra['nationalId']?.toString() ?? m['nationalId']?.toString() ?? 'GHA-729104820-1',
      location: extra['location']?.toString() ?? m['location']?.toString() ?? 'Greater Accra, Ghana',
      employer: extra['employer']?.toString() ?? m['employer']?.toString() ?? 'Self Employed / Trader',
      monthlySalary: (extra['monthlySalary'] as num?)?.toDouble() ?? (m['monthlySalary'] as num?)?.toDouble() ?? 3500.0,
      requestedPhone: reqPhone,
      brand: brand,
      modelName: modelName,
      storage: storage,
      ram: ram,
      deviceCondition: deviceCondition,
      preferredColor: preferredColor,
      planDuration: extra['planDuration']?.toString() ?? m['planDuration']?.toString() ?? 'Monthly',
      customerNotes: customerNotes,
      preferredBranch: preferredBranch,
      phonePrice: price,
      downPayment: downPayment,
      monthlyInstallment: monthlyInstallment,
      dailyInstallment: (m['dailyInstallment'] as num?)?.toDouble() ?? (extra['dailyInstallment'] as num?)?.toDouble(),
      weeklyInstallment: (m['weeklyInstallment'] as num?)?.toDouble() ?? (extra['weeklyInstallment'] as num?)?.toDouble(),
      tenureMonths: tenure,
      applicationDate: DateTime.tryParse(m['applicationDate']?.toString() ?? m['created_at']?.toString() ?? '') ?? DateTime.now(),
      status: status,
      managerNotes: m['managerNotes']?.toString() ?? extra['managerNotes']?.toString() ?? '',
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
    'description': r.description,
    'dropOffBranch': r.dropOffBranch,
    'timeSlot': r.timeSlot,
    'photoPath': r.photoPath,
    'appointmentDate': r.appointmentDate?.toIso8601String(),
  };

  ManagerRepair _repairFromMap(Map<String, dynamic> m) {
    Map<String, dynamic> extra = {};
    if (m['specs'] != null) {
      if (m['specs'] is Map) {
        extra = Map<String, dynamic>.from(m['specs'] as Map);
      } else if (m['specs'] is String && m['specs'].toString().trim().startsWith('{')) {
        try {
          extra = jsonDecode(m['specs'].toString()) as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    RepairStage stage = RepairStage.received;
    final stageStr = (m['stage'] ?? extra['status'] ?? m['condition'] ?? '').toString().toLowerCase();
    for (final s in RepairStage.values) {
      if (s.name.toLowerCase() == stageStr || s.label.toLowerCase() == stageStr) {
        stage = s;
        break;
      }
    }

    final rawId = m['id']?.toString() ?? '';
    final cleanId = rawId.replaceFirst('REPAIR_', '');

    return ManagerRepair(
      id: cleanId.isEmpty ? 'REP-${DateTime.now().millisecondsSinceEpoch % 10000}' : cleanId,
      customerName: extra['customerName']?.toString() ?? m['customerName']?.toString() ?? m['name']?.toString() ?? 'Customer',
      customerPhone: extra['customerPhone']?.toString() ?? m['customerPhone']?.toString() ?? '024 555 0192',
      deviceModel: extra['deviceModel']?.toString() ?? m['deviceModel']?.toString() ?? m['brand']?.toString() ?? 'Device',
      reportedIssue: extra['issueType']?.toString() ?? m['reportedIssue']?.toString() ?? m['issueType']?.toString() ?? 'Hardware Diagnostic',
      bookedDate: DateTime.tryParse(m['bookedDate']?.toString() ?? m['created_at']?.toString() ?? '') ?? DateTime.now(),
      stage: stage,
      estimatedCost: (m['estimatedCost'] ?? m['price'] as num?)?.toDouble() ?? 0.0,
      technicianNotes: m['technicianNotes']?.toString() ?? extra['technicianNotes']?.toString() ?? '',
      description: extra['description']?.toString() ?? m['description']?.toString() ?? '',
      dropOffBranch: extra['dropOffBranch']?.toString() ?? m['dropOffBranch']?.toString() ?? 'Siaka Phones Circle',
      timeSlot: extra['timeSlot']?.toString() ?? m['timeSlot']?.toString() ?? 'Morning (09:00 - 12:00)',
      photoPath: extra['photoPath']?.toString() ?? m['photoPath']?.toString(),
      appointmentDate: DateTime.tryParse(extra['appointmentDate']?.toString() ?? m['appointmentDate']?.toString() ?? ''),
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
    final tenure = p.stock > 0 ? p.stock : (extra['tenureMonths'] as num?)?.toInt() ?? 6;
    final brand = (extra['brand'] ?? p.brand).toString();
    final modelName = (extra['modelName'] ?? '').toString();
    final brandModel = modelName.isNotEmpty
        ? (brand.isNotEmpty ? '$brand $modelName' : modelName)
        : (extra['requestedPhone']?.toString() ?? p.name);

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
      brand: brand,
      modelName: modelName,
      storage: extra['storage']?.toString() ?? p.storage,
      ram: extra['ram']?.toString() ?? p.ram,
      deviceCondition: extra['condition']?.toString() ?? '',
      preferredColor: extra['preferredColor']?.toString() ?? p.color,
      planDuration: extra['planDuration']?.toString() ?? 'Monthly',
      customerNotes: extra['notes']?.toString() ?? '',
      preferredBranch: extra['preferredBranch']?.toString() ?? 'Siaka Phones Circle',
      phonePrice: p.price > 0 ? p.price : 2800.0,
      downPayment: p.price > 0 ? p.price * 0.3 : 840.0,
      monthlyInstallment: p.price > 0 ? (p.price * 0.7) / tenure : 326.0,
      dailyInstallment: (extra['dailyInstallment'] as num?)?.toDouble(),
      weeklyInstallment: (extra['weeklyInstallment'] as num?)?.toDouble(),
      tenureMonths: tenure,
      applicationDate: p.createdAt ?? DateTime.now(),
      status: status,
      managerNotes: extra['managerNotes']?.toString() ?? '',
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
      technicianNotes: extra['technicianNotes']?.toString() ?? '',
      description: extra['description']?.toString() ?? '',
      dropOffBranch: extra['dropOffBranch']?.toString() ?? 'Siaka Phones Circle',
      timeSlot: extra['timeSlot']?.toString() ?? 'Morning (09:00 - 12:00)',
      photoPath: extra['photoPath']?.toString(),
      appointmentDate: DateTime.tryParse(extra['appointmentDate']?.toString() ?? ''),
    );
  }

  ManagerSwap _swapFromSupabase(ManagerProduct p) {
    Map<String, dynamic> extra = {};
    try {
      if (p.specs.isNotEmpty && p.specs.startsWith('{')) {
        extra = jsonDecode(p.specs);
      }
    } catch (_) {}

    SwapEvaluationStatus status = SwapEvaluationStatus.underReview;
    final cond = p.condition.toLowerCase();
    if (cond.contains('approv')) {
      status = SwapEvaluationStatus.approved;
    } else if (cond.contains('reject') || cond.contains('declin')) {
      status = SwapEvaluationStatus.rejected;
    } else if (cond.contains('complete') || cond.contains('swap')) {
      status = SwapEvaluationStatus.swapped;
    } else {
      status = SwapEvaluationStatus.underReview;
    }

    final swapId = p.id.replaceFirst('SWAP_', '');
    final customerName = extra['customerName']?.toString() ?? extra['applicantName']?.toString() ?? p.name;
    final customerPhone = extra['customerPhone']?.toString() ?? extra['applicantPhone']?.toString() ?? '024 555 0192';
    final targetDevice = extra['targetDevice']?.toString() ?? extra['desiredModel']?.toString() ?? p.name;
    final targetPrice = (extra['targetDevicePrice'] as num?)?.toDouble() ?? (p.price > 0 ? p.price : 0.0);
    final currentDevice = extra['currentDevice']?.toString() ?? extra['currentModel']?.toString() ?? 'Traded Device';
    final deviceCondition = extra['deviceCondition']?.toString() ?? extra['currentCondition']?.toString() ?? 'Good (Minor Scratches)';
    final batteryHealth = (extra['batteryHealth'] as num?)?.toInt() ?? 85;
    final tradeInValue = (extra['estimatedTradeInValue'] as num?)?.toDouble() ??
        (extra['estimatedTradeInCredit'] as num?)?.toDouble() ??
        (p.originalPrice > 0 ? p.originalPrice : 0.0);
    final cashTopUp = (extra['customerCashTopUp'] as num?)?.toDouble() ??
        (extra['estimatedTopUp'] as num?)?.toDouble() ??
        (targetPrice > tradeInValue ? targetPrice - tradeInValue : 0.0);
    final notes = extra['notes']?.toString() ?? '';
    final branch = extra['preferredBranch']?.toString() ?? 'Circle Main Branch';
    final currentStorage = extra['currentStorage']?.toString() ?? (p.storage.isNotEmpty ? p.storage : '128 GB');
    final turnsOn = extra['turnsOn'] is bool ? extra['turnsOn'] as bool : (extra['turnsOn']?.toString().toLowerCase() != 'false');
    final screenIntact = extra['screenIntact'] is bool ? extra['screenIntact'] as bool : (extra['screenIntact']?.toString().toLowerCase() != 'false');
    final desiredBrand = extra['desiredBrand']?.toString() ?? p.brand;
    final desiredModel = extra['desiredModel']?.toString() ?? '';
    final desiredStorage = extra['desiredStorage']?.toString() ?? p.storage;
    final desiredRam = extra['desiredRam']?.toString() ?? p.ram;
    final desiredCondition = extra['desiredCondition']?.toString() ?? '';
    final desiredColor = extra['desiredColor']?.toString() ?? p.color;
    final offeredCost = (extra['offeredCost'] as num?)?.toDouble();
    final inspectionNotes = [if (branch.isNotEmpty) 'Branch: $branch', if (notes.isNotEmpty) notes].join(' • ');

    return ManagerSwap(
      id: swapId,
      customerName: customerName.isNotEmpty ? customerName : 'Customer',
      customerPhone: customerPhone,
      targetDevice: targetDevice,
      targetDevicePrice: targetPrice,
      currentDevice: currentDevice,
      deviceCondition: deviceCondition,
      batteryHealth: batteryHealth,
      estimatedTradeInValue: tradeInValue,
      customerCashTopUp: cashTopUp,
      currentStorage: currentStorage,
      turnsOn: turnsOn,
      screenIntact: screenIntact,
      desiredBrand: desiredBrand,
      desiredModel: desiredModel,
      desiredStorage: desiredStorage,
      desiredRam: desiredRam,
      desiredCondition: desiredCondition,
      desiredColor: desiredColor,
      preferredBranch: branch,
      customerNotes: notes,
      offeredCost: offeredCost,
      submissionDate: p.createdAt ?? DateTime.now(),
      status: status,
      inspectionNotes: inspectionNotes,
    );
  }

  CustomerActivity _customerFromSupabase(ManagerProduct p) {
    Map<String, dynamic> extra = {};
    try {
      if (p.specs.isNotEmpty && p.specs.startsWith('{')) {
        extra = jsonDecode(p.specs);
      }
    } catch (_) {}

    final custId = extra['customerId']?.toString() ??
        (p.id.startsWith('CUSTOMER_') ? p.id.substring('CUSTOMER_'.length) : p.id);
    final fullName = extra['fullName']?.toString() ?? p.name;
    final phone = extra['phone']?.toString() ?? (p.ram.isNotEmpty ? p.ram : '+233 24 000 0000');
    final email = extra['email']?.toString() ?? (p.color.isNotEmpty ? p.color : '');
    final signupDate = extra['signupDate'] != null
        ? DateTime.tryParse(extra['signupDate'].toString()) ?? p.createdAt ?? DateTime.now()
        : p.createdAt ?? DateTime.now();
    final loginCount = (extra['loginCount'] as num?)?.toInt() ?? 1;
    final lastLogin = extra['lastLogin'] != null
        ? DateTime.tryParse(extra['lastLogin'].toString()) ?? DateTime.now()
        : DateTime.now();
    final primaryDevice = extra['primaryDevice']?.toString() ?? (p.brand.isNotEmpty ? p.brand : 'Mobile App User');
    final status = extra['status']?.toString() ?? (p.condition.isNotEmpty ? p.condition : 'Active');
    final totalSpend = (extra['totalSpend'] as num?)?.toDouble() ?? p.price;
    final totalOrders = (extra['totalOrders'] as num?)?.toInt() ?? p.stock;
    final branch = extra['branch']?.toString() ?? 'Accra Central (Circle)';
    final isOnline = extra['isOnline'] == true;

    return CustomerActivity(
      id: custId,
      fullName: fullName,
      phone: phone,
      email: email,
      signupDate: signupDate,
      loginCount: loginCount,
      lastLogin: lastLogin,
      primaryDevice: primaryDevice,
      status: status,
      totalSpend: totalSpend,
      totalOrders: totalOrders,
      branch: branch,
      isOnline: isOnline,
    );
  }

  CustomerActivity _customerFromRecordMap(Map<String, dynamic> map) {
    final custId = map['id']?.toString() ?? '';
    final fullName = map['full_name']?.toString() ?? map['name']?.toString() ?? 'Customer';
    final phone = map['phone']?.toString() ?? '';
    final email = map['email']?.toString() ?? '';
    final signupDate = map['signup_date'] != null
        ? DateTime.tryParse(map['signup_date'].toString()) ?? DateTime.now()
        : DateTime.now();
    final loginCount = (map['login_count'] as num?)?.toInt() ?? 1;
    final lastLogin = map['last_login'] != null
        ? DateTime.tryParse(map['last_login'].toString()) ?? DateTime.now()
        : DateTime.now();
    final primaryDevice = map['primary_device']?.toString() ?? map['device']?.toString() ?? 'Mobile App User';
    final status = map['status']?.toString() ?? 'Active';
    final totalSpend = (map['total_spend'] as num?)?.toDouble() ?? 0.0;
    final totalOrders = (map['total_orders'] as num?)?.toInt() ?? 0;
    final branch = map['branch']?.toString() ?? 'Accra Central (Circle)';
    final isOnline = map['is_online'] == true;

    return CustomerActivity(
      id: custId,
      fullName: fullName,
      phone: phone,
      email: email,
      signupDate: signupDate,
      loginCount: loginCount,
      lastLogin: lastLogin,
      primaryDevice: primaryDevice,
      status: status,
      totalSpend: totalSpend,
      totalOrders: totalOrders,
      branch: branch,
      isOnline: isOnline,
    );
  }

  Future<void> _syncCustomerToSupabase(CustomerActivity customer) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final token = ManagerProduct(
        id: 'CUSTOMER_${customer.id}',
        name: customer.fullName,
        brand: customer.primaryDevice,
        category: 'CUSTOMER_RECORD',
        price: customer.totalSpend,
        originalPrice: customer.totalSpend,
        stock: customer.totalOrders,
        specs: jsonEncode({
          'customerId': customer.id,
          'fullName': customer.fullName,
          'phone': customer.phone,
          'email': customer.email,
          'signupDate': customer.signupDate.toIso8601String(),
          'loginCount': customer.loginCount,
          'lastLogin': customer.lastLogin.toIso8601String(),
          'primaryDevice': customer.primaryDevice,
          'status': customer.status,
          'totalSpend': customer.totalSpend,
          'totalOrders': customer.totalOrders,
          'branch': customer.branch,
          'isOnline': customer.isOnline,
        }),
        storage: customer.id,
        ram: customer.phone,
        color: customer.email,
        condition: customer.status,
        isFeatured: false,
        imageUrl: '',
        createdAt: customer.signupDate,
      );

      // 1. Upsert to universal products table (guaranteed table)
      _supabase.upsertProduct(token);

      // 2. Also upsert to dedicated customers table if schema created
      _supabase.upsertCustomerRaw({
        'id': customer.id,
        'full_name': customer.fullName,
        'phone': customer.phone,
        'email': customer.email,
        'signup_date': customer.signupDate.toIso8601String(),
        'login_count': customer.loginCount,
        'last_login': customer.lastLogin.toIso8601String(),
        'primary_device': customer.primaryDevice,
        'status': customer.status,
        'total_spend': customer.totalSpend,
        'total_orders': customer.totalOrders,
        'branch': customer.branch,
        'is_online': customer.isOnline,
      });
    } catch (e) {
      debugPrint('ℹ️ Supabase customer sync deferred (quota/offline): $e');
    }
  }

  ManagerRepository() {
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (isTest) {
      _products = MockManagerData.getInitialProducts();
      _orders = MockManagerData.getInitialOrders();
      _bnplApplications = MockManagerData.getInitialBnplApplications();
      _repairs = MockManagerData.getInitialRepairs();
      _swaps = MockManagerData.getInitialSwaps();
      _bannerPlaylists = MockManagerData.getInitialBannerPlaylists();
      _isLoading = false;
    } else {
      final cached = _loadCachedProducts();
      if (cached.isNotEmpty) {
        _products = cached;
      } else {
        _products = MockManagerData.getInitialProducts();
        _saveCachedProducts(_products);
      }
      if (_products.where((p) => p.isMerchandise).isEmpty) {
        _products = MockManagerData.getInitialProducts();
        _saveCachedProducts(_products);
      }
      _orders = [];
      _bnplApplications = [];
      _repairs = [];
      _swaps = [];
      _isLoading = false;
      _loadCachedManagerState();
      // Initial balance is 0.0 — orders start empty until real customer purchases are made/synced
      if (_bnplApplications.isEmpty) {
        _bnplApplications = MockManagerData.getInitialBnplApplications();
      }
      if (_repairs.isEmpty) {
        _repairs = MockManagerData.getInitialRepairs();
      }
      if (_swaps.isEmpty) {
        _swaps = MockManagerData.getInitialSwaps();
      }
      final initialPlaylists = MockManagerData.getInitialBannerPlaylists();
      if (_bannerPlaylists.isEmpty) {
        _bannerPlaylists = List.from(initialPlaylists);
      } else {
        for (final initP in initialPlaylists) {
          if (!_bannerPlaylists.any((p) => p.id == initP.id)) {
            _bannerPlaylists.add(initP);
          }
        }
      }
    }
    _customers = MockManagerData.getInitialCustomerActivities();
    _sentMessages = MockManagerData.getInitialCustomerMessages();
    _serviceTickets = MockManagerData.getInitialServiceTickets();
    _shipments = [];
    _syncOrdersWithShipments();
    _notifications = MockManagerData.getInitialNotifications();
    _advertisements = MockManagerData.getInitialAdvertisements();
    _initSupabaseSync();
    if (!isTest) {
      LocalSyncServer.start(this);
    }
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
  List<ManagerProduct> get allCatalogTokens => List.unmodifiable(_products);
  List<ManagerOrder> get orders {
    final seen = <String>{};
    final result = <ManagerOrder>[];
    for (final o in _orders) {
      if (o.id.startsWith('NOTIF_') || o.id.startsWith('CUSTOMER_')) continue;
      final clean = o.id.replaceFirst('ORDER_', '');
      if (seen.add(clean)) {
        result.add(o);
      }
    }
    return List.unmodifiable(result);
  }
  List<ManagerBnpl> get bnplApplications => List.unmodifiable(_bnplApplications);
  List<ManagerRepair> get repairs => List.unmodifiable(_repairs);
  List<ManagerSwap> get swaps => List.unmodifiable(_swaps);
  List<CustomerActivity> get customers => List.unmodifiable(_customers);

  /// Generates the next chronological customer ID (e.g., SK-90015) based on highest existing ID
  String generateNextCustomerId() {
    int maxId = 90000;
    for (final c in _customers) {
      final clean = c.id.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.isNotEmpty) {
        final parsed = int.tryParse(clean);
        if (parsed != null && parsed > maxId) {
          maxId = parsed;
        }
      }
    }
    return 'SK-${maxId + 1}';
  }

  /// Registers a customer from app sign-up or inbound order with a chronological ID
  CustomerActivity registerCustomer({
    String? id,
    required String fullName,
    required String phone,
    required String email,
    DateTime? signupDate,
    String? primaryDevice,
    String branch = 'Accra Central (Circle)',
    String status = 'Active',
    double totalSpend = 0.0,
    int totalOrders = 0,
    bool isOnline = true,
  }) {
    // Check if customer already exists by phone or email
    final matchIdx = _customers.indexWhere((c) =>
        (phone.isNotEmpty && c.phone.replaceAll(' ', '') == phone.replaceAll(' ', '')) ||
        (email.isNotEmpty && c.email.trim().toLowerCase() == email.trim().toLowerCase()));

    if (matchIdx != -1) {
      final existing = _customers[matchIdx];
      final updated = CustomerActivity(
        id: existing.id,
        fullName: fullName.isNotEmpty ? fullName : existing.fullName,
        phone: phone.isNotEmpty ? phone : existing.phone,
        email: email.isNotEmpty ? email : existing.email,
        signupDate: existing.signupDate,
        loginCount: existing.loginCount + 1,
        lastLogin: DateTime.now(),
        primaryDevice: primaryDevice ?? existing.primaryDevice,
        status: existing.status,
        totalSpend: existing.totalSpend,
        totalOrders: existing.totalOrders,
        branch: branch,
        isOnline: true,
      );
      _customers[matchIdx] = updated;
      _syncCustomerToSupabase(updated);
      notifyListeners();
      return updated;
    }

    final newId = (id != null && id.trim().isNotEmpty) ? id.trim() : generateNextCustomerId();
    final newCustomer = CustomerActivity(
      id: newId,
      fullName: fullName,
      phone: phone,
      email: email,
      signupDate: signupDate ?? DateTime.now(),
      loginCount: 1,
      lastLogin: DateTime.now(),
      primaryDevice: primaryDevice ?? 'Mobile App User',
      status: status,
      totalSpend: totalSpend,
      totalOrders: totalOrders,
      branch: branch,
      isOnline: isOnline,
    );

    _customers.add(newCustomer);
    _syncCustomerToSupabase(newCustomer);
    syncCustomerActivityMetricsToSupabase();
    notifyListeners();
    return newCustomer;
  }

  /// Records customer session or login activity and syncs updated telemetry to Supabase
  void recordCustomerSession({
    required String customerId,
    String? name,
    String? email,
    String? phone,
    String? device,
    bool isLogin = false,
  }) {
    final idx = _customers.indexWhere((c) =>
        c.id.toLowerCase() == customerId.toLowerCase() ||
        (phone != null && phone.isNotEmpty && c.phone.replaceAll(' ', '') == phone.replaceAll(' ', '')) ||
        (email != null && email.isNotEmpty && c.email.trim().toLowerCase() == email.trim().toLowerCase()));

    if (idx != -1) {
      final existing = _customers[idx];
      final updated = CustomerActivity(
        id: existing.id,
        fullName: (name != null && name.isNotEmpty) ? name : existing.fullName,
        phone: (phone != null && phone.isNotEmpty) ? phone : existing.phone,
        email: (email != null && email.isNotEmpty) ? email : existing.email,
        signupDate: existing.signupDate,
        loginCount: isLogin ? existing.loginCount + 1 : existing.loginCount,
        lastLogin: DateTime.now(),
        primaryDevice: (device != null && device.isNotEmpty) ? device : existing.primaryDevice,
        status: existing.status,
        totalSpend: existing.totalSpend,
        totalOrders: existing.totalOrders,
        branch: existing.branch,
        isOnline: true,
      );
      _customers[idx] = updated;
      _syncCustomerToSupabase(updated);
      syncCustomerActivityMetricsToSupabase();
      _saveCachedManagerState();
      notifyListeners();
    } else if (name != null && name.isNotEmpty) {
      final newCust = registerCustomer(
        id: customerId,
        fullName: name,
        phone: phone ?? '',
        email: email ?? '',
        primaryDevice: device ?? 'Mobile App User',
        isOnline: true,
      );
      _syncCustomerToSupabase(newCust);
      syncCustomerActivityMetricsToSupabase();
    }
  }

  /// Synchronizes the 5 top customer activity intelligence banner metrics to Supabase
  Future<void> syncCustomerActivityMetricsToSupabase() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final totalSignups = _customers.length;
      final totalLogins = _customers.fold<int>(0, (sum, c) => sum + c.loginCount);
      final avgLogins = totalSignups > 0 ? (totalLogins / totalSignups).toStringAsFixed(1) : '0';
      final activeCount = _customers.where((c) => c.status != 'Dormant').length;
      final activeRate = totalSignups > 0 ? ((activeCount / totalSignups) * 100).toStringAsFixed(0) : '100';
      final online = onlineCustomersCount;

      final metricsRecord = {
        'id': 'METRICS_CUSTOMER_ACTIVITY',
        'name': 'Customer Activity Metrics Summary',
        'category': 'METRICS_RECORD',
        'price': totalLogins.toDouble(),
        'original_price': totalSignups.toDouble(),
        'stock': online,
        'specs': jsonEncode({
          'usersOnlineNow': online,
          'newSignups': totalSignups,
          'totalLoginsRecorded': totalLogins,
          'avgLoginsPerUser': avgLogins,
          'engagedRetentionRate': activeRate,
          'activeVipCount': activeCount,
          'lastSynced': DateTime.now().toIso8601String(),
        }),
        'storage': '$online',
        'ram': '$totalSignups',
        'color': '$totalLogins',
        'condition': '$activeRate%',
        'is_featured': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      _supabase.upsertRawRecord(metricsRecord);
    } catch (e) {
      debugPrint('ℹ️ Metrics sync deferred: $e');
    }
  }

  /// Refreshes customer activity and banner metrics directly from Supabase
  Future<void> refreshCustomerActivityFromDatabase() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final liveProducts = await _supabase.fetchProducts();
      if (liveProducts != null) {
        _applyRemoteData(liveProducts);
      }
      final dedicatedCustomers = await _supabase.fetchCustomerRecords();
      if (dedicatedCustomers != null && dedicatedCustomers.isNotEmpty) {
        for (final m in dedicatedCustomers) {
          final cust = _customerFromRecordMap(m);
          final idx = _customers.indexWhere((c) => c.id == cust.id);
          if (idx != -1) {
            _customers[idx] = cust;
          } else {
            _customers.add(cust);
          }
        }
        notifyListeners();
      }
      final dedicatedChatMsgs = await _supabase.fetchChatMessageRecords();
      if (dedicatedChatMsgs != null && dedicatedChatMsgs.isNotEmpty) {
        for (final m in dedicatedChatMsgs) {
          _applyInboundChatMessageMap(m);
        }
      }
      await syncCustomerActivityMetricsToSupabase();
    } catch (e) {
      debugPrint('ℹ️ Database refresh notice: $e');
    }
  }
  List<CustomerMessage> get sentMessages => List.unmodifiable(_sentMessages);
  List<ServiceTicket> get serviceTickets => List.unmodifiable(_serviceTickets);
  List<ManagerShippingItem> get shipments => List.unmodifiable(_shipments);
  List<ManagerNotification> get notifications => List.unmodifiable(_notifications);
  List<Map<String, dynamic>> get customerNotifications => List.unmodifiable(_customerNotifications);
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

  /// Returns current status of database connection and category revenue sync.
  String get categoryRevenueSyncStatus {
    if (_isCategoryRevenueDbSynced && !_supabase.isQuotaExceeded) {
      return 'Connected & Synced';
    }
    if (_supabase.isQuotaExceeded) {
      return 'Quota Standby (Auto-Reconnecting)';
    }
    return 'Ready to Sync';
  }

  /// Computes category-by-category revenue, volume units, and share percentages.
  /// Combines baseline turnover with live customer orders, repairs, and device trade-ins.
  /// Filters dynamically by custom date window ([fromDate] to [toDate]) if provided.
  List<Map<String, dynamic>> getCategoryRevenueShare({
    DateTime? fromDate,
    DateTime? toDate,
    String? branch,
  }) {
    // 1. Filter orders by date range and branch
    final matchingOrders = _orders.where((o) {
      if (o.status == OrderStatus.cancelled) return false;
      if (fromDate != null) {
        final start = DateTime(fromDate.year, fromDate.month, fromDate.day, 0, 0, 0);
        if (o.date.isBefore(start)) return false;
      }
      if (toDate != null) {
        final end = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);
        if (o.date.isAfter(end)) return false;
      }
      return true;
    }).toList();

    // 2. Base metrics
    // When viewing overall period without custom date window, include established store baseline
    final bool isCustomDate = fromDate != null || toDate != null;
    double smartAmt = isCustomDate ? 0.0 : 345200.0;
    int smartUnits = isCustomDate ? 0 : 1140;

    double laptopAmt = isCustomDate ? 0.0 : 118400.0;
    int laptopUnits = isCustomDate ? 0 : 195;

    double accAmt = isCustomDate ? 0.0 : 55800.0;
    int accUnits = isCustomDate ? 0 : 860;

    double repairAmt = isCustomDate ? 0.0 : 33100.0;
    int repairUnits = isCustomDate ? 0 : 320;

    // 3. Accumulate from live customer orders
    for (final order in matchingOrders) {
      for (final item in order.items) {
        final title = item.title.toLowerCase();
        final brand = item.brand.toLowerCase();
        final subtotal = item.subtotal > 0 ? item.subtotal : (item.price * item.quantity);
        final qty = item.quantity > 0 ? item.quantity : 1;

        if (title.contains('macbook') ||
            title.contains('laptop') ||
            title.contains('ipad') ||
            title.contains('tablet') ||
            brand.contains('apple mac')) {
          laptopAmt += subtotal;
          laptopUnits += qty;
        } else if (title.contains('pod') ||
            title.contains('earbud') ||
            title.contains('watch') ||
            title.contains('charger') ||
            title.contains('power') ||
            brand.contains('oraimo') ||
            title.contains('headphone') ||
            title.contains('audio')) {
          accAmt += subtotal;
          accUnits += qty;
        } else {
          smartAmt += subtotal;
          smartUnits += qty;
        }
      }
    }

    // 4. Accumulate from repairs desk
    final matchingRepairs = _repairs.where((r) {
      if (fromDate != null && r.bookedDate.isBefore(fromDate)) return false;
      if (toDate != null && r.bookedDate.isAfter(toDate.add(const Duration(days: 1)))) return false;
      return true;
    });
    for (final r in matchingRepairs) {
      repairAmt += r.estimatedCost;
      repairUnits += 1;
    }

    // 5. Accumulate from trade-in swaps
    final matchingSwaps = _swaps.where((s) {
      if (fromDate != null && s.submissionDate.isBefore(fromDate)) return false;
      if (toDate != null && s.submissionDate.isAfter(toDate.add(const Duration(days: 1)))) return false;
      return true;
    });
    for (final s in matchingSwaps) {
      repairAmt += s.customerCashTopUp;
      repairUnits += 1;
    }

    // Proportional fallback if custom range has orders with 0 item subtotals
    if (isCustomDate && (smartAmt + laptopAmt + accAmt + repairAmt) <= 0 && matchingOrders.isNotEmpty) {
      final totalSales = matchingOrders.fold(0.0, (acc, o) => acc + o.totalAmount);
      smartAmt = totalSales * 0.65;
      smartUnits = matchingOrders.length;
      laptopAmt = totalSales * 0.20;
      accAmt = totalSales * 0.15;
    }

    final grandTotal = smartAmt + laptopAmt + accAmt + repairAmt;

    return [
      {
        'category': 'Smartphones',
        'amount': smartAmt,
        'percentage': grandTotal > 0 ? (smartAmt / grandTotal) * 100 : 0.0,
        'units': smartUnits,
        'color': const Color(0xFF1C7BFF),
        'icon': Icons.phone_android_rounded,
      },
      {
        'category': 'Laptops & Tablets',
        'amount': laptopAmt,
        'percentage': grandTotal > 0 ? (laptopAmt / grandTotal) * 100 : 0.0,
        'units': laptopUnits,
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.laptop_mac_rounded,
      },
      {
        'category': 'Accessories & Audio',
        'amount': accAmt,
        'percentage': grandTotal > 0 ? (accAmt / grandTotal) * 100 : 0.0,
        'units': accUnits,
        'color': const Color(0xFF10B981),
        'icon': Icons.headphones_rounded,
      },
      {
        'category': 'Repairs & Swaps Desk',
        'amount': repairAmt,
        'percentage': grandTotal > 0 ? (repairAmt / grandTotal) * 100 : 0.0,
        'units': repairUnits,
        'color': const Color(0xFFF59E0B),
        'icon': Icons.build_circle_rounded,
      },
    ];
  }

  /// Synchronizes the category revenue share records to the Supabase database.
  /// Seamlessly handles database quota limits by caching locally.
  /// As soon as premium quota is active on Supabase, this will automatically
  /// sync to the database without requiring any reconfiguration.
  Future<bool> syncCategoryRevenueToDatabase() async {
    try {
      final categoryList = getCategoryRevenueShare();
      _saveCachedCategoryRevenue(categoryList);

      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        final success = await _supabase.recordCategoryRevenue(categoryList);
        if (success) {
          _isCategoryRevenueDbSynced = true;
          notifyListeners();
          debugPrint('✅ Category revenue share recorded & synchronized to Supabase database');
          return true;
        } else if (_supabase.isQuotaExceeded) {
          _isCategoryRevenueDbSynced = false;
          notifyListeners();
          debugPrint('ℹ️ Category revenue preserved in local cache (Supabase quota standby)');
        }
      } else {
        _isCategoryRevenueDbSynced = true;
        return true;
      }
    } catch (e) {
      debugPrint('ℹ️ Category revenue sync deferred: $e');
    }
    return false;
  }

  /// Refreshes category revenue share from Supabase database.
  Future<void> refreshCategoryRevenueFromDatabase() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final remote = await _supabase.fetchCategoryRevenue();
      if (remote != null && remote.isNotEmpty) {
        _isCategoryRevenueDbSynced = true;
        _saveCachedCategoryRevenue(remote);
        notifyListeners();
        debugPrint('✅ Category revenue refreshed from database (${remote.length} records)');
      }
    } catch (e) {
      debugPrint('ℹ️ Category revenue refresh deferred: $e');
    }
  }

  int get onlineCustomersCount =>
      _customers.where((c) => c.isOnline || DateTime.now().difference(c.lastLogin).inMinutes < 45).length;

  bool isCustomerOnline(String customerId, {String? phone, String? email}) {
    for (final c in _customers) {
      final idMatch = customerId.isNotEmpty &&
          (c.id.toLowerCase() == customerId.toLowerCase() ||
              customerId.toLowerCase().contains(c.id.toLowerCase()) ||
              c.id.toLowerCase().contains(customerId.toLowerCase()));
      final phoneMatch = phone != null &&
          phone.isNotEmpty &&
          c.phone.replaceAll(' ', '') == phone.replaceAll(' ', '');
      final emailMatch = email != null &&
          email.isNotEmpty &&
          c.email.trim().toLowerCase() == email.trim().toLowerCase();
      if (idMatch || phoneMatch || emailMatch) {
        return c.isOnline || DateTime.now().difference(c.lastLogin).inMinutes < 45;
      }
    }
    return false;
  }

  bool isCustomerOnlineForTicket(ServiceTicket ticket) {
    if (isCustomerOnline(ticket.customerId,
        phone: ticket.customerPhone, email: ticket.customerEmail)) {
      return true;
    }
    final customerMessages =
        ticket.messages.where((m) => m.isFromCustomer).toList();
    if (customerMessages.isNotEmpty) {
      if (DateTime.now().difference(customerMessages.last.timestamp).inMinutes < 45) {
        return true;
      }
    }
    return false;
  }

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

  void processInboundCustomerOrder(Map<String, dynamic> data) {
    try {
      final id = data['id']?.toString() ?? '';
      final cat = data['category']?.toString().toUpperCase() ?? '';
      // Exclude notification or customer records from being registered as orders
      if (id.startsWith('NOTIF_') ||
          id.startsWith('CUSTOMER_') ||
          cat == 'NOTIFICATION_RECORD' ||
          cat == 'CUSTOMER_RECORD') {
        if (id.startsWith('NOTIF_') || cat == 'NOTIFICATION_RECORD') {
          processInboundNotification(data);
        }
        return;
      }

      final order = _orderFromMap(data);
      final cleanId = order.id.replaceFirst('ORDER_', '');
      final idx = _orders.indexWhere((o) => o.id.replaceFirst('ORDER_', '') == cleanId);
      if (idx == -1) {
        _orders.insert(0, order);
        _syncOrdersWithShipments();
        _saveCachedManagerState();
        final notifId = 'NOTIF-ORDER-$cleanId';
        if (!_notifications.any((n) => n.id == notifId || n.referenceId == cleanId || n.referenceId == order.id)) {
          addNotification(
            ManagerNotification(
              id: notifId,
              title: 'New Customer Order Placed',
              message: 'Order #$cleanId for GH₵${order.totalAmount.toStringAsFixed(2)} by ${order.customerName}',
              type: NotificationType.order,
              severity: NotificationSeverity.success,
              timestamp: order.date,
              referenceId: cleanId,
              actionRouteIndex: 1,
            ),
          );
        }
        notifyListeners();
        debugPrint('📦 Inbound customer order received via LocalSync: ${order.id}');
      } else {
        _orders[idx] = order;
        _saveCachedManagerState();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error processing inbound customer order: $e');
    }
  }

  void processInboundNotification(Map<String, dynamic> data) {
    try {
      final title = data['title']?.toString() ?? 'Customer Update';
      final message = data['message']?.toString() ?? (data['body']?.toString() ?? '');
      final typeStr = data['type']?.toString().toLowerCase() ?? 'order';
      final refId = data['referenceId']?.toString() ?? data['orderId']?.toString();
      final id = data['id']?.toString() ?? 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';

      NotificationType notifType = NotificationType.order;
      if (typeStr.contains('bnpl')) {
        notifType = NotificationType.bnpl;
      } else if (typeStr.contains('repair')) {
        notifType = NotificationType.repair;
      } else if (typeStr.contains('message') || typeStr.contains('inquiry')) {
        notifType = NotificationType.customerMessage;
      }

      if (!_notifications.any((n) => n.id == id || (refId != null && n.referenceId == refId))) {
        addNotification(
          ManagerNotification(
            id: id,
            title: title,
            message: message,
            type: notifType,
            severity: NotificationSeverity.success,
            timestamp: DateTime.now(),
            referenceId: refId,
            actionRouteIndex: notifType == NotificationType.order ? 1 : null,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error processing inbound notification: $e');
    }
  }

  void processInboundBnpl(Map<String, dynamic> data) {
    try {
      final bnpl = _bnplFromMap(data);
      final cleanId = bnpl.id.replaceFirst('BNPL_', '');
      final idx = _bnplApplications.indexWhere((b) => b.id.replaceFirst('BNPL_', '') == cleanId);
      if (idx == -1) {
        _bnplApplications.insert(0, bnpl);
        final notifId = 'NOTIF-BNPL-$cleanId';
        if (!_notifications.any((n) => n.id == notifId || n.referenceId == cleanId || n.referenceId == bnpl.id)) {
          _notifications.insert(
            0,
            ManagerNotification(
              id: notifId,
              title: 'New BNPL Application: ${bnpl.brand} ${bnpl.modelName}'.trim(),
              message: '${bnpl.applicantName} applied for installment plan (${bnpl.planDuration}) for ${bnpl.requestedPhone}',
              type: NotificationType.bnpl,
              severity: NotificationSeverity.info,
              timestamp: bnpl.applicationDate,
              referenceId: cleanId,
              actionRouteIndex: 3,
            ),
          );
        }
        _saveCachedManagerState();
        notifyListeners();
        debugPrint('💳 Inbound BNPL application received via LocalSync: ${bnpl.id}');
      } else {
        _bnplApplications[idx] = bnpl;
        _saveCachedManagerState();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error processing inbound BNPL: $e');
    }
  }

  void processInboundRepair(Map<String, dynamic> data) {
    try {
      final repair = _repairFromMap(data);
      final cleanId = repair.id.replaceFirst('REPAIR_', '');
      final idx = _repairs.indexWhere((r) => r.id.replaceFirst('REPAIR_', '') == cleanId);
      if (idx == -1) {
        _repairs.insert(0, repair);
        final notifId = 'NOTIF-REPAIR-$cleanId';
        if (!_notifications.any((n) => n.id == notifId || n.referenceId == cleanId || n.referenceId == repair.id)) {
          _notifications.insert(
            0,
            ManagerNotification(
              id: notifId,
              title: 'New Repair Order: ${repair.deviceModel}',
              message: '${repair.customerName} submitted ${repair.reportedIssue} (${repair.dropOffBranch})',
              type: NotificationType.repair,
              severity: NotificationSeverity.info,
              timestamp: repair.bookedDate,
              referenceId: cleanId,
              actionRouteIndex: 4,
            ),
          );
        }
        _saveCachedManagerState();
        notifyListeners();
        debugPrint('🔧 Inbound repair received via LocalSync: ${repair.id}');
      } else {
        _repairs[idx] = repair;
        _saveCachedManagerState();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error processing inbound repair: $e');
    }
  }

  void processInboundSwap(Map<String, dynamic> data) {
    try {
      ManagerSwap swap;
      if (data.containsKey('specs')) {
        final p = SupabaseService.productFromMap(data);
        swap = _swapFromSupabase(p);
      } else {
        swap = ManagerSwap.fromMap(data);
      }
      final cleanId = swap.id.replaceFirst('SWAP_', '');
      final idx = _swaps.indexWhere((s) => s.id.replaceFirst('SWAP_', '') == cleanId);
      if (idx == -1) {
        _swaps.insert(0, swap);
        final notifId = 'NOTIF-SWAP-$cleanId';
        if (!_notifications.any((n) => n.id == notifId || n.referenceId == cleanId || n.referenceId == swap.id)) {
          _notifications.insert(
            0,
            ManagerNotification(
              id: notifId,
              title: 'New Device Swap Request',
              message: '${swap.customerName} requested swap of ${swap.currentDevice} for ${swap.targetDevice}',
              type: NotificationType.swap,
              severity: NotificationSeverity.info,
              timestamp: swap.submissionDate,
              referenceId: cleanId,
              actionRouteIndex: 5,
            ),
          );
        }
        _saveCachedManagerState();
        notifyListeners();
        debugPrint('🔄 Inbound device swap request received via LocalSync: ${swap.id}');
      } else {
        _swaps[idx] = swap;
        _saveCachedManagerState();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error processing inbound swap: $e');
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

  void _normalizeProductImage(ManagerProduct product) {
    if (product.imageBytes != null && product.imageBytes!.isNotEmpty) {
      if (product.imageUrl.isEmpty || !product.imageUrl.startsWith('data:')) {
        product.imageUrl = 'data:image/png;base64,${base64Encode(product.imageBytes!)}';
      }
    }
    var url = product.imageUrl.trim();
    if (url.isNotEmpty &&
        !url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('data:')) {
      try {
        final clean = url.startsWith('file://') ? Uri.parse(url).toFilePath() : url;
        final f = File(clean);
        if (f.existsSync()) {
          final bytes = f.readAsBytesSync();
          final ext = f.path.contains('.') ? f.path.split('.').last.toLowerCase() : 'png';
          final mime = (ext == 'jpg' || ext == 'jpeg') ? 'jpeg' : (ext == 'webp' ? 'webp' : 'png');
          product.imageUrl = 'data:image/$mime;base64,${base64Encode(bytes)}';
        }
      } catch (_) {}
    }
  }

  // Product Actions
  void addProduct(ManagerProduct product) {
    product.createdAt ??= DateTime.now();
    _normalizeProductImage(product);
    final existingIdx = _products.indexWhere((p) => p.id == product.id);
    if (existingIdx != -1) {
      _products[existingIdx] = product;
    } else {
      _products.insert(0, product);
    }
    _sortProductsList(_products);
    _saveCachedProducts(_products);
    notifyListeners();
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _supabase.upsertProduct(product);
    }
  }

  void updateProduct(ManagerProduct product) {
    _normalizeProductImage(product);
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
        final remoteMerchandise = remoteProducts.where((p) => p.isMerchandise).toList();
        if (remoteMerchandise.isEmpty && _products.isNotEmpty) {
          // Database products table is empty: seed existing catalog to Supabase in background
          for (final p in _products) {
            _supabase.upsertProduct(p);
          }
        } else {
          _applyRemoteData(remoteProducts);
        }
      }

      // Fetch customer records from dedicated customers table if available
      try {
        final dedicatedCustomers = await _supabase.fetchCustomerRecords();
        if (dedicatedCustomers != null && dedicatedCustomers.isNotEmpty) {
          for (final m in dedicatedCustomers) {
            final cust = _customerFromRecordMap(m);
            final idx = _customers.indexWhere((c) => c.id == cust.id);
            if (idx != -1) {
              _customers[idx] = cust;
            } else {
              _customers.add(cust);
            }
          }
        } else if (_customers.isNotEmpty) {
          for (final c in _customers) {
            _syncCustomerToSupabase(c);
          }
        }
      } catch (_) {}

      // Realtime stream listener for products & catalog
      _supabase.streamProducts()?.listen((liveProducts) {
        _applyRemoteData(liveProducts);
      }, onError: (e) {
        debugPrint('Supabase products stream error: $e');
      });

      // Realtime stream listener for live chat messages
      try {
        _supabase.streamChatMessageRecords()?.listen((chatRecords) {
          for (final m in chatRecords) {
            _applyInboundChatMessageMap(m);
          }
        }, onError: (e) {
          debugPrint('Supabase chat message stream error: $e');
        });
      } catch (_) {}

      // Initial fetch of chat messages from database
      try {
        final initialChatRecords = await _supabase.fetchChatMessageRecords();
        if (initialChatRecords != null && initialChatRecords.isNotEmpty) {
          for (final m in initialChatRecords) {
            _applyInboundChatMessageMap(m);
          }
        }
      } catch (_) {}

      // Continuous 3-second auto-poll guarantees live customer, activity metrics, & chat messages from customer app are fetched
      _syncPollTimer?.cancel();
      _syncPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        try {
          final live = await _supabase.fetchProducts();
          if (live != null) {
            _applyRemoteData(live);
          }
          final dedicatedCustomers = await _supabase.fetchCustomerRecords();
          if (dedicatedCustomers != null && dedicatedCustomers.isNotEmpty) {
            for (final m in dedicatedCustomers) {
              final cust = _customerFromRecordMap(m);
              final idx = _customers.indexWhere((c) => c.id == cust.id);
              if (idx != -1) {
                _customers[idx] = cust;
              } else {
                _customers.add(cust);
              }
            }
            notifyListeners();
          }
          final dedicatedNotifs = await _supabase.fetchNotificationRecords();
          if (dedicatedNotifs != null && dedicatedNotifs.isNotEmpty) {
            for (final m in dedicatedNotifs) {
              if (m['target'] == 'manager' || m['type'] == 'order') {
                processInboundNotification(m);
              }
            }
          }
          final dedicatedChatMsgs = await _supabase.fetchChatMessageRecords();
          if (dedicatedChatMsgs != null && dedicatedChatMsgs.isNotEmpty) {
            for (final m in dedicatedChatMsgs) {
              _applyInboundChatMessageMap(m);
            }
          }
          // Periodic check: automatically reconnects category revenue to Supabase as soon as quota is restored
          _categoryRevenueSyncTick = (_categoryRevenueSyncTick + 1) % 10;
          if (_categoryRevenueSyncTick == 0) {
            syncCategoryRevenueToDatabase();
          }
        } catch (_) {}
      });
      syncCustomerActivityMetricsToSupabase();
      syncCategoryRevenueToDatabase();
    } catch (e) {
      debugPrint('ℹ️ Supabase sync deferred: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void seedInitialCatalogIfEmpty({bool force = false}) {
    if (force || _products.where((p) => p.isMerchandise).isEmpty) {
      final initial = MockManagerData.getInitialProducts();
      for (final it in initial) {
        if (!_products.any((p) => p.id == it.id)) {
          _products.add(it);
        }
      }
      _sortProductsList(_products);
      _saveCachedProducts(_products);
      _isLoading = false;
      notifyListeners();
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        for (final p in _products) {
          _supabase.upsertProduct(p);
        }
      }
    }
  }

  void _applyRemoteData(List<ManagerProduct> list) {
    final items = list.where((p) => p.isMerchandise).toList();
    if (items.isNotEmpty) {
      for (final it in items) {
        final idx = _products.indexWhere((p) => p.id == it.id);
        if (idx != -1) {
          _products[idx] = it;
        } else {
          _products.add(it);
        }
      }
      _sortProductsList(_products);
      _saveCachedProducts(_products);
      notifyListeners();
    }

    for (final p in items) {
      if (p.category.trim().isNotEmpty) {
        addCategory(p.category, syncRemote: false);
      }
    }

    final remoteOrderProducts = list.where((p) =>
        (p.id.startsWith('ORDER_') ||
         p.category.toUpperCase() == 'ORDER_RECORD' ||
         p.id.startsWith('SP-')) &&
        !p.id.startsWith('NOTIF_') &&
        !p.id.startsWith('CUSTOMER_') &&
        p.category.toUpperCase() != 'NOTIFICATION_RECORD' &&
        p.category.toUpperCase() != 'CUSTOMER_RECORD').toList();
    if (remoteOrderProducts.isNotEmpty) {
      for (final p in remoteOrderProducts) {
        final parsedOrder = _orderFromSupabase(p);
        final cleanId = parsedOrder.id.replaceFirst('ORDER_', '');
        final idx = _orders.indexWhere((o) => o.id.replaceFirst('ORDER_', '') == cleanId);
        if (idx != -1) {
          _orders[idx] = parsedOrder;
        } else {
          _orders.add(parsedOrder);
          final notifId = 'NOTIF-ORDER-$cleanId';
          if (!_notifications.any((n) => n.id == notifId || n.referenceId == cleanId || n.referenceId == parsedOrder.id)) {
            _notifications.insert(
              0,
              ManagerNotification(
                id: notifId,
                title: 'New Customer Order Placed',
                message: 'Order #$cleanId for GH₵${parsedOrder.totalAmount.toStringAsFixed(2)} by ${parsedOrder.customerName}',
                type: NotificationType.order,
                severity: NotificationSeverity.success,
                timestamp: parsedOrder.date,
                referenceId: cleanId,
                actionRouteIndex: 1,
              ),
            );
          }
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
        final cleanId = parsedRepair.id.replaceFirst('REPAIR_', '');
        final idx = _repairs.indexWhere((r) => r.id.replaceFirst('REPAIR_', '') == cleanId);
        if (idx != -1) {
          _repairs[idx] = parsedRepair;
        } else {
          _repairs.add(parsedRepair);
          final notifId = 'NOTIF-REPAIR-$cleanId';
          if (!_notifications.any((n) => n.id == notifId || n.referenceId == cleanId || n.referenceId == parsedRepair.id)) {
            _notifications.insert(
              0,
              ManagerNotification(
                id: notifId,
                title: 'New Repair Order: ${parsedRepair.deviceModel}',
                message: '${parsedRepair.customerName} submitted ${parsedRepair.reportedIssue} (${parsedRepair.dropOffBranch})',
                type: NotificationType.repair,
                severity: NotificationSeverity.info,
                timestamp: parsedRepair.bookedDate,
                referenceId: cleanId,
                actionRouteIndex: 4,
              ),
            );
          }
        }
      }
      _repairs.sort((a, b) => b.bookedDate.compareTo(a.bookedDate));
    }

    final remoteSwapProducts = list.where((p) =>
        p.id.startsWith('SWAP_') ||
        p.category.toUpperCase() == 'SWAP_RECORD').toList();
    if (remoteSwapProducts.isNotEmpty) {
      for (final p in remoteSwapProducts) {
        final parsedSwap = _swapFromSupabase(p);
        final cleanId = parsedSwap.id.replaceFirst('SWAP_', '');
        final idx = _swaps.indexWhere((s) => s.id.replaceFirst('SWAP_', '') == cleanId);
        if (idx != -1) {
          _swaps[idx] = parsedSwap;
        } else {
          _swaps.insert(0, parsedSwap);
          final notifId = 'NOTIF-SWAP-$cleanId';
          if (!_notifications.any((n) => n.id == notifId || n.referenceId == cleanId || n.referenceId == parsedSwap.id)) {
            _notifications.insert(
              0,
              ManagerNotification(
                id: notifId,
                title: 'New Device Swap Request',
                message: '${parsedSwap.customerName} requested swap of ${parsedSwap.currentDevice} for ${parsedSwap.targetDevice}',
                type: NotificationType.swap,
                severity: NotificationSeverity.info,
                timestamp: parsedSwap.submissionDate,
                referenceId: cleanId,
                actionRouteIndex: 5,
              ),
            );
          }
        }
      }
      _swaps.sort((a, b) => b.submissionDate.compareTo(a.submissionDate));
      _saveCachedManagerState();
      notifyListeners();
    }

    final remoteBannerPlaylists = list.where((p) =>
        p.id.startsWith('BANNER_PLAYLIST_') ||
        p.category.toUpperCase() == 'BANNER_PLAYLIST').toList();
    if (remoteBannerPlaylists.isNotEmpty) {
      for (final p in remoteBannerPlaylists) {
        try {
          if (p.condition.isNotEmpty && p.condition.startsWith('{')) {
            final map = jsonDecode(p.condition) as Map<String, dynamic>;
            final playlist = BannerPlaylist.fromJson(map);
            final idx = _bannerPlaylists.indexWhere((bp) => bp.id == playlist.id);
            if (idx != -1) {
              _bannerPlaylists[idx] = playlist;
            } else {
              _bannerPlaylists.add(playlist);
            }
          }
        } catch (e) {
          debugPrint('Error parsing remote banner playlist: $e');
        }
      }
    }

    final remoteCustomerProducts = list.where((p) =>
        p.id.startsWith('CUSTOMER_') ||
        p.category.toUpperCase() == 'CUSTOMER_RECORD').toList();
    if (remoteCustomerProducts.isNotEmpty) {
      for (final p in remoteCustomerProducts) {
        final parsedCustomer = _customerFromSupabase(p);
        final idx = _customers.indexWhere((c) => c.id == parsedCustomer.id);
        if (idx != -1) {
          _customers[idx] = parsedCustomer;
        } else {
          _customers.add(parsedCustomer);
        }
      }
    }

    final remoteNotifs = list.where((p) =>
        p.id.startsWith('NOTIF_') ||
        p.category.toUpperCase() == 'NOTIFICATION_RECORD').toList();
    for (final p in remoteNotifs) {
      try {
        Map<String, dynamic> extra = {};
        if (p.specs.isNotEmpty && p.specs.startsWith('{')) {
          extra = jsonDecode(p.specs);
        }
        if (extra['target'] == 'manager' || extra['type'] == 'order') {
          final notifId = p.id;
          final refId = extra['referenceId']?.toString() ?? extra['orderId']?.toString();
          if (!_notifications.any((n) => n.id == notifId || (refId != null && n.referenceId == refId))) {
            _notifications.insert(
              0,
              ManagerNotification(
                id: notifId,
                title: extra['title']?.toString() ?? p.name,
                message: extra['message']?.toString() ?? (extra['body']?.toString() ?? ''),
                type: NotificationType.order,
                severity: NotificationSeverity.success,
                timestamp: p.createdAt ?? DateTime.now(),
                referenceId: refId,
                actionRouteIndex: 1,
              ),
            );
          }
        }
      } catch (_) {}
    }

    final remoteChatMsgs = list.where((p) =>
        p.id.startsWith('MSG_') ||
        p.category.toUpperCase() == 'CHAT_MESSAGE').toList();
    for (final p in remoteChatMsgs) {
      _applyInboundChatMessageMap(SupabaseService.productToMap(p));
    }

    _saveCachedManagerState();
    notifyListeners();
  }

  void _applyInboundChatMessageMap(Map<String, dynamic> rawMap) {
    try {
      Map<String, dynamic> extra = {};
      if (rawMap['specs'] != null && rawMap['specs'].toString().startsWith('{')) {
        try {
          extra = jsonDecode(rawMap['specs'].toString());
        } catch (_) {}
      }

      final msgId = (extra['id'] ?? rawMap['id'] ?? '').toString();
      final cleanId = msgId.startsWith('MSG_') ? msgId.substring(4) : msgId;
      if (cleanId.isEmpty) return;

      if (_sentMessages.any((m) => m.id == cleanId || m.id == msgId || m.id == 'MSG_$cleanId')) {
        return;
      }

      final isCustomer = extra['isFromCustomer'] == true ||
          extra['is_from_customer'] == true ||
          rawMap['is_from_customer'] == true ||
          rawMap['isFromCustomer'] == true ||
          rawMap['sender']?.toString().toLowerCase() == 'customer';

      final custId = (extra['customerId'] ?? rawMap['customer_id'] ?? rawMap['customerId'] ?? rawMap['storage'] ?? '').toString();
      final messageText = (extra['message'] ?? rawMap['message'] ?? rawMap['name'] ?? '').toString();
      if (messageText.trim().isEmpty) return;

      final sentAtStr = (extra['sentAt'] ?? rawMap['created_at'] ?? rawMap['sentAt'])?.toString();
      final sentAt = sentAtStr != null ? DateTime.tryParse(sentAtStr) ?? DateTime.now() : DateTime.now();

      final customer = _customers.cast<CustomerActivity?>().firstWhere(
        (c) => c != null && c.id == custId,
        orElse: () => null,
      );
      final custName = extra['customerName']?.toString() ??
          rawMap['customer_name']?.toString() ??
          customer?.fullName ??
          (isCustomer ? 'Customer' : 'Store Manager');
      final custPhone = extra['customerPhone']?.toString() ?? customer?.phone ?? '';
      final custEmail = extra['customerEmail']?.toString() ?? customer?.email ?? '';

      final newMsg = CustomerMessage(
        id: cleanId,
        customerId: custId,
        customerName: custName,
        customerPhone: custPhone,
        customerEmail: custEmail,
        message: messageText,
        subject: (extra['subject'] ?? rawMap['subject'] ?? 'Direct Chat').toString(),
        category: MessageCategory.general,
        channel: MessageChannel.inApp,
        sentAt: sentAt,
        isFromCustomer: isCustomer,
        status: MessageDeliveryStatus.delivered,
      );

      _sentMessages.insert(0, newMsg);
      if (isCustomer && custId.isNotEmpty) {
        setCustomerOnline(custId, true);
        _syncInboundMessageToServiceTickets(
          customerId: custId,
          customerName: custName,
          customerPhone: custPhone,
          customerEmail: custEmail,
          messageText: messageText,
          timestamp: sentAt,
        );
      }
      _saveCachedManagerState();
      notifyListeners();
    } catch (e) {
      debugPrint('Error applying inbound chat message map: $e');
    }
  }

  // BNPL Actions
  void updateBnplStatus(
    String id,
    BnplStatus status, {
    String notes = '',
    double? phonePrice,
    double? downPayment,
    double? monthlyInstallment,
  }) {
    final cleanId = id.replaceFirst('BNPL_', '');
    final idx = _bnplApplications.indexWhere((b) => b.id.replaceFirst('BNPL_', '') == cleanId);
    if (idx != -1) {
      _bnplApplications[idx].status = status;
      if (notes.isNotEmpty) {
        _bnplApplications[idx].managerNotes = notes;
      }
      _saveCachedManagerState();
      notifyListeners();
      LocalSyncServer.broadcast('bnpl_update', {
        'id': _bnplApplications[idx].id,
        'status': status.name,
        'statusLabel': status.label,
        'applicantName': _bnplApplications[idx].applicantName,
        'phone': _bnplApplications[idx].phone,
        'managerNotes': _bnplApplications[idx].managerNotes,
        'phonePrice': _bnplApplications[idx].phonePrice,
        'downPayment': _bnplApplications[idx].downPayment,
        'monthlyInstallment': _bnplApplications[idx].monthlyInstallment,
        'planDuration': _bnplApplications[idx].planDuration,
      });
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        _supabase.updateRecordCondition('BNPL_$cleanId', status.name);
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
      LocalSyncServer.broadcast('repair_update', {
        'id': id,
        'stage': stage.name,
        'estimatedCost': _repairs[idx].estimatedCost,
        'technicianNotes': _repairs[idx].technicianNotes,
        'customerPhone': _repairs[idx].customerPhone,
        'customerName': _repairs[idx].customerName,
      });
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        _supabase.updateRepairCost(
          'REPAIR_$id',
          _repairs[idx].estimatedCost,
          condition: stage.name,
          notes: notes,
        );
      }
    }
  }

  // Swap Actions
  void updateSwapStatus(String id, SwapEvaluationStatus status, {String? notes, double? offeredCost}) {
    final idx = _swaps.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _swaps[idx].status = status;
      if (notes != null && notes.isNotEmpty) {
        _swaps[idx].inspectionNotes = notes;
      }
      if (offeredCost != null) {
        _swaps[idx].offeredCost = offeredCost;
      }
      _saveCachedManagerState();
      notifyListeners();
      LocalSyncServer.broadcast('swap_update', {
        'id': id,
        'status': status.name,
        'statusLabel': status.label,
        'offeredCost': _swaps[idx].offeredCost,
        'inspectionNotes': _swaps[idx].inspectionNotes,
        'customerPhone': _swaps[idx].customerPhone,
        'customerName': _swaps[idx].customerName,
      });
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        _supabase.updateSwapValuation(
          'SWAP_$id',
          _swaps[idx].offeredCost ?? 0.0,
          status: status.name,
          notes: notes,
        );
      }
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
        id: generateNextCustomerId(),
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
      _syncCustomerToSupabase(newCustomer);
      _activeMessagingCustomer = newCustomer;
    }
    notifyListeners();
  }

  // Customer Messaging Actions (Outbound & Inbound Real-Time Chat)
  void sendCustomerMessage(CustomerMessage message) {
    _sentMessages.insert(0, message);
    LocalSyncServer.broadcast('chat_message', message.toJson());
    _dispatchCustomerNotification(message);
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _supabase.upsertChatMessageRaw(message.toJson());
    }
    _saveCachedManagerState();
    notifyListeners();
  }

  void _dispatchCustomerNotification(CustomerMessage message) {
    final notifMap = {
      'id': 'NOTIF_MSG_${message.id}',
      'name': message.subject.isNotEmpty ? message.subject : 'Message from Store Manager',
      'brand': message.channel.label,
      'category': 'NOTIFICATION_RECORD',
      'price': 0.0,
      'specs': jsonEncode({
        'id': message.id,
        'title': message.subject.isNotEmpty ? message.subject : 'Message from Store Manager',
        'body': message.message,
        'customerId': message.customerId,
        'customerPhone': message.customerPhone,
        'customerEmail': message.customerEmail,
        'channel': message.channel.name,
        'channelLabel': message.channel.label,
        'sentBy': message.sentBy,
        'target': 'customer',
        'timestamp': message.sentAt.toIso8601String(),
        'isUnread': true,
      }),
      'condition': 'unread',
      'storage': message.customerId,
      'ram': message.customerPhone,
      'color': message.customerEmail,
      'created_at': message.sentAt.toIso8601String(),
    };

    _customerNotifications.insert(0, notifMap);
    LocalSyncServer.broadcast('notification', notifMap);

    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _supabase.upsertRawRecord(notifMap);
      _supabase.upsertNotificationRaw({
        'id': 'NOTIF_MSG_${message.id}',
        'customer_id': message.customerId,
        'title': message.subject.isNotEmpty ? message.subject : 'Message from Store Manager',
        'message': message.message,
        'channel': message.channel.name,
        'target': 'customer',
        'is_read': false,
        'created_at': message.sentAt.toIso8601String(),
      });
    }
  }

  void setCustomerOnline(String customerId, bool isOnline) {
    final idx = _customers.indexWhere((c) =>
        c.id.toLowerCase() == customerId.toLowerCase() ||
        c.phone.replaceAll(' ', '') == customerId.replaceAll(' ', ''));
    if (idx != -1) {
      final existing = _customers[idx];
      final updated = CustomerActivity(
        id: existing.id,
        fullName: existing.fullName,
        phone: existing.phone,
        email: existing.email,
        signupDate: existing.signupDate,
        loginCount: existing.loginCount,
        lastLogin: DateTime.now(),
        primaryDevice: existing.primaryDevice,
        status: existing.status,
        totalSpend: existing.totalSpend,
        totalOrders: existing.totalOrders,
        branch: existing.branch,
        isOnline: isOnline,
      );
      _customers[idx] = updated;
      if (_activeMessagingCustomer?.id == existing.id) {
        _activeMessagingCustomer = updated;
      }
      notifyListeners();
    }
  }

  CustomerMessage addIncomingCustomerReply(
    String customerId,
    String replyText, {
    MessageChannel channel = MessageChannel.inApp,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) {
    final custIdx = _customers.indexWhere(
      (c) =>
          c.id.toLowerCase() == customerId.toLowerCase() ||
          (customerPhone != null &&
              customerPhone.isNotEmpty &&
              c.phone.replaceAll(' ', '') == customerPhone.replaceAll(' ', '')) ||
          (customerEmail != null &&
              customerEmail.isNotEmpty &&
              c.email.trim().toLowerCase() == customerEmail.trim().toLowerCase()),
    );

    CustomerActivity cust;
    if (custIdx != -1) {
      final existing = _customers[custIdx];
      final updated = CustomerActivity(
        id: existing.id,
        fullName: (customerName != null && customerName.isNotEmpty) ? customerName : existing.fullName,
        phone: (customerPhone != null && customerPhone.isNotEmpty) ? customerPhone : existing.phone,
        email: (customerEmail != null && customerEmail.isNotEmpty) ? customerEmail : existing.email,
        signupDate: existing.signupDate,
        loginCount: existing.loginCount,
        lastLogin: DateTime.now(),
        primaryDevice: existing.primaryDevice,
        status: existing.status,
        totalSpend: existing.totalSpend,
        totalOrders: existing.totalOrders,
        branch: existing.branch,
        isOnline: true,
      );
      _customers[custIdx] = updated;
      if (_activeMessagingCustomer?.id == existing.id) {
        _activeMessagingCustomer = updated;
      }
      cust = updated;
    } else {
      cust = CustomerActivity(
        id: customerId,
        fullName: customerName ?? 'Customer',
        phone: customerPhone ?? '+233 24 000 0000',
        email: customerEmail ?? 'customer@gmail.com',
        signupDate: DateTime.now(),
        loginCount: 1,
        lastLogin: DateTime.now(),
        primaryDevice: 'Mobile App',
        status: 'Active',
        totalSpend: 0.0,
        isOnline: true,
      );
      _customers.insert(0, cust);
      _syncCustomerToSupabase(cust);
    }

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
    _syncInboundMessageToServiceTickets(
      customerId: cust.id,
      customerName: cust.fullName,
      customerPhone: cust.phone,
      customerEmail: cust.email,
      messageText: replyText,
      timestamp: DateTime.now(),
    );
    LocalSyncServer.broadcast('chat_message', newMsg.toJson());
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _supabase.upsertChatMessageRaw(newMsg.toJson());
    }
    _saveCachedManagerState();
    notifyListeners();
    return newMsg;
  }

  void _syncInboundMessageToServiceTickets({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String messageText,
    required DateTime timestamp,
  }) {
    final ticketIdx = _serviceTickets.indexWhere(
      (t) =>
          t.customerId.toLowerCase() == customerId.toLowerCase() ||
          (customerPhone.isNotEmpty &&
              t.customerPhone.replaceAll(' ', '') == customerPhone.replaceAll(' ', '')) ||
          (customerEmail.isNotEmpty &&
              t.customerEmail.trim().toLowerCase() == customerEmail.trim().toLowerCase()),
    );

    if (ticketIdx != -1) {
      final ticket = _serviceTickets[ticketIdx];
      if (!ticket.messages.any((m) => m.text == messageText && m.timestamp.difference(timestamp).inSeconds.abs() < 5)) {
        final newMsg = ServiceMessage(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          senderType: ServiceSenderType.customer,
          senderName: customerName.isNotEmpty ? customerName : ticket.customerName,
          text: messageText,
          timestamp: timestamp,
          isRead: false,
        );
        ticket.messages.add(newMsg);
        ticket.status = ServiceTicketStatus.open;
      }
    } else {
      final newTicket = ServiceTicket(
        id: 'TICK-${DateTime.now().millisecondsSinceEpoch}',
        customerId: customerId,
        customerName: customerName.isNotEmpty ? customerName : 'Customer ($customerId)',
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        subject: 'Mobile App Support Inquiry',
        deviceOrTopic: 'Customer App Live Support',
        createdAt: timestamp,
        status: ServiceTicketStatus.open,
        priority: ServiceTicketPriority.normal,
        messages: [
          ServiceMessage(
            id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
            senderType: ServiceSenderType.customer,
            senderName: customerName.isNotEmpty ? customerName : 'Customer',
            text: messageText,
            timestamp: timestamp,
            isRead: false,
          ),
        ],
      );
      _serviceTickets.insert(0, newTicket);
    }
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

      // Broadcast outbound manager message to customer mobile app via LocalSyncServer & Supabase
      final outbound = CustomerMessage(
        id: 'MSG-SRV-${DateTime.now().millisecondsSinceEpoch}',
        customerId: ticket.customerId,
        customerName: ticket.customerName,
        customerPhone: ticket.customerPhone,
        customerEmail: ticket.customerEmail,
        channel: MessageChannel.inApp,
        category: MessageCategory.general,
        subject: 'Support Desk Reply: ${ticket.subject}',
        message: replyText,
        sentAt: DateTime.now(),
        sentBy: 'Siaka Support Specialist',
        status: MessageDeliveryStatus.delivered,
        isFromCustomer: false,
      );
      _sentMessages.insert(0, outbound);

      LocalSyncServer.broadcast('chat_message', outbound.toJson());
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        _supabase.upsertChatMessageRaw(outbound.toJson());
      }
      _saveCachedManagerState();
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
    addVideoToPlaylist(
      'banner_home_1',
      BannerVideoItem(
        id: ad.id,
        videoUrl: ad.videoUrl,
        title: ad.title,
        description: ad.description,
        badgeText: ad.badgeText,
        isActive: ad.isActive,
        displayOrder: ad.displayOrder,
        createdAt: ad.createdAt,
      ),
    );
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

  // ==========================================
  // 5 Banner Playlists Operations
  // ==========================================

  List<BannerPlaylist> get bannerPlaylists => List.unmodifiable(_bannerPlaylists);

  BannerPlaylist? getBannerPlaylist(String id) {
    return _bannerPlaylists.cast<BannerPlaylist?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
  }

  String _normalizeImageUrl(String input) {
    var trimmed = input.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('data:')) {
      return trimmed;
    }
    if ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
        (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
      trimmed = trimmed.substring(1, trimmed.length - 1).trim();
    }
    if (trimmed.startsWith('file://')) {
      try {
        trimmed = Uri.parse(trimmed).toFilePath();
      } catch (_) {
        trimmed = trimmed.replaceFirst('file://', '');
      }
    }
    try {
      final f = File(trimmed);
      if (f.existsSync()) {
        final bytes = f.readAsBytesSync();
        final ext = f.path.contains('.') ? f.path.split('.').last.toLowerCase() : 'png';
        final mime = (ext == 'jpg' || ext == 'jpeg') ? 'jpeg' : (ext == 'webp' ? 'webp' : 'png');
        return 'data:image/$mime;base64,${base64Encode(bytes)}';
      }
    } catch (e) {
      debugPrint('Note: Could not convert local image path: $e');
    }
    return trimmed;
  }

  BannerPlaylist _sanitizePlaylistImages(BannerPlaylist pl) {
    final newImages = pl.images.map((img) {
      final url = _normalizeImageUrl(img.imageUrl);
      return img.copyWith(imageUrl: url);
    }).toList();
    return pl.copyWith(images: newImages);
  }

  void _syncBannerPlaylistRemote(BannerPlaylist playlist) {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final cleanPlaylist = _sanitizePlaylistImages(playlist);
      final token = ManagerProduct(
        id: 'BANNER_PLAYLIST_${cleanPlaylist.id}',
        name: cleanPlaylist.name,
        brand: cleanPlaylist.targetPage,
        category: 'BANNER_PLAYLIST',
        price: cleanPlaylist.bannerIndex.toDouble(),
        originalPrice: 0.0,
        stock: cleanPlaylist.images.length,
        specs: cleanPlaylist.subtitle,
        condition: jsonEncode(cleanPlaylist.toJson()),
        isFeatured: false,
      );
      _supabase.upsertProduct(token);
    } catch (e) {
      debugPrint('Error syncing banner playlist to Supabase: $e');
    }
  }

  void addImageToPlaylist(String playlistId, BannerImageItem image) {
    final idx = _bannerPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final current = _bannerPlaylists[idx];
      if (current.images.length >= 3) {
        debugPrint('⚠️ Cannot add image: Maximum limit of 3 images reached for banner playlist $playlistId.');
        return;
      }
      final newImages = List<BannerImageItem>.from(current.images);
      final url = _normalizeImageUrl(image.imageUrl);
      final itemToAdd = image.copyWith(imageUrl: url, displayOrder: newImages.length + 1);
      newImages.add(itemToAdd);
      _bannerPlaylists[idx] = current.copyWith(images: newImages);
      _saveCachedManagerState();
      _syncBannerPlaylistRemote(_bannerPlaylists[idx]);
      notifyListeners();
    }
  }

  void removeImageFromPlaylist(String playlistId, String imageId) {
    final idx = _bannerPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final current = _bannerPlaylists[idx];
      final newImages = current.images.where((img) => img.id != imageId).toList();
      for (int i = 0; i < newImages.length; i++) {
        newImages[i] = newImages[i].copyWith(displayOrder: i + 1);
      }
      _bannerPlaylists[idx] = current.copyWith(images: newImages);
      _saveCachedManagerState();
      _syncBannerPlaylistRemote(_bannerPlaylists[idx]);
      notifyListeners();
    }
  }

  void togglePlaylistImageStatus(String playlistId, String imageId) {
    final idx = _bannerPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final current = _bannerPlaylists[idx];
      final newImages = current.images.map((img) {
        if (img.id == imageId) {
          return img.copyWith(isActive: !img.isActive);
        }
        return img;
      }).toList();
      _bannerPlaylists[idx] = current.copyWith(images: newImages);
      _saveCachedManagerState();
      _syncBannerPlaylistRemote(_bannerPlaylists[idx]);
      notifyListeners();
    }
  }

  void reorderPlaylistImages(String playlistId, int oldIndex, int newIndex) {
    final idx = _bannerPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final current = _bannerPlaylists[idx];
      final newImages = List<BannerImageItem>.from(current.images);
      if (oldIndex < 0 || oldIndex >= newImages.length || newIndex < 0 || newIndex >= newImages.length) {
        return;
      }
      final item = newImages.removeAt(oldIndex);
      newImages.insert(newIndex, item);
      for (int i = 0; i < newImages.length; i++) {
        newImages[i] = newImages[i].copyWith(displayOrder: i + 1);
      }
      _bannerPlaylists[idx] = current.copyWith(images: newImages);
      _saveCachedManagerState();
      _syncBannerPlaylistRemote(_bannerPlaylists[idx]);
      notifyListeners();
    }
  }

  void togglePlaylistActive(String playlistId) {
    final idx = _bannerPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final current = _bannerPlaylists[idx];
      _bannerPlaylists[idx] = current.copyWith(isActive: !current.isActive);
      _saveCachedManagerState();
      _syncBannerPlaylistRemote(_bannerPlaylists[idx]);
      notifyListeners();
    }
  }

  void addVideoToPlaylist(String playlistId, BannerVideoItem video) {
    final idx = _bannerPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final current = _bannerPlaylists[idx];
      final newVideos = List<BannerVideoItem>.from(current.videos);
      final itemToAdd = video.copyWith(displayOrder: newVideos.length + 1);
      newVideos.add(itemToAdd);
      _bannerPlaylists[idx] = current.copyWith(videos: newVideos);
      _saveCachedManagerState();
      _syncBannerPlaylistRemote(_bannerPlaylists[idx]);
      notifyListeners();
    }
  }

  void removeVideoFromPlaylist(String playlistId, String videoId) {
    final idx = _bannerPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final current = _bannerPlaylists[idx];
      final newVideos = current.videos.where((v) => v.id != videoId).toList();
      for (int i = 0; i < newVideos.length; i++) {
        newVideos[i] = newVideos[i].copyWith(displayOrder: i + 1);
      }
      _bannerPlaylists[idx] = current.copyWith(videos: newVideos);
      _saveCachedManagerState();
      _syncBannerPlaylistRemote(_bannerPlaylists[idx]);
      notifyListeners();
    }
  }

  void togglePlaylistVideoStatus(String playlistId, String videoId) {
    final idx = _bannerPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final current = _bannerPlaylists[idx];
      final newVideos = current.videos.map((v) {
        if (v.id == videoId) {
          return v.copyWith(isActive: !v.isActive);
        }
        return v;
      }).toList();
      _bannerPlaylists[idx] = current.copyWith(videos: newVideos);
      _saveCachedManagerState();
      _syncBannerPlaylistRemote(_bannerPlaylists[idx]);
      notifyListeners();
    }
  }

  void reorderPlaylistVideos(String playlistId, int oldIndex, int newIndex) {
    final idx = _bannerPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final current = _bannerPlaylists[idx];
      final newVideos = List<BannerVideoItem>.from(current.videos);
      if (oldIndex < 0 || oldIndex >= newVideos.length || newIndex < 0 || newIndex >= newVideos.length) {
        return;
      }
      final item = newVideos.removeAt(oldIndex);
      newVideos.insert(newIndex, item);
      for (int i = 0; i < newVideos.length; i++) {
        newVideos[i] = newVideos[i].copyWith(displayOrder: i + 1);
      }
      _bannerPlaylists[idx] = current.copyWith(videos: newVideos);
      _saveCachedManagerState();
      _syncBannerPlaylistRemote(_bannerPlaylists[idx]);
      notifyListeners();
    }
  }

  void updatePlaylistVideo(String playlistId, BannerVideoItem video) {
    final idx = _bannerPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final current = _bannerPlaylists[idx];
      final newVideos = current.videos.map((v) => v.id == video.id ? video : v).toList();
      _bannerPlaylists[idx] = current.copyWith(videos: newVideos);
      _saveCachedManagerState();
      _syncBannerPlaylistRemote(_bannerPlaylists[idx]);
      notifyListeners();
    }
  }
}
