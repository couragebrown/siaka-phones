import 'package:flutter/foundation.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../domain/models/cart_item.dart';

class CartViewModel extends ChangeNotifier {
  final CartRepository _cartRepository;

  CartViewModel({required CartRepository cartRepository})
      : _cartRepository = cartRepository {
    _cartRepository.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cartRepository.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    notifyListeners();
  }

  List<CartItem> get items => _cartRepository.items;
  int get itemCount => _cartRepository.itemCount;
  String? get appliedPromoCode => _cartRepository.appliedPromoCode;

  double get subtotal => _cartRepository.subtotal;
  double get discountAmount => _cartRepository.discountAmount;
  double get tax => _cartRepository.tax;
  double get shipping => _cartRepository.shipping;
  double get total => _cartRepository.total;

  void updateQuantity(String itemId, int delta) {
    _cartRepository.updateQuantity(itemId, delta);
  }

  void removeItem(String itemId) {
    _cartRepository.removeItem(itemId);
  }

  bool applyPromo(String code) {
    return _cartRepository.applyPromoCode(code);
  }
}
