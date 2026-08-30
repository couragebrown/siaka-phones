import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/neon_button.dart';
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
  final TextEditingController _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final items = widget.viewModel.items;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('Your Cart (${widget.viewModel.itemCount})'),
          ),
          body: items.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ...items.map((item) => _buildCartItemTile(item)),
                          const SizedBox(height: 16),
                          _buildPromoSection(),
                          const SizedBox(height: 16),
                          _buildOrderSummary(),
                        ],
                      ),
                    ),
                    _buildCheckoutBottomBar(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.cyan),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Shopping Bag is Empty',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore our new arrivals and flagship titanium devices to fill your bag.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            NeonButton(
              label: 'Browse Devices',
              icon: Icons.explore_rounded,
              onPressed: widget.onBrowseCatalog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemTile(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.product.images.first,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 70,
                  height: 70,
                  color: AppColors.surface,
                  child: const Icon(Icons.phone_android, color: AppColors.cyan),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.selectedColor} • ${item.selectedStorage}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.neonPink),
                  onPressed: () => widget.viewModel.removeItem(item.id),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => widget.viewModel.updateQuantity(item.id, -1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.remove, size: 14, color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => widget.viewModel.updateQuantity(item.id, 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.add, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoSection() {
    final applied = widget.viewModel.appliedPromoCode;

    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promoController,
              enabled: applied == null,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: applied != null ? 'Code Applied: $applied' : 'Promo Code (e.g. SIAKA10)',
                hintStyle: TextStyle(
                  color: applied != null ? AppColors.cyan : AppColors.textMuted,
                  fontWeight: applied != null ? FontWeight.bold : FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: applied != null ? AppColors.surfaceElevated : AppColors.cyan,
              foregroundColor: applied != null ? AppColors.cyan : Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: applied != null
                ? null
                : () {
                    final ok = widget.viewModel.applyPromo(_promoController.text);
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid code. Try "SIAKA10" or "VIP20"')),
                      );
                    }
                  },
            child: Text(applied != null ? 'Active ✓' : 'Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _buildSummaryRow('Subtotal', '\$${widget.viewModel.subtotal.toStringAsFixed(2)}'),
          if (widget.viewModel.discountAmount > 0)
            _buildSummaryRow('Promo Discount', '-\$${widget.viewModel.discountAmount.toStringAsFixed(2)}', color: AppColors.cyan),
          _buildSummaryRow('Estimated Tax', '\$${widget.viewModel.tax.toStringAsFixed(2)}'),
          _buildSummaryRow('Express Insured Shipping', widget.viewModel.shipping == 0 ? 'FREE' : '\$${widget.viewModel.shipping.toStringAsFixed(2)}'),
          const Divider(color: AppColors.borderLight, height: 20),
          _buildSummaryRow(
            'Total Amount',
            '\$${widget.viewModel.total.toStringAsFixed(2)}',
            isBold: true,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isBold = false, double fontSize = 13, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: fontSize)),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total to Pay', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text(
                  '\$${widget.viewModel.total.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: NeonButton(
                label: 'Proceed to Checkout',
                icon: Icons.lock_outline,
                onPressed: widget.onCheckout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
