import '../mock_data.dart';
import '../../domain/models/product.dart';

class ProductRepository {
  List<Product> _products = List.from(MockData.products);

  Future<List<Product>> getProducts({String? category, String? query}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _products.where((p) {
      if (category != null && category != 'All' && p.category.toLowerCase() != category.toLowerCase()) {
        return false;
      }
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  Future<List<Product>> getFeaturedProducts() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _products.where((p) => p.isFeatured).toList();
  }

  Future<List<Product>> getNewArrivals() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _products.where((p) => p.isNewArrival).toList();
  }

  Future<Product?> getProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> getCategories() async {
    return ['All', 'Smartphones', 'Foldables', 'Wearables', 'Accessories'];
  }
}
