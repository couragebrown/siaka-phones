import 'package:flutter/material.dart';
import '../../../domain/models/product.dart';

class FeaturedPhoneCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool isWishlisted;
  final VoidCallback? onWishlistTap;

  const FeaturedPhoneCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isWishlisted = false,
    this.onWishlistTap,
  });

  String _formatFeaturedPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'From \$$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            // Top Row: "New" badge (left) & Wishlist heart icon (right)
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
                  onTap: onWishlistTap,
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
            // Center: Phone Mockup Visual
            Expanded(
              child: Center(
                child: ProductPhoneGraphic(product: product),
              ),
            ),
            const SizedBox(height: 4),

            // Product Title
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

            // Price ("From $1,099")
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

            // Rating Row: Star 4.8 (245)
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

            // Action button: Full-width blue "Buy Now" button with cart icon
            SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                onPressed: onTap,
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
}

class ProductPhoneGraphic extends StatelessWidget {
  final Product product;

  const ProductPhoneGraphic({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
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
            painter: PhoneMockupPainter(
              brand: product.brand,
              name: product.name,
            ),
          ),
        );
      },
    );
  }
}

class PhoneMockupPainter extends CustomPainter {
  final String brand;
  final String name;

  const PhoneMockupPainter({
    required this.brand,
    required this.name,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bool isApple = brand.toLowerCase() == 'apple' ||
        name.toLowerCase().contains('iphone');
    final bool isSamsung = brand.toLowerCase() == 'samsung' ||
        name.toLowerCase().contains('galaxy');

    final center = Offset(size.width / 2, size.height / 2);
    final phoneWidth = size.width * 0.46;
    final phoneHeight = size.height * 0.94;
    final cornerRadius = isSamsung ? 5.0 : 13.0;

    // 1. Back Phone (positioned on the left side)
    final backLeft = center.dx - phoneWidth * 0.88;
    final backTop = center.dy - phoneHeight / 2;
    final backRect =
        Rect.fromLTWH(backLeft, backTop, phoneWidth, phoneHeight);
    final backRRect =
        RRect.fromRectAndRadius(backRect, Radius.circular(cornerRadius));

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
      final islandRect =
          Rect.fromLTWH(backLeft + 4, backTop + 4, islandWidth, islandHeight);
      final islandRRect =
          RRect.fromRectAndRadius(islandRect, const Radius.circular(8));

      final islandPaint = Paint()..color = const Color(0xFF1E222A);
      canvas.drawRRect(islandRRect, islandPaint);
      final islandStroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.12);
      canvas.drawRRect(islandRRect, islandStroke);

      final lensRadius = islandWidth * 0.20;
      final lensCenters = [
        Offset(islandRect.left + islandWidth * 0.32,
            islandRect.top + islandHeight * 0.30),
        Offset(islandRect.left + islandWidth * 0.32,
            islandRect.top + islandHeight * 0.70),
        Offset(islandRect.left + islandWidth * 0.70,
            islandRect.top + islandHeight * 0.50),
      ];

      for (final lc in lensCenters) {
        final ringPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF7B8496);
        canvas.drawCircle(lc, lensRadius, ringPaint);

        final glassPaint = Paint()..color = const Color(0xFF090B0E);
        canvas.drawCircle(lc, lensRadius - 0.6, glassPaint);

        final highlightPaint = Paint()
          ..color = const Color(0xFF60A5FA).withValues(alpha: 0.45);
        canvas.drawCircle(
            Offset(lc.dx - 1.2, lc.dy - 1.2), lensRadius * 0.35, highlightPaint);
      }

      // Flash & LiDAR
      final flashCenter = Offset(islandRect.left + islandWidth * 0.72,
          islandRect.top + islandHeight * 0.24);
      canvas.drawCircle(flashCenter, 2.0, Paint()..color = const Color(0xFFFEF3C7));

      final lidarCenter = Offset(islandRect.left + islandWidth * 0.72,
          islandRect.top + islandHeight * 0.76);
      canvas.drawCircle(lidarCenter, 1.8, Paint()..color = const Color(0xFF111418));

      // Apple logo in center of back phone
      final logoCenter =
          Offset(backLeft + phoneWidth / 2, backTop + phoneHeight * 0.52);
      final logoPaint = Paint()
        ..color = const Color(0xFF8E97A8).withValues(alpha: 0.75);
      canvas.drawCircle(logoCenter, 4.2, logoPaint);
      canvas.drawCircle(
          Offset(logoCenter.dx + 3.0, logoCenter.dy - 0.5),
          2.0,
          Paint()..color = backColorBottom);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(logoCenter.dx + 0.8, logoCenter.dy - 5.5),
            width: 2.2,
            height: 1.4),
        logoPaint,
      );
    } else {
      final lensX = backLeft + 8.0;
      for (int i = 0; i < 3; i++) {
        final lc = Offset(lensX, backTop + 12.0 + (i * 14.0));
        canvas.drawCircle(
            lc,
            4.5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2
              ..color = const Color(0xFF7B8496));
        canvas.drawCircle(lc, 3.8, Paint()..color = const Color(0xFF090B0E));
        canvas.drawCircle(
            Offset(lc.dx - 1, lc.dy - 1),
            1.5,
            Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.4));
      }
    }

    // 2. Front Phone (positioned on the right, overlapping front)
    final frontLeft = center.dx - phoneWidth * 0.12;
    final frontTop = center.dy - phoneHeight / 2;
    final frontRect =
        Rect.fromLTWH(frontLeft, frontTop, phoneWidth, phoneHeight);
    final frontRRect =
        RRect.fromRectAndRadius(frontRect, Radius.circular(cornerRadius));

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
    final screenRRect = RRect.fromRectAndRadius(
        screenRect, Radius.circular(cornerRadius - 1.5));

    canvas.save();
    canvas.clipRRect(screenRRect);

    // Screen dark background
    canvas.drawPaint(Paint()..color = const Color(0xFF070B13));

    // Luminous organic blue wave wallpaper (signature ribbon)
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
    wavePath.moveTo(
        screenRect.right + 10, screenRect.top + screenRect.height * 0.18);
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
    canvas.drawRRect(
        homeRRect, Paint()..color = Colors.white.withValues(alpha: 0.7));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PhoneMockupPainter oldDelegate) {
    return oldDelegate.brand != brand || oldDelegate.name != name;
  }
}
