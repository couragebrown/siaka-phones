import 'package:flutter_test/flutter_test.dart';

import 'package:siaka_phones_flutter/data/mock_data.dart';
import 'package:siaka_phones_flutter/data/repositories/cart_repository.dart';
import 'package:siaka_phones_flutter/main.dart';
import 'package:siaka_phones_flutter/ui/features/auth/login_view.dart';
import 'package:siaka_phones_flutter/ui/features/product_detail/product_detail_view_model.dart';

void main() {
  testWidgets('app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const SiakaPhonesApp());

    expect(find.byType(LoginView), findsOneWidget);
  });

  test('adding a product updates the cart item count', () {
    final viewModel = ProductDetailViewModel(
      product: MockData.products.first,
      cartRepository: CartRepository(),
    );

    expect(viewModel.cartItemCount, 0);

    viewModel.addToCart();

    expect(viewModel.cartItemCount, 1);
  });
}
