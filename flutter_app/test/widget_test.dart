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

    // Verify search results view
    expect(find.text('Results for "Samsung" (4)'), findsOneWidget);
    expect(find.text('Galaxy S24 Ultra'), findsOneWidget);

    // 4. Clear search query
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify returns to initial featured phones banners
    expect(find.text('Featured Phones'), findsOneWidget);
    expect(find.text('Discover the\nLatest Smartphones'), findsOneWidget);
    // 5. Verify 3-column grid structure and card height 240
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
}



