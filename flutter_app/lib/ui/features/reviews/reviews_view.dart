import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/rating_stars.dart';
import '../../core/widgets/neon_button.dart';
import '../../../domain/models/review.dart';
import 'reviews_view_model.dart';

class ReviewsView extends StatefulWidget {
  final ReviewsViewModel viewModel;

  const ReviewsView({super.key, required this.viewModel});

  @override
  State<ReviewsView> createState() => _ReviewsViewState();
}

class _ReviewsViewState extends State<ReviewsView> {
  void _showAddReviewDialog() {
    double selectedRating = 5.0;
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Write a Verified Review', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.neonAmber,
                      size: 28,
                    ),
                    onPressed: () {
                      setModalState(() {
                        selectedRating = (index + 1).toDouble();
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: TextField(
                  controller: textController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Share your experience with build quality, battery life, camera...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              NeonButton(
                label: 'Post Review',
                onPressed: () {
                  if (textController.text.trim().isNotEmpty) {
                    widget.viewModel.addReview(
                      author: 'Courage Brown',
                      rating: selectedRating,
                      comment: textController.text.trim(),
                    );
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final reviews = widget.viewModel.reviews;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Ratings & Reviews'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Rating Overview Card
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.viewModel.averageRating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900),
                        ),
                        RatingStars(rating: widget.viewModel.averageRating, starSize: 16),
                        const SizedBox(height: 4),
                        Text(
                          'Based on ${reviews.length} customer reviews',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Write Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: _showAddReviewDialog,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text('Customer Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),

              ...reviews.map((r) => _buildReviewCard(r)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(ProductReview review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.surfaceElevated,
                      child: Text(
                        review.author.substring(0, 1),
                        style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      review.author,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  review.date,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                RatingStars(rating: review.rating, starSize: 12),
                if (review.isVerifiedPurchaser) ...[
                  const SizedBox(width: 8),
                  const Text('•  Verified Buyer', style: TextStyle(color: AppColors.neonEmerald, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
