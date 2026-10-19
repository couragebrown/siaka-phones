import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mock_data.dart';
import '../../domain/models/product.dart';
import '../../domain/models/banner_playlist.dart';
import '../services/supabase_service.dart';

class ProductRepository with ChangeNotifier {
  List<Product> _products = [];
  List<BannerPlaylist> _bannerPlaylists = [];
  final Set<String> _customCategories = {};
  final SupabaseService _supabase = SupabaseService();
  Timer? _syncTimer;
  StreamSubscription<void>? _pushSub;
  bool _resyncPending = false;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<BannerPlaylist> get bannerPlaylists => List.unmodifiable(_bannerPlaylists);

  BannerPlaylist? getBannerPlaylist(String id) {
    return _bannerPlaylists.cast<BannerPlaylist?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
  }

  ProductRepository() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _products = List.from(MockData.products);
      _bannerPlaylists = MockData.getInitialBannerPlaylists();
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
      if (_products.isEmpty) {
        _processProductList(List.from(MockData.products));
        _saveToStorage(_products);
        notifyListeners();
      }
      final cachedBannersJson = prefs.getString('cached_banner_playlists_v1');
      if (cachedBannersJson != null && cachedBannersJson.trim().isNotEmpty) {
        final bList = jsonDecode(cachedBannersJson) as List;
        _bannerPlaylists = bList
            .map((item) => BannerPlaylist.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      if (_bannerPlaylists.isEmpty) {
        _bannerPlaylists = MockData.getInitialBannerPlaylists();
      }
    } catch (e) {
      debugPrint('ℹ️ Cache load note: $e');
    }
    _initSupabaseSync();
  }

