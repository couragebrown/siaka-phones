import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/badge_chip.dart';
import '../../core/widgets/rating_stars.dart';
import '../../../domain/models/product.dart';
import 'catalog_view_model.dart';

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

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Device Catalog'),
          ),
          body: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search flagships, foldables, audio...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppColors.cyan, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                widget.viewModel.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (val) => widget.viewModel.setSearchQuery(val),
                  ),
                ),
              ),

              // Categories
              SizedBox(
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
                      onTap: () => widget.viewModel.setCategory(cat),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Products Grid
              Expanded(
                child: widget.viewModel.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
                    : widget.viewModel.products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.devices_other, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                const Text('No devices found', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Try refining your search or category filter', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: widget.viewModel.products.length,
                            itemBuilder: (context, index) {
                              final product = widget.viewModel.products[index];
                              return _buildProductGridCard(product);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductGridCard(Product product) {
    return GlassContainer(
      padding: const EdgeInsets.all(10),
      onTap: () => widget.onProductTap(product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    product.images.first,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surface,
                      child: const Center(
                        child: Icon(Icons.phone_android, color: AppColors.cyan, size: 36),
                      ),
                    ),
                  ),
                ),
                if (product.discountPercent > 0)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.neonPink,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${product.discountPercent.toInt()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.brand.toUpperCase(),
            style: const TextStyle(color: AppColors.cyan, fontSize: 9, fontWeight: FontWeight.bold),
          ),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          RatingStars(rating: product.rating, starSize: 11),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.cyan, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward, size: 12, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
