import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/featured_phone_card.dart';
import '../../../domain/models/product.dart';
import 'catalog_view_model.dart';

class _CatalogHeroPromotion {
  final String title;
  final String description;
  final String primaryAction;
  final Color backgroundColor;

  const _CatalogHeroPromotion({
    required this.title,
    required this.description,
    required this.primaryAction,
    required this.backgroundColor,
  });
}

class CatalogView extends StatefulWidget {
  final CatalogViewModel viewModel;
  final Function(Product) onProductTap;

  const CatalogView({
    super.key,
    required this.viewModel,
    required this.onProductTap,
  });

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _wishlistProductIds = {'phone-1'};
  late final PageController _heroPageController;
  Timer? _heroTimer;
  int _activeHeroIndex = 0;

  static const _heroPromotions = [
    _CatalogHeroPromotion(
      title: 'Discover the\nLatest Smartphones',
      description: 'Shop flagship devices at\nunbeatable prices.',
      primaryAction: 'Shop Now',
      backgroundColor: Color(0xFFDDECFB),
    ),
    _CatalogHeroPromotion(
      title: 'Save up to 20%\non flagship phones',
      description: 'Limited-time prices on the\ndevices you want most.',
      primaryAction: 'View Offers',
      backgroundColor: Color(0xFFE9E4FA),
    ),
    _CatalogHeroPromotion(
      title: 'Trade in. Upgrade.\nPay less.',
      description: 'Turn your current phone into\ninstant upgrade credit.',
      primaryAction: 'Trade In',
      backgroundColor: Color(0xFFDDF5E8),
    ),
    _CatalogHeroPromotion(
      title: 'Premium care.\nMade simple.',
      description: 'Protect, repair, and enjoy\nyour phone with confidence.',
      primaryAction: 'Explore Care',
      backgroundColor: Color(0xFFFFE9DD),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_heroPageController.hasClients) return;
      final nextIndex = (_activeHeroIndex + 1) % _heroPromotions.length;
      _heroPageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });

    widget.viewModel.loadCatalog();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    widget.viewModel.setSearchQuery(_searchController.text);
    setState(() {});
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPageController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final bool isSearching = _searchController.text.trim().isNotEmpty;
        final featuredProducts = widget.viewModel.featuredProducts.isNotEmpty
            ? widget.viewModel.featuredProducts
            : widget.viewModel.products.where((p) => p.isFeatured).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F4F6),
            elevation: 0,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: const Text(
              'Search Devices',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar with typed text color matching the login page
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE1E5EA)),
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
                      const SizedBox(width: 12),
                      const Icon(Icons.search_rounded,
                          color: Color(0xFF8A93A6), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          cursorColor: const Color(0xFF1C7BFF),
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search flagships, foldables, brands...',
                            hintStyle: TextStyle(
                              color: Color(0xFF8A93A6),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (val) {
                            widget.viewModel.setSearchQuery(val);
                          },
                          onSubmitted: (val) {
                            widget.viewModel.setSearchQuery(val);
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                              width: 34, height: 34),
                          icon: const Icon(Icons.clear_rounded,
                              color: Color(0xFF8A93A6), size: 18),
                          onPressed: () {
                            _searchController.clear();
                            widget.viewModel.setSearchQuery('');
                          },
                        )
                      else
                        const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),

              // Categories pills
              SizedBox(
                height: 34,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.viewModel.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = widget.viewModel.categories[index];
                    final isSelected = widget.viewModel.selectedCategory == cat;
                    return InkWell(
                      onTap: () => widget.viewModel.setCategory(cat),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1C7BFF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1C7BFF)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Main body: Featured Banners initially vs Search Results when typing
              Expanded(
                child: widget.viewModel.isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF1C7BFF)),
                      )
                    : isSearching
                        ? _buildSearchResultsView()
                        : _buildInitialFeaturedView(featuredProducts),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialFeaturedView(List<Product> featuredProducts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured Promotional Hero Banners
          _buildHeroBanner(featuredProducts),
          const SizedBox(height: 18),

          // Featured section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Featured Phones',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF1E2432),
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Text(
                    'Top Picks',
                    style: TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Featured Phones grid using the identical featured cards
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final int crossAxisCount = width > 700 ? 4 : 3;
              const double mainAxisExtent = 240;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: mainAxisExtent,
                ),
                itemCount: featuredProducts.length,
                itemBuilder: (context, index) {
                  final product = featuredProducts[index];
                  final isWishlisted =
                      _wishlistProductIds.contains(product.id);
                  return FeaturedPhoneCard(
                    product: product,
                    isWishlisted: isWishlisted,
                    onTap: () => widget.onProductTap(product),
                    onWishlistTap: () {
                      setState(() {
                        if (isWishlisted) {
                          _wishlistProductIds.remove(product.id);
                        } else {
                          _wishlistProductIds.add(product.id);
                        }
                      });
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsView() {
    final products = widget.viewModel.products;

    if (products.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.search_off_rounded,
                          size: 28,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No devices found',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try searching for "${_searchController.text.trim()}" in another category, or check spelling.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          onPressed: () {
                            _searchController.clear();
                            widget.viewModel.setSearchQuery('');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1C7BFF),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Clear Search',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Results for "${_searchController.text.trim()}" (${products.length})',
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final int crossAxisCount = width > 700 ? 4 : 3;
              const double mainAxisExtent = 240;

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: mainAxisExtent,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final isWishlisted =
                      _wishlistProductIds.contains(product.id);
                  return FeaturedPhoneCard(
                    product: product,
                    isWishlisted: isWishlisted,
                    onTap: () => widget.onProductTap(product),
                    onWishlistTap: () {
                      setState(() {
                        if (isWishlisted) {
                          _wishlistProductIds.remove(product.id);
                        } else {
                          _wishlistProductIds.add(product.id);
                        }
                      });
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(List<Product> products) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _heroPageController,
            itemCount: _heroPromotions.length,
            onPageChanged: (index) => setState(() => _activeHeroIndex = index),
            itemBuilder: (context, index) => _buildHeroSlide(
              _heroPromotions[index],
              products,
              index,
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

  Widget _buildHeroSlide(
    _CatalogHeroPromotion promotion,
    List<Product> products,
    int index,
  ) {
    final primaryProduct =
        products.isEmpty ? null : products[index % products.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: promotion.backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promotion.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1B1F2A),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  promotion.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF485569),
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: primaryProduct == null
                            ? null
                            : () => widget.onProductTap(primaryProduct),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: Text(
                          promotion.primaryAction,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (primaryProduct != null)
            Flexible(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.only(right: 2),
                child: _buildHeroProductImage(
                  primaryProduct,
                  96,
                  126,
                  14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroProductImage(
    Product product,
    double width,
    double height,
    double radius,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : width;
        final actualWidth = maxW < width ? maxW : width;
        return Container(
          width: actualWidth,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.network(
              product.images.first,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFFE2E8F0)),
            ),
          ),
        );
      },
    );
  }
}
