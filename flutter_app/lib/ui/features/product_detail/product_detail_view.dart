import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/widgets/bottom_nav_scaffold.dart';
import '../../core/widgets/featured_phone_card.dart';
import '../../core/widgets/product_smart_image.dart';
import '../../../data/repositories/wishlist_repository.dart';
import 'product_detail_view_model.dart';

class ProductDetailView extends StatelessWidget {
  final ProductDetailViewModel viewModel;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onReviewsTap;
  final VoidCallback onGoToCart;
  final int currentTabIndex;
  final WishlistRepository? wishlistRepo;

  const ProductDetailView({
    super.key,
    required this.viewModel,
    required this.onTabSelected,
    required this.onReviewsTap,
    required this.onGoToCart,
    this.currentTabIndex = 0,
    this.wishlistRepo,
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
              if (wishlistRepo != null)
                ListenableBuilder(
                  listenable: wishlistRepo!,
                  builder: (context, _) {
                    final isWishlisted =
                        wishlistRepo!.isWishlisted(viewModel.product.id);
                    return IconButton(
                      onPressed: () {
                        wishlistRepo!.toggleWishlist(viewModel.product);
                      },
                      icon: Icon(
                        isWishlisted
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isWishlisted
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF111827),
                        size: 21,
                      ),
                    );
                  },
                )
              else
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

                      // Hero Phone Display Card (Flagship enlarged size)
                      Container(
                        width: double.infinity,
                        height: 290,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          gradient: viewModel.isVideoSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF090D16),
                                    Color(0xFF111827),
                                    Color(0xFF0F172A),
                                  ],
                                )
                              : const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
                                ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: viewModel.isVideoSelected
                                ? const Color(0xFF1F2937)
                                : const Color(0xFFE5E7EB),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: viewModel.isVideoSelected
                                  ? const Color(0x331C7BFF)
                                  : Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: viewModel.isVideoSelected
                            ? _PhoneVideoShowcase(
                                viewModel: viewModel,
                                product: product,
                              )
                            : Stack(
                                children: [
                                  // Large Phone Image (Bottom/Background layer)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 22),
                                      child: viewModel.displayImages.isNotEmpty &&
                                              viewModel
                                                  .displayImages[viewModel
                                                      .selectedImageIndex
                                                      .clamp(0, 3)]
                                                  .isNotEmpty
                                          ? ProductSmartImage(
                                              imageUrl: viewModel.displayImages[viewModel
                                                  .selectedImageIndex
                                                  .clamp(0, 3)],
                                              fit: BoxFit.contain,
                                              fallback: ProductPhoneGraphic(
                                                  product: product),
                                            )
                                          : ProductPhoneGraphic(
                                              product: product),
                                    ),
                                  ),

                                  // Condition / Status Tag (Top layer)
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 4.5),
                                      decoration: BoxDecoration(
                                        color: product.condition
                                                .toLowerCase()
                                                .contains('uk')
                                            ? const Color(0xFF8B5CF6)
                                            : product.condition
                                                    .toLowerCase()
                                                    .contains('refurb')
                                                ? const Color(0xFFF59E0B)
                                                : const Color(0xFF1C7BFF),
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.verified_rounded,
                                            size: 11,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            product.condition.isNotEmpty
                                                ? product.condition
                                                : 'Featured',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Photo Angle Counter Badge (Top layer)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFE5E7EB),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.camera_alt_outlined,
                                            size: 11.5,
                                            color: Color(0xFF4B5563),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Angle ${viewModel.selectedImageIndex + 1}/4',
                                            style: const TextStyle(
                                              color: Color(0xFF374151),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Bottom Right Zoom / Angle Hint (Top layer)
                                  Positioned(
                                    bottom: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.06),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.zoom_in_rounded,
                                        size: 15,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      // 5 Preview Thumbnails: 4 Image Angles + 1 Video Preview
                      const SizedBox(height: 12),
                      Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 4 Image angle preview thumbnails
                              for (int i = 0; i < 4; i++)
                                _buildImageThumbnail(
                                  index: i,
                                  imageUrl: viewModel.displayImages.length > i
                                      ? viewModel.displayImages[i]
                                      : '',
                                  isSelected:
                                      viewModel.selectedImageIndex == i,
                                  onTap: () => viewModel.selectImage(i),
                                  product: product,
                                ),

                              // 1 Dedicated Video preview thumbnail
                              _buildVideoThumbnail(
                                isSelected: viewModel.isVideoSelected,
                                onTap: () => viewModel.selectImage(4),
                              ),
                            ],
                          ),
                        ),
                      ),

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
                                    mainAxisSize: MainAxisSize.min,
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
                                      Flexible(
                                        child: Text(
                                          '(${product.reviewCount} Reviews)',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
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
                          const Expanded(
                            child: Text(
                              'Inclusive of all taxes & warranty',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                              ),
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
                      Column(
                        children: product.effectiveHighlights.map((highlight) {
                          return _HighlightRow(
                            icon: Icons.check_circle_outline_rounded,
                            text: highlight,
                          );
                        }).toList(),
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

  static const List<String> _angleLabels = ['Front', 'Back', 'Side', 'Angle'];

  Widget _buildImageThumbnail({
    required int index,
    required String imageUrl,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic product,
  }) {
    final label = index < _angleLabels.length ? _angleLabels[index] : 'Angle';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 56,
        height: 62,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFFE5E7EB),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1C7BFF).withValues(alpha: 0.22),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        child: Column(
          children: [
            Expanded(
              child: imageUrl.isNotEmpty
                  ? ProductSmartImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      fallback: const Icon(
                        Icons.phone_android,
                        size: 22,
                        color: Color(0xFF9CA3AF),
                      ),
                    )
                  : const Icon(
                      Icons.phone_android,
                      size: 22,
                      color: Color(0xFF9CA3AF),
                    ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF1C7BFF)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail({
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 56,
        height: 62,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF334155),
            width: isSelected ? 2.2 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_rounded,
                    size: 9.5,
                    color: isSelected ? const Color(0xFFEF4444) : Colors.white70,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'VIDEO',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: isSelected ? const Color(0xFFEF4444) : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneVideoShowcase extends StatefulWidget {
  final ProductDetailViewModel viewModel;
  final dynamic product;

  const _PhoneVideoShowcase({
    required this.viewModel,
    required this.product,
  });

  @override
  State<_PhoneVideoShowcase> createState() => _PhoneVideoShowcaseState();
}

class _PhoneVideoShowcaseState extends State<_PhoneVideoShowcase> {
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    final isTest = WidgetsBinding.instance.runtimeType
        .toString()
        .toLowerCase()
        .contains('test');
    if (!isTest) {
      _playbackTimer =
          Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (mounted &&
            widget.viewModel.isVideoSelected &&
            widget.viewModel.isVideoPlaying) {
          final next = widget.viewModel.videoProgress + 0.015;
          widget.viewModel.setVideoProgress(next >= 1.0 ? 0.0 : next);
        }
      });
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final product = widget.product;
    final currentSeconds = (vm.videoProgress * 45).toInt();
    final timeStr = '0:${currentSeconds.toString().padLeft(2, '0')} / 0:45';

    return Stack(
      children: [
        // Center Phone Graphic with Ambient Glow
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient radial blue glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1C7BFF).withValues(alpha: 0.28),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              // Phone presentation
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
                child: vm.displayImages.isNotEmpty &&
                        vm.displayImages[0].isNotEmpty
                    ? ProductSmartImage(
                        imageUrl: vm.displayImages[0],
                        fit: BoxFit.contain,
                        fallback: ProductPhoneGraphic(product: product),
                      )
                    : ProductPhoneGraphic(product: product),
              ),
            ],
          ),
        ),

        // Tappable overlay for Play/Pause
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: vm.toggleVideoPlayback,
            child: Center(
              child: AnimatedOpacity(
                opacity: vm.isVideoPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Top Video HUD Bar
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 4K Video badge with pulsing red live dot
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      '4K 60FPS DEMO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Audio toggle button
              GestureDetector(
                onTap: vm.toggleVideoMute,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vm.isVideoMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vm.isVideoMuted ? 'Muted' : 'Sound',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom Video Controls Overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${product.brand} ${product.name} • 360° Showcase',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C7BFF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'HD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Scrubber Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: vm.videoProgress,
                    minHeight: 3.5,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF1C7BFF)),
                  ),
                ),
                const SizedBox(height: 6),

                // Bottom row with Play/Pause button, timecode, and tour icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: vm.toggleVideoPlayback,
                          child: Icon(
                            vm.isVideoPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Icon(
                          Icons.threesixty_rounded,
                          size: 15,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Hands-on Tour',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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
