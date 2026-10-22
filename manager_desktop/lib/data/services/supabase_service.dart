import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/manager_product.dart';

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

  bool _isQuotaExceeded = false;
  bool get isQuotaExceeded => _isQuotaExceeded;

  bool checkIsQuotaError(dynamic error) {
    final s = error.toString().toLowerCase();
    return s.contains('quota') ||
        s.contains('rate limit') ||
        s.contains('402') ||
        s.contains('429') ||
        s.contains('exceeded') ||
        s.contains('payment required');
  }

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      ).timeout(const Duration(seconds: 2));
      _isInitialized = true;
      debugPrint('✅ Supabase initialized successfully for Siaka Phones');
    } catch (e) {
      debugPrint('⚠️ Supabase initialization timed out or failed: $e');
      _isInitialized = true;
    }
  }

  // Convert ManagerProduct to Supabase map
  static Map<String, dynamic> productToMap(ManagerProduct product) {
    String finalImageUrl = product.imageUrl.trim();
    if (finalImageUrl.isEmpty && product.imageBytes != null && product.imageBytes!.isNotEmpty) {
      finalImageUrl = 'data:image/png;base64,${base64Encode(product.imageBytes!)}';
    }
    if (finalImageUrl.isNotEmpty &&
        !finalImageUrl.startsWith('http://') &&
        !finalImageUrl.startsWith('https://') &&
        !finalImageUrl.startsWith('data:')) {
      try {
        final cleanPath = finalImageUrl.startsWith('file://')
            ? Uri.parse(finalImageUrl).toFilePath()
            : finalImageUrl;
        final f = File(cleanPath);
        if (f.existsSync()) {
          final bytes = f.readAsBytesSync();
          final ext = f.path.contains('.') ? f.path.split('.').last.toLowerCase() : 'png';
          final mime = (ext == 'jpg' || ext == 'jpeg') ? 'jpeg' : (ext == 'webp' ? 'webp' : 'png');
          finalImageUrl = 'data:image/$mime;base64,${base64Encode(bytes)}';
        }
      } catch (_) {}
    }

    return {
      'id': product.id,
      'name': product.name,
      'brand': product.brand,
      'category': product.category,
      'price': product.price,
      'original_price': product.originalPrice,
      'stock': product.stock,
      'specs': product.specs,
      'specs_list': product.specsList,
      'storage': product.storage,
      'storages': product.storages,
      'storage_options': product.storages,
      'ram': product.ram,
      'rams': product.rams,
      'ram_options': product.rams,
      'color': product.color,
      'colors': product.colors,
      'condition': product.condition,
      'is_featured': product.isFeatured,
      'image_url': finalImageUrl,
      'created_at': product.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  // Parse Supabase map to ManagerProduct
  static ManagerProduct productFromMap(Map<String, dynamic> map) {
    List<String> parsedColors = [];
    if (map['colors'] != null) {
      if (map['colors'] is List) {
        parsedColors = (map['colors'] as List).map((c) => c.toString()).toList();
      }
    }

    List<String> parsedStorages = [];
    if (map['storages'] != null && map['storages'] is List) {
      parsedStorages = (map['storages'] as List).map((s) => s.toString()).toList();
    }

    List<String> parsedRams = [];
    if (map['rams'] != null && map['rams'] is List) {
      parsedRams = (map['rams'] as List).map((r) => r.toString()).toList();
    }

    List<String> parsedSpecsList = [];
    if (map['specs_list'] != null && map['specs_list'] is List) {
      parsedSpecsList = (map['specs_list'] as List).map((s) => s.toString()).toList();
    }

    return ManagerProduct(
      id: map['id']?.toString() ?? 'prod_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name']?.toString() ?? 'Unnamed Device',
      brand: map['brand']?.toString() ?? 'Generic',
      category: map['category']?.toString() ?? 'Smartphones',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (map['original_price'] as num?)?.toDouble() ?? (map['price'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      specs: map['specs']?.toString() ?? '',
      specsList: parsedSpecsList.isNotEmpty ? parsedSpecsList : null,
      storage: map['storage']?.toString() ?? (parsedStorages.isNotEmpty ? parsedStorages.join(', ') : '128GB'),
      storages: parsedStorages.isNotEmpty ? parsedStorages : null,
      ram: map['ram']?.toString() ?? (parsedRams.isNotEmpty ? parsedRams.join(', ') : '8GB'),
      rams: parsedRams.isNotEmpty ? parsedRams : null,
      color: map['color']?.toString() ?? (parsedColors.isNotEmpty ? parsedColors.first : 'Natural Titanium'),
      colors: parsedColors.isNotEmpty ? parsedColors : null,
      condition: map['condition']?.toString() ?? 'New',
      isFeatured: map['is_featured'] == true,
      imageUrl: map['image_url']?.toString() ?? '',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }

  // Fetch all products from Supabase
  Future<List<ManagerProduct>?> fetchProducts() async {
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) return null;
    try {
      final response = await client!
          .from('products')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 4));
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => productFromMap(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('ℹ️ Could not fetch products from Supabase (table might not exist yet or offline): $e');
      return null;
    }
  }

  // Add or update product in Supabase
  Future<bool> upsertProduct(ManagerProduct product) async {
    if (!_isInitialized || client == null) {
      debugPrint('ℹ️ Supabase not yet initialized for upsert, initializing now...');
      await initialize();
    }
    if (!_isInitialized || client == null) {
      debugPrint('⚠️ Supabase unavailable for upsert');
      return false;
    }
    try {
      final payload = productToMap(product);
      debugPrint('🚀 Supabase upserting product: ${payload['name']} (colors: ${payload['colors']})');
      await client!.from('products').upsert(payload).timeout(const Duration(seconds: 4));
      debugPrint('✅ Product upserted successfully: ${product.name}');
      return true;
    } catch (e) {
      debugPrint('⚠️ Error upserting product to Supabase: $e');
      if (e.toString().contains('column') || e.toString().contains('does not exist')) {
        try {
          final fallback = Map<String, dynamic>.from(productToMap(product))
            ..remove('storages')
            ..remove('storage_options')
            ..remove('rams')
            ..remove('ram_options');
          await client!.from('products').upsert(fallback).timeout(const Duration(seconds: 4));
          debugPrint('✅ Product upserted with fallback columns successfully: ${product.name}');
          return true;
        } catch (e2) {
          debugPrint('⚠️ Error upserting fallback product: $e2');
        }
      }
      return false;
    }
  }

  Future<bool> upsertRawRecord(Map<String, dynamic> record) async {
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) {
      return false;
    }
    try {
      await client!.from('products').upsert(record).timeout(const Duration(seconds: 4));
      return true;
    } catch (e) {
      debugPrint('⚠️ Error upserting raw record to Supabase: $e');
      return false;
    }
  }

  Future<bool> upsertCustomerRaw(Map<String, dynamic> record) async {
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) {
      return false;
    }
    try {
      await client!.from('customers').upsert(record).timeout(const Duration(seconds: 3));
      return true;
    } catch (e) {
      debugPrint('ℹ️ Supabase customers table sync (fallback to universal products table): $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchCustomerRecords() async {
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) return null;
    try {
      final response = await client!
          .from('customers')
          .select()
          .timeout(const Duration(seconds: 3));
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('ℹ️ Supabase customers table fetch notice: $e');
      return null;
    }
  }

  Future<bool> upsertNotificationRaw(Map<String, dynamic> notif) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) return false;
    bool success = false;
    try {
      await client!.from('notifications').upsert(notif).timeout(const Duration(milliseconds: 1500));
      success = true;
    } catch (_) {}

    // Universal fallback: products table with category NOTIFICATION_RECORD
    try {
      final fallbackRecord = {
        'id': notif['id'] ?? 'NOTIF_${DateTime.now().millisecondsSinceEpoch}',
        'name': notif['title'] ?? notif['name'] ?? 'Store Notification',
        'brand': notif['channel'] ?? 'Siaka Phones',
        'category': 'NOTIFICATION_RECORD',
        'price': 0,
        'stock': 1,
        'image': '',
        'condition': notif['is_read'] == true ? 'read' : 'unread',
        'specs': jsonEncode(notif),
        'created_at': notif['created_at'] ?? DateTime.now().toIso8601String(),
      };
      await client!.from('products').upsert(fallbackRecord).timeout(const Duration(milliseconds: 1500));
      success = true;
    } catch (_) {}
    return success;
  }

  Future<List<Map<String, dynamic>>?> fetchNotificationRecords() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return null;
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
        if (cat == 'NOTIFICATION_RECORD' || id.startsWith('NOTIF_')) {
          results.add(map);
        }
      }
    } catch (_) {}
    return results;
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
      debugPrint('⚠️ Stream chat message error: $e');
      return null;
    }
  }

  Future<bool> updateRecordCondition(String id, String condition) async {
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) {
      return false;
    }
    try {
      await client!.from('products').update({'condition': condition}).eq('id', id).timeout(const Duration(seconds: 4));
      return true;
    } catch (e) {
      debugPrint('⚠️ Error updating record condition in Supabase: $e');
      return false;
    }
  }

  Future<bool> updateRepairCost(String id, double cost, {String? condition, String? notes}) async {
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) {
      return false;
    }
    try {
      final updateData = <String, dynamic>{
        'price': cost,
        'original_price': cost,
      };
      if (condition != null) {
        updateData['condition'] = condition;
      }
      if (notes != null && notes.isNotEmpty) {
        updateData['description'] = notes;
      }
      await client!.from('products').update(updateData).eq('id', id).timeout(const Duration(seconds: 4));
      return true;
    } catch (e) {
      debugPrint('⚠️ Error updating repair cost in Supabase: $e');
      return false;
    }
  }

  Future<bool> updateSwapValuation(String id, double cost, {String? status, String? notes}) async {
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) {
      return false;
    }
    try {
      final updateData = <String, dynamic>{
        'price': cost,
        'original_price': cost,
      };
      if (status != null) {
        updateData['condition'] = status;
      }
      if (notes != null && notes.isNotEmpty) {
        updateData['description'] = notes;
      }
      await client!.from('products').update(updateData).eq('id', id).timeout(const Duration(seconds: 4));
      return true;
    } catch (e) {
      debugPrint('⚠️ Error updating swap valuation in Supabase: $e');
      return false;
    }
  }

  /// Upload image bytes to Supabase Storage bucket 'product-images'.
  /// Returns the public URL of the uploaded image, or null on failure.
  Future<String?> uploadProductImage(Uint8List imageBytes, String productId) async {
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) {
      debugPrint('⚠️ Supabase unavailable for image upload');
      return null;
    }
    try {
      const bucketName = 'product-images';
      final fileName = '$productId.png';

      // Try to remove existing file first (ignore errors)
      try {
        await client!.storage.from(bucketName).remove([fileName]).timeout(const Duration(seconds: 2));
      } catch (_) {}

      // Upload new image
      await client!.storage.from(bucketName).uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
      ).timeout(const Duration(seconds: 3));

      // Get the public URL
      final publicUrl = client!.storage.from(bucketName).getPublicUrl(fileName);
      debugPrint('✅ Product image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('⚠️ Error uploading product image: $e');
      return null;
    }
  }

  // Delete product from Supabase
  Future<bool> deleteProduct(String id) async {
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('products').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('⚠️ Error deleting product from Supabase: $e');
      return false;
    }
  }

  // Stream products changes in real time
  Stream<List<ManagerProduct>>? streamProducts() {
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
              if (aTime.isNotEmpty && bTime.isNotEmpty) {
                return bTime.compareTo(aTime);
              }
              final aId = a['id']?.toString() ?? '';
              final bId = b['id']?.toString() ?? '';
              return bId.compareTo(aId);
            });
            return sorted.map((map) => productFromMap(map)).toList();
          });
    } catch (e) {
      debugPrint('⚠️ Realtime product streaming error: $e');
      return null;
    }
  }

  /// Records category revenue share data to Supabase.
  /// Attempts dedicated `category_revenue` table first, and backs up to universal `products` table.
  /// Seamlessly handles database quota limits and remains in auto-sync standby so it connects
  /// automatically as soon as premium quota is active.
  Future<bool> recordCategoryRevenue(List<Map<String, dynamic>> categoryList) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) return false;

    bool synced = false;

    // 1. Dedicated category_revenue table
    try {
      final payload = categoryList.map((cat) => {
        'id': 'CAT_REV_${cat['category'].toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
        'category': cat['category'],
        'amount': (cat['amount'] as num?)?.toDouble() ?? 0.0,
        'units': (cat['units'] as num?)?.toInt() ?? 0,
        'percentage': (cat['percentage'] as num?)?.toDouble() ?? 0.0,
        'updated_at': DateTime.now().toIso8601String(),
      }).toList();

      await client!.from('category_revenue').upsert(payload).timeout(const Duration(seconds: 3));
      synced = true;
      _isQuotaExceeded = false;
      debugPrint('✅ Category revenue successfully synchronized to Supabase table category_revenue');
    } catch (e) {
      if (checkIsQuotaError(e)) {
        _isQuotaExceeded = true;
        debugPrint('ℹ️ Supabase Quota standby: Category revenue saved locally until premium quota is active ($e)');
      }
    }

    // 2. Universal fallback: products table with category 'CATEGORY_REVENUE_RECORD'
    try {
      for (final cat in categoryList) {
        final catName = cat['category'].toString();
        final safeId = 'CAT_REV_${catName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        final fallbackRecord = {
          'id': safeId,
          'name': 'Category Revenue: $catName',
          'brand': 'Siaka Analytics',
          'category': 'CATEGORY_REVENUE_RECORD',
          'price': (cat['amount'] as num?)?.toDouble() ?? 0.0,
          'stock': (cat['units'] as num?)?.toInt() ?? 0,
          'storage': '${((cat['percentage'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}%',
          'specs': jsonEncode(cat),
          'condition': 'active',
          'created_at': DateTime.now().toIso8601String(),
        };
        await client!.from('products').upsert(fallbackRecord).timeout(const Duration(milliseconds: 1500));
      }
      synced = true;
      _isQuotaExceeded = false;
      debugPrint('✅ Category revenue synced to universal products table backup');
    } catch (e) {
      if (checkIsQuotaError(e)) {
        _isQuotaExceeded = true;
      }
    }

    return synced;
  }

  /// Fetches category revenue records from Supabase.
  Future<List<Map<String, dynamic>>?> fetchCategoryRevenue() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return null;
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) return null;

    // 1. Try dedicated category_revenue table
    try {
      final response = await client!
          .from('category_revenue')
          .select()
          .timeout(const Duration(seconds: 3));
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        _isQuotaExceeded = false;
        return data.map((d) => Map<String, dynamic>.from(d as Map)).toList();
      }
    } catch (e) {
      if (checkIsQuotaError(e)) {
        _isQuotaExceeded = true;
      }
    }

    // 2. Try universal products table fallback
    try {
      final response = await client!
          .from('products')
          .select()
          .eq('category', 'CATEGORY_REVENUE_RECORD')
          .timeout(const Duration(seconds: 3));
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        _isQuotaExceeded = false;
        final list = <Map<String, dynamic>>[];
        for (final d in data) {
          final m = Map<String, dynamic>.from(d as Map);
          if (m['specs'] != null && m['specs'].toString().startsWith('{')) {
            try {
              list.add(Map<String, dynamic>.from(jsonDecode(m['specs'].toString())));
            } catch (_) {}
          } else {
            list.add({
              'category': m['name']?.toString().replaceFirst('Category Revenue: ', '') ?? 'Category',
              'amount': (m['price'] as num?)?.toDouble() ?? 0.0,
              'units': (m['stock'] as num?)?.toInt() ?? 0,
              'percentage': double.tryParse(m['storage']?.toString().replaceAll('%', '') ?? '0') ?? 0.0,
            });
          }
        }
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      if (checkIsQuotaError(e)) {
        _isQuotaExceeded = true;
      }
    }

    return null;
  }
}
