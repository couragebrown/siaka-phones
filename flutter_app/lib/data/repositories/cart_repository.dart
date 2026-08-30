import 'package:flutter/foundation.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/product.dart';

class CartRepository extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _appliedPromoCode;
  double _discountPercent = 0.0;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  String? get appliedPromoCode => _appliedPromoCode;

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get discountAmount => subtotal * _discountPercent;
  double get tax => (subtotal - discountAmount) * 0.0825;
  double get shipping => subtotal > 500 || _items.isEmpty ? 0.0 : 15.0;
  double get total => (subtotal - discountAmount) + tax + shipping;

  void addToCart(Product product, {String? color, String? storage, int quantity = 1}) {
    final selColor = color ?? product.colors.first;
    final selStorage = storage ?? product.storageOptions.first;

    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id &&
          item.selectedColor == selColor &&
          item.selectedStorage == selStorage,
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
          quantity: quantity,
        ),
      );
    }
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
      notifyListeners();
    }
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
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

  void clearCart() {
    _items.clear();
    _appliedPromoCode = null;
    _discountPercent = 0.0;
    notifyListeners();
  }
}
