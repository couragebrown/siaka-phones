import 'package:flutter/foundation.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../domain/models/product.dart';

class HomeViewModel extends ChangeNotifier {
  final ProductRepository _productRepository;

  HomeViewModel({required ProductRepository productRepository})
      : _productRepository = productRepository {
    _loadFromRepository();
    _isLoading = false;
    _productRepository.addListener(_onRepositoryChanged);
  }

  void _loadFromRepository() {
    _categories = _productRepository.categories;
    final all = _productRepository.filterProducts();
    _allProducts = all;
    final featured = all.where((p) => p.isFeatured).toList();
    _featuredProducts = featured.isNotEmpty ? featured : List.from(all);
    final arrivals = all.where((p) => p.isNewArrival).toList();
    _newArrivals = arrivals.isNotEmpty ? arrivals : List.from(all);
  }

  void _onRepositoryChanged() {
    _loadFromRepository();
    notifyListeners();
  }

  @override
  void dispose() {
    _productRepository.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Product> _allProducts = [];
  List<Product> get allProducts => _allProducts.isNotEmpty ? _allProducts : _productRepository.filterProducts();

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
      await _productRepository.refreshFromSupabase(silent: true);
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
