import 'package:flutter/foundation.dart';
import '../../../data/mock_data.dart';
import '../../../domain/models/review.dart';

class ReviewsViewModel extends ChangeNotifier {
  final List<ProductReview> _reviews = List.from(MockData.reviews);

  List<ProductReview> get reviews => List.unmodifiable(_reviews);

  double get averageRating {
    if (_reviews.isEmpty) return 5.0;
    return _reviews.fold(0.0, (sum, r) => sum + r.rating) / _reviews.length;
  }

  void addReview({required String author, required double rating, required String comment}) {
    _reviews.insert(
      0,
      ProductReview(
        id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
        productId: 'phone-1',
        author: author,
        rating: rating,
        date: 'Just now',
        comment: comment,
        isVerifiedPurchaser: true,
        helpfulCount: 0,
      ),
    );
    notifyListeners();
  }
}
