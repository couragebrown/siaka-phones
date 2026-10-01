import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mock_data.dart';
import '../../domain/models/product.dart';
import '../services/supabase_service.dart';

class ProductRepository with ChangeNotifier {
  List<Product> _products = [];
  final Set<String> _customCategories = {};
  final SupabaseService _supabase = SupabaseService();
  Timer? _syncTimer;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ProductRepository() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _products = List.from(MockData.products);
      _processProductList(_products);
    } else {
      _initFromStorageAndSync();
    }
  }

  Future<void> _initFromStorageAndSync() async {
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_products_v1');
      if (cachedJson != null && cachedJson.trim().isNotEmpty) {
        final list = jsonDecode(cachedJson) as List;
        final cached = list
            .map((item) => Product.fromMap(item as Map<String, dynamic>))
            .toList();
        if (cached.isNotEmpty) {
          _processProductList(cached);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('ℹ️ Cache load note: $e');
    }
    _initSupabaseSync();
  }

  Future<void> _saveToStorage(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = products.map((p) => p.toMap()).toList();
      await prefs.setString('cached_products_v1', jsonEncode(data));
    } catch (_) {}
  }

  static const List<String> defaultCategories = [
    'Smartphones',
    'UK Used',
    'Keypad Phones',
    'Laptops',
    'Accessories',
    'Tablets',
    'Foldables',
    'Wearables',
    'Headphones',
  ];

  void _processProductList(List<Product> list) {
    for (final p in list) {
      if (p.id.startsWith('CAT_')) {
        final catName = p.name.trim().isNotEmpty ? p.name.trim() : p.category.trim();
        if (catName.isNotEmpty && catName.toLowerCase() != 'category') {
          _customCategories.add(catName);
        }
      } else {
        final cat = p.category.trim();
        if (cat.isNotEmpty &&
            cat.toLowerCase() != 'category' &&
            !defaultCategories.any((b) => b.toLowerCase() == cat.toLowerCase())) {
          _customCategories.add(cat);
        }
      }
    }
    _products = list.where((p) =>
        !p.id.startsWith('CAT_') &&
        !p.id.startsWith('ORDER_') &&
        !p.id.startsWith('BNPL_') &&
        !p.id.startsWith('REPAIR_')).toList();
  }

  bool _productsOrCategoriesChanged(
    List<Product> oldProducts,
    List<Product> newProducts,
    Set<String> oldCats,
    Set<String> newCats,
  ) {
    if (oldProducts.length != newProducts.length) return true;
    if (oldCats.length != newCats.length) return true;
    for (final c in newCats) {
      if (!oldCats.contains(c)) return true;
    }
    final oldMap = {for (final p in oldProducts) p.id: p};
    for (final p2 in newProducts) {
      final p1 = oldMap[p2.id];
      if (p1 == null) return true;
      if (p1.name != p2.name ||
          p1.price != p2.price ||
          p1.originalPrice != p2.originalPrice ||
          p1.category != p2.category ||
          p1.brand != p2.brand ||
          p1.isFeatured != p2.isFeatured ||
          p1.images.length != p2.images.length) {
        return true;
      }
      if (p1.images.isNotEmpty &&
          p2.images.isNotEmpty &&
          p1.images.first != p2.images.first) {
        return true;
      }
    }
    return false;
  }

  Future<void> refreshFromSupabase({bool silent = false}) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      if (!_supabase.isInitialized) {
        await _supabase.initialize();
      }
      final remote = await _supabase.fetchProducts();
      if (remote != null && remote.isNotEmpty) {
        final oldProducts = List<Product>.from(_products);
        final oldCustomCats = Set<String>.from(_customCategories);
        _processProductList(remote);
        _isLoading = false;
        _saveToStorage(_products);
        if (_productsOrCategoriesChanged(
            oldProducts, _products, oldCustomCats, _customCategories)) {
          notifyListeners();
        }
      }
    } catch (e) {
      if (!silent) {
        debugPrint('ℹ️ Supabase fetch note: $e');
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _initSupabaseSync() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      await _supabase.initialize();
      await refreshFromSupabase(silent: true);
      _supabase.streamProducts()?.listen(
        (liveList) {
          if (liveList.isNotEmpty) {
            final oldProducts = List<Product>.from(_products);
            final oldCustomCats = Set<String>.from(_customCategories);
            _processProductList(liveList);
            _isLoading = false;
            _saveToStorage(_products);
            if (_productsOrCategoriesChanged(
                oldProducts, _products, oldCustomCats, _customCategories)) {
              notifyListeners();
            }
          }
        },
        onError: (err) {
          debugPrint('ℹ️ Supabase stream note: $err');
        },
      );
      // Periodic fallback sync so any updates made in Manager Desktop auto-reflect
      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        refreshFromSupabase(silent: true);
      });
    } catch (e) {
      debugPrint('ℹ️ Supabase sync note: $e');
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  List<Product> filterProducts({String? category, String? query}) {
    final trimmedQuery = query?.trim().toLowerCase() ?? '';
    final hasQuery = trimmedQuery.isNotEmpty;

    if (!hasQuery) {
      if (category != null && category != 'All' && category != 'All Products') {
        if (category.toLowerCase() == 'uk used') {
          return _products
              .where((p) => p.condition.toLowerCase() == 'uk used')
              .toList();
        }
        return _products
            .where((p) => p.category.toLowerCase() == category.toLowerCase())
            .toList();
      }
      return List.from(_products);
    }

    final tokens = trimmedQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    List<String> getWords(String text) {
      return text
          .toLowerCase()
          .split(RegExp(r'[^a-z0-9]+'))
          .where((w) => w.isNotEmpty)
          .toList();
    }

    bool matchesToken(Product p, String token) {
      final nameWords = getWords(p.name);
      final brandWords = getWords(p.brand);

      // 1. Device name or Brand words start with the token (e.g. 'i' -> 'iPhone', 's' -> 'Samsung'/'Siaka', 'g' -> 'Google'/'Galaxy')
      if (brandWords.any((w) => w.startsWith(token)) ||
          nameWords.any((w) => w.startsWith(token))) {
        return true;
      }

      // 2. Direct substring in name or brand (e.g. '15', '24', 'pro', 'max', 'ultra', 'fold')
      if (p.name.toLowerCase().contains(token) ||
          p.brand.toLowerCase().contains(token)) {
        return true;
      }

      // 3. Category matching (requires at least 3 chars so 's' does not match all 'Smartphones')
      if (token.length >= 3 && p.category.toLowerCase().contains(token)) {
        return true;
      }

      // 4. Common device category synonyms
      final isPhone = p.category.toLowerCase().contains('smartphone') ||
          p.category.toLowerCase().contains('foldable') ||
          p.category.toLowerCase().contains('keypad');
      if (isPhone && (token == 'phone' || token == 'phones' || token == 'mobile')) {
        return true;
      }
      if (p.category.toLowerCase().contains('keypad') &&
          (token == 'keypad' || token == 'feature' || token == 'yam' || token == 'button')) {
        return true;
      }
      if (p.category.toLowerCase().contains('laptop') &&
          (token == 'laptop' || token == 'laptops' || token == 'macbook' || token == 'pc' || token == 'notebook' || token == 'computer')) {
        return true;
      }
      if (p.category.toLowerCase().contains('tablet') &&
          (token == 'tablet' || token == 'tablets' || token == 'ipad' || token == 'tab')) {
        return true;
      }
      if (p.category.toLowerCase().contains('wearable') && (token == 'watch' || token == 'watches')) {
        return true;
      }
      if (p.category.toLowerCase().contains('accessories') &&
          (token == 'buds' || token == 'airpods' || token == 'charger' || token == 'audio')) {
        return true;
      }

      // 5. For tokens of 3 or more characters, also check specs/colors/description
      if (token.length >= 3) {
        final colors = p.colors.map((c) => c.toLowerCase()).join(' ');
        final storage = p.storageOptions.map((s) => s.toLowerCase()).join(' ');
        final specs = p.specs.values.map((v) => v.toLowerCase()).join(' ');
        final desc = p.description.toLowerCase();
        final secondaryText = '$colors $storage $specs $desc';
        if (secondaryText.contains(token)) {
          return true;
        }
      }

      return false;
    }

    bool matchesAllTokens(Product p) {
      return tokens.every((t) => matchesToken(p, t));
    }

    final inCategory = _products.where((p) {
      if (category != null &&
          category != 'All' &&
          category != 'All Products') {
        if (category.toLowerCase() == 'uk used') {
          if (p.condition.toLowerCase() != 'uk used') return false;
        } else if (p.category.toLowerCase() != category.toLowerCase()) {
          return false;
        }
      }
      return matchesAllTokens(p);
    }).toList();

    if (inCategory.isNotEmpty ||
        category == null ||
        category == 'All' ||
        category == 'All Products') {
      return inCategory;
    }

    // Fallback across all products if no matches in active category
    return _products.where(matchesAllTokens).toList();
  }

  Future<List<Product>> getProducts({String? category, String? query}) async {
    return filterProducts(category: category, query: query);
  }

  Future<List<Product>> getFeaturedProducts() async {
    return _products.where((p) => p.isFeatured).toList();
  }

  Future<List<Product>> getNewArrivals() async {
    return _products.where((p) => p.isNewArrival).toList();
  }

  Future<Product?> getProductById(String id) async {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<String> get categories {
    final result = <String>['All', 'Smartphones'];
    // Insert custom categories right after Smartphones so newly added categories
    // (e.g. Drones, Cameras, Gaming) are instantly visible upfront in the pills!
    for (final cat in _customCategories) {
      if (cat.isNotEmpty && !result.any((c) => c.toLowerCase() == cat.toLowerCase())) {
        result.add(cat);
      }
    }
    for (final p in _products) {
      final cat = p.category.trim();
      if (cat.isNotEmpty &&
          cat.toLowerCase() != 'category' &&
          !result.any((c) => c.toLowerCase() == cat.toLowerCase())) {
        result.add(cat);
      }
    }
    for (final cat in defaultCategories.skip(1)) {
      if (!result.any((c) => c.toLowerCase() == cat.toLowerCase())) {
        result.add(cat);
      }
    }
    return result;
  }

  Future<List<String>> getCategories() async {
    return categories;
  }

  void addCategory(String category) {
    final clean = category.trim();
    if (clean.isNotEmpty) {
      _customCategories.add(clean);
      notifyListeners();
    }
  }
}
