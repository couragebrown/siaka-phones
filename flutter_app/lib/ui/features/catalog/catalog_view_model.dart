import 'package:flutter/foundation.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../domain/models/product.dart';

class CatalogViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;

  CatalogViewModel({required ProductRepository productRepository})
      : _productRepository = productRepository;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Product> _products = [];
  List<Product> get products => _products;

  List<String> _categories = [];
  List<String> get categories => _categories;

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Future<void> loadCatalog() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _productRepository.getCategories();
      _products = await _productRepository.getProducts(
        category: _selectedCategory,
        query: _searchQuery,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    loadCatalog();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadCatalog();
  }
}
