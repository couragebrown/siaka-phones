import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/product.dart';

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
      debugPrint('✅ Supabase initialized for Mobile App');
    } catch (e) {
      debugPrint('⚠️ Supabase Mobile init warning: $e');
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
    if (map['storage_options'] != null && map['storage_options'] is List) {
      storageOptions = (map['storage_options'] as List).map((s) => s.toString()).toList();
    } else if (map['storage'] != null) {
      storageOptions = [map['storage'].toString()];
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
      specs: specs,
      highlights: highlights,
      isFeatured: map['is_featured'] == true,
      isNewArrival: map['condition'] == 'New',
      inStock: ((map['stock'] as num?)?.toInt() ?? 10) > 0,
      stockCount: (map['stock'] as num?)?.toInt() ?? 10,
      condition: map['condition']?.toString() ?? 'New',
    );
  }

  Future<List<Product>?> fetchProducts() async {
    if (!_isInitialized || client == null) return null;
    try {
      final response = await client!.from('products').select().order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => productFromMap(item as Map<String, dynamic>))
          .where((p) => p.isMerchandise)
          .toList();
    } catch (e) {
      debugPrint('ℹ️ Mobile fetchProducts note: $e');
      return null;
    }
  }

  Stream<List<Product>>? streamProducts() {
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
                .where((p) => p.isMerchandise)
                .toList();
          });
    } catch (e) {
      debugPrint('⚠️ Mobile streamProducts error: $e');
      return null;
    }
  }

  Future<bool> upsertRawRecord(Map<String, dynamic> record) async {
    if (!_isInitialized || client == null) {
      await initialize();
    }
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('products').upsert(record);
      debugPrint('✅ Synced record to Supabase: ${record['id']}');
      return true;
    } catch (e) {
      debugPrint('⚠️ Error upserting record to Supabase: $e');
      return false;
    }
  }
}
