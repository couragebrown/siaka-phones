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
  final bool isFeatured;
  final bool isNewArrival;
  final bool inStock;
  final int stockCount;

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
    this.isFeatured = false,
    this.isNewArrival = false,
    this.inStock = true,
    this.stockCount = 15,
  });

  double get discountPercent =>
      originalPrice > price ? ((originalPrice - price) / originalPrice * 100).roundToDouble() : 0.0;
}
