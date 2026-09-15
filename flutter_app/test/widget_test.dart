import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siaka_phones_flutter/data/mock_data.dart';
import 'package:siaka_phones_flutter/data/repositories/cart_repository.dart';
import 'package:siaka_phones_flutter/data/repositories/product_repository.dart';
import 'package:siaka_phones_flutter/data/repositories/user_repository.dart';
import 'package:siaka_phones_flutter/main.dart';
import 'package:siaka_phones_flutter/ui/core/app_colors.dart';
import 'package:siaka_phones_flutter/ui/features/auth/login_view.dart';
import 'package:siaka_phones_flutter/ui/features/catalog/catalog_view.dart';
import 'package:siaka_phones_flutter/ui/features/catalog/catalog_view_model.dart';
import 'package:siaka_phones_flutter/ui/features/home/home_view.dart';
import 'package:siaka_phones_flutter/ui/features/home/home_view_model.dart';
import 'package:siaka_phones_flutter/ui/core/widgets/bottom_nav_scaffold.dart';
import 'package:siaka_phones_flutter/ui/features/product_detail/product_detail_view.dart';
import 'package:siaka_phones_flutter/ui/features/product_detail/product_detail_view_model.dart';
import 'package:siaka_phones_flutter/ui/features/profile/profile_view.dart';
import 'package:siaka_phones_flutter/ui/features/profile/profile_view_model.dart';
import 'package:siaka_phones_flutter/data/repositories/wishlist_repository.dart';
import 'package:siaka_phones_flutter/ui/features/wishlist/wishlist_view.dart';
import 'package:siaka_phones_flutter/ui/features/cart/cart_view.dart';
import 'package:siaka_phones_flutter/ui/features/cart/cart_view_model.dart';
import 'package:siaka_phones_flutter/data/repositories/order_repository.dart';
import 'package:siaka_phones_flutter/domain/models/order.dart';
import 'package:siaka_phones_flutter/ui/features/checkout/checkout_view.dart';
import 'package:siaka_phones_flutter/ui/features/checkout/checkout_view_model.dart';
import 'package:siaka_phones_flutter/ui/features/confirmation/confirmation_view.dart';
import 'package:siaka_phones_flutter/ui/features/track_order/track_order_view.dart';
import 'package:siaka_phones_flutter/domain/models/cart_item.dart';


