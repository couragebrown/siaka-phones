import 'package:flutter/foundation.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../domain/models/product.dart';

class HomeViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;

  HomeViewModel({required ProductRepository productRepository})
      : _productRepository = productRepository {
    _featuredProducts = _productRepository
        .filterProducts()
        .where((p) => p.isFeatured)
        .toList();
    _newArrivals = _productRepository
        .filterProducts()
        .where((p) => p.isNewArrival)
        .toList();
    _categories = [
      'All',
      'Smartphones',
      'Keypad Phones',
      'Laptops',
      'Accessories',
      'Tablets',
      'Foldables',
      'Wearables',
    ];
    _isLoading = false;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Product> _featuredProducts = [];
  List<Product> get featuredProducts => _featuredProducts;

  List<Product> _newArrivals = [];
  List<Product> get newArrivals => _newArrivals;

  List<String> _categories = [];
  List<String> get categories => _categories;

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  Future<void> loadData() async {
    if (_featuredProducts.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _featuredProducts = await _productRepository.getFeaturedProducts();
      _newArrivals = await _productRepository.getNewArrivals();
      _categories = await _productRepository.getCategories();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String category) {
    _selectedCategory = (category == 'All Products') ? 'All' : category;
    notifyListeners();
  }
}
