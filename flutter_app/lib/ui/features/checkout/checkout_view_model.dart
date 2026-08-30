import 'package:flutter/foundation.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../domain/models/order.dart';

class CheckoutViewModel extends ChangeNotifier {
  final CartRepository _cartRepository;
  final OrderRepository _orderRepository;

  CheckoutViewModel({
    required CartRepository cartRepository,
    required OrderRepository orderRepository,
  })  : _cartRepository = cartRepository,
        _orderRepository = orderRepository;

  String _fullName = 'Courage Brown';
  String _address = '742 Evergreen Terrace';
  String _city = 'Springfield';
  String _zip = '97477';
  String _phone = '+1 (555) 839-2041';
  String _selectedPaymentMethod = 'Siaka Apple Pay';
  bool _isPlacingOrder = false;

  String get fullName => _fullName;
  String get address => _address;
  String get city => _city;
  String get zip => _zip;
  String get phone => _phone;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  bool get isPlacingOrder => _isPlacingOrder;

  double get subtotal => _cartRepository.subtotal;
  double get tax => _cartRepository.tax;
  double get shipping => _cartRepository.shipping;
  double get total => _cartRepository.total;
  int get itemCount => _cartRepository.itemCount;

  void updateShippingInfo({
    String? fullName,
    String? address,
    String? city,
    String? zip,
    String? phone,
  }) {
    if (fullName != null) _fullName = fullName;
    if (address != null) _address = address;
    if (city != null) _city = city;
    if (zip != null) _zip = zip;
    if (phone != null) _phone = phone;
    notifyListeners();
  }

  void selectPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  Future<OrderModel?> placeOrder() async {
    if (_cartRepository.items.isEmpty) return null;

    _isPlacingOrder = true;
    notifyListeners();

    try {
      final order = await _orderRepository.placeOrder(
        items: _cartRepository.items,
        subtotal: subtotal,
        tax: tax,
        shippingFee: shipping,
        totalAmount: total,
        shippingAddress: '$_address, $_city, $_zip',
        paymentMethod: _selectedPaymentMethod,
      );

      _cartRepository.clearCart();
      return order;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }
}
