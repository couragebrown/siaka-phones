import 'dart:async';

import 'package:flutter/material.dart';
import '../../../domain/models/cart_item.dart';
import '../../../domain/models/product.dart';
import '../../core/widgets/featured_phone_card.dart';
import 'cart_view_model.dart';

class _CartHeroPromotion {
  final String title;
  final String description;
  final String primaryAction;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;

  const _CartHeroPromotion({
    required this.title,
    required this.description,
    required this.primaryAction,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
  });
}

class CartView extends StatefulWidget {
  final CartViewModel viewModel;
  final VoidCallback onCheckout;
  final VoidCallback onBrowseCatalog;
  final Function(Product)? onProductTap;

  const CartView({
    super.key,
    required this.viewModel,
    required this.onCheckout,
    required this.onBrowseCatalog,
    this.onProductTap,
  });

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  static const _heroSlideInterval = Duration(seconds: 5);

  static const _heroPromotions = [
    _CartHeroPromotion(
      title: 'Free Express Shipping',
      description: 'On all orders over ₵500 nationwide',
      primaryAction: 'View Terms',
      backgroundColor: Color(0xFFDDF5E8),
      icon: Icons.local_shipping_rounded,
      iconColor: Color(0xFF059669),
    ),
    _CartHeroPromotion(
      title: '0% APR Financing',
      description: 'Split into 4 equal bi-weekly payments',
      primaryAction: 'Learn More',
      backgroundColor: Color(0xFFFFE9DD),
      icon: Icons.payments_rounded,
      iconColor: Color(0xFFEA580C),
    ),
    _CartHeroPromotion(
      title: '1-Year Warranty',
      description: 'Full hardware and screen protection',
      primaryAction: 'Protection Plan',
      backgroundColor: Color(0xFFE9E4FA),
      icon: Icons.verified_user_rounded,
      iconColor: Color(0xFF7C3AED),
    ),
    _CartHeroPromotion(
      title: 'Easy 30-Day Returns',
      description: 'Hassle-free exchanges and instant support',
      primaryAction: 'Return Policy',
      backgroundColor: Color(0xFFDDECFB),
      icon: Icons.assignment_return_rounded,
      iconColor: Color(0xFF1D4ED8),
    ),
  ];

  late final PageController _heroPageController;
  Timer? _heroTimer;
  int _activeHeroIndex = 0;
  final TextEditingController _promoController = TextEditingController();
  String? _promoFeedback;
  bool _promoSuccess = false;

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController();
    _heroTimer = Timer.periodic(_heroSlideInterval, (_) => _advanceHero());
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPageController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _advanceHero() {
    if (!mounted || !_heroPageController.hasClients) {
      return;
    }
    final nextIndex = (_activeHeroIndex + 1) % _heroPromotions.length;
    _heroPageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '₵$formatted';
  }

