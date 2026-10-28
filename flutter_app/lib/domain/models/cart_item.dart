import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final String selectedColor;
  final String selectedStorage;
  final String selectedRam;
  int quantity;

  CartItem({
    required this.id,
    required this.product,
    required this.selectedColor,
    required this.selectedStorage,
    this.selectedRam = '',
    this.quantity = 1,
  });

  String get specsDescription {
    final parts = <String>[];
    if (selectedStorage.isNotEmpty) parts.add(selectedStorage);
    if (selectedRam.isNotEmpty) parts.add(selectedRam);
    if (selectedColor.isNotEmpty) parts.add(selectedColor);
    return parts.join(' • ');
  }

  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product': product.toMap(),
      'selectedColor': selectedColor,
      'selectedStorage': selectedStorage,
      'selectedRam': selectedRam,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id']?.toString() ?? '',
      product: Product.fromMap(
        map['product'] is Map<String, dynamic>
            ? map['product'] as Map<String, dynamic>
            : (map['product'] is Map ? Map<String, dynamic>.from(map['product'] as Map) : {}),
      ),
      selectedColor: map['selectedColor']?.toString() ?? '',
      selectedStorage: map['selectedStorage']?.toString() ?? '',
      selectedRam: map['selectedRam']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
