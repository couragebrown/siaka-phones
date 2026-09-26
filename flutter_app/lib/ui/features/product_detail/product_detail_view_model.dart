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

  bool get isVideoSelected => _selectedImageIndex == 4;

  bool _isVideoPlaying = true;
  bool get isVideoPlaying => _isVideoPlaying;

  double _videoProgress = 0.32;
  double get videoProgress => _videoProgress;

  bool _isVideoMuted = false;
  bool get isVideoMuted => _isVideoMuted;

  void toggleVideoMute() {
    _isVideoMuted = !_isVideoMuted;
    notifyListeners();
  }

  void toggleVideoPlayback() {
    _isVideoPlaying = !_isVideoPlaying;
    notifyListeners();
  }

  void setVideoProgress(double value) {
    _videoProgress = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  List<String> get displayImages {
    final list = List<String>.from(product.images);
    if (list.isEmpty) {
      return const ['', '', '', ''];
    }
    if (list.length >= 4) {
      return list.sublist(0, 4);
    }
    final results = <String>[];
    for (int i = 0; i < 4; i++) {
      if (i < list.length) {
        results.add(list[i]);
      } else {
        final base = list[i % list.length];
        if (base.contains('unsplash.com')) {
          final separator = base.contains('?') ? '&' : '?';
          results.add('$base${separator}angle=${i + 1}');
        } else {
          results.add(base);
        }
      }
    }
    return results;
  }

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
    if (index == 4) {
      _isVideoPlaying = true;
    }
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
