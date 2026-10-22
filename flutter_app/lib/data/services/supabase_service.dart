import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/product.dart';
import '../../domain/models/banner_playlist.dart';

class SupabaseConfig {
  static const String url = 'https://cueyxcsncpxxljzrriqq.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN1ZXl4Y3NuY3B4eGxqenJyaXFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA2OTEzNTMsImV4cCI6MjEwNjI2NzM1M30.jswIEYjD02QReTzh842ugp6aXwJhkfVVCoq2U41zQm0';
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      ).timeout(const Duration(seconds: 2));
      _isInitialized = true;
      debugPrint('✅ Supabase initialized for Mobile App');
    } catch (e) {
      debugPrint('⚠️ Supabase Mobile init warning or timeout: $e');
      _isInitialized = true;
    }
  }

  static Product productFromMap(Map<String, dynamic> map) {
    List<String> parsedColors = [];
    if (map['colors'] != null && map['colors'] is List) {
      parsedColors = (map['colors'] as List).map((c) => c.toString()).toList();
    } else if (map['color'] != null) {
      parsedColors = [map['color'].toString()];
    }
    if (parsedColors.isEmpty) {
      parsedColors = ['Natural Titanium'];
    }

    List<String> images = [];
    if (map['images'] != null && map['images'] is List && (map['images'] as List).isNotEmpty) {
      images = (map['images'] as List).map((i) => i.toString()).toList();
    } else if (map['image_url'] != null && map['image_url'].toString().trim().isNotEmpty) {
      images = [map['image_url'].toString().trim()];
    }

    if (images.isEmpty) {
      final brandLower = (map['brand']?.toString() ?? '').toLowerCase();
      if (brandLower.contains('apple') || brandLower.contains('iphone')) {
        images = ['https://images.unsplash.com/photo-1695048133142-1a20484d2569?auto=format&fit=crop&w=800&q=80'];
      } else if (brandLower.contains('samsung') || brandLower.contains('galaxy')) {
        images = ['https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?auto=format&fit=crop&w=800&q=80'];
      } else if (brandLower.contains('tecno')) {
        images = ['https://images.unsplash.com/photo-1598327105666-5b89351aff97?auto=format&fit=crop&w=800&q=80'];
      } else if (brandLower.contains('infinix')) {
        images = ['https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80'];
      } else {
        images = ['https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80'];
      }
    }

    List<String> storageOptions = [];
    if (map['storages'] != null && map['storages'] is List) {
      storageOptions = (map['storages'] as List)
          .map((s) => s.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (map['storage_options'] != null && map['storage_options'] is List) {
      storageOptions = (map['storage_options'] as List)
          .map((s) => s.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (map['storage'] != null) {
      final raw = map['storage'].toString().trim();
      if (raw.isNotEmpty) {
        storageOptions = raw
            .split(RegExp(r'[,/•|]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }

    List<String> ramOptions = [];
    if (map['rams'] != null && map['rams'] is List) {
      ramOptions = (map['rams'] as List)
          .map((r) => r.toString().trim())
          .where((r) => r.isNotEmpty)
          .toList();
    } else if (map['ram_options'] != null && map['ram_options'] is List) {
      ramOptions = (map['ram_options'] as List)
          .map((r) => r.toString().trim())
          .where((r) => r.isNotEmpty)
          .toList();
    } else if (map['ram'] != null) {
      final raw = map['ram'].toString().trim();
      if (raw.isNotEmpty) {
        ramOptions = raw
            .split(RegExp(r'[,/•|]'))
            .map((r) => r.trim())
            .where((r) => r.isNotEmpty)
            .toList();
      }
    }

    Map<String, String> specs = {};
    List<String> highlights = [];
    if (map['specs_list'] != null && map['specs_list'] is List) {
      final list = map['specs_list'] as List;
      for (int i = 0; i < list.length; i++) {
        final text = list[i].toString().trim();
        if (text.isNotEmpty) {
          specs['Feature ${i + 1}'] = text;
          highlights.add(text);
        }
      }
    } else if (map['specs'] != null) {
      final specsStr = map['specs'].toString().trim();
      specs['Overview'] = specsStr;
      if (specsStr.isNotEmpty) {
        if (specsStr.contains(' • ')) {
          highlights = specsStr.split(' • ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        } else if (specsStr.contains('\n')) {
          highlights = specsStr.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        } else {
          highlights = [specsStr];
        }
      }
    }

    if (highlights.isEmpty && map['specs'] != null && map['specs'].toString().trim().isNotEmpty) {
      final specsStr = map['specs'].toString().trim();
      if (specsStr.contains(' • ')) {
        highlights = specsStr.split(' • ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      } else if (specsStr.contains('\n')) {
        highlights = specsStr.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      } else {
        highlights = [specsStr];
      }
    }

    final retailPrice = (map['original_price'] as num?)?.toDouble() ?? 0.0;
    final wholesalePrice = (map['price'] as num?)?.toDouble() ?? 0.0;
    final displayPrice = retailPrice > 0 ? retailPrice : wholesalePrice;

    return Product(
      id: map['id']?.toString() ?? 'prod_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name']?.toString() ?? 'Phone Model',
      brand: map['brand']?.toString() ?? 'Generic',
      category: map['category']?.toString() ?? 'Smartphones',
      price: displayPrice,
      originalPrice: displayPrice,
      rating: 4.8,
      reviewCount: 42,
      description: map['specs']?.toString() ?? 'Flagship high performance smartphone with premium AMOLED display and fast charging.',
      images: images.isNotEmpty ? images : ['https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=400'],
      colors: parsedColors,
      storageOptions: storageOptions.isNotEmpty ? storageOptions : ['128GB', '256GB'],
      ramOptions: ramOptions,
      specs: specs,
      highlights: highlights,
      isFeatured: map['is_featured'] == true,
      isNewArrival: map['condition'] == 'New',
      inStock: ((map['stock'] as num?)?.toInt() ?? 10) > 0,
      stockCount: (map['stock'] as num?)?.toInt() ?? 10,
      condition: map['condition']?.toString() ?? 'New',
    );
  }

  static HttpClient? _localSyncClient;
  static HttpClient get _syncClient {
    _localSyncClient ??= HttpClient()
      ..connectionTimeout = const Duration(milliseconds: 1200)
      ..idleTimeout = const Duration(seconds: 30);
    return _localSyncClient!;
  }

  static bool _isQuotaRestricted = false;
  static DateTime? _quotaRestrictedUntil;

  /// Returns true if Supabase is currently restricted due to payment/quota limits.
  /// Prevents continuous CPU spin and socket thrashing on mobile clients.
  static bool get isQuotaRestricted {
    if (_isQuotaRestricted && _quotaRestrictedUntil != null) {
      if (DateTime.now().isAfter(_quotaRestrictedUntil!)) {
        _isQuotaRestricted = false;
        _quotaRestrictedUntil = null;
      }
    }
    return _isQuotaRestricted;
  }

  static void markQuotaRestricted() {
    _isQuotaRestricted = true;
    _quotaRestrictedUntil = DateTime.now().add(const Duration(minutes: 5));
    debugPrint('⚠️ Supabase egress quota exceeded (402). Pausing remote polling for 5 minutes.');
  }

  static void checkAndHandleQuotaError(dynamic error) {
    if (error == null) return;
    final str = error.toString().toLowerCase();
    if (str.contains('402') ||
        str.contains('exceed_egress_quota') ||
        str.contains('payment required') ||
        str.contains('restricted due to the following violations')) {
      markQuotaRestricted();
    }
  }

  static String? _activeLocalHost;
  static DateTime? _lastHostCheckTime;
  static const Duration _hostCheckCooldown = Duration(seconds: 15);
  static const List<String> _candidateHosts = [
    '10.0.2.2',      // Android Emulator host loopback
    '192.168.1.167', // PC host Wi-Fi LAN IP (for physical phones)
    '127.0.0.1',     // Localhost loopback
    'localhost',
  ];

  static Future<String?> _resolveLocalHost() async {
    if (_activeLocalHost != null) return _activeLocalHost;
    if (_lastHostCheckTime != null &&
        DateTime.now().difference(_lastHostCheckTime!) < _hostCheckCooldown) {
      return null;
    }
    _lastHostCheckTime = DateTime.now();

    for (final host in _candidateHosts) {
      try {
        final req = await _syncClient.getUrl(Uri.parse('http://$host:8088/api/sync'));
        final res = await req.close().timeout(const Duration(milliseconds: 300));
        if (res.statusCode == 200) {
          _activeLocalHost = host;
          return host;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Live push channel from the PC Manager app (Server-Sent Events). Emits one
  /// event every time the PC inventory changes, so the phone can refresh at once.
  /// Reconnects automatically if the PC app restarts or the network drops.
  Stream<void> localChangeEvents() async* {
    while (true) {
      final host = await _resolveLocalHost();
      if (host == null) {
        await Future.delayed(const Duration(seconds: 10));
        continue;
      }
      HttpClient? client;
      try {
        client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
        final req = await client.getUrl(Uri.parse('http://$host:8088/api/events'));
        req.headers.set('Accept', 'text/event-stream');
        final res = await req.close().timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          // A fresh connection means we may have missed changes: refresh once.
          yield null;
          await for (final chunk in res.transform(utf8.decoder)) {
            if (chunk.contains('event: sync')) {
              yield null;
            }
          }
        }
      } catch (_) {
        _activeLocalHost = null;
      } finally {
        client?.close(force: true);
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  /// High-speed unified sync: fetches products and banners in a single round-trip over port 8088.
  Future<({List<Product>? products, List<BannerPlaylist>? banners})> fetchFullSyncState() async {
    final host = await _resolveLocalHost();
    if (host == null) {
      return (products: null, banners: null);
    }
    try {
      final req = await _syncClient.getUrl(Uri.parse('http://$host:8088/api/sync'));
      final res = await req.close().timeout(const Duration(milliseconds: 1500));
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final map = jsonDecode(body) as Map<String, dynamic>;
        List<Product>? products;
        List<BannerPlaylist>? banners;
        if (map['products'] != null && map['products'] is List) {
          final pList = map['products'] as List;
          products = pList.map((item) => productFromMap(item as Map<String, dynamic>)).toList();
        }
        if (map['banners'] != null && map['banners'] is List) {
          final bList = map['banners'] as List;
          banners = bList.map((item) => BannerPlaylist.fromJson(item as Map<String, dynamic>)).toList();
        }
        if ((products != null && products.isNotEmpty) || (banners != null && banners.isNotEmpty)) {
          return (products: products, banners: banners);
        }
      } else {
        _activeLocalHost = null;
      }
    } catch (_) {
      _activeLocalHost = null;
    }
    return (products: null, banners: null);
  }

  Future<List<Product>?> fetchProducts() async {
    // 1. Direct local sync with PC Manager app (instant for emulator and local network)
    final host = await _resolveLocalHost();
    if (host != null) {
      try {
        final req = await _syncClient.getUrl(Uri.parse('http://$host:8088/api/products'));
        final res = await req.close().timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final List<dynamic> data = jsonDecode(body) as List<dynamic>;
          if (data.isNotEmpty) {
            debugPrint('⚡ Connected directly to Siaka Manager PC on port 8088: loaded ${data.length} products');
            return data
                .map((item) => productFromMap(item as Map<String, dynamic>))
                .toList();
          }
        }
      } catch (_) {}
    }

    if (isQuotaRestricted) return null;
    if (!_isInitialized || client == null) return null;
    try {
      final response = await client!
          .from('products')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 2));
      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => productFromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      checkAndHandleQuotaError(e);
      debugPrint('ℹ️ Mobile fetchProducts note: $e');
      return null;
    }
  }

  Future<List<BannerPlaylist>?> fetchBannerPlaylists() async {
    // Check local PC Manager sync server first
    final host = await _resolveLocalHost();
    if (host != null) {
      try {
        final req = await _syncClient.getUrl(Uri.parse('http://$host:8088/api/banners'));
        final res = await req.close().timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final List<dynamic> data = jsonDecode(body) as List<dynamic>;
          if (data.isNotEmpty) {
            return data.map((item) => BannerPlaylist.fromJson(item as Map<String, dynamic>)).toList();
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Stream<List<Product>>? streamProducts() {
    if (isQuotaRestricted) return null;
    if (!_isInitialized || client == null) return null;
    try {
      return client!
          .from('products')
          .stream(primaryKey: ['id'])
          .map((data) {
            final sorted = List<Map<String, dynamic>>.from(data);
            sorted.sort((a, b) {
              final aTime = a['created_at']?.toString() ?? '';
              final bTime = b['created_at']?.toString() ?? '';
              return bTime.compareTo(aTime);
            });
            return sorted
                .map((map) => productFromMap(map))
                .toList();
          });
    } catch (e) {
      checkAndHandleQuotaError(e);
      debugPrint('⚠️ Mobile streamProducts error: $e');
      return null;
    }
  }

  Future<bool> upsertRawRecord(Map<String, dynamic> record) async {
    // Send to local PC Manager if reachable
    try {
      final host = _activeLocalHost ?? (Platform.isAndroid ? '10.0.2.2' : '127.0.0.1');
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1500);
      final cat = record['category']?.toString().toUpperCase() ?? '';
      final id = record['id']?.toString().toUpperCase() ?? '';
      String? endpoint;
      if (cat == 'ORDER_RECORD' || id.startsWith('ORDER_')) {
        endpoint = '/api/orders';
      } else if (cat.contains('BNPL') || id.startsWith('BNPL_')) {
        endpoint = '/api/bnpl';
      } else if (cat.contains('REPAIR') || id.startsWith('REPAIR_')) {
        endpoint = '/api/repairs';
      } else if (cat.contains('SWAP') || id.startsWith('SWAP_') || cat.contains('TRADEIN')) {
        endpoint = '/api/swaps';
      } else if (cat.contains('NOTIFICATION') || id.startsWith('NOTIF_')) {
        endpoint = '/api/notifications';
      } else if (cat.contains('CUSTOMER') || id.startsWith('CUSTOMER_')) {
        endpoint = '/api/customers';
      }
      if (endpoint != null) {
        final req = await client.postUrl(Uri.parse('http://$host:8088$endpoint'));
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(record));
        await req.close().timeout(const Duration(milliseconds: 1500));
      }
    } catch (_) {}

    if (isQuotaRestricted) return false;
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('products').upsert(record).timeout(const Duration(seconds: 2));
      debugPrint('✅ Synced record to Supabase: ${record['id']}');
      return true;
    } catch (e) {
      checkAndHandleQuotaError(e);
      debugPrint('⚠️ Error upserting record to Supabase: $e');
      return false;
    }
  }

  Future<bool> upsertCustomerRecord(Map<String, dynamic> customer) async {
    final custId = customer['id']?.toString() ?? '';
    final custName = customer['name']?.toString() ?? customer['fullName']?.toString() ?? 'Customer';
    final custPhone = customer['phone']?.toString() ?? '';
    final custEmail = customer['email']?.toString() ?? '';
    final device = customer['device']?.toString() ?? 'Mobile App User';

    // 1. Try dedicated 'customers' table in Supabase
    try {
      if (!isQuotaRestricted && _isInitialized && client != null) {
        await client!.from('customers').upsert({
          'id': custId,
          'full_name': custName,
          'phone': custPhone,
          'email': custEmail,
          'signup_date': DateTime.now().toIso8601String(),
          'primary_device': device,
          'status': 'Active',
          'is_online': true,
        }).timeout(const Duration(seconds: 2));
      }
    } catch (e) {
      checkAndHandleQuotaError(e);
    }

    // 2. Also upsert to 'products' table as universal fallback
    try {
      final record = {
        'id': 'CUSTOMER_$custId',
        'name': custName,
        'brand': device,
        'category': 'CUSTOMER_RECORD',
        'price': 0.0,
        'original_price': 0.0,
        'stock': 0,
        'specs': jsonEncode({
          'customerId': custId,
          'fullName': custName,
          'phone': custPhone,
          'email': custEmail,
          'signupDate': DateTime.now().toIso8601String(),
          'loginCount': 1,
          'primaryDevice': device,
          'status': 'Active',
          'address': customer['address'] ?? '',
          'gpsCode': customer['gpsCode'] ?? '',
          'region': customer['region'] ?? '',
          'country': customer['country'] ?? '',
          'isOnline': true,
        }),
        'storage': custId,
        'ram': custPhone,
        'color': custEmail,
        'condition': 'Active',
        'is_featured': false,
        'image_url': '',
        'created_at': DateTime.now().toIso8601String(),
      };
      return await upsertRawRecord(record);
    } catch (e) {
      checkAndHandleQuotaError(e);
      debugPrint('ℹ️ Mobile customer Supabase sync deferred (quota/offline): $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchOrderRecords() async {
    if (isQuotaRestricted) return null;
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) return null;
    try {
      final response = await client!
          .from('products')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 2));
      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => item as Map<String, dynamic>)
          .where((m) {
            final cat = m['category']?.toString().toUpperCase() ?? '';
            final id = m['id']?.toString().toUpperCase() ?? '';
            return cat == 'ORDER_RECORD' || cat.contains('ORDER') || id.startsWith('ORDER_');
          })
          .toList();
    } catch (e) {
      checkAndHandleQuotaError(e);
      debugPrint('ℹ️ Mobile fetchOrderRecords error: $e');
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>>? streamOrderRecords() {
    if (isQuotaRestricted) return null;
    if (!_isInitialized || client == null) return null;
    try {
      return client!
          .from('products')
          .stream(primaryKey: ['id'])
          .map((data) => List<Map<String, dynamic>>.from(data).where((m) {
                final cat = m['category']?.toString().toUpperCase() ?? '';
                final id = m['id']?.toString().toUpperCase() ?? '';
                return cat == 'ORDER_RECORD' || cat.contains('ORDER') || id.startsWith('ORDER_');
              }).toList());
    } catch (e) {
      checkAndHandleQuotaError(e);
      debugPrint('⚠️ Mobile streamOrderRecords error: $e');
      return null;
    }
  }

  Future<bool> upsertNotificationRaw(Map<String, dynamic> notif) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    if (isQuotaRestricted) return false;
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('notifications').upsert(notif).timeout(const Duration(milliseconds: 1500));
      return true;
    } catch (e) {
      checkAndHandleQuotaError(e);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchNotificationRecords({String? customerId}) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return null;
    if (isQuotaRestricted) return null;
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) return null;
    final results = <Map<String, dynamic>>[];
    try {
      final response = await client!
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(milliseconds: 1500));
      for (final item in response) {
        results.add(Map<String, dynamic>.from(item));
      }
    } catch (e) {
      checkAndHandleQuotaError(e);
    }

    try {
      final response = await client!
          .from('products')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(milliseconds: 1500));
      for (final item in response) {
        final map = Map<String, dynamic>.from(item);
        final cat = map['category']?.toString().toUpperCase() ?? '';
        final id = map['id']?.toString() ?? '';
        if (cat == 'NOTIFICATION_RECORD' || id.startsWith('NOTIF_')) {
          results.add(map);
        }
      }
    } catch (e) {
      checkAndHandleQuotaError(e);
    }
    return results;
  }

  Stream<List<Map<String, dynamic>>>? streamNotificationRecords({String? customerId}) {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return null;
    if (isQuotaRestricted) return null;
    if (!_isInitialized || client == null) return null;
    try {
      return client!
          .from('products')
          .stream(primaryKey: ['id'])
          .map((data) => List<Map<String, dynamic>>.from(data).where((m) {
                final cat = m['category']?.toString().toUpperCase() ?? '';
                final id = m['id']?.toString() ?? '';
                return cat == 'NOTIFICATION_RECORD' || id.startsWith('NOTIF_');
              }).toList());
    } catch (e) {
      checkAndHandleQuotaError(e);
      debugPrint('⚠️ Mobile streamNotificationRecords error: $e');
      return null;
    }
  }

  Future<bool> upsertChatMessageRaw(Map<String, dynamic> msgMap) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) return false;
    bool success = false;
    try {
      await client!.from('messages').upsert({
        'id': msgMap['id'] ?? 'MSG_${DateTime.now().millisecondsSinceEpoch}',
        'customer_id': msgMap['customerId'] ?? msgMap['customer_id'] ?? '',
        'sender': msgMap['sentBy'] ?? (msgMap['isFromCustomer'] == true ? 'Customer' : 'Store Manager'),
        'message': msgMap['message'] ?? '',
        'subject': msgMap['subject'] ?? 'Direct Chat',
        'channel': msgMap['channel'] ?? 'inApp',
        'is_from_customer': msgMap['isFromCustomer'] == true || msgMap['is_from_customer'] == true,
        'status': msgMap['status'] ?? 'delivered',
        'created_at': msgMap['sentAt'] ?? DateTime.now().toIso8601String(),
      }).timeout(const Duration(milliseconds: 1500));
      success = true;
    } catch (_) {}

    // Universal fallback: products table with category CHAT_MESSAGE
    try {
      final msgId = msgMap['id']?.toString() ?? 'MSG_${DateTime.now().millisecondsSinceEpoch}';
      final cleanId = msgId.startsWith('MSG_') ? msgId : 'MSG_$msgId';
      final fallbackRecord = {
        'id': cleanId,
        'name': msgMap['sentBy']?.toString() ?? (msgMap['isFromCustomer'] == true ? 'Customer' : 'Store Manager'),
        'brand': msgMap['channel']?.toString() ?? 'inApp',
        'category': 'CHAT_MESSAGE',
        'price': 0,
        'stock': 1,
        'image': '',
        'condition': msgMap['status']?.toString() ?? 'delivered',
        'storage': msgMap['customerId']?.toString() ?? msgMap['customer_id']?.toString() ?? '',
        'ram': msgMap['customerPhone']?.toString() ?? '',
        'color': msgMap['customerEmail']?.toString() ?? '',
        'specs': jsonEncode(msgMap),
        'created_at': msgMap['sentAt']?.toString() ?? DateTime.now().toIso8601String(),
      };
      await client!.from('products').upsert(fallbackRecord).timeout(const Duration(milliseconds: 1500));
      success = true;
    } catch (_) {}
    return success;
  }

  Future<List<Map<String, dynamic>>?> fetchChatMessageRecords({String? customerId}) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return null;
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) return null;
    final results = <Map<String, dynamic>>[];
    try {
      final response = await client!
          .from('messages')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(milliseconds: 1500));
      for (final item in response) {
        final m = Map<String, dynamic>.from(item);
        if (customerId == null || customerId.isEmpty || m['customer_id'] == customerId || m['customerId'] == customerId) {
          results.add(m);
        }
      }
    } catch (_) {}

    try {
      final response = await client!
          .from('products')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(milliseconds: 1500));
      for (final item in response) {
        final map = Map<String, dynamic>.from(item);
        final cat = map['category']?.toString().toUpperCase() ?? '';
        final id = map['id']?.toString() ?? '';
        if (cat == 'CHAT_MESSAGE' || id.startsWith('MSG_')) {
          if (customerId != null && customerId.isNotEmpty) {
            final targetCust = map['storage']?.toString() ?? '';
            if (targetCust.isNotEmpty && targetCust != customerId) {
              continue;
            }
          }
          results.add(map);
        }
      }
    } catch (_) {}
    return results;
  }

  Stream<List<Map<String, dynamic>>>? streamChatMessageRecords({String? customerId}) {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return null;
    if (!_isInitialized || client == null) return null;
    try {
      return client!
          .from('products')
          .stream(primaryKey: ['id'])
          .map((data) => List<Map<String, dynamic>>.from(data).where((m) {
                final cat = m['category']?.toString().toUpperCase() ?? '';
                final id = m['id']?.toString() ?? '';
                final matchCat = cat == 'CHAT_MESSAGE' || id.startsWith('MSG_');
                if (!matchCat) return false;
                if (customerId != null && customerId.isNotEmpty) {
                  final target = m['storage']?.toString() ?? '';
                  if (target.isNotEmpty && target != customerId) return false;
                }
                return true;
              }).toList());
    } catch (e) {
      debugPrint('⚠️ Mobile streamChatMessageRecords error: $e');
      return null;
    }
  }
}

