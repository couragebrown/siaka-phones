class ProductReview {
  final String id;
  final String productId;
  final String author;
  final double rating;
  final String date;
  final String comment;
  final bool isVerifiedPurchaser;
  final int helpfulCount;

  const ProductReview({
    required this.id,
    required this.productId,
    required this.author,
    required this.rating,
    required this.date,
    required this.comment,
    this.isVerifiedPurchaser = true,
    this.helpfulCount = 0,
  });
}
