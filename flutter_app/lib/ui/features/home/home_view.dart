import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../domain/models/product.dart';
import '../../../data/repositories/wishlist_repository.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/running_light_arrow.dart';
import '../../core/widgets/banner_video_player.dart';
import '../../core/widgets/flash_sale_promo_banner.dart';
import '../../core/widgets/ai_customer_service_pill.dart';
import '../brands/brands_view.dart';
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
  final ValueChanged<String>? onCategoryTap;
  final VoidCallback? onBuyNowPayLaterTap;
  final VoidCallback? onSignOut;
  final bool isCurrentTab;

  const HomeView({
    super.key,
    required this.viewModel,
    required this.onProductTap,
    required this.onSeeAllCatalog,
    this.onSeeAllBrands,
    this.onBrandTap,
    this.onCategoryTap,
    required this.onTradeInTap,
    required this.onRepairsTap,
    required this.onOrdersTap,
    required this.onLocationsTap,
    required this.onSupportTap,
    required this.onProfileTap,
    this.onBuyNowPayLaterTap,
    this.onSignOut,
    this.wishlistRepo,
    this.isCurrentTab = true,
  });

  final WishlistRepository? wishlistRepo;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const _heroSlideInterval = Duration(seconds: 5);
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isAiHelpVisible = false;
  Timer? _aiHelpHideTimer;

  void _triggerAiHelpVisibility() {
    if (!_isAiHelpVisible) {
      setState(() {
        _isAiHelpVisible = true;
      });
    }
    _aiHelpHideTimer?.cancel();
    _aiHelpHideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isAiHelpVisible = false;
        });
      }
    });
  }

  void _closeMenuDrawer() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  @override
  void didUpdateWidget(HomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isCurrentTab && oldWidget.isCurrentTab) {
      _closeMenuDrawer();
      _aiHelpHideTimer?.cancel();
      _isAiHelpVisible = false;
    } else if (widget.isCurrentTab && !oldWidget.isCurrentTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
          _closeMenuDrawer();
        }
      });
    }
  }

  static const _heroPromotions = [
    _HeroPromotion(
      title: 'Discover the\nLatest Smartphones',
      description: 'Shop flagship devices at\nunbeatable prices.',
      primaryAction: 'Shop Now',
      backgroundColor: Color(0xFFDDECFB),
    ),
    _HeroPromotion(
      title: 'Save up to 20%\non flagship phones',
      description: 'Shop flagship devices at\nunbeatable prices.',
      primaryAction: 'Explore Deals',
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
    return 'From ₵$formatted';
  }

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController();
    widget.viewModel.loadData();
    // First banner (index 0) has a promotional video; it advances when the video ends.
    // If starting on a non-video banner, start the 5-second timer.
    if (_activeHeroIndex != 0) {
      _heroTimer = Timer(_heroSlideInterval, _advanceHero);
    }
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPageController.dispose();
    _aiHelpHideTimer?.cancel();
    super.dispose();
  }

  void _onHeroPageChanged(int index) {
    setState(() => _activeHeroIndex = index);
    _heroTimer?.cancel();
    if (index != 0) {
      // Banners 1, 2, 3 advance on standard 5-second interval
      _heroTimer = Timer(_heroSlideInterval, _advanceHero);
    }
    // Banner 0 holds until video completion triggers _onBannerVideoCompleted
  }

  void _onBannerVideoCompleted() {
    if (!mounted || _activeHeroIndex != 0) return;
    _advanceHero();
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
        if (widget.viewModel.isLoading &&
            widget.viewModel.featuredProducts.isEmpty) {
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
          body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is UserScrollNotification) {
                if (notification.direction == ScrollDirection.forward) {
                  _triggerAiHelpVisibility();
                }
              } else if (notification is ScrollUpdateNotification) {
                final delta = notification.scrollDelta ?? 0;
                if (delta < -6.0 && !_isAiHelpVisible) {
                  _triggerAiHelpVisibility();
                }
              }
              return false;
            },
            child: Stack(
              children: [
                RefreshIndicator(
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
                        const SizedBox(height: 16),
                        _buildHeroBanner(),
                        const SizedBox(height: 18),
                        _buildBrandRow(),
                        const SizedBox(height: 24),
                        _buildFeaturedByBrand(),
                      ],
                    ),
                  ),
                ),

                // Floating Customer Service AI Pill on the bottom right
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: AiCustomerServicePill(
                    isVisible: _isAiHelpVisible,
                    onTap: widget.onSupportTap,
                  ),
                ),
              ],
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
      toolbarHeight: 50,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Open menu',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              onPressed: () {
                if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                  _closeMenuDrawer();
                } else {
                  _scaffoldKey.currentState?.openDrawer();
                }
              },
              icon: const Icon(Icons.menu, color: Color(0xFF1F2937), size: 25),
            ),
            const SizedBox(width: 8),
            Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8CD4FF),
                    Color(0xFFC4E8FF),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8CD4FF).withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const CustomPaint(
                painter: _HeaderPhoneBadgePainter(),
              ),
            ),
            const SizedBox(width: 7),
            const Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Siaka',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(
                      text: 'Phones',
                      style: TextStyle(
                        color: Color(0xFF1D70FE),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                      color: Color(0xFF1F2937), size: 25),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1C7BFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('2',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
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

  Widget _buildDrawerCategorySelector() {
    final mainCategories = [
      (
        category: 'Smartphones',
        icon: Icons.phone_android_rounded,
        subtitle: 'Flagship & 5G',
        color: const Color(0xFF1C7BFF),
      ),
      (
        category: 'Keypad Phones',
        icon: Icons.dialpad_rounded,
        subtitle: 'Nokia & Itel',
        color: const Color(0xFF10B981),
      ),
      (
        category: 'Laptops',
        icon: Icons.laptop_mac_rounded,
        subtitle: 'MacBooks & Dell',
        color: const Color(0xFF8B5CF6),
      ),
      (
        category: 'Accessories',
        icon: Icons.headphones_rounded,
        subtitle: 'Audio & Power',
        color: const Color(0xFFF59E0B),
      ),
    ];

    final moreCategories = [
      (category: 'All Products', icon: Icons.grid_view_rounded),
      (category: 'Tablets', icon: Icons.tablet_mac_rounded),
      (category: 'UK Used', icon: Icons.verified_rounded),
      (category: 'Wearables', icon: Icons.watch_rounded),
      (category: 'Foldables', icon: Icons.devices_fold_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2x2 Grid for the top 4 requested categories
          Row(
            children: [
              Expanded(child: _buildCategoryCard(mainCategories[0])),
              const SizedBox(width: 8),
              Expanded(child: _buildCategoryCard(mainCategories[1])),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildCategoryCard(mainCategories[2])),
              const SizedBox(width: 8),
              Expanded(child: _buildCategoryCard(mainCategories[3])),
            ],
          ),
          const SizedBox(height: 8),
          // Horizontal scrolling row for more categories
          SizedBox(
            height: 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: moreCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final item = moreCategories[index];
                final isSelected =
                    widget.viewModel.selectedCategory == item.category ||
                    (item.category == 'All Products' &&
                        (widget.viewModel.selectedCategory == 'All' ||
                            widget.viewModel.selectedCategory == 'All Products'));
                return InkWell(
                  onTap: () {
                    _closeMenuDrawer();
                    final cat = item.category == 'All Products'
                        ? 'All'
                        : item.category;
                    widget.viewModel.selectCategory(cat);
                    widget.onCategoryTap?.call(cat);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1C7BFF)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1C7BFF)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 13,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.category,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF334155),
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(({
    String category,
    IconData icon,
    String subtitle,
    Color color
  }) item) {
    final isSelected = widget.viewModel.selectedCategory == item.category;

    return InkWell(
      onTap: () {
        _closeMenuDrawer();
        widget.viewModel.selectCategory(item.category);
        widget.onCategoryTap?.call(item.category);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? item.color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? item.color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(item.icon, size: 16, color: item.color),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.category,
                      maxLines: 1,
                      style: TextStyle(
                        color: const Color(0xFF1E293B),
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w400,
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

  Widget _menuSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
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
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
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
                          'Shop & Account Services',
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
                    onPressed: _closeMenuDrawer,
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _menuSectionHeader('Shop by Category'),
                    _buildDrawerCategorySelector(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                    ),
                    _menuSectionHeader('Services & Account'),
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
                      icon: Icons.support_agent_rounded,
                      label: 'Support Team',
                      onTap: widget.onSupportTap,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
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
    String? subtitle,
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
      visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
      subtitle: subtitle != null
          ? Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
              ),
            )
          : null,
      trailing: isDestructive
          ? null
          : const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF9CA3AF),
            ),
      onTap: () {
        _closeMenuDrawer();
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
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE1E5EA)),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                key: const ValueKey('home_search_bar_field'),
                behavior: HitTestBehavior.opaque,
                onTap: widget.onSeeAllCatalog,
                child: const Row(
                  children: [
                    SizedBox(width: 12),
                    Icon(Icons.search, color: Color(0xFF8A93A6), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search for phones, accessories...',
                        style: TextStyle(
                          color: Color(0xFF8A93A6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _GlowingCategoryTuneButton(
              onTap: _showCategoriesBottomSheet,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoriesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final categories = [
          (
            category: 'Smartphones',
            icon: Icons.phone_android_rounded,
            subtitle: 'Flagship & 5G',
            color: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
          ),
          (
            category: 'UK Used',
            icon: Icons.verified_rounded,
            subtitle: 'Grade A+ Tested',
            color: const Color(0xFFEA580C),
            bgColor: const Color(0xFFFFF7ED),
          ),
          (
            category: 'Keypad Phones',
            icon: Icons.dialpad_rounded,
            subtitle: 'Nokia & Itel',
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
          ),
          (
            category: 'Laptops',
            icon: Icons.laptop_mac_rounded,
            subtitle: 'MacBooks & Dell',
            color: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
          ),
          (
            category: 'Accessories',
            icon: Icons.headphones_rounded,
            subtitle: 'Audio & Power',
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFFBEB),
          ),
          (
            category: 'Tablets',
            icon: Icons.tablet_mac_rounded,
            subtitle: 'iPads & Android',
            color: const Color(0xFF0284C7),
            bgColor: const Color(0xFFF0F9FF),
          ),
          (
            category: 'Wearables',
            icon: Icons.watch_rounded,
            subtitle: 'Smartwatches',
            color: const Color(0xFFEC4899),
            bgColor: const Color(0xFFFDF2F8),
          ),
          (
            category: 'Foldables',
            icon: Icons.devices_fold_rounded,
            subtitle: 'Flip & Fold',
            color: const Color(0xFF6366F1),
            bgColor: const Color(0xFFEEF2FF),
          ),
          (
            category: 'All Products',
            icon: Icons.grid_view_rounded,
            subtitle: 'Entire Store',
            color: const Color(0xFF059669),
            bgColor: const Color(0xFFECFDF5),
          ),
        ];

        final bottomInset = MediaQuery.of(ctx).padding.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 2),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 12, 6),
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
                        Icons.tune_rounded,
                        color: Color(0xFF1C7BFF),
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Category',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'Filter phones, laptops & gadgets in store',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 8),

              // 2-column Grid of categories
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < categories.length; i += 2) ...[
                      Row(
                        children: [
                          Expanded(child: _buildCategorySheetCard(ctx, categories[i])),
                          if (i + 1 < categories.length) ...[
                            const SizedBox(width: 9),
                            Expanded(child: _buildCategorySheetCard(ctx, categories[i + 1])),
                          ],
                        ],
                      ),
                      if (i + 2 < categories.length) const SizedBox(height: 9),
                    ],
                  ],
                ),
              ),

              // Horizontal divider and generous space under All Products to move contents up significantly
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE2E8F0),
                ),
              ),
              SizedBox(height: bottomInset + 125),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategorySheetCard(
    BuildContext ctx,
    ({
      String category,
      IconData icon,
      String subtitle,
      Color color,
      Color bgColor,
    }) item,
  ) {
    final isSelected = widget.viewModel.selectedCategory == item.category ||
        (item.category == 'All Products' &&
            (widget.viewModel.selectedCategory == 'All' ||
                widget.viewModel.selectedCategory == 'All Products'));

    return InkWell(
      key: ValueKey('category_card_${item.category}'),
      onTap: () {
        Navigator.of(ctx).pop();
        final cat = item.category == 'All Products' ? 'All' : item.category;
        widget.viewModel.selectCategory(cat);
        if (widget.onCategoryTap != null) {
          widget.onCategoryTap!(cat);
        } else {
          widget.onSeeAllCatalog();
        }
      },
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10.5),
        decoration: BoxDecoration(
          color: isSelected ? item.bgColor : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isSelected ? item.color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 21, color: item.color),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.category,
                      maxLines: 1,
                      style: TextStyle(
                        color: const Color(0xFF1E293B),
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.subtitle,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                      ),
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

  Widget _buildHeroBanner() {
    final products = widget.viewModel.featuredProducts;
    return Column(
      children: [
        SizedBox(
          height: 204,
          child: PageView.builder(
            controller: _heroPageController,
            itemCount: _heroPromotions.length,
            onPageChanged: _onHeroPageChanged,
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
            (index) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _heroPageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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

  Widget _buildHeroSlide(
    _HeroPromotion promotion,
    List<Product> products,
    int index,
  ) {
    final primaryProduct =
        products.isEmpty ? null : products[index % products.length];
    final secondaryProduct =
        products.length < 2 ? null : products[(index + 1) % products.length];

    if (index == 0) {
      return _buildVideoHeroSlide(promotion, primaryProduct);
    }

    final tertiaryProduct = products.length < 3
        ? null
        : products[(index + 2) % products.length];
    return _buildGraphicHeroSlide(
      promotion,
      primaryProduct,
      secondaryProduct,
      tertiaryProduct,
      index,
    );
  }

  Widget _buildVideoHeroSlide(
    _HeroPromotion promotion,
    Product? primaryProduct,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD6EEFF),
            Color(0xFFEAF5FF),
            Color(0xFFDCEFFF),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Protruding soft blue circle on far left
          Positioned(
            left: -22,
            top: 60,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF93C5FD).withValues(alpha: 0.45),
              ),
            ),
          ),

          // 2. Soft pastel purple / lavender glow behind the phone on the right
          Positioned(
            right: -12,
            top: -4,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFDDD6FE).withValues(alpha: 0.65),
                    const Color(0xFFDDD6FE).withValues(alpha: 0.0),
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
                    _buildDot(const Color(0xFF60A5FA)),
                    const SizedBox(width: 4),
                    _buildDot(const Color(0xFFF87171)),
                    const SizedBox(width: 4),
                    _buildDot(const Color(0xFF60A5FA)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(const Color(0xFFF87171)),
                    const SizedBox(width: 4),
                    _buildDot(const Color(0xFF60A5FA)),
                    const SizedBox(width: 4),
                    _buildDot(const Color(0xFFF87171)),
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

          // 7. Soft blue circular dot at bottom
          Positioned(
            bottom: 6,
            left: 162,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF93C5FD).withValues(alpha: 0.7),
              ),
            ),
          ),

          // Main Layout Content Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                // Left Column: Texts, Benefits Row, CTA Button
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
                            'Discover the\nLatest Smartphones',
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
                            'Shop flagship devices at\nunbeatable prices.',
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
                                Icons.local_shipping_outlined,
                                'Free',
                                'Shipping',
                              ),
                              const SizedBox(width: 5),
                              _buildBenefitPill(
                                Icons.verified_user_outlined,
                                '1 Year',
                                'Warranty',
                              ),
                              const SizedBox(width: 5),
                              _buildBenefitPill(
                                Icons.local_offer_outlined,
                                'Best',
                                'Prices',
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          GestureDetector(
                            onTap: primaryProduct == null
                                ? null
                                : () => widget.onProductTap(primaryProduct),
                            child: Container(
                              height: 31,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 13),
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
                                    'Shop Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white,
                                    size: 16,
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

                // Right Column: Video inside smartphone mockup frame with Trending badge & Better Tech label
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
                                    child: BannerVideoPlayer(
                                      isActive: _activeHeroIndex == 0,
                                      onVideoCompleted:
                                          _onBannerVideoCompleted,
                                      aspectRatio: 16 / 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 🔥 Trending Badge with speech tail at top-right
                            Positioned(
                              top: 10,
                              right: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFC533),
                                          Color(0xFFFF9E1B),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(11),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF9E1B)
                                              .withValues(alpha: 0.35),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('🔥',
                                            style: TextStyle(fontSize: 9.5)),
                                        SizedBox(width: 3),
                                        Text(
                                          'Trending',
                                          style: TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: SizedBox(
                                      width: 7,
                                      height: 4,
                                      child: CustomPaint(
                                        painter: _SpeechBubbleTrianglePainter(
                                          color: Color(0xFFFF9E1B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // "Better Tech Brighter Tomorrow" with curved doodle arrow at bottom-right
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Transform.rotate(
                                    angle: -0.08,
                                    child: const Text(
                                      'Better\nTech\nBrighter\nTomorrow',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: Color(0xFF0D62FE),
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
                                    width: 20,
                                    height: 11,
                                    child: CustomPaint(
                                      painter: _CurvedDoodleArrowPainter(
                                        color: Color(0xFF0D62FE),
                                      ),
                                    ),
                                  ),
                                ],
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

  Widget _buildGraphicHeroSlide(
    _HeroPromotion promotion,
    Product? primaryProduct,
    Product? secondaryProduct,
    Product? tertiaryProduct,
    int index,
  ) {
    final List<Color> gradientColors;
    final String tagText;
    final Color tagColor;
    final Color leftBlobColor;
    final Color glowHaloColor;
    final Color dotColor1;
    final Color dotColor2;
    final Color bottomDotColor;
    final Color scriptColor;
    final Color arrowColor;
    final List<Color> badgeGradient;
    final String badgeTopText;
    final String badgeMidText;
    final String badgeBottomText;
    final List<({IconData icon, String line1, String line2})> benefits;

    if (index == 2) {
      // Banner 3: Trade in & Upgrade (Mint Green theme from app banner)
      gradientColors = const [
        Color(0xFFD6F5E3),
        Color(0xFFEFFCF4),
        Color(0xFFCEF1DD),
      ];
      tagText = 'TRADE-IN DEALS';
      tagColor = const Color(0xFF059669);
      leftBlobColor = const Color(0xFFA7F3D0).withValues(alpha: 0.45);
      glowHaloColor = const Color(0xFFBBF7D0);
      dotColor1 = const Color(0xFF10B981);
      dotColor2 = const Color(0xFF38BDF8);
      bottomDotColor = const Color(0xFF34D399).withValues(alpha: 0.7);
      scriptColor = const Color(0xFF047857);
      arrowColor = const Color(0xFF0D9488);
      badgeGradient = const [Color(0xFFFF6536), Color(0xFFFF3018)];
      badgeTopText = 'UP TO';
      badgeMidText = '50%';
      badgeBottomText = 'OFF';
      benefits = const [
        (icon: Icons.sync_alt_rounded, line1: 'Instant', line2: 'Credit'),
        (icon: Icons.speed_rounded, line1: 'Quick', line2: 'Inspect'),
        (icon: Icons.local_offer_outlined, line1: 'Best', line2: 'Value'),
      ];
    } else if (index == 3) {
      // Banner 4: Premium Care (Warm Peach theme from app banner)
      gradientColors = const [
        Color(0xFFFFE4D6),
        Color(0xFFFFF5EE),
        Color(0xFFFFDBCD),
      ];
      tagText = 'PREMIUM CARE';
      tagColor = const Color(0xFFD97706);
      leftBlobColor = const Color(0xFFFED7AA).withValues(alpha: 0.45);
      glowHaloColor = const Color(0xFFFFEDD5);
      dotColor1 = const Color(0xFFF97316);
      dotColor2 = const Color(0xFFA855F7);
      bottomDotColor = const Color(0xFFFB923C).withValues(alpha: 0.7);
      scriptColor = const Color(0xFFC2410C);
      arrowColor = const Color(0xFFEA580C);
      badgeGradient = const [Color(0xFFFF5722), Color(0xFFE64A19)];
      badgeTopText = 'UP TO';
      badgeMidText = '40%';
      badgeBottomText = 'OFF';
      benefits = const [
        (icon: Icons.shield_outlined, line1: 'Screen', line2: 'Protect'),
        (icon: Icons.build_circle_outlined, line1: 'OEM', line2: 'Parts'),
        (icon: Icons.verified_user_outlined, line1: '1 Year', line2: 'Warranty'),
      ];
    } else {
      // Banner 2: Flagship Phones (Lavender theme from app banner)
      gradientColors = const [
        Color(0xFFE8DCFA),
        Color(0xFFF7F0FF),
        Color(0xFFE2D4F8),
      ];
      tagText = 'NEW ARRIVALS';
      tagColor = const Color(0xFF6D28D9);
      leftBlobColor = const Color(0xFFC4B5FD).withValues(alpha: 0.40);
      glowHaloColor = const Color(0xFFDDD6FE);
      dotColor1 = const Color(0xFF8B5CF6);
      dotColor2 = const Color(0xFFF472B6);
      bottomDotColor = const Color(0xFFA78BFA).withValues(alpha: 0.7);
      scriptColor = const Color(0xFF6366F1);
      arrowColor = const Color(0xFF06B6D4);
      badgeGradient = const [Color(0xFFFF6536), Color(0xFFFF3018)];
      badgeTopText = 'UP TO';
      badgeMidText = '40%';
      badgeBottomText = 'OFF';
      benefits = const [
        (icon: Icons.local_shipping_outlined, line1: 'Free', line2: 'Shipping'),
        (icon: Icons.verified_user_outlined, line1: '1 Year', line2: 'Warranty'),
        (icon: Icons.local_offer_outlined, line1: 'Best', line2: 'Prices'),
      ];
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
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
                color: leftBlobColor,
              ),
            ),
          ),

          // 2. Soft pastel glow halo behind the phones on the right
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
                    glowHaloColor.withValues(alpha: 0.75),
                    glowHaloColor.withValues(alpha: 0.0),
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
                    _buildDot(dotColor1),
                    const SizedBox(width: 4),
                    _buildDot(dotColor2),
                    const SizedBox(width: 4),
                    _buildDot(dotColor1),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(dotColor2),
                    const SizedBox(width: 4),
                    _buildDot(dotColor1),
                    const SizedBox(width: 4),
                    _buildDot(dotColor2),
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
                color: bottomDotColor,
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
                          Text(
                            tagText,
                            style: TextStyle(
                              color: tagColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            promotion.title,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            promotion.description,
                            style: const TextStyle(
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
                                benefits[0].icon,
                                benefits[0].line1,
                                benefits[0].line2,
                              ),
                              const SizedBox(width: 5),
                              _buildBenefitPill(
                                benefits[1].icon,
                                benefits[1].line1,
                                benefits[1].line2,
                              ),
                              const SizedBox(width: 5),
                              _buildBenefitPill(
                                benefits[2].icon,
                                benefits[2].line1,
                                benefits[2].line2,
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          GestureDetector(
                            onTap: () {
                              if (index == 2) {
                                widget.onTradeInTap();
                              } else if (index == 3) {
                                widget.onRepairsTap();
                              } else if (primaryProduct != null) {
                                widget.onProductTap(primaryProduct);
                              }
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    promotion.primaryAction,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
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

                // Right Column: Phones cascade matching app design, UP TO 40% OFF badge, Smarter Tech Brighter Days
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
                            // Phones cascade keeping the phone images and design from the app banner
                            if (tertiaryProduct != null)
                              Positioned(
                                left: 6,
                                bottom: 18,
                                child: Transform.rotate(
                                  angle: -0.06,
                                  child: _buildHeroProductImage(
                                    tertiaryProduct,
                                    66,
                                    102,
                                    10,
                                  ),
                                ),
                              ),
                            if (secondaryProduct != null)
                              Positioned(
                                left: tertiaryProduct != null ? 44 : 14,
                                bottom: 14,
                                child: Transform.rotate(
                                  angle: 0.02,
                                  child: _buildHeroProductImage(
                                    secondaryProduct,
                                    74,
                                    116,
                                    12,
                                  ),
                                ),
                              ),
                            if (primaryProduct != null)
                              Positioned(
                                left: tertiaryProduct != null ? 80 : 68,
                                bottom: 10,
                                child: Transform.rotate(
                                  angle: 0.07,
                                  child: _buildHeroProductImage(
                                    primaryProduct,
                                    86,
                                    130,
                                    14,
                                  ),
                                ),
                              ),

                            // Floating badge with tail pointing to phone
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
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: badgeGradient,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: badgeGradient.first
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
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          badgeTopText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                            height: 1.0,
                                          ),
                                        ),
                                        Text(
                                          badgeMidText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                            height: 1.05,
                                          ),
                                        ),
                                        Text(
                                          badgeBottomText,
                                          style: const TextStyle(
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
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: SizedBox(
                                      width: 8,
                                      height: 5,
                                      child: CustomPaint(
                                        painter: _SpeechBubbleTrianglePainter(
                                          color: badgeGradient.last,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // "Smarter Tech Brighter Days" with curved doodle arrow / squiggle at bottom-right
                            Positioned(
                              bottom: 4,
                              right: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Transform.rotate(
                                    angle: -0.07,
                                    child: Text(
                                      'Smarter\nTech\nBrighter\nDays',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: scriptColor,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 8.5,
                                        height: 1.05,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  SizedBox(
                                    width: 22,
                                    height: 10,
                                    child: CustomPaint(
                                      painter: _CurvedDoodleArrowPainter(
                                        color: arrowColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Sparkle star near Smarter Tech
                            const Positioned(
                              top: 48,
                              right: 4,
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
    final brands = BrandsView.allBrands.map((b) => b.name).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View more',
                        style: TextStyle(
                          color: Color(0xFF1C7BFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: Color(0xFF1C7BFF),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: brands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final brandName = brands[index];
              return SizedBox(
                width: 72,
                child: Material(
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 28,
                            child: Center(
                              child: BrandLogo(brand: brandName),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            brandName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel,
                    style: const TextStyle(
                      color: Color(0xFF1C7BFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: Color(0xFF1C7BFF),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Groups featured products by brand and renders each group as a
  /// horizontally-scrollable row with 2 cards visible at a time,
  /// with the brand name shown as a label above each row.
  Widget _buildFeaturedByBrand() {
    final items = widget.viewModel.featuredProducts;

    // Group products by brand, preserving insertion order.
    final Map<String, List<Product>> byBrand = {};
    for (final p in items) {
      byBrand.putIfAbsent(p.brand, () => []).add(p);
    }

    final brandEntries = byBrand.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with "Featured Phones" title + View all link
        _buildSectionHeader('Featured Phones', 'View all'),
        const SizedBox(height: 14),
        // One horizontal-scroll row per brand, followed by an alternating Flash Sale banner under each
        for (int i = 0; i < brandEntries.length; i++) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
                        brandEntries[i].key,
                        style: const TextStyle(
                          color: Color(0xFF1E2432),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${brandEntries[i].value.length} phones',
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Horizontal scroll list — 2 cards visible at a time
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Card width = (screen width - horizontal padding (32) - spacing between 2 cards (12)) / 2
                    final cardWidth =
                        (constraints.maxWidth - 32 - 12) / 2;
                    // Proportional height corresponding to horizontal size (1:1.56 aspect ratio)
                    final cardHeight = cardWidth * 1.56;
                    return SizedBox(
                      height: cardHeight,
                      child: _FeaturedBrandRow(
                        brand: brandEntries[i].key,
                        products: brandEntries[i].value,
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                        buildCard: _buildCompactFeaturedCard,
                        onBrandTap: widget.onBrandTap,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: FlashSalePromoBanner(
              isDark: i.isOdd,
              onShopNowTap: () => widget.onCategoryTap?.call('Smartphones'),
            ),
          ),
        ],
      ],
    );
  }

  /// Featured card for the 2-per-row horizontal brand sections.
  Widget _buildCompactFeaturedCard(Product product) {
    final isWishlisted = widget.wishlistRepo?.isWishlisted(product.id) ??
        _wishlistProductIds.contains(product.id);
    final displayName =
        product.name.toLowerCase().startsWith(product.brand.toLowerCase())
            ? product.name
            : '${product.brand} ${product.name}';

    return GestureDetector(
      onTap: () => widget.onProductTap(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge + wishlist row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _buildConditionBadge(product.condition),
                  ),
                ),
                const SizedBox(width: 4),
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
                      size: 17,
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
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 12,
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
                fontSize: 11,
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
                      size: 13, color: Color(0xFFFFA000)),
                  const SizedBox(width: 2),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '(${product.reviewCount})',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 10,
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
              height: 32,
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
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
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
            : 120.0;
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 160.0;
        final availableHeight = maxH.clamp(40.0, 180.0);
        final availableWidth = maxW.clamp(40.0, 180.0);
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

  Widget _buildConditionBadge(String condition) {
    final lower = condition.toLowerCase().trim();
    final String label;
    final Color badgeBg;
    if (lower.contains('uk') || lower.contains('used')) {
      label = 'UK Used';
      badgeBg = const Color(0xFFEA580C);
    } else if (lower.contains('refurb')) {
      label = 'Refurbished';
      badgeBg = const Color(0xFF059669);
    } else if (lower.contains('open')) {
      label = 'Open Box';
      badgeBg = const Color(0xFF7C3AED);
    } else {
      label = 'New';
      badgeBg = const Color(0xFF1C7BFF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
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

class _GlowingCategoryTuneButton extends StatefulWidget {
  final VoidCallback onTap;

  const _GlowingCategoryTuneButton({
    required this.onTap,
  });

  @override
  State<_GlowingCategoryTuneButton> createState() =>
      _GlowingCategoryTuneButtonState();
}

class _GlowingCategoryTuneButtonState extends State<_GlowingCategoryTuneButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _controller.repeat();
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('home_search_tune_button'),
      borderRadius: BorderRadius.circular(10),
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 6, left: 4, top: 4, bottom: 4),
        child: SizedBox(
          width: 34,
          height: 34,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _GlowingLightBorderPainter(progress: _controller.value),
                child: child,
              );
            },
            child: Container(
              margin: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 17,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowingLightBorderPainter extends CustomPainter {
  final double progress;

  _GlowingLightBorderPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(1.0),
      const Radius.circular(10),
    );

    // Subtle background border so the button outline remains crisp all around
    final baseBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFE2E8F0);
    canvas.drawRRect(rrect, baseBorderPaint);

    final angle = progress * 2 * math.pi;
    final sweepShader = SweepGradient(
      center: Alignment.center,
      transform: GradientRotation(angle),
      colors: const [
        Colors.transparent,
        Colors.transparent,
        Color(0x0000E5FF),
        Color(0x6600E5FF),
        Color(0xFF00E5FF), // Brilliant Cyan Head
        Color(0xFF1C7BFF), // Vibrant Royal Blue
        Color(0xFF8B5CF6), // Neon Purple Tail
        Colors.transparent,
      ],
      stops: const [
        0.0,
        0.55,
        0.70,
        0.82,
        0.91,
        0.96,
        0.985,
        1.0,
      ],
    ).createShader(rect);

    // 1. Radiant luminous glow aura
    final glowAuraPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2)
      ..shader = sweepShader;
    canvas.drawRRect(rrect, glowAuraPaint);

    // 2. Focused razor-sharp beam running along border
    final coreBeamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = sweepShader;
    canvas.drawRRect(rrect, coreBeamPaint);
  }

  @override
  bool shouldRepaint(covariant _GlowingLightBorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Horizontal scroll row for each featured brand that features an animated
/// running-light arrow indicator at the right edge ("in the middle way ending")
/// to indicate that more featured phones exist on the right, plus an end-of-list
/// card with the matching arrow to view all brand models.
class _FeaturedBrandRow extends StatefulWidget {
  final String brand;
  final List<Product> products;
  final double cardWidth;
  final double cardHeight;
  final Widget Function(Product) buildCard;
  final ValueChanged<String>? onBrandTap;

  const _FeaturedBrandRow({
    required this.brand,
    required this.products,
    required this.cardWidth,
    required this.cardHeight,
    required this.buildCard,
    this.onBrandTap,
  });

  @override
  State<_FeaturedBrandRow> createState() => _FeaturedBrandRowState();
}

class _FeaturedBrandRowState extends State<_FeaturedBrandRow> {
  late final ScrollController _scrollController;
  bool _hasMoreOnRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _hasMoreOnRight = widget.products.length > 2;
  }

  @override
  void didUpdateWidget(_FeaturedBrandRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products.length != widget.products.length) {
      _hasMoreOnRight = widget.products.length > 2;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    final hasMore = (max - current) > 16.0;
    if (hasMore != _hasMoreOnRight) {
      setState(() {
        _hasMoreOnRight = hasMore;
      });
    }
  }

  void _scrollRight() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (current >= max - 16.0) {
      widget.onBrandTap?.call(widget.brand);
    } else {
      final target = (current + widget.cardWidth + 12.0).clamp(0.0, max);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showIndicator = widget.products.length > 2;

    return Stack(
      children: [
        // Horizontal list of cards
        ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: widget.products.length + (showIndicator ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            if (i < widget.products.length) {
              return SizedBox(
                width: widget.cardWidth,
                child: widget.buildCard(widget.products[i]),
              );
            }

            // End card: View all [Brand] with arrow
            return SizedBox(
              width: widget.cardWidth * 0.76,
              child: GestureDetector(
                onTap: () => widget.onBrandTap?.call(widget.brand),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RunningLightArrowButton(
                        onTap: () => widget.onBrandTap?.call(widget.brand),
                        size: 40.0,
                        tooltip: 'View all ${widget.brand} phones',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.brand} Phones',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Indicator at the end of each row in the middle ("in the middle way ending")
        if (showIndicator)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !_hasMoreOnRight,
              child: AnimatedOpacity(
                opacity: _hasMoreOnRight ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  padding: const EdgeInsets.only(right: 6, left: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                  child: Center(
                    child: RunningLightArrowButton(
                      onTap: _scrollRight,
                      tooltip: 'More ${widget.brand} phones',
                      size: 38.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
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

class _HeaderPhoneBadgePainter extends CustomPainter {
  const _HeaderPhoneBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Smartphone body (solid dark navy/black with rounded corners)
    final bodyPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final phoneWidth = size.width * 0.44;
    final phoneHeight = size.height * 0.66;
    final phoneLeft = (size.width - phoneWidth) / 2;
    final phoneTop = (size.height - phoneHeight) / 2;

    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(phoneLeft, phoneTop, phoneWidth, phoneHeight),
      Radius.circular(phoneWidth * 0.26),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Screen (light sky-blue matching header brand badge)
    final screenPaint = Paint()
      ..color = const Color(0xFFC0E5FF)
      ..style = PaintingStyle.fill;

    final screenWidth = phoneWidth * 0.73;
    final screenHeight = phoneHeight * 0.62;
    final screenLeft = (size.width - screenWidth) / 2;
    final screenTop = phoneTop + phoneHeight * 0.10;

    final screenRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(screenLeft, screenTop, screenWidth, screenHeight),
      const Radius.circular(1.0),
    );
    canvas.drawRRect(screenRRect, screenPaint);

    // Home button (small white button at bottom center)
    final btnPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final btnWidth = phoneWidth * 0.20;
    final btnHeight = phoneHeight * 0.10;
    final btnLeft = (size.width - btnWidth) / 2;
    final btnTop = phoneTop + phoneHeight - btnHeight - phoneHeight * 0.05;

    final btnRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(btnLeft, btnTop, btnWidth, btnHeight),
      const Radius.circular(0.5),
    );
    canvas.drawRRect(btnRRect, btnPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
