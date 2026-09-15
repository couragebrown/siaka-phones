import 'package:flutter/material.dart';
import '../../core/widgets/bottom_nav_scaffold.dart';
import '../../core/widgets/featured_phone_card.dart';
import 'product_detail_view_model.dart';

class ProductDetailView extends StatelessWidget {
  final ProductDetailViewModel viewModel;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onReviewsTap;
  final VoidCallback onGoToCart;
  final int currentTabIndex;

  const ProductDetailView({
    super.key,
    required this.viewModel,
    required this.onTabSelected,
    required this.onReviewsTap,
    required this.onGoToCart,
    this.currentTabIndex = 0,
  });

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return formatted;
  }

  Color _colorForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('black') || lower.contains('dark')) {
      return const Color(0xFF1F2937);
    }
    if (lower.contains('white')) {
      return const Color(0xFFF9FAFB);
    }
    if (lower.contains('gray') ||
        lower.contains('grey') ||
        lower.contains('titanium')) {
      return const Color(0xFF9CA3AF);
    }
    if (lower.contains('blue')) {
      return const Color(0xFF3B82F6);
    }
    if (lower.contains('violet') || lower.contains('purple')) {
      return const Color(0xFF8B5CF6);
    }
    if (lower.contains('green')) {
      return const Color(0xFF10B981);
    }
    if (lower.contains('yellow') || lower.contains('gold')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final product = viewModel.product;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F4F6),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF111827),
                size: 19,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              product.brand,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.favorite_border_rounded,
                  color: Color(0xFF111827),
                  size: 21,
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: onGoToCart,
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFF111827),
                      size: 21,
                    ),
                  ),
                  if (viewModel.cartItemCount > 0)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1C7BFF),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '${viewModel.cartItemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),

                      // Hero Phone Display Card
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1.0,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 10,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C7BFF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Featured',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: product.images.isNotEmpty
                                    ? Image.network(
                                        product.images[
                                            viewModel.selectedImageIndex <
                                                    product.images.length
                                                ? viewModel.selectedImageIndex
                                                : 0],
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            ProductPhoneGraphic(
                                                product: product),
                                      )
                                    : ProductPhoneGraphic(product: product),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Image Thumbnails (if multiple images)
                      if (product.images.length > 1) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            product.images.length,
                            (index) {
                              final isSelected =
                                  viewModel.selectedImageIndex == index;
                              return GestureDetector(
                                onTap: () => viewModel.selectImage(index),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF1C7BFF)
                                          : const Color(0xFFE5E7EB),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: Image.network(
                                    product.images[index],
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.phone_android,
                                      size: 20,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Title & Rating
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: onReviewsTap,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFFFA000),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        product.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Color(0xFF111827),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '(${product.reviewCount} Reviews)',
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'In Stock',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Price Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₵${_formatPrice(product.price)}',
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Inclusive of all taxes & warranty',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Storage Selection
                      const Text(
                        'Storage',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: product.storageOptions.map((storage) {
                          final selected = storage == viewModel.selectedStorage;
                          return GestureDetector(
                            onTap: () => viewModel.selectStorage(storage),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF1C7BFF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF1C7BFF)
                                      : const Color(0xFFE5E7EB),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                storage,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),

                      // Color Selection
                      Text(
                        'Color: ${viewModel.selectedColor}',
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: product.colors.map((colorName) {
                          final selected = colorName == viewModel.selectedColor;
                          final color = _colorForName(colorName);
                          return GestureDetector(
                            onTap: () => viewModel.selectColor(colorName),
                            child: Container(
                              width: 26,
                              height: 26,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF1C7BFF)
                                      : const Color(0xFFD1D5DB),
                                  width: selected ? 2.5 : 1,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF1C7BFF)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),

                      // Quantity Selector
                      Row(
                        children: [
                          const Text(
                            'Quantity',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFE5E7EB), width: 1),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => viewModel.updateQuantity(-1),
                                  borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(8)),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Icon(Icons.remove,
                                        size: 16, color: Color(0xFF4B5563)),
                                  ),
                                ),
                                Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 26),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${viewModel.quantity}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => viewModel.updateQuantity(1),
                                  borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(8)),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Icon(Icons.add,
                                        size: 16, color: Color(0xFF4B5563)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Action Buttons: Add to Cart & Buy Now
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  viewModel.addToCart();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${product.name} added to cart!'),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: const Color(0xFF1F2937),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1C7BFF),
                                  side: const BorderSide(
                                      color: Color(0xFF1C7BFF)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                icon: Icon(
                                  viewModel.isAddedSuccess
                                      ? Icons.check
                                      : Icons.shopping_bag_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  viewModel.isAddedSuccess
                                      ? 'Added!'
                                      : 'Add to Cart',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: ElevatedButton(
                                onPressed: onGoToCart,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1C7BFF),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text(
                                  'Buy Now',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Delivery Banner (Clean with Expanded to prevent ANY overflow/yellow strokes)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFA7F3D0),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.local_shipping_outlined,
                              color: Color(0xFF0F9F65),
                              size: 17,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Order within 2h 15m for delivery by May 27, 2025',
                                style: TextStyle(
                                  color: Color(0xFF0F9F65),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Product Highlights
                      const Text(
                        'Product Highlights',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Column(
                        children: [
                          _HighlightRow(
                            icon: Icons.check_circle_outline_rounded,
                            text:
                                'Super Retina XDR OLED display with ProMotion 120Hz',
                          ),
                          _HighlightRow(
                            icon: Icons.check_circle_outline_rounded,
                            text:
                                'Next-generation flagship processor with high efficiency',
                          ),
                          _HighlightRow(
                            icon: Icons.check_circle_outline_rounded,
                            text:
                                'Pro camera system with advanced night mode & 4K HDR',
                          ),
                          _HighlightRow(
                            icon: Icons.check_circle_outline_rounded,
                            text: 'All-day battery life with fast charging',
                          ),
                          _HighlightRow(
                            icon: Icons.check_circle_outline_rounded,
                            text: '5G ultra-wideband connectivity & Dual SIM',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              AppBottomNavBar(
                currentIndex: currentTabIndex,
                onTabSelected: onTabSelected,
                cartBadgeCount: viewModel.cartItemCount,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HighlightRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1C7BFF)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
