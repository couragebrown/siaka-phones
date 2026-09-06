import 'package:flutter/material.dart';
import 'product_detail_view_model.dart';

class ProductDetailView extends StatelessWidget {
  final ProductDetailViewModel viewModel;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onReviewsTap;
  final VoidCallback onGoToCart;

  const ProductDetailView({
    super.key,
    required this.viewModel,
    required this.onTabSelected,
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
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F4F6),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1F2937)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(''),
            actions: [
              IconButton(
                onPressed: () {},
                icon:
                    const Icon(Icons.favorite_border, color: Color(0xFF1F2937)),
              ),
              IconButton(
                onPressed: onGoToCart,
                icon: const Icon(Icons.shopping_bag_outlined,
                    color: Color(0xFF1F2937)),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFB8C0CC)),
                            ),
                            child: product.images.isNotEmpty
                                ? Image.network(product.images[0],
                                    fit: BoxFit.cover)
                                : const Icon(Icons.phone_android,
                                    color: Colors.black54),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 240,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8EEF7),
                                borderRadius: BorderRadius.circular(26),
                                border:
                                    Border.all(color: const Color(0xFFB8C0CC)),
                              ),
                              child: product.images.isNotEmpty
                                  ? Image.network(
                                      product
                                          .images[viewModel.selectedImageIndex],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                          color: const Color(0xFFE8EEF7)),
                                    )
                                  : const Icon(Icons.phone_android,
                                      color: Colors.black54, size: 60),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFC107), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${product.rating} (${product.reviewCount} Reviews)',
                            style: const TextStyle(
                                color: Color(0xFF525F73),
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '₵${product.price.toStringAsFixed(3)}',
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Inclusive of all taxes',
                        style:
                            TextStyle(color: Color(0xFF697586), fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Storage',
                        style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: product.storageOptions.map((storage) {
                          final selected = storage == viewModel.selectedStorage;
                          return ChoiceChip(
                            label: Text(storage,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF1F2937))),
                            selected: selected,
                            onSelected: (_) => viewModel.selectStorage(storage),
                            backgroundColor: const Color(0xFFE5E7EB),
                            selectedColor: const Color(0xFF1C7BFF),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Color: Natural Titanium',
                        style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(4, (index) {
                          final colors = [
                            const Color(0xFFB7B7B9),
                            const Color(0xFFDAD3CF),
                            const Color(0xFFB8A49D),
                            const Color(0xFF9FA4A9)
                          ];
                          final selected = index == 0;
                          return Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: colors[index],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF1C7BFF)
                                    : const Color(0xFFD6D9DE),
                                width: selected ? 2 : 1,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => viewModel.addToCart(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C7BFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text('Add to Cart',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: onGoToCart,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1F2937),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Buy Now',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.local_shipping_outlined,
                                color: Color(0xFF0F9F65)),
                            SizedBox(width: 10),
                            Text(
                                'Order within 2h 15m for delivery by May 27, 2025',
                                style: TextStyle(
                                    color: Color(0xFF0F9F65),
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Product Highlights',
                        style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 18,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      const Column(
                        children: [
                          _HighlightRow(
                              icon: Icons.check,
                              text:
                                  '6.7-inch Super Retina XDR display with ProMotion'),
                          _HighlightRow(
                              icon: Icons.check,
                              text: 'A17 Pro chip with 6-core GPU'),
                          _HighlightRow(
                              icon: Icons.check,
                              text:
                                  'Pro camera system with 48MP Main | 12MP Ultra Wide | 12MP Telephoto'),
                          _HighlightRow(
                              icon: Icons.check,
                              text: 'Up to 29 hours video playback'),
                          _HighlightRow(
                              icon: Icons.check, text: '5G Connectivity'),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 78,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _navItem(0, Icons.home_outlined, 'Home'),
            _navItem(1, Icons.search_rounded, 'Search'),
            _navItem(3, Icons.favorite_border_rounded, 'Wishlist'),
            _navItem(2, Icons.shopping_bag_outlined, 'Cart',
                badge: viewModel.cartItemCount),
            _navItem(4, Icons.person_outline_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, {int badge = 0}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabSelected(index),
      child: SizedBox(
        width: 72,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFF7A8194), size: 26),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF7A8194),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            if (badge > 0)
              Positioned(
                right: 16,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1C7BFF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                      child: Text('$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HighlightRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1C7BFF)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: Color(0xFF1F2937), fontSize: 15, height: 1.5))),
        ],
      ),
    );
  }
}
