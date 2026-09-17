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
import 'package:siaka_phones_flutter/data/repositories/location_repository.dart';
import 'package:siaka_phones_flutter/ui/features/locations/locations_view.dart';
import 'package:siaka_phones_flutter/ui/features/locations/locations_view_model.dart';
import 'package:siaka_phones_flutter/data/repositories/repair_repository.dart';
import 'package:siaka_phones_flutter/ui/features/repairs/repairs_view.dart';
import 'package:siaka_phones_flutter/ui/features/repairs/repairs_view_model.dart';
import 'package:siaka_phones_flutter/ui/features/support/support_view.dart';
import 'package:siaka_phones_flutter/ui/features/bnpl/bnpl_view.dart';
import 'package:siaka_phones_flutter/ui/features/bnpl/bnpl_view_model.dart';
import 'package:siaka_phones_flutter/ui/features/repairs/my_repairs_view.dart';
import 'package:siaka_phones_flutter/ui/features/tradein/tradein_view.dart';
import 'package:siaka_phones_flutter/ui/features/tradein/tradein_view_model.dart';
import 'package:siaka_phones_flutter/ui/features/tradein/devices_swapped_view.dart';
import 'package:siaka_phones_flutter/ui/features/splash/splash_view.dart';
import 'package:siaka_phones_flutter/ui/features/orders/orders_view.dart';
import 'package:siaka_phones_flutter/ui/features/orders/orders_view_model.dart';



