import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/product.dart';
import '../services/supabase_service.dart';

class WishlistRepository extends ChangeNotifier {
  final Map<String, Product> _items = {};
  String? _currentCustomerId;

  WishlistRepository({List<Product>? initialProducts}) {
    if (initialProducts != null) {
      for (final p in initialProducts) {
        _items[p.id] = p;
      }
    }
  }

  List<Product> get items => _items.values.toList();
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  String? get currentCustomerId => _currentCustomerId;

  bool isWishlisted(String productId) => _items.containsKey(productId);

  Future<void> loadForCustomer(String customerId) async {
    if (customerId.isEmpty) return;
    _currentCustomerId = customerId;

    // 1. Immediately load local customer cache if present
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('customer_wishlist_$customerId');
      if (localJson != null && localJson.isNotEmpty) {
        final decoded = jsonDecode(localJson);
        if (decoded is List) {
          _items.clear();
          for (final raw in decoded) {
            if (raw is Map) {
              try {
                final p = Product.fromMap(Map<String, dynamic>.from(raw));
                _items[p.id] = p;
              } catch (_) {}
            }
          }
          notifyListeners();
        }
      }
    } catch (_) {}

    // 2. Fetch from Database / Local PC Manager
    try {
      final remoteData = await SupabaseService().fetchCustomerCartAndWishlist(customerId);
      if (remoteData != null && remoteData['wishlist'] != null) {
        final rawWishlist = remoteData['wishlist'];
        if (rawWishlist is List && rawWishlist.isNotEmpty) {
          _items.clear();
          for (final raw in rawWishlist) {
            if (raw is Map) {
              try {
                final p = Product.fromMap(Map<String, dynamic>.from(raw));
                _items[p.id] = p;
              } catch (_) {}
            }
          }
          await _saveToLocalCache();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToLocalCache({String? customerId, List<Product>? snapshot}) async {
    final targetId = customerId ?? _currentCustomerId;
    if (targetId == null || targetId.isEmpty) return;
    final list = snapshot ?? _items.values.toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = jsonEncode(list.map((p) => p.toMap()).toList());
      await prefs.setString('customer_wishlist_$targetId', serialized);
    } catch (_) {}
  }

  Future<void> _persistWishlist() async {
    final targetId = _currentCustomerId;
    if (targetId == null || targetId.isEmpty) return;
    final snapshot = _items.values.toList();
    await _saveToLocalCache(customerId: targetId, snapshot: snapshot);
    final wishlistMaps = snapshot.map((p) => p.toMap()).toList();
    await SupabaseService().saveCustomerCartAndWishlist(
      customerId: targetId,
      cartItems: const [],
      wishlistItems: wishlistMaps,
    );
  }

  bool toggleWishlist(Product product) {
    final bool willAdd = !_items.containsKey(product.id);
    if (willAdd) {
      _items[product.id] = product;
    } else {
      _items.remove(product.id);
    }
    _persistWishlist();
    notifyListeners();
    return willAdd;
  }

  void addToWishlist(Product product) {
    _items[product.id] = product;
    _persistWishlist();
    notifyListeners();
  }

  void removeFromWishlist(String productId) {
    if (_items.remove(productId) != null) {
      _persistWishlist();
      notifyListeners();
    }
  }

  void clearWishlist({bool isSignOut = false}) {
    _items.clear();
    if (isSignOut) {
      _currentCustomerId = null;
    } else {
      _persistWishlist();
    }
    notifyListeners();
  }
}
