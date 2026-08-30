import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/rating_stars.dart';
import '../../core/widgets/neon_button.dart';
import 'product_detail_view_model.dart';

class ProductDetailView extends StatelessWidget {
  final ProductDetailViewModel viewModel;
  final VoidCallback onReviewsTap;
  final VoidCallback onGoToCart;

  const ProductDetailView({
    super.key,
    required this.viewModel,
    required this.onReviewsTap,
    required this.onGoToCart,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final product = viewModel.product;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(product.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product link copied to clipboard!')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.cyan),
                onPressed: onGoToCart,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main gallery image
                      Container(
                        height: 260,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            product.images[viewModel.selectedImageIndex],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.phone_android, size: 60, color: AppColors.cyan),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Thumbnails
                      if (product.images.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: product.images.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final img = entry.value;
                            final isSel = idx == viewModel.selectedImageIndex;
                            return GestureDetector(
                              onTap: () => viewModel.selectImage(idx),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel ? AppColors.cyan : AppColors.borderLight,
                                    width: isSel ? 2 : 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(img, fit: BoxFit.cover),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 20),

                      // Title & Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.brand.toUpperCase(),
                                  style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                              ),
                              if (product.originalPrice > product.price)
                                Text(
                                  '\$${product.originalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Rating & Reviews CTA
                      GestureDetector(
                        onTap: onReviewsTap,
                        child: Row(
                          children: [
                            RatingStars(rating: product.rating, reviewCount: product.reviewCount),
                            const SizedBox(width: 8),
                            const Text(
                              'Read customer reviews →',
                              style: TextStyle(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        product.description,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                      ),

                      const SizedBox(height: 20),

                      // Color Options
                      const Text('Choose Color', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: product.colors.map((color) {
                          final isSel = color == viewModel.selectedColor;
                          return ChoiceChip(
                            label: Text(color, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 12)),
                            selected: isSel,
                            selectedColor: AppColors.cyan,
                            backgroundColor: AppColors.surfaceElevated,
                            onSelected: (_) => viewModel.selectColor(color),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Storage Options
                      const Text('Storage Capacity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: product.storageOptions.map((storage) {
                          final isSel = storage == viewModel.selectedStorage;
                          return ChoiceChip(
                            label: Text(storage, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 12)),
                            selected: isSel,
                            selectedColor: AppColors.cyan,
                            backgroundColor: AppColors.surfaceElevated,
                            onSelected: (_) => viewModel.selectStorage(storage),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Technical Specifications Accordion / Card
                      const Text('Technical Specs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      GlassContainer(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: product.specs.entries.map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    entry.value,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Quantity Controller
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                              onPressed: () => viewModel.updateQuantity(-1),
                            ),
                            Text(
                              '${viewModel.quantity}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16, color: Colors.white),
                              onPressed: () => viewModel.updateQuantity(1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Add to Cart Button
                      Expanded(
                        child: NeonButton(
                          label: viewModel.isAddedSuccess ? 'Added to Cart ✓' : 'Add to Cart',
                          icon: viewModel.isAddedSuccess ? Icons.check_circle : Icons.shopping_bag,
                          gradient: viewModel.isAddedSuccess ? const LinearGradient(colors: [Color(0xFF06D6A0), Color(0xFF00F2FE)]) : null,
                          onPressed: () => viewModel.addToCart(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
