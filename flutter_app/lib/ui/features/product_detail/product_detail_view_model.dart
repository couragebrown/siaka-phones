import 'package:flutter/foundation.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../domain/models/product.dart';

class ProductDetailViewModel extends ChangeNotifier {
  final Product product;
  final CartRepository _cartRepository;

  ProductDetailViewModel({
    required this.product,
    required CartRepository cartRepository,
  })  : _cartRepository = cartRepository,
        _selectedColor = product.colors.first,
        _selectedStorage = product.storageOptions.first;

  int _selectedImageIndex = 0;
  int get selectedImageIndex => _selectedImageIndex;

  String _selectedColor;
  String get selectedColor => _selectedColor;

  String _selectedStorage;
  String get selectedStorage => _selectedStorage;

  int _quantity = 1;
  int get quantity => _quantity;

  int get cartItemCount => _cartRepository.itemCount;

  bool _isAddedSuccess = false;
  bool get isAddedSuccess => _isAddedSuccess;

  void selectImage(int index) {
    _selectedImageIndex = index;
    notifyListeners();
  }

  void selectColor(String color) {
    _selectedColor = color;
    notifyListeners();
  }

  void selectStorage(String storage) {
    _selectedStorage = storage;
    notifyListeners();
  }

  void updateQuantity(int delta) {
    final next = _quantity + delta;
    if (next >= 1 && next <= product.stockCount) {
      _quantity = next;
      notifyListeners();
    }
  }

  void addToCart() {
    _cartRepository.addToCart(
      product,
      color: _selectedColor,
      storage: _selectedStorage,
      quantity: _quantity,
    );
    _isAddedSuccess = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 2), () {
      _isAddedSuccess = false;
      notifyListeners();
    });
  }
}
