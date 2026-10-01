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

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );
      _isInitialized = true;
      debugPrint('✅ Supabase initialized successfully for Siaka Phones');
    } catch (e) {
      debugPrint('⚠️ Supabase initialization failed or already initialized: $e');
      _isInitialized = true;
    }
  }

  // Convert ManagerProduct to Supabase map
  static Map<String, dynamic> productToMap(ManagerProduct product) {
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
      'ram': product.ram,
      'color': product.color,
      'colors': product.colors,
      'condition': product.condition,
      'is_featured': product.isFeatured,
      'image_url': product.imageUrl,
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
      storage: map['storage']?.toString() ?? '128GB',
      ram: map['ram']?.toString() ?? '8GB',
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
      final response = await client!.from('products').select().order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => productFromMap(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('ℹ️ Could not fetch products from Supabase (table might not exist yet): $e');
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
      await client!.from('products').upsert(payload);
      debugPrint('✅ Product upserted successfully: ${product.name}');
      return true;
    } catch (e) {
      debugPrint('⚠️ Error upserting product to Supabase: $e');
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
        await client!.storage.from(bucketName).remove([fileName]);
      } catch (_) {}

      // Upload new image
      await client!.storage.from(bucketName).uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
      );

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
}
