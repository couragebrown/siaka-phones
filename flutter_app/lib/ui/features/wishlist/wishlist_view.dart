import 'dart:async';

import 'package:flutter/material.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../data/repositories/wishlist_repository.dart';
import '../../../domain/models/product.dart';
import '../../core/widgets/featured_phone_card.dart';

class _WishlistHeroPromotion {
  final String title;
  final String description;
  final String primaryAction;
  final Color backgroundColor;

  const _WishlistHeroPromotion({
    required this.title,
    required this.description,
    required this.primaryAction,
    required this.backgroundColor,
  });
}

class WishlistView extends StatefulWidget {
  final WishlistRepository wishlistRepo;
  final CartRepository? cartRepo;
  final Function(Product)? onProductTap;
  final VoidCallback? onBrowseCatalog;
  final VoidCallback? onGoToCart;
  final VoidCallback? onBack;

  const WishlistView({
    super.key,
    required this.wishlistRepo,
    this.cartRepo,
    this.onProductTap,
    this.onBrowseCatalog,
    this.onGoToCart,
    this.onBack,
  });

  @override
  State<WishlistView> createState() => _WishlistViewState();
}

class _WishlistViewState extends State<WishlistView> {
  static const _heroSlideInterval = Duration(seconds: 5);
  late final PageController _heroPageController;
  Timer? _heroTimer;
  int _activeHeroIndex = 0;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  static const _heroPromotions = [
    _WishlistHeroPromotion(
      title: 'Your Saved Devices\nTrack Prices & Drops',
      description: 'Get instant updates when your\nfavorite items change price.',
      primaryAction: 'Explore Deals',
      backgroundColor: Color(0xFFDDECFB),
    ),
    _WishlistHeroPromotion(
      title: 'Trade in & Upgrade\nInstant Credit',
      description: 'Exchange your current phone\nfor credit toward wishlist items.',
      primaryAction: 'Trade In',
      backgroundColor: Color(0xFFDDF5E8),
    ),
    _WishlistHeroPromotion(
      title: 'Save up to 20%\non flagship phones',
      description: 'Special seasonal pricing on\ntop tier smartphones.',
      primaryAction: 'View Offers',
      backgroundColor: Color(0xFFE9E4FA),
    ),
    _WishlistHeroPromotion(
      title: 'Buy Now, Pay Later\n0% APR Financing',
      description: 'Split payments into 4 equal\nbi-weekly installments.',
      primaryAction: 'Learn More',
      backgroundColor: Color(0xFFFFE9DD),
    ),
  ];

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

  void _showAutoDismissSnackBar({
    required String message,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    if (!mounted) return;
    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.wishlistRepo,
      builder: (context, _) {
        final items = widget.wishlistRepo.items;

        return ScaffoldMessenger(
          key: _messengerKey,
          child: Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F4F6),
            elevation: 0,
            automaticallyImplyLeading: false,
            centerTitle: true,
            leading: Navigator.canPop(context) || widget.onBack != null
                ? IconButton(
                    onPressed: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF1F2937), size: 20),
                  )
                : null,
            title: Text(
              'My Wishlist (${items.length})',
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
                    widget.wishlistRepo.clearWishlist();
                    _showAutoDismissSnackBar(message: 'Wishlist cleared');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1C7BFF),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appropriately Sized Hero Promotional Banner (height: 140)
                _buildHeroBanner(),
                const SizedBox(height: 16),

                // Content Section: Items List vs Empty State
                if (items.isEmpty)
                  _buildEmptyState()
                else
                  _buildWishlistItemsList(items),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  /// Appropriately sized promotional banner carousel (height: 140)
  Widget _buildHeroBanner() {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _heroPageController,
            itemCount: _heroPromotions.length,
            onPageChanged: (index) => setState(() => _activeHeroIndex = index),
            itemBuilder: (context, index) => _buildHeroSlide(
              _heroPromotions[index],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _heroPromotions.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: _activeHeroIndex == index ? 14 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: _activeHeroIndex == index
                    ? const Color(0xFF1C7BFF)
                    : const Color(0xFFB8C0CC),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSlide(_WishlistHeroPromotion promotion) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: promotion.backgroundColor,
        borderRadius: BorderRadius.circular(10),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  promotion.title,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  promotion.description,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onBrowseCatalog?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C7BFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Text(
                      promotion.primaryAction,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Clean preview graphic container
          Container(
            width: 72,
            height: 94,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.favorite_rounded,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state when no items are wishlisted
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFEE2E2)),
              ),
              child: const Center(
                child: Icon(
                  Icons.favorite_border_rounded,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Wishlist is Empty',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap the heart icon on any device across the Home or Search pages to save it to your wishlist.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onBrowseCatalog?.call();
                },
                icon: const Icon(Icons.search_rounded, size: 16),
                label: const Text(
                  'Browse Devices',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C7BFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// List of wishlisted items with appropriately sized product cards
  Widget _buildWishlistItemsList(List<Product> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Devices (${items.length})',
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (widget.cartRepo != null)
                TextButton.icon(
                  onPressed: () {
                    for (final item in items) {
                      widget.cartRepo!.addToCart(item);
                    }
                    _showAutoDismissSnackBar(
                      message: 'Moved all ${items.length} items to cart!',
                    );
                  },
                  icon: const Icon(Icons.shopping_cart_outlined,
                      size: 14, color: Color(0xFF1C7BFF)),
                  label: const Text(
                    'Move All to Cart',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C7BFF),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final product = items[index];
              return _buildWishlistProductCard(product);
            },
          ),
        ],
      ),
    );
  }

  /// Sleek, appropriately-sized item card with genuine phone graphic and actions
  Widget _buildWishlistProductCard(Product product) {
    return GestureDetector(
      onTap: () => widget.onProductTap?.call(product),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product phone mockup graphic
            Container(
              width: 68,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Center(
                child: ProductPhoneGraphic(product: product),
              ),
            ),
            const SizedBox(width: 12),

            // Product Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.brand.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
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
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatPrice(product.price),
                        style: const TextStyle(
                          color: Color(0xFF1C7BFF),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFBBF24), size: 14),
                      const SizedBox(width: 2),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Actions Row: Move to Cart & Un-heart button
                  Row(
                    children: [
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.cartRepo?.addToCart(product);
                            _showAutoDismissSnackBar(
                              message: '${product.name} added to cart!',
                            );
                          },
                          icon: const Icon(Icons.shopping_cart_outlined,
                              size: 13),
                          label: const Text(
                            'Move to Cart',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C7BFF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Red Heart remove button
                      InkWell(
                        onTap: () {
                          widget.wishlistRepo.removeFromWishlist(product.id);
                          _showAutoDismissSnackBar(
                            message: '${product.name} removed from wishlist',
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    const Color(0xFFEF4444).withValues(alpha: 0.2)),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFEF4444),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
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