  Future<void> _saveToStorage(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = products.where((p) => p.isMerchandise).map((p) => p.toMap()).toList();
      await prefs.setString('cached_products_v1', jsonEncode(data));
      if (_bannerPlaylists.isNotEmpty) {
        final plData = _bannerPlaylists.map((p) => p.toJson()).toList();
        await prefs.setString('cached_banner_playlists_v1', jsonEncode(plData));
      }
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
    final freshCats = <String>{};
    for (final p in list) {
      if (p.id.startsWith('CAT_')) {
        final catName = p.name.trim().isNotEmpty ? p.name.trim() : p.category.trim();
        if (catName.isNotEmpty && catName.toLowerCase() != 'category') {
          freshCats.add(catName);
        }
      } else if (p.isMerchandise) {
        final cat = p.category.trim();
        if (cat.isNotEmpty &&
            cat.toLowerCase() != 'category' &&
            !defaultCategories.any((b) => b.toLowerCase() == cat.toLowerCase())) {
          freshCats.add(cat);
        }
      }
    }
    _customCategories
      ..clear()
      ..addAll(freshCats);
    final bannerProducts = list.where((p) =>
        p.id.startsWith('BANNER_PLAYLIST_') ||
        p.category.toUpperCase() == 'BANNER_PLAYLIST').toList();
    if (bannerProducts.isNotEmpty) {
      for (final bp in bannerProducts) {
        try {
          if (bp.condition.isNotEmpty && bp.condition.startsWith('{')) {
            final map = jsonDecode(bp.condition) as Map<String, dynamic>;
            final pl = BannerPlaylist.fromJson(map);
            final idx = _bannerPlaylists.indexWhere((x) => x.id == pl.id);
            if (idx != -1) {
              _bannerPlaylists[idx] = pl;
            } else {
              _bannerPlaylists.add(pl);
            }
          }
        } catch (e) {
          debugPrint('Error decoding banner playlist on mobile: $e');
        }
      }
    }
    if (_bannerPlaylists.isEmpty) {
      _bannerPlaylists = MockData.getInitialBannerPlaylists();
    }

    final seenIds = <String>{};
    final uniqueProducts = <Product>[];
    for (final p in list) {
      if (p.isMerchandise && !p.id.startsWith('prod_sort_') && !p.id.startsWith('test_')) {
        if (seenIds.add(p.id)) {
          uniqueProducts.add(p);
        }
      }
    }
    _products = uniqueProducts;
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
    // Check ordering (e.g. newly created SKU placed at top)
    for (int i = 0; i < oldProducts.length; i++) {
      if (oldProducts[i].id != newProducts[i].id) return true;
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
          p1.isNewArrival != p2.isNewArrival ||
          p1.stockCount != p2.stockCount ||
          p1.inStock != p2.inStock ||
          p1.condition != p2.condition ||
          p1.description != p2.description ||
          p1.images.length != p2.images.length ||
          p1.colors.length != p2.colors.length ||
          p1.storageOptions.length != p2.storageOptions.length ||
          p1.highlights.length != p2.highlights.length) {
        return true;
      }
      for (int i = 0; i < p2.images.length; i++) {
        if (p1.images[i] != p2.images[i]) return true;
      }
      for (int i = 0; i < p2.colors.length; i++) {
        if (p1.colors[i] != p2.colors[i]) return true;
      }
      for (int i = 0; i < p2.storageOptions.length; i++) {
        if (p1.storageOptions[i] != p2.storageOptions[i]) return true;
      }
    }
    return false;
  }

  bool _bannerPlaylistsChanged(List<BannerPlaylist> oldP, List<BannerPlaylist> newP) {
    if (oldP.length != newP.length) return true;
    for (int i = 0; i < newP.length; i++) {
      final p1 = oldP[i];
      final p2 = newP[i];
      if (p1.id != p2.id ||
          p1.isActive != p2.isActive ||
          p1.images.length != p2.images.length ||
          p1.videos.length != p2.videos.length) {
        return true;
      }
      for (int j = 0; j < p2.images.length; j++) {
        if (p1.images[j].id != p2.images[j].id ||
            p1.images[j].imageUrl != p2.images[j].imageUrl ||
            p1.images[j].isActive != p2.images[j].isActive) {
          return true;
        }
      }
      for (int j = 0; j < p2.videos.length; j++) {
        if (p1.videos[j].id != p2.videos[j].id ||
            p1.videos[j].videoUrl != p2.videos[j].videoUrl ||
            p1.videos[j].isActive != p2.videos[j].isActive) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isSyncing = false;

  Future<void> refreshFromSupabase({bool silent = false}) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (_isSyncing) {
      // A change arrived mid-refresh: run once more right after so it is never missed.
      _resyncPending = true;
      return;
    }
    _isSyncing = true;
    try {
      if (!_supabase.isInitialized) {
        await _supabase.initialize();
      }

      // 1. High-speed unified sync round-trip (products + banners in one fast call)
      final fullSync = await _supabase.fetchFullSyncState();
      List<Product>? remote = fullSync.products;
      List<BannerPlaylist>? remoteBanners = fullSync.banners;

      // 2. Fallback to individual parallel fetches if unified sync was unavailable
      if (remote == null || remoteBanners == null) {
        final results = await Future.wait([
          if (remote == null) _supabase.fetchProducts() else Future.value(remote),
          if (remoteBanners == null) _supabase.fetchBannerPlaylists() else Future.value(remoteBanners),
        ]);
        remote = results[0] as List<Product>?;
        remoteBanners = results[1] as List<BannerPlaylist>?;
      }

      bool changed = false;
      final oldProducts = List<Product>.from(_products);
      final oldCustomCats = Set<String>.from(_customCategories);
      final oldBanners = List<BannerPlaylist>.from(_bannerPlaylists);

      if (remote != null && remote.isNotEmpty) {
        _processProductList(remote);
        if (!silent || _productsOrCategoriesChanged(oldProducts, _products, oldCustomCats, _customCategories)) {
          changed = true;
        }
      }

      if (remoteBanners != null && remoteBanners.isNotEmpty) {
        _bannerPlaylists = remoteBanners;
        if (!silent || _bannerPlaylistsChanged(oldBanners, _bannerPlaylists)) {
          changed = true;
        }
      }

      if (changed) {
        _isLoading = false;
        _saveToStorage(_products);
        notifyListeners();
      }
    } catch (e) {
      if (!silent) {
        debugPrint('ℹ️ Sync note: $e');
      }
    } finally {
      _isLoading = false;
      _isSyncing = false;
      if (_resyncPending) {
        _resyncPending = false;
        unawaited(refreshFromSupabase(silent: true));
      }
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
            final oldBanners = List<BannerPlaylist>.from(_bannerPlaylists);
            _processProductList(liveList);
            _isLoading = false;
            _saveToStorage(_products);
            if (_bannerPlaylistsChanged(oldBanners, _bannerPlaylists) ||
                _productsOrCategoriesChanged(
                    oldProducts, _products, oldCustomCats, _customCategories)) {
              notifyListeners();
            }
          }
        },
        onError: (err) {
          debugPrint('ℹ️ Supabase stream note: $err');
        },
      );
      // Instant push: the PC Manager app announces every inventory change over a live
      // connection, so adds/edits/deletes appear on the phone immediately.
      _pushSub?.cancel();
      _pushSub = _supabase.localChangeEvents().listen((_) {
        refreshFromSupabase(silent: true);
      });
      // Safety-net poll in case the live connection drops (e.g. PC app restarted).
      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (!_isSyncing && !SupabaseService.isQuotaRestricted) {
          refreshFromSupabase(silent: true);
        }
      });
    } catch (e) {
      debugPrint('ℹ️ Supabase sync note: $e');
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _pushSub?.cancel();
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
