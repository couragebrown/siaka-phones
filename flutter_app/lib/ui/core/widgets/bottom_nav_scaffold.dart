import 'package:flutter/material.dart';

class BottomNavScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final Widget body;
  final int cartBadgeCount;

  const BottomNavScaffold({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.body,
    this.cartBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: body,
      bottomNavigationBar: Container(
        height: 82,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home',
                  isSelected: currentIndex == 0),
              _buildNavItem(1, Icons.search_rounded, 'Search',
                  isSelected: currentIndex == 1),
              _buildNavItem(3, Icons.favorite_border_rounded, 'Wishlist',
                  isSelected: currentIndex == 3),
              _buildCartItem(cartBadgeCount),
              _buildNavItem(4, Icons.person_outline_rounded, 'Profile',
                  isSelected: currentIndex == 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label,
      {required bool isSelected}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabSelected(index),
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSlide(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              offset: isSelected ? const Offset(0, -0.08) : Offset.zero,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                scale: isSelected ? 1.08 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 36,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1C7BFF).withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? const Color(0xFF1C7BFF)
                        : const Color(0xFF7A8194),
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF1C7BFF)
                    : const Color(0xFF7A8194),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(
                label,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(int badgeCount) {
    final isSelected = currentIndex == 2;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabSelected(2),
      child: SizedBox(
        width: 68,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSlide(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  offset: isSelected ? const Offset(0, -0.08) : Offset.zero,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    scale: isSelected ? 1.08 : 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: 36,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1C7BFF).withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: isSelected
                            ? const Color(0xFF1C7BFF)
                            : const Color(0xFF7A8194),
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF1C7BFF)
                        : const Color(0xFF7A8194),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: const Text('Cart'),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                right: 10,
                top: 2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1C7BFF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
