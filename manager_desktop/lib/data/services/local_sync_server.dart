import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../repositories/manager_repository.dart';
import 'supabase_service.dart';

class LocalSyncServer {
  static HttpServer? _server;
  static const int port = 8088;

  // Live push channel (Server-Sent Events) so connected mobile apps are told the
  // instant inventory changes instead of waiting for their next poll.
  static final Set<HttpResponse> _eventClients = {};
  static Timer? _heartbeat;
  static Timer? _debounce;
  static VoidCallback? _repoListener;
  static ManagerRepository? _listeningRepo;
  static final Map<String, Map<String, dynamic>> _customerCartWishlist = {};

  static void _broadcast(String payload) {
    final dead = <HttpResponse>[];
    for (final c in _eventClients) {
      try {
        c.write(payload);
      } catch (_) {
        dead.add(c);
      }
    }
    _eventClients.removeAll(dead);
  }

  static void _attachRepositoryListener(ManagerRepository repository) {
    if (_listeningRepo == repository) return;
    if (_listeningRepo != null && _repoListener != null) {
      _listeningRepo!.removeListener(_repoListener!);
    }
    _repoListener = () {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 60), () {
        _broadcast('event: sync\ndata: ${DateTime.now().millisecondsSinceEpoch}\n\n');
      });
    };
    repository.addListener(_repoListener!);
    _listeningRepo = repository;
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 10), (_) => _broadcast(': ping\n\n'));
  }

  static Future<void> start(ManagerRepository repository) async {
    if (_server != null) return;
    for (int attempt = 1; attempt <= 5; attempt++) {
      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
        debugPrint('🚀 Siaka Manager Local Sync Server listening on port $port');
        break;
      } catch (e) {
        if (attempt == 5) {
          debugPrint('⚠️ Could not bind LocalSyncServer on port $port: $e');
          return;
        }
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }
    if (_server == null) return;
    _attachRepositoryListener(repository);

    try {
      _server!.listen((HttpRequest request) async {
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', '*');

        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        final path = request.uri.path;
        try {
          if (request.method == 'GET' && path == '/api/events') {
            final res = request.response;
            res.bufferOutput = false;
            res.statusCode = HttpStatus.ok;
            res.headers.contentType = ContentType('text', 'event-stream', charset: 'utf-8');
            res.headers.set('Cache-Control', 'no-cache');
            res.headers.set('Connection', 'keep-alive');
            res.write('retry: 500\n: connected\n\n');
            await res.flush();
            _eventClients.add(res);
            res.done.then((_) => _eventClients.remove(res)).catchError((_) {
              _eventClients.remove(res);
              return true;
            });
            return;
          } else if (request.method == 'GET' && path == '/api/sync') {
            final productList = repository.allCatalogTokens.map((p) => SupabaseService.productToMap(p)).toList();
            final bannerList = repository.bannerPlaylists.map((b) => b.toJson()).toList();
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({
              'products': productList,
              'banners': bannerList,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }));
            await request.response.close();
          } else if (request.method == 'GET' && path == '/api/products') {
            final list = repository.allCatalogTokens.map((p) => SupabaseService.productToMap(p)).toList();
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode(list));
            await request.response.close();
          } else if (request.method == 'POST' && path == '/api/products') {
            final body = await _readRequestBody(request);
            if (body.isNotEmpty) {
              final data = jsonDecode(body) as Map<String, dynamic>;
              final p = SupabaseService.productFromMap(data);
              repository.addProduct(p);
            }
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'success': true, 'count': repository.products.length}));
            await request.response.close();
          } else if (request.method == 'PUT' && path == '/api/products') {
            final body = await _readRequestBody(request);
            if (body.isNotEmpty) {
              final data = jsonDecode(body) as Map<String, dynamic>;
              final p = SupabaseService.productFromMap(data);
              repository.updateProduct(p);
            }
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'success': true, 'count': repository.products.length}));
            await request.response.close();
          } else if (request.method == 'DELETE' && (path == '/api/products' || path.startsWith('/api/products/'))) {
            String productId = '';
            if (path.startsWith('/api/products/') && path.length > '/api/products/'.length) {
              productId = path.substring('/api/products/'.length);
            } else if (request.uri.queryParameters.containsKey('id')) {
              productId = request.uri.queryParameters['id']!;
            } else {
              final body = await _readRequestBody(request);
              if (body.isNotEmpty) {
                final data = jsonDecode(body) as Map<String, dynamic>;
                productId = data['id']?.toString() ?? '';
              }
            }
            if (productId.isNotEmpty) {
              repository.deleteProduct(productId);
            }
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'success': true, 'deleted': productId, 'count': repository.products.length}));
            await request.response.close();
          } else if (request.method == 'POST' && path == '/api/seed') {
            repository.seedInitialCatalogIfEmpty(force: true);
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'success': true, 'count': repository.products.length}));
            await request.response.close();
          } else if (request.method == 'GET' && path == '/api/banners') {
            final list = repository.bannerPlaylists.map((b) => b.toJson()).toList();
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode(list));
            await request.response.close();
          } else if (request.method == 'POST' && path == '/api/orders') {
            final body = await _readRequestBody(request);
            if (body.isNotEmpty) {
              final data = jsonDecode(body) as Map<String, dynamic>;
              repository.processInboundCustomerOrder(data);
            }
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'success': true}));
            await request.response.close();
          } else if (request.method == 'POST' && path == '/api/bnpl') {
            final body = await _readRequestBody(request);
            if (body.isNotEmpty) {
              final data = jsonDecode(body) as Map<String, dynamic>;
              repository.processInboundBnpl(data);
            }
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'success': true}));
            await request.response.close();
          } else if (request.method == 'GET' && path == '/api/bnpl') {
            final custPhone = request.uri.queryParameters['phone'] ?? '';
            final custName = request.uri.queryParameters['name'] ?? '';
            final list = repository.bnplApplications.where((b) {
              if (custPhone.isEmpty && custName.isEmpty) return true;
              return (custPhone.isNotEmpty && b.phone.replaceAll(' ', '') == custPhone.replaceAll(' ', '')) ||
                     (custName.isNotEmpty && b.applicantName.toLowerCase() == custName.toLowerCase());
            }).map((b) => b.toMap()).toList();
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode(list));
            await request.response.close();
          } else if (request.method == 'POST' && path == '/api/repairs') {
            final body = await _readRequestBody(request);
            if (body.isNotEmpty) {
              final data = jsonDecode(body) as Map<String, dynamic>;
              repository.processInboundRepair(data);
            }
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'success': true}));
            await request.response.close();
          } else if (request.method == 'GET' && path == '/api/repairs') {
            final custPhone = request.uri.queryParameters['phone'] ?? '';
            final custName = request.uri.queryParameters['name'] ?? '';
            final list = repository.repairs.where((r) {
              if (custPhone.isEmpty && custName.isEmpty) return true;
              return (custPhone.isNotEmpty && r.customerPhone.replaceAll(' ', '') == custPhone.replaceAll(' ', '')) ||
                     (custName.isNotEmpty && r.customerName.toLowerCase() == custName.toLowerCase());
            }).map((r) => {
              'id': r.id,
              'customerName': r.customerName,
              'customerPhone': r.customerPhone,
              'deviceModel': r.deviceModel,
              'reportedIssue': r.reportedIssue,
              'description': r.description,
              'dropOffBranch': r.dropOffBranch,
              'timeSlot': r.timeSlot,
              'estimatedCost': r.estimatedCost,
              'stage': r.stage.name,
              'stageLabel': r.stage.label,
              'technicianNotes': r.technicianNotes,
              'appointmentDate': r.appointmentDate?.toIso8601String(),
              'bookedDate': r.bookedDate.toIso8601String(),
            }).toList();
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode(list));
            await request.response.close();
          } else if (request.method == 'POST' && (path == '/api/swaps' || path == '/api/tradein')) {
            final body = await _readRequestBody(request);
            if (body.isNotEmpty) {
              final data = jsonDecode(body) as Map<String, dynamic>;
              repository.processInboundSwap(data);
            }
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'success': true}));
            await request.response.close();
          } else if (request.method == 'GET' && (path == '/api/swaps' || path == '/api/tradein')) {
            final custPhone = request.uri.queryParameters['phone'] ?? '';
            final custName = request.uri.queryParameters['name'] ?? '';
            final list = repository.swaps.where((s) {
              if (custPhone.isEmpty && custName.isEmpty) return true;
              return (custPhone.isNotEmpty && s.customerPhone.replaceAll(' ', '') == custPhone.replaceAll(' ', '')) ||
                     (custName.isNotEmpty && s.customerName.toLowerCase() == custName.toLowerCase());
            }).map((s) => {
              'id': s.id,
              'customerName': s.customerName,
              'customerPhone': s.customerPhone,
              'currentDevice': s.currentDevice,
              'targetDevice': s.targetDevice,
              'deviceCondition': s.deviceCondition,
              'preferredBranch': s.preferredBranch,
              'status': s.status.name,
              'statusLabel': s.status.label,
              'offeredCost': s.offeredCost,
              'inspectionNotes': s.inspectionNotes,
              'submittedDate': s.submissionDate.toIso8601String(),
            }).toList();
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode(list));
            await request.response.close();
          } else if (request.method == 'GET' && path == '/api/next_customer_id') {
            final nextId = repository.generateNextCustomerId();
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'id': nextId, 'customerId': nextId}));
            await request.response.close();
          } else if (request.method == 'GET' && (path == '/api/cart-wishlist' || path == '/api/cart_wishlist')) {
            final custId = request.uri.queryParameters['customerId'] ?? request.uri.queryParameters['id'] ?? '';
            final data = _customerCartWishlist[custId] ?? {'cart': [], 'wishlist': []};
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode(data));
            await request.response.close();
          } else if (request.method == 'POST' && (path == '/api/cart-wishlist' || path == '/api/cart_wishlist')) {
            final body = await _readRequestBody(request);
            if (body.isNotEmpty) {
              final data = jsonDecode(body) as Map<String, dynamic>;
              final custId = data['customerId']?.toString() ?? data['id']?.toString() ?? '';
              if (custId.isNotEmpty) {
                _customerCartWishlist[custId] = {
                  'cart': data['cart'] ?? data['cartItems'] ?? [],
                  'wishlist': data['wishlist'] ?? data['wishlistItems'] ?? [],
                  'updatedAt': DateTime.now().toIso8601String(),
                };
              }
            }
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'success': true}));
            await request.response.close();
          } else if (request.method == 'POST' && (path == '/api/customers' || path == '/api/register')) {
            final body = await _readRequestBody(request);
            if (body.isNotEmpty) {
              final data = jsonDecode(body) as Map<String, dynamic>;
              final cust = repository.registerCustomer(
                id: data['id']?.toString(),
                fullName: data['name']?.toString() ?? data['fullName']?.toString() ?? 'Customer',
                phone: data['phone']?.toString() ?? '',
                email: data['email']?.toString() ?? '',
                primaryDevice: data['device']?.toString() ?? data['primaryDevice']?.toString() ?? 'Mobile App User',
              );
              request.response.statusCode = HttpStatus.ok;
              request.response.headers.contentType = ContentType.json;
              request.response.write(jsonEncode({
                'success': true,
                'id': cust.id,
                'customerId': cust.id,
              }));
            } else {
              request.response.statusCode = HttpStatus.badRequest;
            }
            await request.response.close();
          } else if (request.method == 'GET' && path == '/api/customers') {
            final list = repository.customers.map((c) => {
              'id': c.id,
              'fullName': c.fullName,
              'phone': c.phone,
              'email': c.email,
              'signupDate': c.signupDate.toIso8601String(),
              'loginCount': c.loginCount,
              'lastLogin': c.lastLogin.toIso8601String(),
              'primaryDevice': c.primaryDevice,
              'status': c.status,
              'totalSpend': c.totalSpend,
              'totalOrders': c.totalOrders,
              'branch': c.branch,
              'isOnline': c.isOnline,
            }).toList();
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode(list));
            await request.response.close();
          } else if (request.method == 'POST' && (path == '/api/telemetry' || path == '/api/ping')) {
            final body = await _readRequestBody(request);
            if (body.isNotEmpty) {
              final data = jsonDecode(body) as Map<String, dynamic>;
              final custId = data['customerId']?.toString() ?? data['id']?.toString() ?? '';
              if (custId.isNotEmpty) {
                repository.recordCustomerSession(
                  customerId: custId,
                  name: data['name']?.toString(),
                  email: data['email']?.toString(),
                  phone: data['phone']?.toString(),
                  device: data['device']?.toString(),
                  isLogin: data['isLogin'] == true,
                );
              }
            }
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'success': true}));
            await request.response.close();
          } else if (request.method == 'GET' && path == '/api/customer_metrics') {
            final totalSignups = repository.customers.length;
            final totalLogins = repository.customers.fold<int>(0, (sum, c) => sum + c.loginCount);
            final avgLogins = totalSignups > 0 ? (totalLogins / totalSignups).toStringAsFixed(1) : '0';
            final activeCount = repository.customers.where((c) => c.status != 'Dormant').length;
            final activeRate = totalSignups > 0 ? ((activeCount / totalSignups) * 100).toStringAsFixed(0) : '100';
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({
              'usersOnlineNow': repository.onlineCustomersCount,
              'newSignups': totalSignups,
              'totalLogins': totalLogins,
              'avgLoginsPerUser': avgLogins,
              'engagedRetentionRate': '$activeRate%',
              'activeVipCount': activeCount,
            }));
            await request.response.close();
          } else if (request.method == 'GET' && (path == '/api/notifications' || path == '/api/customer_notifications')) {
            final custId = request.uri.queryParameters['customerId'] ?? '';
            final list = repository.customerNotifications.where((n) {
              if (custId.isEmpty) return true;
              final targetCust = n['customerId']?.toString() ?? n['storage']?.toString() ?? '';
              return targetCust.isEmpty || targetCust == custId || targetCust == 'all';
            }).toList();
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode(list));
            await request.response.close();
          } else if (request.method == 'POST' && path == '/api/notifications') {
            final body = await _readRequestBody(request);
            if (body.isNotEmpty) {
              final data = jsonDecode(body) as Map<String, dynamic>;
              repository.processInboundNotification(data);
            }
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'success': true}));
            await request.response.close();
          } else if (request.method == 'GET' && path == '/api/messages') {
            final custId = request.uri.queryParameters['customerId'] ?? '';
            final list = repository.sentMessages.where((m) {
              if (custId.isEmpty) return true;
              return m.customerId == custId ||
                  m.customerId.toLowerCase() == custId.toLowerCase() ||
                  m.customerPhone.replaceAll(' ', '') == custId.replaceAll(' ', '');
            }).map((m) => m.toJson()).toList();
            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode(list));
            await request.response.close();
          } else if (request.method == 'POST' && path == '/api/messages') {
            final body = await _readRequestBody(request);
            if (body.isNotEmpty) {
              final data = jsonDecode(body) as Map<String, dynamic>;
              final custId = data['customerId']?.toString() ?? data['customer_id']?.toString() ?? '';
              final msgText = data['message']?.toString() ?? data['text']?.toString() ?? '';
              if (custId.isNotEmpty && msgText.isNotEmpty) {
                final newMsg = repository.addIncomingCustomerReply(
                  custId,
                  msgText,
                  customerName: data['customerName']?.toString() ?? data['name']?.toString(),
                  customerPhone: data['customerPhone']?.toString() ?? data['phone']?.toString(),
                  customerEmail: data['customerEmail']?.toString() ?? data['email']?.toString(),
                );
                request.response.statusCode = HttpStatus.ok;
                request.response.headers.contentType = ContentType.json;
                request.response.write(jsonEncode({'success': true, 'id': newMsg.id}));
              } else {
                request.response.statusCode = HttpStatus.badRequest;
                request.response.headers.contentType = ContentType.json;
                request.response.write(jsonEncode({'error': 'Missing customerId or message'}));
              }
            } else {
              request.response.statusCode = HttpStatus.badRequest;
            }
            await request.response.close();
          } else {
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
          }
        } catch (e) {
          debugPrint('LocalSyncServer request error: $e');
          try {
            request.response.statusCode = HttpStatus.internalServerError;
            await request.response.close();
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('ℹ️ LocalSyncServer note: $e');
    }
  }

  static Future<String> _readRequestBody(HttpRequest request) async {
    final List<int> bytes = [];
    await for (final chunk in request) {
      bytes.addAll(chunk);
    }
    if (bytes.isEmpty) return '';
    try {
      return utf8.decode(bytes);
    } catch (_) {
      try {
        return latin1.decode(bytes);
      } catch (_) {
        return String.fromCharCodes(bytes);
      }
    }
  }

  static void stop() {
    _heartbeat?.cancel();
    _debounce?.cancel();
    if (_listeningRepo != null && _repoListener != null) {
      _listeningRepo!.removeListener(_repoListener!);
    }
    _listeningRepo = null;
    _eventClients.clear();
    _server?.close(force: true);
    _server = null;
  }

  static void broadcast(String event, dynamic data) {
    final payload = 'event: $event\ndata: ${jsonEncode(data)}\n\n';
    for (final client in List.of(_eventClients)) {
      try {
        client.write(payload);
        client.flush();
      } catch (_) {
        _eventClients.remove(client);
      }
    }
  }
}
