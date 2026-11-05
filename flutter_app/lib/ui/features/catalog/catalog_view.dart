import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/featured_phone_card.dart';
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
        final featuredProducts = (widget.viewModel.products.isNotEmpty
            ? [
                ...widget.viewModel.products.where((p) => p.isFeatured && p.isMerchandise),
                ...widget.viewModel.products.where((p) => !p.isFeatured && p.isMerchandise),
              ]
            : widget.viewModel.featuredProducts)
            .where((p) => p.isMerchandise)
            .toList();

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

              const SizedBox(height: 10),

              // Department Quick Category Cards Row (as in image 1)
              _buildCategoryShortcuts(),

              const SizedBox(height: 8),

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
          // Featured section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Flexible(
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
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/images/ic_fire.png',
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                    ],
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



  Widget _buildCategoryShortcuts() {
    const shortcuts = [
      _CategoryShortcutItem(
        label: 'Phones',
        targetCategory: 'Phones',
        assetPath: 'assets/images/cat_phones.png',
        fallbackIcon: Icons.phone_iphone_rounded,
      ),
      _CategoryShortcutItem(
        label: 'Tablets',
        targetCategory: 'Tablets',
        assetPath: 'assets/images/cat_tablets.png',
        fallbackIcon: Icons.tablet_mac_rounded,
      ),
      _CategoryShortcutItem(
        label: 'Wearables',
        targetCategory: 'Wearables',
        assetPath: 'assets/images/cat_wearables.png',
        fallbackIcon: Icons.watch_rounded,
      ),
      _CategoryShortcutItem(
        label: 'Tech',
        targetCategory: 'Accessories',
        assetPath: 'assets/images/cat_tech.png',
        fallbackIcon: Icons.headphones_rounded,
      ),
      _CategoryShortcutItem(
        label: 'Consoles',
        targetCategory: 'Consoles',
        assetPath: 'assets/images/cat_consoles.png',
        fallbackIcon: Icons.sports_esports_rounded,
      ),
      _CategoryShortcutItem(
        label: 'Macbooks',
        targetCategory: 'Laptops',
        assetPath: 'assets/images/cat_macbooks.png',
        fallbackIcon: Icons.laptop_mac_rounded,
      ),
      _CategoryShortcutItem(
        label: 'Covers',
        targetCategory: 'Covers',
        assetPath: 'assets/images/cat_covers.png',
        fallbackIcon: Icons.shield_rounded,
      ),
      _CategoryShortcutItem(
        label: 'Keyboards',
        targetCategory: 'Keyboards',
        assetPath: 'assets/images/cat_keyboards.png',
        fallbackIcon: Icons.keyboard_rounded,
      ),
    ];

    return SizedBox(
      height: 94,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: shortcuts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = shortcuts[index];
          final isSelected =
              widget.viewModel.selectedCategory.toLowerCase() ==
                  item.targetCategory.toLowerCase() ||
              (item.targetCategory == 'Accessories' &&
                  widget.viewModel.selectedCategory.toLowerCase() == 'tech') ||
              (item.targetCategory == 'Laptops' &&
                  widget.viewModel.selectedCategory.toLowerCase() == 'macbooks');

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (isSelected) {
                  widget.viewModel.setCategory('All');
                } else {
                  widget.viewModel.setCategory(item.targetCategory);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 86,
                height: 90,
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1C7BFF)
                        : const Color(0xFFE5E7EB),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Image.asset(
                          item.assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            item.fallbackIcon,
                            size: 28,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1C7BFF)
                            : const Color(0xFF1E2432),
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryShortcutItem {
  final String label;
  final String targetCategory;
  final String assetPath;
  final IconData fallbackIcon;

  const _CategoryShortcutItem({
    required this.label,
    required this.targetCategory,
    required this.assetPath,
    required this.fallbackIcon,
  });
}