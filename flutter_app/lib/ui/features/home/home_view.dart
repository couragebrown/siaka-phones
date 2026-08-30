import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/badge_chip.dart';
import '../../core/widgets/rating_stars.dart';
import '../../core/widgets/neon_button.dart';
import '../../../domain/models/product.dart';
import 'home_view_model.dart';

class HomeView extends StatefulWidget {
  final HomeViewModel viewModel;
  final Function(Product) onProductTap;
  final VoidCallback onSeeAllCatalog;
  final VoidCallback onTradeInTap;
  final VoidCallback onRepairsTap;

  const HomeView({
    super.key,
    required this.viewModel,
    required this.onProductTap,
    required this.onSeeAllCatalog,
    required this.onTradeInTap,
    required this.onRepairsTap,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.cyan),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(),
          body: RefreshIndicator(
            color: AppColors.cyan,
            backgroundColor: AppColors.surface,
            onRefresh: () => widget.viewModel.loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(),
                  const SizedBox(height: 20),
                  _buildQuickServices(),
                  const SizedBox(height: 24),
                  _buildCategoryChips(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Flagship Highlights', widget.onSeeAllCatalog),
                  const SizedBox(height: 12),
                  _buildFeaturedCarousel(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('New Arrivals & Eco-Deals', widget.onSeeAllCatalog),
                  const SizedBox(height: 12),
                  _buildNewArrivalsList(),
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
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.phone_android, size: 20, color: Colors.black),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SIAKA PHONES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'AMOLED Flagship Experience',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
          onPressed: widget.onSeeAllCatalog,
        ),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderColor: AppColors.borderCyan,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyan),
              ),
              child: const Text(
                'SPECIAL LAUNCH DEAL • UP TO 20% OFF',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Siaka Titan 16 Pro\nTitanium Cyber',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Zero-lag HyperDrive chip with 200MP computational low-light sensor.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: 'Pre-Order Now',
                    icon: Icons.flash_on_rounded,
                    onPressed: () {
                      if (widget.viewModel.featuredProducts.isNotEmpty) {
                        widget.onProductTap(widget.viewModel.featuredProducts.first);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickServices() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              onTap: widget.onTradeInTap,
              child: const Row(
                children: [
                  Icon(Icons.swap_horizontal_circle_outlined, color: AppColors.cyan, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trade-In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Instant Cash', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              onTap: widget.onRepairsTap,
              child: const Row(
                children: [
                  Icon(Icons.handyman_outlined, color: AppColors.neonAmber, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Express Repair', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Same-day fix', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: widget.viewModel.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = widget.viewModel.categories[index];
          final isSelected = widget.viewModel.selectedCategory == cat;
          return BadgeChip(
            label: cat,
            isSelected: isSelected,
            onTap: () => widget.viewModel.selectCategory(cat),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text(
              'See All',
              style: TextStyle(
                color: AppColors.cyan,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCarousel() {
    final products = widget.viewModel.featuredProducts;
    return SizedBox(
      height: 270,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(product, 190);
        },
      ),
    );
  }

  Widget _buildNewArrivalsList() {
    final products = widget.viewModel.newArrivals;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: products.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildHorizontalProductCard(p),
        )).toList(),
      ),
    );
  }

  Widget _buildProductCard(Product product, double width) {
    return Container(
      width: width,
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        onTap: () => widget.onProductTap(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.images.first,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: AppColors.surface,
                  child: const Icon(Icons.phone_android, color: AppColors.cyan, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.brand.toUpperCase(),
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            RatingStars(rating: product.rating, starSize: 12),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.cyan,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalProductCard(Product product) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      onTap: () => widget.onProductTap(product),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              product.images.first,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: AppColors.surface,
                child: const Icon(Icons.phone_android, color: AppColors.cyan),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                RatingStars(rating: product.rating, reviewCount: product.reviewCount, starSize: 11),
                const SizedBox(height: 6),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
