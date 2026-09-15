import 'package:flutter/foundation.dart';
import '../../domain/models/product.dart';

class WishlistRepository extends ChangeNotifier {
  final Map<String, Product> _items = {};

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

  bool isWishlisted(String productId) => _items.containsKey(productId);

  bool toggleWishlist(Product product) {
    final bool willAdd = !_items.containsKey(product.id);
    if (willAdd) {
      _items[product.id] = product;
    } else {
      _items.remove(product.id);
    }
    notifyListeners();
    return willAdd;
  }

  void addToWishlist(Product product) {
    _items[product.id] = product;
    notifyListeners();
  }

  void removeFromWishlist(String productId) {
    if (_items.remove(productId) != null) {
      notifyListeners();
    }
  }

  void clearWishlist() {
    _items.clear();
    notifyListeners();
  }
}
