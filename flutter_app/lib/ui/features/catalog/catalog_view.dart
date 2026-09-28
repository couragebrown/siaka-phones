import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/featured_phone_card.dart';
import '../../core/widgets/banner_video_player.dart';
import '../../../domain/models/product.dart';
import '../../../data/repositories/wishlist_repository.dart';
import 'catalog_view_model.dart';

class CatalogView extends StatefulWidget {
  final CatalogViewModel viewModel;
  final Function(Product)? onProductTap;
  final VoidCallback? onBack;
  final WishlistRepository? wishlistRepo;
  final bool autoFocusSearch;
  final VoidCallback? onSearchFocused;
  final VoidCallback? onRepairsTap;

  const CatalogView({
    super.key,
    required this.viewModel,
    this.onProductTap,
    this.onBack,
    this.wishlistRepo,
    this.autoFocusSearch = false,
    this.onSearchFocused,
    this.onRepairsTap,
  });

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;
  final Set<String> _wishlistProductIds = {'phone-1'};
  void _triggerAutoFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
      widget.onSearchFocused?.call();
    });
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    if (widget.autoFocusSearch) {
      _triggerAutoFocus();
    }
    widget.viewModel.loadCatalog();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant CatalogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoFocusSearch) {
      _triggerAutoFocus();
    }
  }

  void _onSearchChanged() {
    widget.viewModel.setSearchQuery(_searchController.text);
    setState(() {});
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.viewModel,
        if (widget.wishlistRepo != null) widget.wishlistRepo!,
      ]),
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
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
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
                          key: const ValueKey('catalog_search_textfield'),
                          controller: _searchController,
                          focusNode: _searchFocusNode,
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
                            _searchFocusNode.unfocus();
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

              const SizedBox(height: 6),

              // Main body: Featured Banners initially vs Search Results when typing
              Expanded(
                child: widget.viewModel.isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF1C7BFF)),
                      )
                    : (isSearching ||
                            widget.viewModel.selectedCategory != 'All')
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
          // Featured Promotional Hero Banner
          _buildHeroBanner(),
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
              final int crossAxisCount = width > 700 ? 4 : 2;
              final double cardWidth =
                  (width - 32 - (12 * (crossAxisCount - 1))) / crossAxisCount;
              final double mainAxisExtent = cardWidth * 1.56;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: mainAxisExtent,
                ),
                itemCount: featuredProducts.length,
                itemBuilder: (context, index) {
                  final product = featuredProducts[index];
                  final isWishlisted =
                      widget.wishlistRepo?.isWishlisted(product.id) ??
                          _wishlistProductIds.contains(product.id);
                  return FeaturedPhoneCard(
                    product: product,
                    isWishlisted: isWishlisted,
                    onTap: () => widget.onProductTap?.call(product),
                    onWishlistTap: () {
                      if (widget.wishlistRepo != null) {
                        widget.wishlistRepo!.toggleWishlist(product);
                      } else {
                        setState(() {
                          if (isWishlisted) {
                            _wishlistProductIds.remove(product.id);
                          } else {
                            _wishlistProductIds.add(product.id);
                          }
                        });
                      }
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
          final isSearching = _searchController.text.trim().isNotEmpty;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                minWidth: constraints.maxWidth,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1C7BFF)
                                  .withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.search_off_rounded,
                          size: 32,
                          color: Color(0xFF1C7BFF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No devices found',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(
                          isSearching
                              ? 'We couldn\'t find any devices matching "${_searchController.text.trim()}". Check spelling or try a different term.'
                              : 'There are currently no devices available in this category.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_searchController.text.isNotEmpty) {
                              _searchController.clear();
                              widget.viewModel.setSearchQuery('');
                            }
                            widget.viewModel.setCategory('All');
                          },
                          icon: Icon(
                            isSearching
                                ? Icons.clear_rounded
                                : Icons.grid_view_rounded,
                            size: 17,
                          ),
                          label: Text(
                            isSearching ? 'Clear Search' : 'Show All Devices',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
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
            _searchController.text.trim().isNotEmpty
                ? 'Results for "${_searchController.text.trim()}" (${products.length})'
                : '${widget.viewModel.selectedCategory} (${products.length})',
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
              final int crossAxisCount = width > 700 ? 4 : 2;
              final double cardWidth =
                  (width - 32 - (12 * (crossAxisCount - 1))) / crossAxisCount;
              final double mainAxisExtent = cardWidth * 1.56;

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: mainAxisExtent,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final isWishlisted =
                      widget.wishlistRepo?.isWishlisted(product.id) ??
                          _wishlistProductIds.contains(product.id);
                  return FeaturedPhoneCard(
                    product: product,
                    isWishlisted: isWishlisted,
                    onTap: () => widget.onProductTap?.call(product),
                    onWishlistTap: () {
                      if (widget.wishlistRepo != null) {
                        widget.wishlistRepo!.toggleWishlist(product);
                      } else {
                        setState(() {
                          if (isWishlisted) {
                            _wishlistProductIds.remove(product.id);
                          } else {
                            _wishlistProductIds.add(product.id);
                          }
                        });
                      }
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

  Widget _buildBenefitPill(IconData icon, String line1, String line2) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 12.5, color: const Color(0xFF0D62FE)),
        const SizedBox(width: 2.5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              line1,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            Text(
              line2,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 8,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDot(Color c) => Container(
        width: 3.5,
        height: 3.5,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  Widget _buildHeroBanner() {
    return Container(
      height: 204,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE4D6),
            Color(0xFFFFF5EE),
            Color(0xFFFFDBCD),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Protruding soft circle on far left
          Positioned(
            left: -22,
            top: 60,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFED7AA).withValues(alpha: 0.45),
              ),
            ),
          ),

          // 2. Soft pastel glow halo behind video on the right
          Positioned(
            right: -14,
            top: -6,
            child: Container(
              width: 175,
              height: 175,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFEDD5).withValues(alpha: 0.75),
                    const Color(0xFFFFEDD5).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 3. 2x3 colorful dot grid near top-middle
          Positioned(
            top: 14,
            left: 146,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(const Color(0xFFF97316)),
                    const SizedBox(width: 4),
                    _buildDot(const Color(0xFFA855F7)),
                    const SizedBox(width: 4),
                    _buildDot(const Color(0xFFF97316)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(const Color(0xFFA855F7)),
                    const SizedBox(width: 4),
                    _buildDot(const Color(0xFFF97316)),
                    const SizedBox(width: 4),
                    _buildDot(const Color(0xFFA855F7)),
                  ],
                ),
              ],
            ),
          ),

          // 4. Yellow sparkle star near top
          const Positioned(
            top: 12,
            left: 178,
            child: SizedBox(
              width: 13,
              height: 13,
              child: CustomPaint(
                painter: _SparkleStarPainter(
                  color: Color(0xFFFACC15),
                ),
              ),
            ),
          ),

          // 5. Floating tilted yellow capsule sprinkles
          Positioned(
            top: 76,
            left: 144,
            child: Transform.rotate(
              angle: 0.4,
              child: Container(
                width: 15,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE047).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          Positioned(
            top: 68,
            right: 14,
            child: Transform.rotate(
              angle: -0.6,
              child: Container(
                width: 17,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE047).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          // 6. Yellow sparkle star near bottom
          const Positioned(
            bottom: 12,
            left: 136,
            child: SizedBox(
              width: 12,
              height: 12,
              child: CustomPaint(
                painter: _SparkleStarPainter(
                  color: Color(0xFFFACC15),
                ),
              ),
            ),
          ),

          // 7. Soft circular dot at bottom
          Positioned(
            bottom: 6,
            left: 162,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFB923C).withValues(alpha: 0.7),
              ),
            ),
          ),

          // Main Layout Content Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                // Left Column: Tag, Title, Subtitle, Benefits Row, CTA Button
                Expanded(
                  flex: 10,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'PREMIUM CARE',
                            style: TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Premium care.\nMade simple.',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Protect, repair, and enjoy\nyour phone with confidence.',
                            style: TextStyle(
                              color: Color(0xFF475467),
                              fontSize: 11,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildBenefitPill(
                                Icons.shield_outlined,
                                'Screen',
                                'Protect',
                              ),
                              const SizedBox(width: 5),
                              _buildBenefitPill(
                                Icons.build_circle_outlined,
                                'OEM',
                                'Parts',
                              ),
                              const SizedBox(width: 5),
                              _buildBenefitPill(
                                Icons.verified_user_outlined,
                                '1 Year',
                                'Warranty',
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          GestureDetector(
                            onTap: () {
                              widget.onRepairsTap?.call();
                            },
                            child: Container(
                              height: 31,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D62FE),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0D62FE)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Explore Care',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Right Column: Video inside smartphone mockup frame with UP TO 40% OFF badge and Smarter Tech Brighter Days
                Expanded(
                  flex: 12,
                  child: Align(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 196,
                        height: 186,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Video Player inside tilted Smartphone frame
                            Center(
                              child: Transform.rotate(
                                angle: -0.065,
                                child: Container(
                                  width: 176,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E222A),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: const Color(0xFF282D37),
                                      width: 3.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.30),
                                        blurRadius: 12,
                                        offset: const Offset(2, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: const BannerVideoPlayer(
                                      isActive: true,
                                      aspectRatio: 16 / 10,
                                      autoReplay: true,
                                      replayDelay: Duration(seconds: 3),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Floating badge with speech tail at top-right
                            Positioned(
                              top: 6,
                              right: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFF5722),
                                          Color(0xFFE64A19),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF5722)
                                              .withValues(alpha: 0.45),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'UP TO',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                            height: 1.0,
                                          ),
                                        ),
                                        Text(
                                          '40%',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                            height: 1.05,
                                          ),
                                        ),
                                        Text(
                                          'OFF',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                            height: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: SizedBox(
                                      width: 8,
                                      height: 5,
                                      child: CustomPaint(
                                        painter: _SpeechBubbleTrianglePainter(
                                          color: Color(0xFFE64A19),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // "Smarter Tech Brighter Days" with curved doodle arrow at bottom-right
                            Positioned(
                              bottom: 4,
                              right: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Transform.rotate(
                                    angle: -0.07,
                                    child: const Text(
                                      'Smarter\nTech\nBrighter\nDays',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: Color(0xFFC2410C),
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 8.5,
                                        height: 1.05,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  const SizedBox(
                                    width: 22,
                                    height: 10,
                                    child: CustomPaint(
                                      painter: _CurvedDoodleArrowPainter(
                                        color: Color(0xFFEA580C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Sparkle star near Smarter Tech
                            const Positioned(
                              top: 48,
                              right: 6,
                              child: SizedBox(
                                width: 11,
                                height: 11,
                                child: CustomPaint(
                                  painter: _SparkleStarPainter(
                                    color: Color(0xFFFACC15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurvedDoodleArrowPainter extends CustomPainter {
  final Color color;
  const _CurvedDoodleArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width - 2, 2);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 3,
      3,
      size.height * 0.45,
    );
    canvas.drawPath(path, paint);

    final headPaint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final headPath = Path();
    headPath.moveTo(8, size.height * 0.2);
    headPath.lineTo(3, size.height * 0.45);
    headPath.lineTo(9, size.height * 0.7);
    canvas.drawPath(headPath, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SparkleStarPainter extends CustomPainter {
  final Color color;
  const _SparkleStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w / 2, 0);
    path.quadraticBezierTo(w / 2, h / 2, w, h / 2);
    path.quadraticBezierTo(w / 2, h / 2, w / 2, h);
    path.quadraticBezierTo(w / 2, h / 2, 0, h / 2);
    path.quadraticBezierTo(w / 2, h / 2, w / 2, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpeechBubbleTrianglePainter extends CustomPainter {
  final Color color;
  const _SpeechBubbleTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width * 0.25, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
