import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final String selectedColor;
  final String selectedStorage;
  int quantity;

  CartItem({
    required this.id,
    required this.product,
    required this.selectedColor,
    required this.selectedStorage,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}
