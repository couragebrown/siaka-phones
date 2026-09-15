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

  List<Product> _featuredProducts = [];
  List<Product> get featuredProducts => _featuredProducts;

  List<String> _categories = [];
  List<String> get categories => _categories;

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  int _searchRequestId = 0;

  Future<void> loadCatalog() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _productRepository.getCategories();
      _featuredProducts = await _productRepository.getFeaturedProducts();
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
    _filterProducts();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterProducts();
  }

  Future<void> _filterProducts() async {
    final currentRequestId = ++_searchRequestId;
    final results = await _productRepository.getProducts(
      category: _selectedCategory,
      query: _searchQuery,
    );

    // Only commit results if this is still the most recent query request
    if (currentRequestId == _searchRequestId) {
      _products = results;
      notifyListeners();
    }
  }
}
