class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final double originalPrice;
  final double rating;
  final int reviewCount;
  final String description;
  final List<String> images;
  final List<String> colors;
  final List<String> storageOptions;
  final Map<String, String> specs;
  final List<String> highlights;
  final bool isFeatured;
  final bool isNewArrival;
  final bool inStock;
  final int stockCount;
  final String condition;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.reviewCount,
    required this.description,
    required this.images,
    required this.colors,
    required this.storageOptions,
    required this.specs,
    this.highlights = const [],
    this.isFeatured = false,
    this.isNewArrival = false,
    this.inStock = true,
    this.stockCount = 15,
    this.condition = 'New',
  });

  List<String> get effectiveHighlights {
    if (highlights.isNotEmpty) {
      return highlights;
    }
    if (specs.isNotEmpty) {
      return specs.values.where((s) => s.trim().isNotEmpty).toList();
    }
    return const [
      'Super Retina XDR OLED display with ProMotion 120Hz',
      'Next-generation flagship processor with high efficiency',
      'Pro camera system with advanced night mode & 4K HDR',
      'All-day battery life with fast charging',
      '5G ultra-wideband connectivity & Dual SIM',
    ];
  }

  double get discountPercent =>
      originalPrice > price ? ((originalPrice - price) / originalPrice * 100).roundToDouble() : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'price': price,
      'original_price': originalPrice,
      'rating': rating,
      'review_count': reviewCount,
      'description': description,
      'images': images,
      'colors': colors,
      'storage_options': storageOptions,
      'specs': specs,
      'highlights': highlights,
      'is_featured': isFeatured,
      'is_new_arrival': isNewArrival,
      'in_stock': inStock,
      'stock_count': stockCount,
      'condition': condition,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    List<String> parsedColors = [];
    if (map['colors'] != null && map['colors'] is List) {
      parsedColors = (map['colors'] as List).map((c) => c.toString()).toList();
    } else if (map['color'] != null) {
      parsedColors = [map['color'].toString()];
    }
    if (parsedColors.isEmpty) {
      parsedColors = ['Natural Titanium'];
    }

    List<String> images = [];
    if (map['images'] != null && map['images'] is List && (map['images'] as List).isNotEmpty) {
      images = (map['images'] as List).map((i) => i.toString()).toList();
    } else if (map['image_url'] != null && map['image_url'].toString().trim().isNotEmpty) {
      images = [map['image_url'].toString().trim()];
    }

    List<String> storageOptions = [];
    if (map['storage_options'] != null && map['storage_options'] is List) {
      storageOptions = (map['storage_options'] as List).map((s) => s.toString()).toList();
    } else if (map['storage'] != null) {
      storageOptions = [map['storage'].toString()];
    }

    Map<String, String> specs = {};
    if (map['specs'] is Map) {
      specs = (map['specs'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
    } else if (map['specs'] is String && map['specs'].toString().trim().isNotEmpty) {
      specs = {'Details': map['specs'].toString()};
    }

    List<String> highlights = [];
    if (map['highlights'] != null && map['highlights'] is List) {
      highlights = (map['highlights'] as List).map((h) => h.toString()).toList();
    }

    return Product(
      id: map['id']?.toString() ?? 'prod_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name']?.toString() ?? 'Unnamed Device',
      brand: map['brand']?.toString() ?? 'Siaka Phones',
      category: map['category']?.toString() ?? 'Smartphones',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      originalPrice: double.tryParse(map['original_price']?.toString() ?? '0') ?? 0.0,
      rating: double.tryParse(map['rating']?.toString() ?? '4.8') ?? 4.8,
      reviewCount: int.tryParse(map['review_count']?.toString() ?? '42') ?? 42,
      description: map['description']?.toString() ?? '',
      images: images,
      colors: parsedColors,
      storageOptions: storageOptions,
      specs: specs,
      highlights: highlights,
      isFeatured: map['is_featured'] == true || map['is_featured']?.toString() == 'true',
      isNewArrival: map['is_new_arrival'] == true || map['is_new_arrival']?.toString() == 'true',
      inStock: map['in_stock'] != false && map['in_stock']?.toString() != 'false',
      stockCount: int.tryParse(map['stock_count']?.toString() ?? map['stock']?.toString() ?? '15') ?? 15,
      condition: map['condition']?.toString() ?? 'New',
    );
  }
}