  void _handleApplyPromo() {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    final success = widget.viewModel.applyPromo(code);
    setState(() {
      _promoSuccess = success;
      if (success) {
        _promoFeedback = 'Promo "$code" applied successfully!';
      } else {
        _promoFeedback = 'Invalid promo code. Try SIAKA10 or VIP20';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final items = widget.viewModel.items;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F4F6),
            elevation: 0,
            automaticallyImplyLeading: false,
            centerTitle: true,
            leading: Navigator.canPop(context)
                ? IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF1F2937), size: 20),
                  )
                : null,
            title: Text(
              'My Cart (${items.length})',
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              if (items.isNotEmpty)
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear Cart'),
                        content: const Text(
                            'Are you sure you want to remove all items from your cart?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              for (final item in List.from(items)) {
                                widget.viewModel.removeItem(item.id);
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                            ),
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Appropriate-sized Promotional Banner (140dp height)
                _buildHeroBanner(),
                const SizedBox(height: 12),

                if (items.isEmpty)
                  _buildEmptyState()
                else ...[
                  // 2. Compact Free Shipping Progress Banner
                  _buildFreeShippingProgress(widget.viewModel.subtotal),
                  const SizedBox(height: 16),

                  // 3. Cart Items List
                  _buildCartItemsList(items),
                  const SizedBox(height: 16),

                  // 4. Order Summary Card
                  _buildOrderSummaryCard(),
                  const SizedBox(height: 16),

                  // 5. Checkout Action Button
                  Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: widget.onCheckout,
                            icon: const Icon(Icons.lock_outline_rounded,
                                size: 16),
                            label: const Text(
                              'Proceed to Checkout',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1C7BFF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
        );
      },
    );
  }

  /// Compact 140dp Hero Banner Carousel matching Search & Wishlist
  Widget _buildHeroBanner() {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _heroPageController,
            onPageChanged: (idx) => setState(() => _activeHeroIndex = idx),
            itemCount: _heroPromotions.length,
            itemBuilder: (context, index) {
              final promo = _heroPromotions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildHeroCard(promo),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _heroPromotions.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _activeHeroIndex == index ? 16 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: _activeHeroIndex == index
                    ? const Color(0xFF1C7BFF)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(_CartHeroPromotion promo) {
    return Container(
      decoration: BoxDecoration(
        color: promo.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  promo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  promo.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 26,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C7BFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      promo.primaryAction,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 68,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                promo.icon,
                color: promo.iconColor,
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact Dynamic Free Shipping Banner
  Widget _buildFreeShippingProgress(double subtotal) {
    const freeShippingThreshold = 500.0;
    final isUnlocked = subtotal >= freeShippingThreshold;
    final remaining = freeShippingThreshold - subtotal;
    final progress = (subtotal / freeShippingThreshold).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUnlocked ? const Color(0xFFECFDF5) : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isUnlocked ? const Color(0xFFA7F3D0) : const Color(0xFFDBEAFE),
            width: 1,
          ),
        ),
        child: isUnlocked
            ? const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF059669), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You've unlocked FREE Express Shipping!",
                      style: TextStyle(
                        color: Color(0xFF065F46),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'FREE',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined,
                          color: Color(0xFF1C7BFF), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Add ₵${remaining.toStringAsFixed(0)} more for FREE Express Shipping',
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '₵${remaining.toStringAsFixed(0)} left',
                        style: const TextStyle(
                          color: Color(0xFF1C7BFF),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1C7BFF),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Sized Cart Items List
  Widget _buildCartItemsList(List<CartItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Cart Items (${items.length})',
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Text(
                '${widget.viewModel.itemCount} qty',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => _buildCartProductCard(item)),
        ],
      ),
    );
  }

  /// Compact uniform product card (~108dp) matching Wishlist design
  Widget _buildCartProductCard(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Authentic device graphic preview
          GestureDetector(
            onTap: () => widget.onProductTap?.call(item.product),
            child: Container(
              width: 76,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: ProductPhoneGraphic(product: item.product),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand pill tag, in stock tag & close/delete button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.product.brand.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'In Stock',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => widget.viewModel.removeItem(item.id),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFFFEE2E2)),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Name
                GestureDetector(
                  onTap: () => widget.onProductTap?.call(item.product),
                  child: Text(
                    item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 2),

                // Specs
                Text(
                  '${item.selectedStorage} • ${item.selectedColor}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),

                // Price & compact quantity stepper row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatPrice(item.totalPrice),
                            style: const TextStyle(
                              color: Color(0xFF1C7BFF),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (item.quantity > 1)
                            Text(
                              '(${_formatPrice(item.product.price)} ea)',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 9.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Compact Quantity Stepper
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () =>
                                widget.viewModel.updateQuantity(item.id, -1),
                            borderRadius: BorderRadius.circular(6),
                            child: const SizedBox(
                              width: 26,
                              height: 26,
                              child: Center(
                                child: Icon(Icons.remove,
                                    size: 13, color: Color(0xFF475569)),
                              ),
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 24),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                widget.viewModel.updateQuantity(item.id, 1),
                            borderRadius: BorderRadius.circular(6),
                            child: const SizedBox(
                              width: 26,
                              height: 26,
                              child: Center(
                                child: Icon(Icons.add,
                                    size: 13, color: Color(0xFF475569)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact Order Summary Card
  Widget _buildOrderSummaryCard() {
    final subtotal = widget.viewModel.subtotal;
    final discount = widget.viewModel.discountAmount;
    final shipping = widget.viewModel.shipping;
    final tax = widget.viewModel.tax;
    final total = widget.viewModel.total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),

            // Promo Code Input Row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _promoController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Promo Code (e.g. SIAKA10)',
                        hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF), fontSize: 11.5),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF1C7BFF)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _handleApplyPromo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            if (_promoFeedback != null) ...[
              const SizedBox(height: 6),
              Text(
                _promoFeedback!,
                style: TextStyle(
                  color: _promoSuccess
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Summary Breakdown Rows
            _buildSummaryRow('Subtotal', _formatPrice(subtotal)),
            if (discount > 0) ...[
              const SizedBox(height: 6),
              _buildSummaryRow(
                'Promo Discount',
                '-${_formatPrice(discount)}',
                valueColor: const Color(0xFF059669),
              ),
            ],
            const SizedBox(height: 6),
            _buildSummaryRow(
              'Shipping',
              shipping == 0.0 ? 'FREE' : _formatPrice(shipping),
              valueColor: shipping == 0.0
                  ? const Color(0xFF059669)
                  : const Color(0xFF1F2937),
            ),
            const SizedBox(height: 6),
            _buildSummaryRow(
              'Estimated Tax (8.25%)',
              '₵${tax.toStringAsFixed(2)}',
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Color(0xFFE5E7EB)),
            ),
            _buildSummaryRow(
              'Total',
              '₵${total.toStringAsFixed(2)}',
              isBold: true,
              valueColor: const Color(0xFF1C7BFF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color valueColor = const Color(0xFF1F2937),
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isBold ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
              fontSize: isBold ? 14.5 : 12.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: isBold ? 15.5 : 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// Empty Cart State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF1C7BFF),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your Cart is Empty',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Explore our smartphone collection and add devices to your cart.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: widget.onBrowseCatalog,
                  icon: const Icon(Icons.explore_outlined, size: 16),
                  label: const Text(
                    'Explore Phones',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C7BFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
