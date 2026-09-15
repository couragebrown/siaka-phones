import 'dart:async';

import 'package:flutter/material.dart';
import '../../../domain/models/product.dart';
import '../../../data/repositories/wishlist_repository.dart';
import '../../core/widgets/brand_logo.dart';
import '../notifications/notifications_view.dart';
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
  final VoidCallback? onSeeAllBrands;
  final Function(String brand)? onBrandTap;
  final VoidCallback onTradeInTap;
  final VoidCallback onRepairsTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onLocationsTap;
  final VoidCallback onSupportTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onBuyNowPayLaterTap;
  final VoidCallback? onSignOut;

  const HomeView({
    super.key,
    required this.viewModel,
    required this.onProductTap,
    required this.onSeeAllCatalog,
    this.onSeeAllBrands,
    this.onBrandTap,
    required this.onTradeInTap,
    required this.onRepairsTap,
    required this.onOrdersTap,
    required this.onLocationsTap,
    required this.onSupportTap,
    required this.onProfileTap,
    this.onBuyNowPayLaterTap,
    this.onSignOut,
    this.wishlistRepo,
  });

  final WishlistRepository? wishlistRepo;

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

  final Set<String> _wishlistProductIds = {'phone-1'};
  late final PageController _heroPageController;
  Timer? _heroTimer;
  int _activeHeroIndex = 0;

  String _formatFeaturedPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return 'From \$$formatted';
  }

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
      listenable: Listenable.merge([
        widget.viewModel,
        if (widget.wishlistRepo != null) widget.wishlistRepo!,
      ]),
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
          body: RefreshIndicator(
            color: const Color(0xFF1C7BFF),
            backgroundColor: Colors.white,
            onRefresh: () => widget.viewModel.loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildHeroBanner(),
                  const SizedBox(height: 18),
                  _buildBrandRow(),
                  const SizedBox(height: 24),
                  _buildFeaturedByBrand(),
                ],
              ),
            ),
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
            const Expanded(
              child: Text(
                'SiakaPhones',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsView(),
                ),
              ),
              child: Stack(
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
              ),
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
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C7BFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF1C7BFF),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Menu',
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Account & Services',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close menu',
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  _menuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'My Profile',
                    onTap: widget.onProfileTap,
                  ),
                  _menuItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'My Orders',
                    onTap: widget.onOrdersTap,
                  ),
                  _menuItem(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Swap My Device',
                    onTap: widget.onTradeInTap,
                  ),
                  _menuItem(
                    icon: Icons.payments_outlined,
                    label: 'Buy Now Pay Later',
                    badgeText: '0% APR',
                    onTap: () {
                      if (widget.onBuyNowPayLaterTap != null) {
                        widget.onBuyNowPayLaterTap!();
                      } else {
                        _showBuyNowPayLaterSheet();
                      }
                    },
                  ),
                  _menuItem(
                    icon: Icons.build_outlined,
                    label: 'Repairs',
                    onTap: widget.onRepairsTap,
                  ),
                  _menuItem(
                    icon: Icons.location_on_outlined,
                    label: 'Store Locations',
                    onTap: widget.onLocationsTap,
                  ),
                  _menuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Support',
                    onTap: widget.onSupportTap,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _menuItem(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                isDestructive: true,
                onTap: () {
                  widget.onSignOut?.call();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? badgeText,
    bool isDestructive = false,
  }) {
    final textColor =
        isDestructive ? const Color(0xFFDC2626) : const Color(0xFF1F2937);
    final iconColor =
        isDestructive ? const Color(0xFFDC2626) : const Color(0xFF1C7BFF);
    final iconBgColor = isDestructive
        ? const Color(0xFFFEE2E2)
        : const Color(0xFF1C7BFF).withValues(alpha: 0.08);

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13.5,
                fontWeight: isDestructive ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      trailing: isDestructive
          ? null
          : const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF9CA3AF),
            ),
      onTap: () {
        Navigator.of(context).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) => onTap());
      },
    );
  }

  void _showBuyNowPayLaterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: Color(0xFF1C7BFF),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buy Now, Pay Later',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            '0% APR Financing with Siaka Pay',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Upgrade to your dream smartphone today and spread the cost comfortably over time with simple, transparent terms.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _bnplBenefit(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Pay in 4 Installments',
                  subtitle:
                      'Split into 4 equal bi-weekly payments. 0% interest and no hidden fees.',
                ),
                const SizedBox(height: 10),
                _bnplBenefit(
                  icon: Icons.bolt_rounded,
                  title: 'Instant Decision',
                  subtitle:
                      'Fast digital approval in seconds without affecting your credit score.',
                ),
                const SizedBox(height: 10),
                _bnplBenefit(
                  icon: Icons.calendar_month_outlined,
                  title: 'Flexible Monthly Terms',
                  subtitle:
                      'Spread larger purchases over 6 to 12 months with low monthly rates.',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C7BFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      widget.onSeeAllCatalog();
                    },
                    child: const Text(
                      'Browse Eligible Phones',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bnplBenefit({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF1C7BFF), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF6B7280),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: widget.onSeeAllCatalog,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE1E5EA)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, color: Color(0xFF8A93A6), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Search for phones, accessories...',
                  style: TextStyle(
                    color: Color(0xFF8A93A6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 6),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFFE6E8ED)),
                ),
                child: const Icon(Icons.tune_rounded,
                    size: 16, color: Color(0xFF1F2937)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    final products = widget.viewModel.featuredProducts;
    return Column(
      children: [
        SizedBox(
          height: 160,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: promotion.backgroundColor,
        borderRadius: BorderRadius.circular(10),
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
                          backgroundColor: const Color(0xFF1C7BFF),
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
                            fontSize: 12,
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
          Expanded(
            flex: 9,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                if (secondaryProduct != null)
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: _buildHeroProductImage(
                      secondaryProduct,
                      70,
                      96,
                      10,
                    ),
                  ),
                if (primaryProduct != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: _buildHeroProductImage(
                      primaryProduct,
                      96,
                      126,
                      14,
                    ),
                  ),
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
  }

  Widget _buildBrandRow() {
    final brands = [
      'Apple',
      'Samsung',
      'Google',
      'OnePlus',
      'Xiaomi',
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Shop by Brand',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF1E2432),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                onTap: widget.onSeeAllBrands,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'View more',
                    style: TextStyle(
                      color: Color(0xFF1C7BFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
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
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brandName = brands[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.onBrandTap?.call(brandName),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 26,
                            child: Center(
                              child: BrandLogo(brand: brandName),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            brandName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1E2432),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          InkWell(
            onTap: widget.onSeeAllCatalog,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Color(0xFF1C7BFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Groups featured products by brand and renders each group as a
  /// horizontally-scrollable row with 3 cards visible at a time,
  /// with the brand name shown as a label above each row.
  Widget _buildFeaturedByBrand() {
    final items = widget.viewModel.featuredProducts;

    // Group products by brand, preserving insertion order.
    final Map<String, List<Product>> byBrand = {};
    for (final p in items) {
      byBrand.putIfAbsent(p.brand, () => []).add(p);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with "Featured Phones" title + View all link
        _buildSectionHeader('Featured Phones', 'View all'),
        const SizedBox(height: 14),
        // One horizontal-scroll row per brand
        ...byBrand.entries.map((entry) {
          final brand = entry.key;
          final products = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand label
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C7BFF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        brand,
                        style: const TextStyle(
                          color: Color(0xFF1E2432),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${products.length} phones',
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Horizontal scroll list — 3 cards visible at a time
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Card width = screen width / 3 minus padding/spacing
                    final cardWidth =
                        (constraints.maxWidth - 32 - 20) / 3;
                    return SizedBox(
                      height: 240,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: products.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          return SizedBox(
                            width: cardWidth,
                            child: _buildCompactFeaturedCard(
                                products[i]),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Compact card for the 3-per-row horizontal brand sections.
  Widget _buildCompactFeaturedCard(Product product) {
    final isWishlisted = widget.wishlistRepo?.isWishlisted(product.id) ??
        _wishlistProductIds.contains(product.id);

    return GestureDetector(
      onTap: () => widget.onProductTap(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge + wishlist row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C7BFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'New',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
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
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isWishlisted
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isWishlisted
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFCBD5E1),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            // Phone graphic — takes remaining space
            Expanded(
              child: Center(
                child: _buildProductPhoneGraphic(product),
              ),
            ),
            const SizedBox(height: 4),
            // Name
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 2),
            // Price
            Text(
              _formatFeaturedPrice(product.price),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            // Rating: Star 4.8 (245)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 12, color: Color(0xFFFFA000)),
                  const SizedBox(width: 2),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '(${product.reviewCount})',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Buy Now button with cart icon
            SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                onPressed: () => widget.onProductTap(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C7BFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 13,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPhoneGraphic(Product product) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 100.0;
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 100.0;
        final availableHeight = maxH.clamp(40.0, 140.0);
        final availableWidth = maxW.clamp(40.0, 160.0);
        return SizedBox(
          width: availableWidth,
          height: availableHeight,
          child: CustomPaint(
            painter: _PhoneMockupPainter(
              brand: product.brand,
              name: product.name,
            ),
          ),
        );
      },
    );
  }
}

class _PhoneMockupPainter extends CustomPainter {
  final String brand;
  final String name;

  const _PhoneMockupPainter({
    required this.brand,
    required this.name,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bool isApple = brand.toLowerCase() == 'apple' || name.toLowerCase().contains('iphone');
    final bool isSamsung = brand.toLowerCase() == 'samsung' || name.toLowerCase().contains('galaxy');

    final center = Offset(size.width / 2, size.height / 2);
    final phoneWidth = size.width * 0.46;
    final phoneHeight = size.height * 0.94;
    final cornerRadius = isSamsung ? 5.0 : 13.0;

    // 1. Back Phone (positioned on the left side)
    final backLeft = center.dx - phoneWidth * 0.88;
    final backTop = center.dy - phoneHeight / 2;
    final backRect = Rect.fromLTWH(backLeft, backTop, phoneWidth, phoneHeight);
    final backRRect = RRect.fromRectAndRadius(backRect, Radius.circular(cornerRadius));

    // Shadow for back phone
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(backRRect.shift(const Offset(0, 3)), shadowPaint);

    // Back body gradient
    final Color backColorTop = isApple
        ? const Color(0xFF3F4653)
        : (isSamsung ? const Color(0xFF383E48) : const Color(0xFF374151));
    final Color backColorBottom = isApple
        ? const Color(0xFF22262F)
        : (isSamsung ? const Color(0xFF1E222A) : const Color(0xFF1F2937));

    final backBodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [backColorTop, backColorBottom],
      ).createShader(backRect);
    canvas.drawRRect(backRRect, backBodyPaint);

    // Back phone rim highlight
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.18);
    canvas.drawRRect(backRRect, rimPaint);

    // Camera module on back phone
    if (isApple) {
      final islandWidth = phoneWidth * 0.52;
      final islandHeight = islandWidth;
      final islandRect = Rect.fromLTWH(backLeft + 4, backTop + 4, islandWidth, islandHeight);
      final islandRRect = RRect.fromRectAndRadius(islandRect, const Radius.circular(8));

      final islandPaint = Paint()..color = const Color(0xFF1E222A);
      canvas.drawRRect(islandRRect, islandPaint);
      final islandStroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.12);
      canvas.drawRRect(islandRRect, islandStroke);

      final lensRadius = islandWidth * 0.20;
      final lensCenters = [
        Offset(islandRect.left + islandWidth * 0.32, islandRect.top + islandHeight * 0.30),
        Offset(islandRect.left + islandWidth * 0.32, islandRect.top + islandHeight * 0.70),
        Offset(islandRect.left + islandWidth * 0.70, islandRect.top + islandHeight * 0.50),
      ];

      for (final lc in lensCenters) {
        final ringPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF7B8496);
        canvas.drawCircle(lc, lensRadius, ringPaint);

        final glassPaint = Paint()..color = const Color(0xFF090B0E);
        canvas.drawCircle(lc, lensRadius - 0.6, glassPaint);

        final highlightPaint = Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.45);
        canvas.drawCircle(Offset(lc.dx - 1.2, lc.dy - 1.2), lensRadius * 0.35, highlightPaint);
      }

      // Flash & LiDAR
      final flashCenter = Offset(islandRect.left + islandWidth * 0.72, islandRect.top + islandHeight * 0.24);
      canvas.drawCircle(flashCenter, 2.0, Paint()..color = const Color(0xFFFEF3C7));

      final lidarCenter = Offset(islandRect.left + islandWidth * 0.72, islandRect.top + islandHeight * 0.76);
      canvas.drawCircle(lidarCenter, 1.8, Paint()..color = const Color(0xFF111418));

      // Apple logo in center of back phone
      final logoCenter = Offset(backLeft + phoneWidth / 2, backTop + phoneHeight * 0.52);
      final logoPaint = Paint()..color = const Color(0xFF8E97A8).withValues(alpha: 0.75);
      canvas.drawCircle(logoCenter, 4.2, logoPaint);
      canvas.drawCircle(Offset(logoCenter.dx + 3.0, logoCenter.dy - 0.5), 2.0, Paint()..color = backColorBottom);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(logoCenter.dx + 0.8, logoCenter.dy - 5.5), width: 2.2, height: 1.4),
        logoPaint,
      );
    } else {
      final lensX = backLeft + 8.0;
      for (int i = 0; i < 3; i++) {
        final lc = Offset(lensX, backTop + 12.0 + (i * 14.0));
        canvas.drawCircle(lc, 4.5, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = const Color(0xFF7B8496));
        canvas.drawCircle(lc, 3.8, Paint()..color = const Color(0xFF090B0E));
        canvas.drawCircle(Offset(lc.dx - 1, lc.dy - 1), 1.5, Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.4));
      }
    }

    // 2. Front Phone (positioned on the right, overlapping front)
    final frontLeft = center.dx - phoneWidth * 0.12;
    final frontTop = center.dy - phoneHeight / 2;
    final frontRect = Rect.fromLTWH(frontLeft, frontTop, phoneWidth, phoneHeight);
    final frontRRect = RRect.fromRectAndRadius(frontRect, Radius.circular(cornerRadius));

    // Shadow for front phone
    canvas.drawRRect(frontRRect.shift(const Offset(0, 4)), shadowPaint);

    // Frame/bezel
    final framePaint = Paint()..color = const Color(0xFF11151D);
    canvas.drawRRect(frontRRect, framePaint);
    canvas.drawRRect(frontRRect, rimPaint);

    // OLED Screen
    const screenInset = 2.0;
    final screenRect = Rect.fromLTWH(
      frontLeft + screenInset,
      frontTop + screenInset,
      phoneWidth - screenInset * 2,
      phoneHeight - screenInset * 2,
    );
    final screenRRect = RRect.fromRectAndRadius(screenRect, Radius.circular(cornerRadius - 1.5));

    canvas.save();
    canvas.clipRRect(screenRRect);

    // Screen dark background
    canvas.drawPaint(Paint()..color = const Color(0xFF070B13));

    // Luminous organic blue wave wallpaper (iPhone 15 Pro signature ribbon)
    final wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFF1E3A8A).withValues(alpha: 0.95),
          const Color(0xFF2563EB),
          const Color(0xFF60A5FA),
          const Color(0xFF0284C7).withValues(alpha: 0.4),
        ],
      ).createShader(screenRect);

    final wavePath = Path();
    wavePath.moveTo(screenRect.right + 10, screenRect.top + screenRect.height * 0.18);
    wavePath.cubicTo(
      screenRect.left + screenRect.width * 0.15,
      screenRect.top + screenRect.height * 0.35,
      screenRect.right - screenRect.width * 0.05,
      screenRect.top + screenRect.height * 0.65,
      screenRect.left - 10,
      screenRect.bottom - screenRect.height * 0.10,
    );
    wavePath.lineTo(screenRect.right + 10, screenRect.bottom + 10);
    wavePath.close();

    canvas.drawPath(wavePath, wavePaint);

    // Dynamic Island / Notch
    final islandW = phoneWidth * 0.38;
    const islandH = 5.2;
    final islandL = frontLeft + (phoneWidth - islandW) / 2;
    final islandT = frontTop + 4.5;
    final dynIslandRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(islandL, islandT, islandW, islandH),
      const Radius.circular(2.6),
    );
    canvas.drawRRect(dynIslandRRect, Paint()..color = Colors.black);

    // Home indicator at bottom
    final homeW = phoneWidth * 0.45;
    const homeH = 1.8;
    final homeL = frontLeft + (phoneWidth - homeW) / 2;
    final homeT = frontTop + phoneHeight - 6.0;
    final homeRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(homeL, homeT, homeW, homeH),
      const Radius.circular(0.9),
    );
    canvas.drawRRect(homeRRect, Paint()..color = Colors.white.withValues(alpha: 0.7));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PhoneMockupPainter oldDelegate) {
    return oldDelegate.brand != brand || oldDelegate.name != name;
  }
}
