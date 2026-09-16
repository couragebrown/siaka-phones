import 'package:flutter/foundation.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/mock_data.dart';
import '../../../domain/models/cart_item.dart';
import '../../../domain/models/order.dart';

class CheckoutViewModel extends ChangeNotifier {
  final CartRepository _cartRepository;
  final OrderRepository _orderRepository;
  final UserRepository? _userRepository;

  CheckoutViewModel({
    required CartRepository cartRepository,
    required OrderRepository orderRepository,
    UserRepository? userRepository,
  })  : _cartRepository = cartRepository,
        _orderRepository = orderRepository,
        _userRepository = userRepository {
    final p = userRepository?.profile ?? MockData.profile;
    _fullName = p.name;
    _address = p.detailAddress;
    _city = p.region;
    _zip = p.gpsCode;
    _phone = p.phone;
  }

  UserRepository? get userRepository => _userRepository;

  late String _fullName;
  late String _address;
  late String _city;
  late String _zip;
  late String _phone;
  String _selectedPaymentMethod = 'MTN Mobile Money';
  String _selectedShippingMethod = 'Standard Express (2–4 days)';
  double? _customShippingFee;
  bool _isPlacingOrder = false;

  String get fullName => _fullName;
  String get address => _address;
  String get city => _city;
  String get zip => _zip;
  String get phone => _phone;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  String get selectedShippingMethod => _selectedShippingMethod;
  bool get isPlacingOrder => _isPlacingOrder;

  List<CartItem> get items => _cartRepository.items;
  double get subtotal => _cartRepository.subtotal;
  double get discountAmount => _cartRepository.discountAmount;
  String? get appliedPromoCode => _cartRepository.appliedPromoCode;
  double get shipping => _customShippingFee ?? _cartRepository.shipping;
  double get tax => (subtotal - discountAmount) * 0.0825;
  double get total => (subtotal - discountAmount) + tax + shipping;
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

  void selectShippingMethod(String method, double fee) {
    _selectedShippingMethod = method;
    _customShippingFee = fee;
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
        shippingAddress: '$_address, $_city • $_zip',
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