void main() {
  testWidgets('app launches directly to HomeView without splash',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SiakaPhonesApp(startAuthenticated: true));
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
    expect(find.text('From ₵1,099'), findsOneWidget);
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
    expect(find.text('Support Team'), findsOneWidget);
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
    expect(find.text('My Repairs'), findsOneWidget);
    expect(find.text('Devices Swapped'), findsOneWidget);
    // Verify Saved Delivery Address row has small Edit button
    expect(find.text('Saved Delivery Address'), findsOneWidget);
    final editBtn = find.text('Edit');
    expect(editBtn, findsOneWidget);

    // Tapping on 'Saved Delivery Address' label text must NOT open the sheet
    await tester.tap(find.text('Saved Delivery Address'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Saved Address'), findsNothing);

    // Clicking directly on 'Edit' opens the edit address sheet
    await tester.tap(editBtn);
    await tester.pumpAndSettle();
    expect(find.text('Edit Saved Address'), findsOneWidget);
    expect(find.text('Detail Address / Street / House No.'), findsOneWidget);
    expect(find.text('Ghana GPS Digital Address'), findsOneWidget);

    // Save and close sheet
    await tester.tap(find.text('Save Address'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Saved Address'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Customer Support & FAQ'), findsOneWidget);
    expect(find.text('Saved Payment Methods'), findsOneWidget);
    expect(find.text('My Wishlist'), findsNothing);

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
 
    await tester.pumpWidget(
      MaterialApp(
        home: LoginView(
          onBack: () {},
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
    expect(find.byTooltip('Google'), findsOneWidget);
    expect(find.byIcon(Icons.apple), findsOneWidget);
    expect(find.byIcon(Icons.facebook), findsOneWidget);

    // Note: Back button was removed on Sign In page per user design request

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
    expect(find.byTooltip('Google'), findsOneWidget);
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
    expect(find.text('₵1,099'), findsOneWidget);
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
    expect(find.text('₵1,099'), findsWidgets);
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
    expect(find.text('Edit'), findsOneWidget);
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
    expect(find.text('₵1189.67'), findsOneWidget);

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

  testWidgets(
      'LocationsView displays Siaka Phones Circle, Madina, and Kasoa without search bar',
      (WidgetTester tester) async {
    final locationRepo = LocationRepository();
    final viewModel = LocationsViewModel(locationRepository: locationRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: LocationsView(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify all 3 stores display
    expect(find.text('Store Locations'), findsOneWidget);
    expect(find.text('Siaka Phones Circle'), findsOneWidget);
    expect(find.text('Siaka Phones Madina'), findsOneWidget);
    expect(find.text('Siaka Phones Kasoa'), findsOneWidget);
    expect(find.text('3 branches'), findsOneWidget);
    expect(find.text('GhanaPost GPS: GA-078-4321'), findsOneWidget);
    expect(find.text('GhanaPost GPS: GM-023-8890'), findsOneWidget);
    expect(find.text('GhanaPost GPS: CG-012-5544'), findsOneWidget);

    // 2. Verify search bar has been removed
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets(
      'RepairsView allows selecting problem, typing device model, choosing calendar date, entering description, and submitting without prices',
      (WidgetTester tester) async {
    final repairRepo = RepairRepository();
    final viewModel = RepairsViewModel(repairRepository: repairRepo);
    bool returnedHome = false;

    await tester.pumpWidget(
      MaterialApp(
        home: RepairsView(
          viewModel: viewModel,
          onReturnHome: () => returnedHome = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify header and sections
    expect(find.text('Express Repair Service'), findsOneWidget);
    expect(find.text('Select Problem to be Fixed'), findsOneWidget);
    expect(find.text('Send a Picture of the Device'), findsOneWidget);
    expect(find.text('What is Actually Wrong?'), findsOneWidget);

    // 2. Verify NO prices (₵) are displayed on the repair page
    expect(find.textContaining('₵'), findsNothing);
    expect(find.text('Free Inspection • Estimate Sent by Manager'), findsWidgets);

    // 3. Select problem: Battery Degradation
    expect(find.text('Battery Degradation / Fast Drain'), findsOneWidget);
    await tester.tap(find.text('Battery Degradation / Fast Drain'));
    await tester.pumpAndSettle();
    expect(viewModel.selectedIssue, 'Battery Degradation / Fast Drain');

    // 4. Attach a photo
    viewModel.setPhotoPath('/sdcard/test_damage.jpg');
    await tester.pumpAndSettle();
    expect(find.text('Photo Attached'), findsOneWidget);

    // 5. Type Device Model in the typed input field
    final modelField = find.byWidgetPredicate(
      (w) => w is TextField && (w.decoration?.hintText?.contains('phone model') ?? false),
    );
    expect(modelField, findsOneWidget);
    await tester.ensureVisible(modelField);
    await tester.pumpAndSettle();
    await tester.enterText(modelField, 'iPhone 15 Pro Max');
    await tester.pumpAndSettle();
    expect(viewModel.deviceModel, 'iPhone 15 Pro Max');

    // 6. Verify calendar / available day selection
    await tester.ensureVisible(find.text('Available Day (Calendar)'));
    await tester.pumpAndSettle();
    expect(find.text('Available Day (Calendar)'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);

    // 7. Input detailed description into large text box
    final descField = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          (w.decoration?.hintText?.contains('Describe what is actually wrong') ??
              false),
    );
    expect(descField, findsOneWidget);
    await tester.ensureVisible(descField);
    await tester.pumpAndSettle();
    await tester.enterText(
        descField, 'Phone battery drops from 60% to 0% in 10 minutes when using camera.');
    await tester.pumpAndSettle();
    expect(viewModel.description,
        'Phone battery drops from 60% to 0% in 10 minutes when using camera.');

    // 8. Submit Repair Request
    await tester.ensureVisible(find.text('Submit Repair Request'));
    await tester.pumpAndSettle();
    expect(find.text('Free Diagnostic & Quotation'), findsOneWidget);
    expect(find.text('Submit Repair Request'), findsOneWidget);
    await tester.tap(find.text('Submit Repair Request'));
    await tester.pumpAndSettle();

    // 9. Verify confirmation screen: no prices, shows manager quotation notice
    expect(find.text('Repair Request Submitted!'), findsOneWidget);
    expect(find.text('Ticket ID: ${viewModel.lastBooking!.id}'), findsOneWidget);
    expect(find.text('iPhone 15 Pro Max'), findsOneWidget);
    expect(find.text('Battery Degradation / Fast Drain'), findsOneWidget);
    expect(find.text('Sent by Store Manager'), findsOneWidget);
    expect(find.text('Store Manager Estimate Pending'), findsOneWidget);
    expect(find.textContaining('₵'), findsNothing);
    expect(find.text('Reported Fault Details'), findsOneWidget);
    expect(
        find.text(
            'Phone battery drops from 60% to 0% in 10 minutes when using camera.'),
        findsOneWidget);
    expect(find.text('Attached Damage Photo'), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);

    // 10. Tapping Back to Home calls onReturnHome and resets booking state
    await tester.ensureVisible(find.text('Back to Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();
    expect(returnedHome, isTrue);
    expect(viewModel.lastBooking, isNull);
  });

  testWidgets(
      'submitting repairs in app and tapping Back to Home returns user directly to HomeView',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SiakaPhonesApp(startAuthenticated: true));
    await tester.pumpAndSettle();

    // 1. App starts at HomeView
    expect(find.byType(HomeView), findsOneWidget);

    // 2. Open menu drawer and tap Repairs
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repairs'));
    await tester.pumpAndSettle();

    // 3. Verify on Express Repair Service screen
    expect(find.text('Express Repair Service'), findsOneWidget);

    // 4. Fill in device model
    final modelField = find.byWidgetPredicate(
      (w) => w is TextField && (w.decoration?.hintText?.contains('phone model') ?? false),
    );
    await tester.ensureVisible(modelField);
    await tester.pumpAndSettle();
    await tester.enterText(modelField, 'Samsung S24 Ultra');
    await tester.pumpAndSettle();

    // 5. Fill in fault description
    final descField = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          (w.decoration?.hintText?.contains('Describe what is actually wrong') ??
              false),
    );
    await tester.ensureVisible(descField);
    await tester.pumpAndSettle();
    await tester.enterText(descField, 'S-Pen not charging inside slot.');
    await tester.pumpAndSettle();

    // 6. Submit Repair Request
    final submitButton = find.text('Submit Repair Request');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // 7. Verify Confirmation ticket screen and Back to Home button
    expect(find.text('Repair Request Submitted!'), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);

    // 8. Tap Back to Home
    await tester.ensureVisible(find.text('Back to Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();

    // 9. Successfully back on HomeView
    expect(find.byType(HomeView), findsOneWidget);
    expect(find.text('Express Repair Service'), findsNothing);
    expect(find.text('Customer Menu'), findsNothing);
  });

  testWidgets(
      'when menu is opened and user navigates to another page and comes back, menu popup is dismissed',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SiakaPhonesApp(startAuthenticated: true));
    await tester.pumpAndSettle();

    // 1. Open menu
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    expect(find.text('Customer Menu'), findsOneWidget);

    // 2. Tap Store Locations
    await tester.tap(find.text('Store Locations'));
    await tester.pumpAndSettle();
    expect(find.text('Siaka Phones Circle'), findsOneWidget);

    // 3. Tap back to return to Home
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 4. On HomeView, the menu popup / drawer is NOT there
    expect(find.byType(HomeView), findsOneWidget);
    expect(find.text('Customer Menu'), findsNothing);

    // 5. Open menu again, then tap a bottom nav tab (Search)
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    expect(find.text('Customer Menu'), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogView), findsOneWidget);

    // 6. Switch back to Home tab
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeView), findsOneWidget);
    expect(find.text('Customer Menu'), findsNothing);
  });

  testWidgets(
      'drawer menu displays Shop by Category section with Smartphones, Keypad Phones, Laptops, and Accessories',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SiakaPhonesApp(startAuthenticated: true));
    await tester.pumpAndSettle();

    // 1. Open menu
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();

    // 2. Verify Shop by Category section
    expect(find.text('SHOP BY CATEGORY'), findsOneWidget);
    expect(find.text('Smartphones'), findsOneWidget);
    expect(find.text('Keypad Phones'), findsOneWidget);
    expect(find.text('Laptops'), findsOneWidget);
    expect(find.text('Accessories'), findsWidgets);
    expect(find.text('Tablets'), findsOneWidget);
    expect(find.text('SERVICES & ACCOUNT'), findsOneWidget);
    expect(find.text('My Orders'), findsOneWidget);
  });

  testWidgets(
      'selecting a category from drawer menu closes drawer and navigates to Catalog with matching products',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SiakaPhonesApp(startAuthenticated: true));
    await tester.pumpAndSettle();

    // 1. Open menu
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();

    // 2. Tap Keypad Phones in drawer menu
    await tester.ensureVisible(find.text('Keypad Phones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keypad Phones'));
    await tester.pumpAndSettle();

    // 3. Menu is dismissed, CatalogView is displayed with Keypad Phones products
    expect(find.text('Customer Menu'), findsNothing);
    expect(find.byType(CatalogView), findsOneWidget);
    expect(find.text('Nokia 3310 (2024 Dual SIM)'), findsOneWidget);
    expect(find.text('Itel Magic 2 4G (Wi-Fi Hotspot)'), findsOneWidget);

    // 4. Return to Home tab
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeView), findsOneWidget);
    expect(find.text('Customer Menu'), findsNothing);

    // 5. Open menu again and tap Laptops
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Laptops'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laptops'));
    await tester.pumpAndSettle();

    // 6. Menu is dismissed, CatalogView displays Laptops products
    expect(find.text('Customer Menu'), findsNothing);
    expect(find.byType(CatalogView), findsOneWidget);
    expect(find.text('MacBook Pro 16" (M3 Max)'), findsOneWidget);
    expect(find.text('Dell XPS 15 9530'), findsOneWidget);
  });

  testWidgets(
      'All Products is first in drawer categories and tapping it navigates to Catalog showing all products',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SiakaPhonesApp(startAuthenticated: true));
    await tester.pumpAndSettle();

    // 1. Open menu
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();

    // 2. Verify 'All Products' is visible
    expect(find.text('All Products'), findsOneWidget);

    // 3. Tap 'All Products'
    await tester.tap(find.text('All Products'));
    await tester.pumpAndSettle();

    // 4. Menu is dismissed and CatalogView is displayed
    expect(find.text('Customer Menu'), findsNothing);
    expect(find.byType(CatalogView), findsOneWidget);

    // 5. Verify devices from multiple categories are present (not empty)
    expect(find.text('No devices found'), findsNothing);
    expect(find.text('iPhone 15 Pro Max'), findsOneWidget);
  });

  testWidgets(
      'tapping Support Team in drawer opens SupportView with Customer Service Line and quick topics',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SiakaPhonesApp(startAuthenticated: true));
    await tester.pumpAndSettle();

    // 1. Open menu
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();

    // 2. Tap 'Support Team'
    expect(find.text('Support Team'), findsOneWidget);
    await tester.tap(find.text('Support Team'));
    await tester.pumpAndSettle();

    // 3. Verify SupportView is displayed
    expect(find.byType(SupportView), findsOneWidget);
    expect(find.text('CUSTOMER SERVICE LINE'), findsOneWidget);
    expect(find.text('+233 (024) 555-0192'), findsWidgets);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Customer service line'), findsOneWidget);
    expect(find.text('Track my order'), findsOneWidget);

    // 4. Tap 'Call' button
    await tester.tap(find.text('Call'));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'tapping Buy Now Pay Later in app drawer navigates to dedicated BnplView',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SiakaPhonesApp(startAuthenticated: true));
    await tester.pumpAndSettle();

    // 1. Open menu drawer
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();

    // 2. Tap 'Buy Now Pay Later'
    expect(find.text('Buy Now Pay Later'), findsOneWidget);
    await tester.tap(find.text('Buy Now Pay Later'));
    await tester.pumpAndSettle();

    // 3. Verify BnplView is opened
    expect(find.byType(BnplView), findsOneWidget);
    expect(find.text('0% APR Installment Plans with Siaka Pay'), findsOneWidget);
  });

  testWidgets(
      'BnplView allows selecting between Tecno, Infinix, Samsung, and iPhone, typing model, selecting specs, and submitting for manager review',
      (WidgetTester tester) async {
    final viewModel = BnplViewModel();

    await tester.pumpWidget(
      MaterialApp(
        home: BnplView(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify 4 brand options exist
    expect(find.text('Tecno'), findsOneWidget);
    expect(find.text('Infinix'), findsOneWidget);
    expect(find.text('Samsung'), findsOneWidget);
    expect(find.text('iPhone'), findsOneWidget);

    // 2. Select Samsung brand
    await tester.tap(find.text('Samsung'));
    await tester.pumpAndSettle();
    expect(viewModel.selectedBrand, 'Samsung');

    // 3. Tap popular model chip or enter text into TextField
    expect(find.text('Galaxy S24 Ultra'), findsOneWidget);
    await tester.tap(find.text('Galaxy S24 Ultra'));
    await tester.pumpAndSettle();
    expect(viewModel.modelName, 'Galaxy S24 Ultra');

    // 4. Select specs (e.g. 512 GB storage, 12 GB RAM, and Weekly installment duration)
    await tester.tap(find.text('512 GB'));
    await tester.pumpAndSettle();
    expect(viewModel.selectedStorage, '512 GB');

    await tester.tap(find.text('12 GB'));
    await tester.pumpAndSettle();
    expect(viewModel.selectedRam, '12 GB');

    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    expect(viewModel.selectedPlanDuration, 'Weekly');

    // 5. Submit for manager review
    await tester.tap(find.text('Submit for Manager Review'));
    await tester.pump();
    await tester.pumpAndSettle();

    // 6. Verify submission confirmation screen
    expect(find.text('Application Submitted to Manager!'), findsOneWidget);
    expect(find.textContaining('Reference: BNPL-'), findsOneWidget);
    expect(
        find.textContaining('Manager response expected within 30 - 60 minutes'),
        findsOneWidget);
    expect(find.text('Galaxy S24 Ultra'), findsOneWidget);
    expect(find.text('512 GB'), findsOneWidget);
    expect(find.text('12 GB'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(
        find.text('Call Customer Service: +233 (024) 555-0192'), findsOneWidget);
  });

  testWidgets(
      'tapping Swap My Device in drawer menu opens TradeInView with phone selection and swap specs',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SiakaPhonesApp(startAuthenticated: true));
    await tester.pumpAndSettle();

    // 1. Open drawer menu
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();

    // 2. Tap Swap My Device
    await tester.ensureVisible(find.text('Swap My Device'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Swap My Device'));
    await tester.pumpAndSettle();

    // 3. Verify TradeInView is opened
    expect(find.byType(TradeInView), findsOneWidget);
    expect(find.text('Swap My Device'), findsOneWidget);
    expect(find.text('Phone You Want'), findsOneWidget);
    expect(find.text('The Phone You Are Swapping'), findsOneWidget);
    expect(find.text('SWAP SUMMARY'), findsOneWidget);
  });

  testWidgets(
      'TradeInView allows selecting desired phone and specs, selecting current phone to swap, and submitting request',
      (WidgetTester tester) async {
    final viewModel = TradeInViewModel();

    await tester.pumpWidget(
      MaterialApp(
        home: TradeInView(
          viewModel: viewModel,
          onApplyToPurchase: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Desired phone brand selection (e.g. Samsung)
    expect(find.text('Samsung'), findsWidgets);
    await tester.tap(find.text('Samsung').first);
    await tester.pumpAndSettle();
    expect(viewModel.desiredBrand, 'Samsung');

    // 2. Select desired model via suggestion or controller
    expect(find.text('Galaxy S24 Ultra'), findsWidgets);
    await tester.tap(find.text('Galaxy S24 Ultra').first);
    await tester.pumpAndSettle();
    expect(viewModel.desiredModel, 'Galaxy S24 Ultra');

    // 3. Select desired storage (512 GB)
    await tester.tap(find.text('512 GB').first);
    await tester.pumpAndSettle();
    expect(viewModel.desiredStorage, '512 GB');

    // 4. Current phone selection (e.g. Tecno)
    await tester.ensureVisible(find.text('Select Current Phone Brand'));
    await tester.pumpAndSettle();
    expect(find.text('Tecno'), findsWidgets);
    await tester.tap(find.text('Tecno').last);
    await tester.pumpAndSettle();
    expect(viewModel.currentBrand, 'Tecno');

    // Tap popular model for current phone (e.g. Camon 30 Pro 5G)
    expect(find.text('Camon 30 Pro 5G'), findsWidgets);
    await tester.tap(find.text('Camon 30 Pro 5G').first);
    await tester.pumpAndSettle();
    expect(viewModel.currentModel, 'Camon 30 Pro 5G');

    // 5. Submit swap request
    await tester.ensureVisible(find.text('Submit Swap Request for Manager Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit Swap Request for Manager Review'));
    await tester.pump();
    await tester.pumpAndSettle();

    // 6. Verify submission confirmation screen
    expect(find.text('Swap Request Sent to Manager!'), findsOneWidget);
    expect(find.textContaining('Reference #SWAP-GH-'), findsOneWidget);
    expect(find.text('Swap Device Breakdown'), findsOneWidget);
    expect(find.textContaining('Galaxy S24 Ultra'), findsWidgets);
    expect(find.text('Valuation & Cost: Pending Manager Review'), findsOneWidget);
    expect(find.text('Call Store Manager (+233 024 555-0192)'), findsOneWidget);
  });

  testWidgets('TradeInView renders on narrow 320px screen without any overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final viewModel = TradeInViewModel();

    await tester.pumpWidget(
      MaterialApp(
        home: TradeInView(
          viewModel: viewModel,
          onApplyToPurchase: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Phone You Want'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('The Phone You Are Swapping'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('The Phone You Are Swapping'), findsOneWidget);
  });

  testWidgets('MyRepairsView displays all repairs initiated or completed',
      (WidgetTester tester) async {
    final repairRepo = RepairRepository();
    final repairsVM = RepairsViewModel(repairRepository: repairRepo);

    bool bookedNew = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MyRepairsView(
          viewModel: repairsVM,
          onBookNewRepair: () => bookedNew = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Repairs'), findsOneWidget);
    expect(find.text('Repairs initiated or completed at Siaka Phones'), findsOneWidget);
    expect(find.text('Total Repairs'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Completed'), findsWidgets);
    expect(find.text('REP-GH-8219'), findsOneWidget);
    expect(find.text('REP-GH-9442'), findsOneWidget);
    expect(find.text('Samsung Galaxy S22 Ultra'), findsOneWidget);
    expect(find.text('iPhone 13 Pro'), findsOneWidget);

    // Tap Book a New Device Repair
    await tester.tap(find.text('Book a New Device Repair'));
    await tester.pumpAndSettle();
    expect(bookedNew, isTrue);
  });

  testWidgets('DevicesSwappedView displays all devices swapped or initiated without artificial prices',
      (WidgetTester tester) async {
    final tradeInVM = TradeInViewModel();

    bool initiatedNew = false;
    await tester.pumpWidget(
      MaterialApp(
        home: DevicesSwappedView(
          viewModel: tradeInVM,
          onInitiateNewSwap: () => initiatedNew = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Devices Swapped'), findsOneWidget);
    expect(find.text('All device swaps initiated or completed'), findsOneWidget);
    expect(find.text('Total Swaps'), findsOneWidget);
    expect(find.text('Under Review'), findsWidgets);
    expect(find.text('Completed'), findsWidgets);
    expect(find.text('SWAP-GH-7840'), findsOneWidget);
    expect(find.text('SWAP-GH-4921'), findsOneWidget);
    expect(find.text('Phone Wanted (Target Device):'), findsWidgets);
    expect(find.text('Phone Swapped / Traded-In:'), findsWidgets);
    expect(find.text('Initiate New Device Swap'), findsOneWidget);

    // Tap Initiate New Device Swap
    await tester.tap(find.text('Initiate New Device Swap'));
    await tester.pumpAndSettle();
    expect(initiatedNew, isTrue);
  });

  testWidgets('SplashView displays official logo, animated loading bar state, and transitions on completion',
      (WidgetTester tester) async {
    bool loaded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashView(
          duration: const Duration(milliseconds: 300),
          onLoaded: () => loaded = true,
        ),
      ),
    );

    // Initial state: SplashView is active, logo container is 250x250
    expect(find.byType(SplashView), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.textContaining('%'), findsOneWidget);

    // Advance halfway through animation
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(SplashView), findsOneWidget);

    // Settle through the rest of the duration
    await tester.pumpAndSettle();
    expect(loaded, isTrue);
  });

  testWidgets('app launched with showSplash: true shows SplashView on first page before transitioning to HomeView',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SiakaPhonesApp(startAuthenticated: true, showSplash: true));

    // First frame: SplashView is the first page that appears after app is launched
    expect(find.byType(SplashView), findsOneWidget);
    expect(find.byType(HomeView), findsNothing);

    // After animation completes, transitions smoothly to HomeView
    await tester.pumpAndSettle();
    expect(find.byType(SplashView), findsNothing);
    expect(find.byType(HomeView), findsOneWidget);
  });

  testWidgets(
      'TrackOrderView shows green ORDER PLACED & CONFIRMED and CONFIRMED badge on step 1 when order is placed',
      (WidgetTester tester) async {
    final orderRepo = OrderRepository();
    orderRepo.updateOrderStatus('SP-883921', OrderStatus.placed);
    final placedOrder = orderRepo.getOrderById('SP-883921')!;

    await tester.pumpWidget(
      MaterialApp(
        home: TrackOrderView(
          order: placedOrder,
          orderRepository: orderRepo,
          onTabSelected: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify correct green badge on summary card
    expect(find.text('ORDER PLACED & CONFIRMED'), findsOneWidget);
    expect(find.text('Order Placed & Confirmed'), findsWidgets);
    expect(find.text('CONFIRMED'), findsOneWidget);
    expect(find.text(placedOrder.trackingNumber), findsOneWidget);

    // Manager status advance simulation in order repository
    orderRepo.advanceOrderStatus(placedOrder.orderId);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // After manager updates, status moves forward to Packing / Processing
    expect(find.text('PROCESSING & PACKING'), findsOneWidget);
    expect(find.text('Order is Being Packed'), findsOneWidget);

    // Manager advances order again: status moves to Dispatched / In Transit
    orderRepo.advanceOrderStatus(placedOrder.orderId);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('IN TRANSIT'), findsOneWidget);
    expect(find.text('Package is on the way'), findsOneWidget);
  });

  testWidgets('OrdersView displays orders with Ghanaian Cedis and triggers onTrackOrder',
      (WidgetTester tester) async {
    final orderRepo = OrderRepository();
    final ordersVM = OrdersViewModel(orderRepository: orderRepo);
    OrderModel? trackedOrder;

    await tester.pumpWidget(
      MaterialApp(
        home: OrdersView(
          viewModel: ordersVM,
          orderRepo: orderRepo,
          onTrackOrder: (o) => trackedOrder = o,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Orders & Tracking'), findsOneWidget);
    expect(find.text('All Orders'), findsNothing); // Chips are 'All (3)', 'In Progress (2)', etc.
    expect(find.textContaining('All ('), findsOneWidget);
    expect(find.text('Track Order'), findsWidgets);

    // Tap first Track Order button
    await tester.tap(find.text('Track Order').first);
    await tester.pumpAndSettle();

    expect(trackedOrder, isNotNull);
  });

  testWidgets('ProfileView orders stat and My Orders & Tracking row both trigger onOrdersTap',
      (WidgetTester tester) async {
    final userRepo = UserRepository();
    final profileVM = ProfileViewModel(userRepository: userRepo);
    int ordersTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileView(
          viewModel: profileVM,
          ordersCount: '5',
          onOrdersTap: () => ordersTapCount++,
          onTradeInTap: () {},
          onLocationsTap: () {},
          onSupportTap: () {},
          onSignOut: () {},
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Orders stat shows count '5'
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);

    // Tap Orders stat
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(ordersTapCount, 1);

    // Tap My Orders & Tracking row
    await tester.tap(find.text('My Orders & Tracking'));
    await tester.pumpAndSettle();
    expect(ordersTapCount, 2);
  });

  testWidgets(
      'tapping tune button in homepage search bar opens categories sheet and selecting category filters catalog',
      (tester) async {
    await tester.pumpWidget(const SiakaPhonesApp(startAuthenticated: true));
    await tester.pumpAndSettle();

    // Verify search bar has the tune button
    final tuneBtn = find.byKey(const ValueKey('home_search_tune_button'));
    expect(tuneBtn, findsOneWidget);

    // Tap the tune button
    await tester.tap(tuneBtn);
    await tester.pumpAndSettle();

    // Verify category sheet is open with title & categories from image
    expect(find.text('Select Category'), findsOneWidget);
    expect(find.text('Filter phones, laptops & gadgets in store'), findsOneWidget);
    expect(find.text('Smartphones'), findsOneWidget);
    expect(find.text('Flagship & 5G'), findsOneWidget);
    expect(find.text('Keypad Phones'), findsOneWidget);
    expect(find.text('Nokia & Itel'), findsOneWidget);
    expect(find.text('Laptops'), findsOneWidget);
    expect(find.text('MacBooks & Dell'), findsOneWidget);
    expect(find.text('Accessories'), findsWidgets);
    expect(find.text('Audio & Power'), findsOneWidget);

    // Tap Smartphones card
    final smartphonesCard =
        find.byKey(const ValueKey('category_card_Smartphones'));
    expect(smartphonesCard, findsOneWidget);
    await tester.tap(smartphonesCard);
    await tester.pumpAndSettle();

    // Verify sheet dismissed and navigated to Catalog filtered to Smartphones
    expect(find.text('Select Category'), findsNothing);
    expect(find.textContaining('Smartphones'), findsWidgets);
    expect(find.text('iPhone 15 Pro Max'), findsWidgets);
  });

  testWidgets(
      'tapping search bar on homepage navigates to catalog and auto-focuses search textfield',
      (tester) async {
    await tester.pumpWidget(const SiakaPhonesApp(startAuthenticated: true));
    await tester.pumpAndSettle();

    // Verify on HomeView
    expect(find.byType(HomeView), findsOneWidget);

    // Tap the search bar field on HomeView
    final searchBarField =
        find.byKey(const ValueKey('home_search_bar_field'));
    expect(searchBarField, findsOneWidget);
    await tester.tap(searchBarField);
    await tester.pumpAndSettle();

    // Verify CatalogView is now active and search TextField has focus
    final searchTextField =
        find.byKey(const ValueKey('catalog_search_textfield'));
    expect(searchTextField, findsOneWidget);
    final textFieldWidget = tester.widget<TextField>(searchTextField);
    expect(textFieldWidget.focusNode?.hasFocus, isTrue);
  });
}






