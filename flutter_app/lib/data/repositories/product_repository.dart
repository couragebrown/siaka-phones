import '../mock_data.dart';
import '../../domain/models/product.dart';

class ProductRepository {
  final List<Product> _products = List.from(MockData.products);

  Future<List<Product>> getProducts({String? category, String? query}) async {
    final trimmedQuery = query?.trim().toLowerCase() ?? '';
    final hasQuery = trimmedQuery.isNotEmpty;

    if (!hasQuery) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    final tokens = hasQuery
        ? trimmedQuery
            .split(RegExp(r'\s+'))
            .where((t) => t.isNotEmpty)
            .toList()
        : <String>[];

    bool matchesProduct(Product p) {
      if (!hasQuery) return true;

      final name = p.name.toLowerCase();
      final brand = p.brand.toLowerCase();
      final cat = p.category.toLowerCase();
      final desc = p.description.toLowerCase();
      final colors = p.colors.map((c) => c.toLowerCase()).join(' ');
      final storage = p.storageOptions.map((s) => s.toLowerCase()).join(' ');
      final specs = p.specs.values.map((v) => v.toLowerCase()).join(' ');
      final isPhone = cat.contains('smartphone') || cat.contains('foldable');
      final synonyms = isPhone ? 'phone phones mobile device flagship' : 'device gadget accessory';

      final fullSearchText =
          '$name $brand $cat $desc $colors $storage $specs $synonyms';

      return tokens.every((token) => fullSearchText.contains(token));
    }

    final categoryFiltered = _products.where((p) {
      if (category != null &&
          category != 'All' &&
          p.category.toLowerCase() != category.toLowerCase()) {
        return false;
      }
      return matchesProduct(p);
    }).toList();

    // If matches found in the selected category, or no category was specified, return them
    if (categoryFiltered.isNotEmpty || !hasQuery || category == null || category == 'All') {
      return categoryFiltered;
    }

    // Fallback: if query didn't match within the active category pill, search across all categories
    return _products.where(matchesProduct).toList();
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
