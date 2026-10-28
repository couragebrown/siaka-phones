import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/product.dart';
import '../services/supabase_service.dart';

class CartRepository extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _appliedPromoCode;
  double _discountPercent = 0.0;
  String? _currentCustomerId;
  bool isGuestMode = false;
  VoidCallback? onAuthRequired;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  String? get appliedPromoCode => _appliedPromoCode;
  String? get currentCustomerId => _currentCustomerId;

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get discountAmount => subtotal * _discountPercent;
  double get tax => 0.0;
  double get shipping => subtotal > 500 || _items.isEmpty ? 0.0 : 15.0;
  double get total => (subtotal - discountAmount) + shipping;

  Future<void> loadForCustomer(String customerId) async {
    if (customerId.isEmpty) return;
    _currentCustomerId = customerId;

    // 1. Immediately load local customer cache if present
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('customer_cart_$customerId');
      if (localJson != null && localJson.isNotEmpty) {
        final decoded = jsonDecode(localJson);
        if (decoded is List) {
          _items.clear();
          for (final raw in decoded) {
            if (raw is Map) {
              try {
                _items.add(CartItem.fromMap(Map<String, dynamic>.from(raw)));
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
      if (remoteData != null && remoteData['cart'] != null) {
        final rawCart = remoteData['cart'];
        if (rawCart is List && rawCart.isNotEmpty) {
          _items.clear();
          for (final raw in rawCart) {
            if (raw is Map) {
              try {
                _items.add(CartItem.fromMap(Map<String, dynamic>.from(raw)));
              } catch (_) {}
            }
          }
          await _saveToLocalCache();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToLocalCache({String? customerId, List<CartItem>? snapshot}) async {
    final targetId = customerId ?? _currentCustomerId;
    if (targetId == null || targetId.isEmpty) return;
    final list = snapshot ?? List<CartItem>.from(_items);
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = jsonEncode(list.map((i) => i.toMap()).toList());
      await prefs.setString('customer_cart_$targetId', serialized);
    } catch (_) {}
  }

  Future<void> _persistCart() async {
    final targetId = _currentCustomerId;
    if (targetId == null || targetId.isEmpty) return;
    final snapshot = List<CartItem>.from(_items);
    await _saveToLocalCache(customerId: targetId, snapshot: snapshot);
    final cartMaps = snapshot.map((i) => i.toMap()).toList();
    await SupabaseService().saveCustomerCartAndWishlist(
      customerId: targetId,
      cartItems: cartMaps,
      wishlistItems: const [],
    );
  }

  void addToCart(Product product, {String? color, String? storage, String? ram, int quantity = 1}) {
    if (isGuestMode) {
      onAuthRequired?.call();
      return;
    }

    final selColor = color ?? (product.colors.isNotEmpty ? product.colors.first : 'Natural Titanium');
    final selStorage = storage ?? (product.storageOptions.isNotEmpty ? product.storageOptions.first : '128 GB');
    final selRam = ram ?? (product.ramOptions.isNotEmpty ? product.ramOptions.first : '');

    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id &&
          item.selectedColor == selColor &&
          item.selectedStorage == selStorage &&
          item.selectedRam == selRam,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(
        CartItem(
          id: 'cart-${DateTime.now().millisecondsSinceEpoch}-${_items.length}',
          product: product,
          selectedColor: selColor,
          selectedStorage: selStorage,
          selectedRam: selRam,
          quantity: quantity,
        ),
      );
    }
    _persistCart();
    notifyListeners();
  }

  void updateQuantity(String itemId, int delta) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final newQty = _items[index].quantity + delta;
      if (newQty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQty;
      }
      _persistCart();
      notifyListeners();
    }
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    _persistCart();
    notifyListeners();
  }

  bool applyPromoCode(String code) {
    final clean = code.trim().toUpperCase();
    if (clean == 'SIAKA10') {
      _appliedPromoCode = 'SIAKA10';
      _discountPercent = 0.10;
      notifyListeners();
      return true;
    } else if (clean == 'VIP20') {
      _appliedPromoCode = 'VIP20';
      _discountPercent = 0.20;
      notifyListeners();
      return true;
    }
    return false;
  }

  void clearCart({bool isSignOut = false}) {
    _items.clear();
    _appliedPromoCode = null;
    _discountPercent = 0.0;
    if (isSignOut) {
      _currentCustomerId = null;
    } else {
      _persistCart();
    }
    notifyListeners();
  }
}