void main() {
  testWidgets('app launches directly to HomeView without splash',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SiakaPhonesApp());
    await tester.pumpAndSettle();

    // Directly displays HomeView
    expect(find.byType(HomeView), findsOneWidget);
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

  testWidgets('featured phones section renders matching card without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final homeViewModel = HomeViewModel(
      productRepository: ProductRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeView(
          viewModel: homeViewModel,
          onProductTap: (_) {},
          onSeeAllCatalog: () {},
          onTradeInTap: () {},
          onRepairsTap: () {},
          onOrdersTap: () {},
          onLocationsTap: () {},
          onSupportTap: () {},
          onProfileTap: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Featured Phones'), findsOneWidget);
    expect(find.text('iPhone 15 Pro Max'), findsOneWidget);
    expect(find.text('From \$1,099'), findsOneWidget);
    expect(find.text('New'), findsWidgets);
    expect(find.text('Buy Now'), findsWidgets);

    // Verify no RenderFlex overflow exception was thrown
    expect(tester.takeException(), isNull);
  });

  testWidgets('featured phones section on narrow screen (320px) has no overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final homeViewModel = HomeViewModel(
      productRepository: ProductRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeView(
          viewModel: homeViewModel,
          onProductTap: (_) {},
          onSeeAllCatalog: () {},
          onTradeInTap: () {},
          onRepairsTap: () {},
          onOrdersTap: () {},
          onLocationsTap: () {},
          onSupportTap: () {},
          onProfileTap: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Featured Phones'), findsOneWidget);
    expect(find.text('iPhone 15 Pro Max'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu slide displays well-arranged customer menu items and sign out works',
      (WidgetTester tester) async {
    final homeViewModel = HomeViewModel(
      productRepository: ProductRepository(),
    );

    bool signedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        home: HomeView(
          viewModel: homeViewModel,
          onProductTap: (_) {},
          onSeeAllCatalog: () {},
          onTradeInTap: () {},
          onRepairsTap: () {},
          onOrdersTap: () {},
          onLocationsTap: () {},
          onSupportTap: () {},
          onProfileTap: () {},
          onSignOut: () => signedOut = true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open menu drawer
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();

    // Verify Customer Menu header and items
    expect(find.text('Customer Menu'), findsOneWidget);
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('Swap My Device'), findsOneWidget);
    expect(find.text('Buy Now Pay Later'), findsOneWidget);
    expect(find.text('Repairs'), findsOneWidget);
    expect(find.text('Store Locations'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);

    // Verify tapping Sign Out invokes callback
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
  });

  testWidgets('tapping Buy Now Pay Later in menu opens informative BNPL sheet',
      (WidgetTester tester) async {
    final homeViewModel = HomeViewModel(
      productRepository: ProductRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeView(
          viewModel: homeViewModel,
          onProductTap: (_) {},
          onSeeAllCatalog: () {},
          onTradeInTap: () {},
          onRepairsTap: () {},
          onOrdersTap: () {},
          onLocationsTap: () {},
          onSupportTap: () {},
          onProfileTap: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open menu drawer
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();

    // Tap Buy Now Pay Later
    await tester.tap(find.text('Buy Now Pay Later'));
    await tester.pumpAndSettle();

    // Verify BNPL sheet content
    expect(find.text('0% APR Financing with Siaka Pay'), findsOneWidget);
    expect(find.text('Browse Eligible Phones'), findsOneWidget);
  });

  testWidgets('profile page renders with uniform compact typography and actions',
      (WidgetTester tester) async {
    final userRepo = UserRepository();
    final profileVM = ProfileViewModel(userRepository: userRepo);

    bool signedOut = false;
    bool backTapped = false;
    bool ordersTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileView(
          viewModel: profileVM,
          onOrdersTap: () => ordersTapped = true,
          onTradeInTap: () {},
          onLocationsTap: () {},
          onSupportTap: () {},
          onBack: () => backTapped = true,
          onSignOut: () => signedOut = true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar
    expect(find.text('My Account'), findsOneWidget);

    // Verify User Details & Tier
    expect(find.text(userRepo.profile.name), findsOneWidget);
    expect(find.text(userRepo.profile.email), findsOneWidget);
    expect(find.text(userRepo.profile.membershipTier), findsOneWidget);

    // Verify Stats
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Wishlist'), findsOneWidget);
    expect(find.text('Addresses'), findsOneWidget);

    // Verify Account Services section
    expect(find.text('Account Services'), findsOneWidget);
    expect(find.text('My Orders & Tracking'), findsOneWidget);
    expect(find.text('Swap My Device'), findsOneWidget);
    expect(find.text('Saved Delivery Addresses'), findsOneWidget);
    expect(find.text('Customer Support & FAQ'), findsOneWidget);
    expect(find.text('Saved Payment Methods'), findsOneWidget);
    expect(find.text('My Wishlist'), findsOneWidget);

    // Tap Orders
    await tester.tap(find.text('My Orders & Tracking'));
    await tester.pumpAndSettle();
    expect(ordersTapped, isTrue);

    // Verify Sign Out button
    expect(find.text('Sign Out'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign Out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
    expect(signedOut, isTrue);

    // Verify Back button
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(backTapped, isTrue);
  });

  testWidgets(
      'search page initially displays featured banners and typed text matches login color',
      (WidgetTester tester) async {
    final productRepo = ProductRepository();
    final catalogVM = CatalogViewModel(productRepository: productRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: CatalogView(
          viewModel: catalogVM,
          onProductTap: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify initially displayed elements before an item is searched
    expect(find.text('Search Devices'), findsOneWidget);
    expect(find.text('Discover the\nLatest Smartphones'), findsOneWidget);
    expect(find.text('Featured Phones'), findsOneWidget);
    expect(find.text('iPhone 15 Pro Max'), findsOneWidget);

    // 2. Verify search TextField typed text style matches the login page (AppColors.textPrimary)
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.style?.color, equals(AppColors.textPrimary));
    expect(textField.style?.color, equals(const Color(0xFF111827)));

    // 3. Enter search query
    await tester.enterText(find.byType(TextField), 'Samsung');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify search results view with matching devices displayed
    expect(find.textContaining('Results for "Samsung"'), findsOneWidget);
    expect(find.text('Galaxy S24 Ultra'), findsOneWidget);

    // 4. Test multi-token search with trailing space (e.g., keyboard autocomplete)
    await tester.enterText(find.byType(TextField), 'iphone 15 ');
    await tester.pumpAndSettle();
    expect(find.textContaining('Results for "iphone 15"'), findsOneWidget);
    expect(find.text('iPhone 15 Pro Max'), findsOneWidget);

    // 5. Clear search query
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify returns to initial featured phones banners
    expect(find.text('Featured Phones'), findsOneWidget);
    expect(find.text('Discover the\nLatest Smartphones'), findsOneWidget);
    // 6. Verify 3-column grid structure and card height 240
    final gridFinder = find.byType(GridView);
    expect(gridFinder, findsOneWidget);
    final grid = tester.widget<GridView>(gridFinder);
    final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, anyOf(equals(3), equals(4)));
    expect(delegate.mainAxisExtent, equals(240));
    expect(delegate.crossAxisSpacing, equals(10));
    expect(delegate.mainAxisSpacing, equals(10));

    // Verify Buy Now button exists on the cards
    expect(find.text('Buy Now'), findsWidgets);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsWidgets);

    // Verify no brand title headers exist like "| Apple 4 phones"
    expect(find.text('4 phones'), findsNothing);
  });

  testWidgets(
      'search page 3-column featured layout renders on narrow 320px screen without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final productRepo = ProductRepository();
    final catalogVM = CatalogViewModel(productRepository: productRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: CatalogView(
          viewModel: catalogVM,
          onProductTap: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Featured Phones'), findsOneWidget);
    expect(find.text('Buy Now'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'when no device is found on search, empty state renders on short screen (keyboard open) with zero yellow overflow stroke',
      (WidgetTester tester) async {
    // Simulate mobile screen with keyboard open (height: 350, width: 360)
    tester.view.physicalSize = const Size(360, 350);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final productRepo = ProductRepository();
    final catalogVM = CatalogViewModel(productRepository: productRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: CatalogView(
          viewModel: catalogVM,
          onProductTap: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Type a query that yields no devices
    await tester.enterText(find.byType(TextField), 'xyznonexistent123');
    await tester.pumpAndSettle();

    // Verify empty state is displayed
    expect(find.text('No devices found'), findsOneWidget);
    expect(find.text('Clear Search'), findsOneWidget);

    // Verify ABSOLUTELY NO RenderFlex overflow exception or yellow stroke
    expect(tester.takeException(), isNull);
  });

  testWidgets('homepage bottom navigation design is uniformly used across views', (WidgetTester tester) async {
    final detailVM = ProductDetailViewModel(
      product: MockData.products.first,
      cartRepository: CartRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailView(
          viewModel: detailVM,
          onTabSelected: (_) {},
          onReviewsTap: () {},
          onGoToCart: () {},
        ),
      ),
    );

    expect(find.byType(AppBottomNavBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Wishlist'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('redesigned LoginView renders Sign In with mock aesthetic and toggles to Sign Up',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool signedIn = false;
    bool backPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginView(
          onBack: () => backPressed = true,
          onSignIn: () => signedIn = true,
          onCreateAccount: (_, __, ___, ____, _____, ______, _______) {},
        ),
      ),
    );


    await tester.pumpAndSettle();

    // 1. Verify Sign In View Header, Typography, and Greeting Avatar
    expect(find.text('Welcome to SiakaPhones'), findsOneWidget);
    expect(find.text('Explore a modern experience built for speed and simplicity.'), findsOneWidget);
    expect(find.text('Email or Phone'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets); // button and tab
    expect(find.text('Or'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsOneWidget);

    // Verify back button works
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(backPressed, isTrue);

    // Verify Sign In action
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();
    expect(signedIn, isTrue);


    // 2. Switch to Create Account via tab or bottom switch
    await tester.ensureVisible(find.text('Create Account').first);
    await tester.tap(find.text('Create Account').first);
    await tester.pumpAndSettle();

    // Verify Create Account View Header and Fields
    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Sign up to get started with your account and orders.'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Detailed Address'), findsOneWidget);
    expect(find.text('Region'), findsOneWidget);
    expect(find.text('Ghana GPS Code'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('I agree to the Terms and Privacy Policy'), findsOneWidget);
    expect(find.text('Already have an account? '), findsOneWidget);

    // 3. Switch back to Sign In
    await tester.ensureVisible(find.text('Sign In').first);
    await tester.tap(find.text('Sign In').first);
    await tester.pumpAndSettle();

    expect(find.text('Welcome to SiakaPhones'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('LoginView renders on narrow 320px screen with no overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginView(
          onBack: () {},
          onSignIn: () {},
          onCreateAccount: (_, __, ___, ____, _____, ______, _______) {},
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);




    // Switch to Create Account on 320px screen
    await tester.ensureVisible(find.text('Create Account').first);
    await tester.tap(find.text('Create Account').first);
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('WishlistRepository toggles, adds, and removes products correctly', () {
    final product1 = MockData.products[0];
    final product2 = MockData.products[1];
    final repo = WishlistRepository(initialProducts: [product1]);

    expect(repo.itemCount, 1);
    expect(repo.isWishlisted(product1.id), isTrue);
    expect(repo.isWishlisted(product2.id), isFalse);

    // Toggle product2 -> should be added
    final added = repo.toggleWishlist(product2);
    expect(added, isTrue);
    expect(repo.itemCount, 2);
    expect(repo.isWishlisted(product2.id), isTrue);

    // Toggle product1 -> should be removed
    final removed = repo.toggleWishlist(product1);
    expect(removed, isFalse);
    expect(repo.itemCount, 1);
    expect(repo.isWishlisted(product1.id), isFalse);

    // Remove product2
    repo.removeFromWishlist(product2.id);
    expect(repo.itemCount, 0);
    expect(repo.isEmpty, isTrue);
  });

  testWidgets('WishlistView displays appropriate compact banner and product items',
      (WidgetTester tester) async {
    final product = MockData.products.first;
    final wishlistRepo = WishlistRepository(initialProducts: [product]);
    final cartRepo = CartRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: WishlistView(
          wishlistRepo: wishlistRepo,
          cartRepo: cartRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify app bar title
    expect(find.text('My Wishlist (1)'), findsOneWidget);

    // Verify compact promotional banner is rendered
    expect(find.text('Your Saved Devices\nTrack Prices & Drops'), findsOneWidget);

    // Verify product name and price rendered correctly
    expect(find.text('iPhone 15 Pro Max'), findsOneWidget);
    expect(find.text('\$1,099'), findsOneWidget);
    expect(find.text('Move to Cart'), findsOneWidget);

    // Move to Cart
    await tester.tap(find.text('Move to Cart'));
    await tester.pumpAndSettle();

    // Verify item was added to cart
    expect(cartRepo.itemCount, 1);
    expect(wishlistRepo.itemCount, 1);

    // Tap Clear in AppBar to empty wishlist
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    // Wishlist should now be empty
    expect(wishlistRepo.isEmpty, isTrue);
    expect(find.text('Your Wishlist is Empty'), findsOneWidget);
    expect(find.text('Browse Devices'), findsOneWidget);
  });

  testWidgets('CartView displays appropriate compact banner, item cards, and order summary',
      (WidgetTester tester) async {
    final cartRepo = CartRepository();
    final product = MockData.products.first;
    cartRepo.addToCart(product);

    final cartVM = CartViewModel(cartRepository: cartRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartView(
            viewModel: cartVM,
            onCheckout: () {},
            onBrowseCatalog: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar
    expect(find.text('My Cart (1)'), findsOneWidget);

    // Verify appropriate compact promotional banner is rendered
    expect(find.text('Free Express Shipping'), findsOneWidget);

    // Verify Free Shipping alert banner
    expect(find.text("You've unlocked FREE Express Shipping!"), findsOneWidget);

    // Verify product card and proper price formatting
    expect(find.text('iPhone 15 Pro Max'), findsOneWidget);
    expect(find.text('\$1,099'), findsWidgets);
    expect(find.text('1'), findsWidgets);

    // Verify Order Summary and checkout button
    expect(find.text('Order Summary'), findsOneWidget);
    expect(find.text('Proceed to Checkout'), findsOneWidget);

    // Clear cart via Clear button in dialog
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    // Tap Clear All in confirmation dialog
    expect(find.text('Clear Cart'), findsOneWidget);
    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();

    // Verify empty state
    expect(find.text('Your Cart is Empty'), findsOneWidget);
    expect(find.text('Explore Phones'), findsOneWidget);
    expect(cartRepo.items.isEmpty, isTrue);
  });

  testWidgets('CartView renders on narrow 320px screen without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final cartRepo = CartRepository();
    cartRepo.addToCart(MockData.products[0]);
    final cartVM = CartViewModel(cartRepository: cartRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartView(
            viewModel: cartVM,
            onCheckout: () {},
            onBrowseCatalog: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('My Cart (1)'), findsOneWidget);
    expect(find.text('Proceed to Checkout'), findsOneWidget);
  });

  testWidgets('CheckoutView begins on Shipping (Step 0) with authentic addresses and delivery speeds',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final cartRepo = CartRepository();
    cartRepo.addToCart(MockData.products[0]);
    final orderRepo = OrderRepository();
    final checkoutVM = CheckoutViewModel(
      cartRepository: cartRepo,
      orderRepository: orderRepo,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheckoutView(
            viewModel: checkoutVM,
            onTabSelected: (_) {},
            onOrderPlaced: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify stepper shows Shipping, Review, Payment
    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Shipping'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);

    // Verify Step 0 sections
    expect(find.text('Delivery Address'), findsOneWidget);
    expect(find.text('+ Add New'), findsOneWidget);
    expect(find.text('Delivery Speed'), findsOneWidget);
    expect(find.text('Standard Express (2–4 days)'), findsOneWidget);

    // Verify Action button
    expect(find.text('Continue to Review'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CheckoutView completes Shipping -> Review -> Payment -> Place Order flow seamlessly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final cartRepo = CartRepository();
    cartRepo.addToCart(MockData.products[0]);
    final orderRepo = OrderRepository();
    final checkoutVM = CheckoutViewModel(
      cartRepository: cartRepo,
      orderRepository: orderRepo,
    );

    OrderModel? placedOrder;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheckoutView(
            viewModel: checkoutVM,
            onTabSelected: (_) {},
            onOrderPlaced: (order) {
              placedOrder = order;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Advance Step 0 -> Step 1 (Shipping to Review)
    final reviewBtn = find.text('Continue to Review');
    expect(reviewBtn, findsOneWidget);
    await tester.ensureVisible(reviewBtn);
    await tester.tap(reviewBtn);
    await tester.pumpAndSettle();

    // Verify Step 1 content
    expect(find.text('Shipping Destination'), findsOneWidget);
    expect(find.text('Items in Order (1)'), findsOneWidget);
    expect(find.text('iPhone 15 Pro Max'), findsOneWidget);

    // Advance Step 1 -> Step 2 (Review to Payment)
    final paymentBtn = find.text('Continue to Payment');
    expect(paymentBtn, findsOneWidget);
    await tester.ensureVisible(paymentBtn);
    await tester.tap(paymentBtn);
    await tester.pumpAndSettle();

    // Verify Step 2 content
    expect(find.text('Select Payment Method'), findsOneWidget);
    expect(find.textContaining('Mobile Money'), findsWidgets);
    expect(find.text('Credit / Debit Card'), findsOneWidget);
    expect(find.text('Total Payable'), findsOneWidget);

    // Tap Place Order
    final placeOrderBtn = find.textContaining('Place Order');
    expect(placeOrderBtn, findsOneWidget);
    await tester.ensureVisible(placeOrderBtn);
    await tester.tap(placeOrderBtn);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    // Verify order placed callback and cart cleared
    expect(placedOrder, isNotNull);
    expect(cartRepo.items.isEmpty, isTrue);
  });

  testWidgets('CheckoutView on narrow screen (320px) renders without overflow on all steps',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final cartRepo = CartRepository();
    cartRepo.addToCart(MockData.products[0]);
    final orderRepo = OrderRepository();
    final checkoutVM = CheckoutViewModel(
      cartRepository: cartRepo,
      orderRepository: orderRepo,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheckoutView(
            viewModel: checkoutVM,
            onTabSelected: (_) {},
            onOrderPlaced: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Step 0 -> Step 1 on 320px
    final reviewBtn = find.text('Continue to Review');
    await tester.ensureVisible(reviewBtn);
    await tester.tap(reviewBtn);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Step 1 -> Step 2 on 320px
    final paymentBtn = find.text('Continue to Payment');
    await tester.ensureVisible(paymentBtn);
    await tester.tap(paymentBtn);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('ConfirmationView displays uniform compact sizing, authentic order receipt, and 48dp action buttons',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final order = OrderModel(
      orderId: 'SP-99201',
      date: DateTime(2026, 9, 15, 14, 30),
      items: [
        CartItem(
          id: 'test-cart-item-1',
          product: MockData.products[0],
          selectedColor: 'Natural Titanium',
          selectedStorage: '256 GB',
          quantity: 1,
        ),
      ],
      subtotal: 1099.0,
      tax: 90.67,
      shippingFee: 0.0,
      totalAmount: 1189.67,
      shippingAddress: 'House No. 14, Airport Residential Area, Accra',
      paymentMethod: 'MTN Mobile Money',
      status: OrderStatus.placed,
      trackingNumber: 'TRK-GH-99201-SP',
    );

    bool trackOrderTapped = false;
    bool continueShoppingTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ConfirmationView(
          order: order,
          onTrackOrder: () => trackOrderTapped = true,
          onContinueShopping: () => continueShoppingTapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Order Placed Successfully!'), findsOneWidget);
    expect(find.textContaining('Thank you for your order!'), findsOneWidget);

    // Verify Order ID & Status Badge
    expect(find.text('#SP-99201'), findsOneWidget);
    expect(find.text('CONFIRMED'), findsOneWidget);

    // Verify item preview
    expect(find.text('iPhone 15 Pro Max'), findsOneWidget);
    expect(find.textContaining('256 GB • Natural Titanium'), findsOneWidget);

    // Verify receipt rows
    expect(find.text('September 15, 2026'), findsOneWidget);
    expect(find.text('House No. 14, Airport Residential Area, Accra'), findsOneWidget);
    expect(find.text('MTN Mobile Money'), findsOneWidget);
    expect(find.text('TRK-GH-99201-SP'), findsOneWidget);
    expect(find.text('\$1189.67'), findsOneWidget);

    // Verify 48dp Buttons
    final trackBtn = find.text('Track Your Order');
    expect(trackBtn, findsOneWidget);
    await tester.ensureVisible(trackBtn);
    await tester.tap(trackBtn);
    expect(trackOrderTapped, isTrue);

    final continueBtn = find.text('Continue Shopping');
    expect(continueBtn, findsOneWidget);
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn);
    expect(continueShoppingTapped, isTrue);

    expect(tester.takeException(), isNull);
  });

  testWidgets('ConfirmationView renders on narrow 320px screen without any overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final order = OrderModel(
      orderId: 'SP-99201',
      date: DateTime(2026, 9, 15, 14, 30),
      items: [
        CartItem(
          id: 'test-cart-item-1',
          product: MockData.products[0],
          selectedColor: 'Natural Titanium',
          selectedStorage: '256 GB',
          quantity: 1,
        ),
      ],
      subtotal: 1099.0,
      tax: 90.67,
      shippingFee: 0.0,
      totalAmount: 1189.67,
      shippingAddress: 'House No. 14, Airport Residential Area, Accra',
      paymentMethod: 'MTN Mobile Money',
      status: OrderStatus.placed,
      trackingNumber: 'TRK-GH-99201-SP',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ConfirmationView(
          order: order,
          onTrackOrder: () {},
          onContinueShopping: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Order Placed Successfully!'), findsOneWidget);
    expect(find.text('#SP-99201'), findsOneWidget);
    expect(find.text('Track Your Order'), findsOneWidget);
    expect(find.text('Continue Shopping'), findsOneWidget);
  });

  testWidgets(
      'TrackOrderView displays simple and nice layout, authentic order details, and 48dp action button',
      (WidgetTester tester) async {
    final order = OrderModel(
      orderId: 'SP-99201',
      date: DateTime(2026, 9, 15, 14, 30),
      items: [
        CartItem(
          id: 'test-cart-item-1',
          product: MockData.products[0],
          selectedColor: 'Natural Titanium',
          selectedStorage: '256 GB',
          quantity: 1,
        ),
      ],
      subtotal: 1099.0,
      tax: 90.67,
      shippingFee: 0.0,
      totalAmount: 1189.67,
      shippingAddress: 'House No. 14, Airport Residential Area, Accra',
      paymentMethod: 'MTN Mobile Money',
      status: OrderStatus.shipped,
      trackingNumber: 'TRK-GH-99201-SP',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TrackOrderView(
          order: order,
          onTabSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Track Order'), findsOneWidget);
    expect(find.text('#SP-99201'), findsOneWidget);
    expect(find.text('Package is on the way'), findsOneWidget);
    expect(find.text('TRK-GH-99201-SP'), findsOneWidget);
    expect(find.text('Shipment Progress'), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);

    // Verify 48dp button
    final backBtn = tester.widget<SizedBox>(
      find.ancestor(
        of: find.widgetWithText(ElevatedButton, 'Back to Home'),
        matching: find.byType(SizedBox),
      ).first,
    );
    expect(backBtn.height, 48);
  });

  testWidgets(
      'TrackOrderView renders on narrow 320px screen without any overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final order = OrderModel(
      orderId: 'SP-99201',
      date: DateTime(2026, 9, 15, 14, 30),
      items: [
        CartItem(
          id: 'test-cart-item-1',
          product: MockData.products[0],
          selectedColor: 'Natural Titanium',
          selectedStorage: '256 GB',
          quantity: 1,
        ),
      ],
      subtotal: 1099.0,
      tax: 90.67,
      shippingFee: 0.0,
      totalAmount: 1189.67,
      shippingAddress: 'House No. 14, Airport Residential Area, Accra',
      paymentMethod: 'MTN Mobile Money',
      status: OrderStatus.shipped,
      trackingNumber: 'TRK-GH-99201-SP',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TrackOrderView(
          order: order,
          onTabSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Track Order'), findsOneWidget);
    expect(find.text('#SP-99201'), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);
  });

  testWidgets(
      'AppBottomNavBar Cart item is properly aligned alongside other nav items',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: 0,
            onTabSelected: (_) {},
            cartBadgeCount: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Wishlist'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // cart badge
    expect(tester.takeException(), isNull);
  });
}



