import 'package:flutter/material.dart';
import '../app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double starSize;

  const RatingStars({
    super.key,
    required this.rating,
    this.reviewCount,
    this.starSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final isFull = index < rating.floor();
          final isHalf = !isFull && (index < rating);
          return Icon(
            isFull
                ? Icons.star_rounded
                : (isHalf ? Icons.star_half_rounded : Icons.star_outline_rounded),
            size: starSize,
            color: AppColors.neonAmber,
          );
        }),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: starSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: starSize - 2,
            ),
          ),
        ],
      ],
    );
  }
}
