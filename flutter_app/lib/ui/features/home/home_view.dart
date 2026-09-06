import 'dart:async';

import 'package:flutter/material.dart';
import '../../../domain/models/product.dart';
import 'home_view_model.dart';

class _HeroPromotion {
  final String title;
  final String description;
  final String primaryAction;
  final Color backgroundColor;

  const _HeroPromotion({
    required this.title,
    required this.description,
    required this.primaryAction,
    required this.backgroundColor,
  });
}

class HomeView extends StatefulWidget {
  final HomeViewModel viewModel;
  final Function(Product) onProductTap;
  final VoidCallback onSeeAllCatalog;
  final VoidCallback onTradeInTap;
  final VoidCallback onRepairsTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onLocationsTap;
  final VoidCallback onSupportTap;
  final VoidCallback onProfileTap;

  const HomeView({
    super.key,
    required this.viewModel,
    required this.onProductTap,
    required this.onSeeAllCatalog,
    required this.onTradeInTap,
    required this.onRepairsTap,
    required this.onOrdersTap,
    required this.onLocationsTap,
    required this.onSupportTap,
    required this.onProfileTap,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const _heroSlideInterval = Duration(seconds: 5);
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _heroPromotions = [
    _HeroPromotion(
      title: 'Discover the\nLatest Smartphones',
      description: 'Shop flagship devices at\nunbeatable prices.',
      primaryAction: 'Shop Now',
      backgroundColor: Color(0xFFDDECFB),
    ),
    _HeroPromotion(
      title: 'Save up to 20%\non flagship phones',
      description: 'Limited-time prices on the\ndevices you want most.',
      primaryAction: 'View Offers',
      backgroundColor: Color(0xFFE9E4FA),
    ),
    _HeroPromotion(
      title: 'Trade in. Upgrade.\nPay less.',
      description: 'Turn your current phone into\ninstant upgrade credit.',
      primaryAction: 'Trade In',
      backgroundColor: Color(0xFFDDF5E8),
    ),
    _HeroPromotion(
      title: 'Premium care.\nMade simple.',
      description: 'Protect, repair, and enjoy\nyour phone with confidence.',
      primaryAction: 'Explore Care',
      backgroundColor: Color(0xFFFFE9DD),
    ),
  ];

  late final PageController _heroPageController;
  Timer? _heroTimer;
  int _activeHeroIndex = 0;

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController();
    widget.viewModel.loadData();
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF3F4F6),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF1C7BFF)),
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: _buildAppBar(),
          drawer: _buildMenuDrawer(),
          body: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF1C7BFF),
                  backgroundColor: Colors.white,
                  onRefresh: () => widget.viewModel.loadData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildSearchBar(),
                        const SizedBox(height: 18),
                        _buildHeroBanner(),
                        const SizedBox(height: 24),
                        _buildBrandRow(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Featured Phones', 'View all'),
                        const SizedBox(height: 12),
                        _buildFeaturedGrid(),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: _buildBenefitsRow(),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF3F4F6),
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Open menu',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu, color: Color(0xFF1F2937), size: 28),
            ),
            const SizedBox(width: 8),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF1F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(Icons.phone_android_rounded,
                  size: 18, color: Color(0xFF1F2937)),
            ),
            const SizedBox(width: 10),
            const Text(
              'SiakaPhones',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
            const Spacer(),
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded,
                    color: Color(0xFF1F2937), size: 28),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1C7BFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('2',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 18),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Menu',
                      style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close menu',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _menuItem(Icons.search_rounded, 'Browse phones',
                      widget.onSeeAllCatalog),
                  _menuItem(Icons.receipt_long_outlined, 'My orders',
                      widget.onOrdersTap),
                  _menuItem(
                      Icons.build_outlined, 'Repairs', widget.onRepairsTap),
                  _menuItem(Icons.swap_horiz_rounded, 'Trade in',
                      widget.onTradeInTap),
                  _menuItem(Icons.location_on_outlined, 'Store locations',
                      widget.onLocationsTap),
                  _menuItem(Icons.help_outline_rounded, 'Support',
                      widget.onSupportTap),
                  const Divider(height: 28),
                  _menuItem(Icons.person_outline_rounded, 'My profile',
                      widget.onProfileTap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1C7BFF)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        Navigator.of(context).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) => onTap());
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE1E5EA)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: Color(0xFF8A93A6), size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Search for phones, accessories...',
                style: TextStyle(
                  color: Color(0xFF8A93A6),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6E8ED)),
              ),
              child: const Icon(Icons.tune_rounded,
                  size: 18, color: Color(0xFF1F2937)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    final products = widget.viewModel.featuredProducts;
    return Column(
      children: [
        SizedBox(
          height: 282,
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
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _heroPromotions.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _activeHeroIndex == index ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _activeHeroIndex == index
                    ? const Color(0xFF1C7BFF)
                    : const Color(0xFFB8C0CC),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSlide(
    _HeroPromotion promotion,
    List<Product> products,
    int index,
  ) {
    final primaryProduct =
        products.isEmpty ? null : products[index % products.length];
    final secondaryProduct =
        products.length < 2 ? null : products[(index + 1) % products.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: promotion.backgroundColor,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(promotion.title,
                    style: const TextStyle(
                        color: Color(0xFF1B1F2A),
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.06,
                        letterSpacing: -1.0)),
                const SizedBox(height: 14),
                Text(promotion.description,
                    style: const TextStyle(
                        color: Color(0xFF485569),
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: primaryProduct == null
                        ? null
                        : () => widget.onProductTap(primaryProduct),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C7BFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: Text(
                      promotion.primaryAction,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (secondaryProduct != null)
                  Positioned(
                    left: 10,
                    bottom: 0,
                    child: _buildHeroProductImage(
                      secondaryProduct,
                      110,
                      150,
                      18,
                    ),
                  ),
                if (primaryProduct != null)
                  _buildHeroProductImage(primaryProduct, 160, 210, 26),
              ],
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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 16),
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
  }

  Widget _buildBrandRow() {
    final brands = [
      {
        'name': 'Apple',
        'icon': Icons.apple,
        'isIcon': true,
        'bg': const Color(0xFFF2F4F7),
        'textColor': const Color(0xFF111827),
      },
      {
        'name': 'Samsung',
        'icon': 'S',
        'isIcon': false,
        'bg': const Color(0xFFF2F4F7),
        'textColor': const Color(0xFF111827),
      },
      {
        'name': 'Google',
        'icon': 'G',
        'isIcon': false,
        'bg': const Color(0xFFF2F4F7),
        'textColor': const Color(0xFF111827),
      },
      {
        'name': 'OnePlus',
        'icon': '1+',
        'isIcon': false,
        'bg': const Color(0xFFF2F4F7),
        'textColor': const Color(0xFF111827),
      },
      {
        'name': 'Xiaomi',
        'icon': 'MI',
        'isIcon': false,
        'bg': const Color(0xFFF2F4F7),
        'textColor': const Color(0xFF111827),
      },
    ];

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shop by Brand',
                style: TextStyle(
                  color: Color(0xFF1E2432),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'View all',
                style: TextStyle(
                  color: Color(0xFF1C7BFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              final isIcon = brand['isIcon'] as bool;
              return Container(
                decoration: BoxDecoration(
                  color: brand['bg'] as Color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isIcon)
                      Icon(
                        brand['icon'] as IconData,
                        size: 26,
                        color: brand['textColor'] as Color,
                      )
                    else
                      Text(
                        brand['icon'] as String,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: brand['textColor'] as Color,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      brand['name'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String actionLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E2432),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            actionLabel,
            style: const TextStyle(
              color: Color(0xFF1C7BFF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedGrid() {
    final items = widget.viewModel.featuredProducts;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 208,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final product = items[index];
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C7BFF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('New',
                        style: TextStyle(
                            color: Color(0xFF1C7BFF),
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                  const Icon(Icons.favorite_border,
                      color: Color(0xFF7A8194), size: 17),
                ],
              ),
              const SizedBox(height: 5),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    product.images.first,
                    height: 68,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 68,
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(Icons.phone_android,
                          size: 30, color: Colors.black54),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.star, size: 12, color: Color(0xFFFFC107)),
                  const SizedBox(width: 2),
                  Text(
                    '${product.rating}',
                    style: const TextStyle(
                        color: Color(0xFF525F73),
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '₵${product.price.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w800,
                    fontSize: 13),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 28,
                child: ElevatedButton(
                  onPressed: () => widget.onProductTap(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C7BFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 13),
                      SizedBox(width: 4),
                      Text('Buy Now',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildBenefitsRow() {
    final benefits = [
      {
        'icon': Icons.local_shipping_outlined,
        'title': 'Free Shipping',
        'sub': 'On orders over ₵50'
      },
      {
        'icon': Icons.verified_outlined,
        'title': '1 Year Warranty',
        'sub': 'Official warranty'
      },
      {
        'icon': Icons.assignment_return_outlined,
        'title': '14-Day Returns',
        'sub': 'Easy returns'
      },
      {
        'icon': Icons.shield_outlined,
        'title': 'Secure Payments',
        'sub': '100% safe & secure'
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: benefits.map((item) {
          final icon = item['icon'] as IconData;
          final title = item['title'] as String;
          final sub = item['sub'] as String;

          return Expanded(
            child: Row(
              children: [
                Icon(icon, size: 22, color: const Color(0xFF1C7BFF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937))),
                      Text(sub,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF7A8194))),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
