import 'dart:typed_data';

class ManagerProduct {
  final String id;
  String name;
  String brand;
  String category;
  double price; // Wholesale Price (Shop selling rate)
  double originalPrice; // Retail Price (MSRP)
  int stock;
  String specs;
  String storage;
  List<String> storages;
  String ram;
  List<String> rams;
  String color;
  List<String> colors;
  bool isFeatured;
  String condition;
  String imageUrl;
  Uint8List? imageBytes;
  List<String> specsList;
  DateTime? createdAt;

  ManagerProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.originalPrice,
    required this.stock,
    required this.specs,
    this.storage = '128GB',
    List<String>? storages,
    this.ram = '8GB',
    List<String>? rams,
    this.color = 'Natural Titanium',
    List<String>? colors,
    this.isFeatured = false,
    this.condition = 'New',
    this.imageUrl = '',
    this.imageBytes,
    List<String>? specsList,
    this.createdAt,
  }) : storages = storages ?? _parseMultiValue(storage, '128GB'),
       rams = rams ?? _parseMultiValue(ram, '8GB'),
       colors = colors ?? (color.isNotEmpty ? [color] : ['Natural Titanium']),
       specsList = specsList ?? _parseSpecs(specs);

  // Convenient pricing aliases matching Siaka Phones B2B terminology
  double get wholesalePrice => price;
  set wholesalePrice(double val) => price = val;

  double get retailPrice => originalPrice;
  set retailPrice(double val) => originalPrice = val;

  // Margin calculation between retail MSRP and wholesale selling price
  double get savingsAmount => (originalPrice > price) ? (originalPrice - price) : 0.0;
  double get marginPercentage => (originalPrice > 0) ? ((originalPrice - price) / originalPrice) * 100 : 0.0;

  bool get inStock => stock > 0;
  bool get lowStock => stock > 0 && stock <= 5;

  bool get isMerchandise {
    if (id.startsWith('CAT_') ||
        id.startsWith('ORDER_') ||
        id.startsWith('BNPL_') ||
        id.startsWith('REPAIR_') ||
        id.startsWith('SWAP_') ||
        id.startsWith('SP-') ||
        id.startsWith('TRK-') ||
        id.startsWith('BANNER_') ||
        id.startsWith('BANNER_PLAYLIST_') ||
        name.toLowerCase().contains('homepage banner') ||
        name.toLowerCase().contains('search banner') ||
        name.toLowerCase().startsWith('banner') ||
        brand.toLowerCase() == 'home' ||
        brand.toLowerCase() == 'search') {
      return false;
    }
    final catUpper = category.trim().toUpperCase();
    if (catUpper == 'ORDER_RECORD' ||
        catUpper == 'BNPL_RECORD' ||
        catUpper == 'REPAIR_RECORD' ||
        catUpper == 'SWAP_RECORD' ||
        catUpper == 'CATEGORY' ||
        catUpper == 'BANNER_PLAYLIST' ||
        catUpper.startsWith('BANNER_') ||
        catUpper.startsWith('ORDER_') ||
        catUpper.startsWith('BNPL_') ||
        catUpper.startsWith('REPAIR_') ||
        catUpper.contains('BANNER')) {
      return false;
    }
    return true;
  }

  static List<String> _parseSpecs(String specsStr) {
    if (specsStr.trim().isEmpty) return [];
    if (specsStr.contains(' • ')) {
      return specsStr.split(' • ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    if (specsStr.contains('\n')) {
      return specsStr.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [specsStr.trim()];
  }

  static List<String> _parseMultiValue(String raw, String fallback) {
    if (raw.trim().isEmpty) return [fallback];
    final parts = raw.split(RegExp(r'[,/•|]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts : [fallback];
  }
}
