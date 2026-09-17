import '../mock_data.dart';
import '../../domain/models/product.dart';

class ProductRepository {
  final List<Product> _products = List.from(MockData.products);

  List<Product> filterProducts({String? category, String? query}) {
    final trimmedQuery = query?.trim().toLowerCase() ?? '';
    final hasQuery = trimmedQuery.isNotEmpty;

    if (!hasQuery) {
      if (category != null && category != 'All' && category != 'All Products') {
        return _products
            .where((p) => p.category.toLowerCase() == category.toLowerCase())
            .toList();
      }
      return List.from(_products);
    }

    final tokens = trimmedQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    List<String> getWords(String text) {
      return text
          .toLowerCase()
          .split(RegExp(r'[^a-z0-9]+'))
          .where((w) => w.isNotEmpty)
          .toList();
    }

    bool matchesToken(Product p, String token) {
      final nameWords = getWords(p.name);
      final brandWords = getWords(p.brand);

      // 1. Device name or Brand words start with the token (e.g. 'i' -> 'iPhone', 's' -> 'Samsung'/'Siaka', 'g' -> 'Google'/'Galaxy')
      if (brandWords.any((w) => w.startsWith(token)) ||
          nameWords.any((w) => w.startsWith(token))) {
        return true;
      }

      // 2. Direct substring in name or brand (e.g. '15', '24', 'pro', 'max', 'ultra', 'fold')
      if (p.name.toLowerCase().contains(token) ||
          p.brand.toLowerCase().contains(token)) {
        return true;
      }

      // 3. Category matching (requires at least 3 chars so 's' does not match all 'Smartphones')
      if (token.length >= 3 && p.category.toLowerCase().contains(token)) {
        return true;
      }

      // 4. Common device category synonyms
      final isPhone = p.category.toLowerCase().contains('smartphone') ||
          p.category.toLowerCase().contains('foldable') ||
          p.category.toLowerCase().contains('keypad');
      if (isPhone && (token == 'phone' || token == 'phones' || token == 'mobile')) {
        return true;
      }
      if (p.category.toLowerCase().contains('keypad') &&
          (token == 'keypad' || token == 'feature' || token == 'yam' || token == 'button')) {
        return true;
      }
      if (p.category.toLowerCase().contains('laptop') &&
          (token == 'laptop' || token == 'laptops' || token == 'macbook' || token == 'pc' || token == 'notebook' || token == 'computer')) {
        return true;
      }
      if (p.category.toLowerCase().contains('tablet') &&
          (token == 'tablet' || token == 'tablets' || token == 'ipad' || token == 'tab')) {
        return true;
      }
      if (p.category.toLowerCase().contains('wearable') && (token == 'watch' || token == 'watches')) {
        return true;
      }
      if (p.category.toLowerCase().contains('accessories') &&
          (token == 'buds' || token == 'airpods' || token == 'charger' || token == 'audio')) {
        return true;
      }

      // 5. For tokens of 3 or more characters, also check specs/colors/description
      if (token.length >= 3) {
        final colors = p.colors.map((c) => c.toLowerCase()).join(' ');
        final storage = p.storageOptions.map((s) => s.toLowerCase()).join(' ');
        final specs = p.specs.values.map((v) => v.toLowerCase()).join(' ');
        final desc = p.description.toLowerCase();
        final secondaryText = '$colors $storage $specs $desc';
        if (secondaryText.contains(token)) {
          return true;
        }
      }

      return false;
    }

    bool matchesAllTokens(Product p) {
      return tokens.every((t) => matchesToken(p, t));
    }

    // Try within the active category pill first
    final inCategory = _products.where((p) {
      if (category != null &&
          category != 'All' &&
          category != 'All Products' &&
          p.category.toLowerCase() != category.toLowerCase()) {
        return false;
      }
      return matchesAllTokens(p);
    }).toList();

    if (inCategory.isNotEmpty ||
        category == null ||
        category == 'All' ||
        category == 'All Products') {
      return inCategory;
    }

    // Fallback across all products if no matches in active category
    return _products.where(matchesAllTokens).toList();
  }

  Future<List<Product>> getProducts({String? category, String? query}) async {
    return filterProducts(category: category, query: query);
  }

  Future<List<Product>> getFeaturedProducts() async {
    return _products.where((p) => p.isFeatured).toList();
  }

  Future<List<Product>> getNewArrivals() async {
    return _products.where((p) => p.isNewArrival).toList();
  }

  Future<Product?> getProductById(String id) async {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> getCategories() async {
    return [
      'All',
      'Smartphones',
      'Keypad Phones',
      'Laptops',
      'Accessories',
      'Tablets',
      'Foldables',
      'Wearables',
    ];
  }
}
