import 'package:flutter/foundation.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../domain/models/product.dart';

class HomeViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;

  HomeViewModel({required ProductRepository productRepository})
      : _productRepository = productRepository;

  bool _isLoading = true;
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
    _isLoading = true;
    notifyListeners();

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
    _selectedCategory = category;
    notifyListeners();
  }
}
