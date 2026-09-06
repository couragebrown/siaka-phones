import 'package:flutter/material.dart';
import '../../../domain/models/cart_item.dart';
import 'cart_view_model.dart';

class CartView extends StatefulWidget {
  final CartViewModel viewModel;
  final VoidCallback onCheckout;
  final VoidCallback onBrowseCatalog;

  const CartView({
    super.key,
    required this.viewModel,
    required this.onCheckout,
    required this.onBrowseCatalog,
  });

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final items = widget.viewModel.items;

        final cartTitle = items.isEmpty
            ? 'My Cart'
            : 'My Cart (${items.length} ${items.length == 1 ? 'Item' : 'Items'})';

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F4F6),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF1F2937)),
                  onPressed: widget.onBrowseCatalog,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      cartTitle,
                      style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const Text('Edit',
                    style: TextStyle(
                        color: Color(0xFF1C7BFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
              ],
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final content = items.isEmpty
                  ? SizedBox(
                      height: constraints.maxHeight - 80,
                      child: const Center(
                        child: Text('Cart is empty'),
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4F5EC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.local_shipping_outlined,
                                  color: Color(0xFF1C7BFF)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'You are ₵13 away from free shipping!',
                                  style: TextStyle(
                                      color: Color(0xFF1F2937),
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text('₵13 left',
                                  style: TextStyle(
                                      color: Color(0xFF1C7BFF),
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...items.map((item) => _buildCartItemTile(item)),
                        const SizedBox(height: 12),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              _summaryRow('Subtotal',
                                  '₵${widget.viewModel.subtotal.toStringAsFixed(3)}'),
                              const SizedBox(height: 8),
                              _summaryRow('Shipping', 'FREE',
                                  valueColor: const Color(0xFF0F9F65)),
                              const SizedBox(height: 8),
                              _summaryRow('Estimated Tax',
                                  '₵${widget.viewModel.tax.toStringAsFixed(3)}'),
                              const Divider(height: 20),
                              _summaryRow('Total',
                                  '₵${widget.viewModel.total.toStringAsFixed(3)}',
                                  isBold: true,
                                  valueColor: const Color(0xFF1C7BFF)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: widget.onCheckout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1C7BFF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Proceed to Checkout',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 18),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: content,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCartItemTile(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: item.product.images.isNotEmpty
                ? Image.network(item.product.images.first, fit: BoxFit.cover)
                : const Icon(Icons.phone_android,
                    color: Colors.black54, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${item.selectedStorage}, ${item.selectedColor}',
                    style: const TextStyle(
                        color: Color(0xFF667085), fontSize: 13)),
                const SizedBox(height: 12),
                Text('₵${item.totalPrice.toStringAsFixed(3)}',
                    style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => widget.viewModel.updateQuantity(item.id, -1),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Icon(Icons.remove,
                            size: 18, color: Color(0xFF1F2937)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text('${item.quantity}',
                        style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () => widget.viewModel.updateQuantity(item.id, 1),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Icon(Icons.add,
                            size: 18, color: Color(0xFF1F2937)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => widget.viewModel.removeItem(item.id),
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFF7A8194)),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isBold = false, Color valueColor = const Color(0xFF1F2937)}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: const Color(0xFF1F2937),
                fontSize: isBold ? 18 : 15,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: isBold ? 18 : 15,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w700)),
      ],
    );
  }
}
