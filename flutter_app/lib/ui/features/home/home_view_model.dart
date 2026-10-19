import 'package:flutter/foundation.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/banner_playlist.dart';

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
    final all = _productRepository.filterProducts().where((p) => p.isMerchandise).toList();
    _allProducts = all;
    final featured = all.where((p) => p.isFeatured && p.isMerchandise).toList();
    _featuredProducts = featured.isNotEmpty ? featured : all;
    final arrivals = all.where((p) => p.isNewArrival && p.isMerchandise).toList();
    _newArrivals = arrivals.isNotEmpty ? arrivals : all;
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
  List<Product> get allProducts => _allProducts.isNotEmpty ? _allProducts : _productRepository.filterProducts().where((p) => p.isMerchandise).toList();

  List<Product> _featuredProducts = [];
  List<Product> get featuredProducts => _featuredProducts.where((p) => p.isMerchandise).toList();

  List<Product> _newArrivals = [];
  List<Product> get newArrivals => _newArrivals.where((p) => p.isMerchandise).toList();

  List<String> _categories = [];
  List<String> get categories => _categories;

  List<BannerPlaylist> get bannerPlaylists => _productRepository.bannerPlaylists;
  BannerPlaylist? getBannerPlaylist(String id) => _productRepository.getBannerPlaylist(id);

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  Future<void> loadData() async {
    if (_featuredProducts.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      await _productRepository.refreshFromSupabase(silent: true);
      _loadFromRepository();
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
