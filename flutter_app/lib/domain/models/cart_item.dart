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
}
