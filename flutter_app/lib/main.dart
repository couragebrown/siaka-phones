import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Data Layer & Repositories
import 'data/repositories/product_repository.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/repair_repository.dart';
import 'data/repositories/location_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/wishlist_repository.dart';
import 'data/mock_data.dart';
import 'data/services/session_manager.dart';

// Models
import 'domain/models/product.dart';
import 'domain/models/order.dart';

// Core UI & Theme
import 'ui/core/app_theme.dart';
import 'ui/core/widgets/bottom_nav_scaffold.dart';

// Feature Views & ViewModels
import 'ui/features/auth/login_view.dart';
import 'ui/features/home/home_view_model.dart';
import 'ui/features/home/home_view.dart';
import 'ui/features/catalog/catalog_view_model.dart';
import 'ui/features/catalog/catalog_view.dart';
import 'ui/features/product_detail/product_detail_view_model.dart';
import 'ui/features/product_detail/product_detail_view.dart';
import 'ui/features/cart/cart_view_model.dart';
import 'ui/features/cart/cart_view.dart';
import 'ui/features/checkout/checkout_view_model.dart';
import 'ui/features/checkout/checkout_view.dart';
import 'ui/features/confirmation/confirmation_view.dart';
import 'ui/features/profile/profile_view_model.dart';
import 'ui/features/profile/profile_view.dart';
import 'ui/features/orders/orders_view_model.dart';
import 'ui/features/orders/orders_view.dart';
import 'ui/features/repairs/repairs_view_model.dart';
import 'ui/features/repairs/repairs_view.dart';
import 'ui/features/tradein/tradein_view_model.dart';
import 'ui/features/tradein/tradein_view.dart';
import 'ui/features/support/support_view_model.dart';
import 'ui/features/support/support_view.dart';
import 'ui/features/locations/locations_view_model.dart';
import 'ui/features/locations/locations_view.dart';
import 'ui/features/reviews/reviews_view_model.dart';
import 'ui/features/reviews/reviews_view.dart';
import 'ui/features/wishlist/wishlist_view.dart';
import 'ui/features/track_order/track_order_view.dart';
import 'ui/features/brands/brands_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Check whether the user has a valid (non-expired) session
  final hasSession = await SessionManager.hasValidSession();

  runApp(SiakaPhonesApp(startAuthenticated: hasSession));
}

class SiakaPhonesApp extends StatefulWidget {
  final bool startAuthenticated;
  const SiakaPhonesApp({super.key, required this.startAuthenticated});

  @override
  State<SiakaPhonesApp> createState() => _SiakaPhonesAppState();
}

class _SiakaPhonesAppState extends State<SiakaPhonesApp> {
  // Shared Singleton Repositories
  final ProductRepository _productRepo = ProductRepository();
  final CartRepository _cartRepo = CartRepository();
  final OrderRepository _orderRepo = OrderRepository();
  final RepairRepository _repairRepo = RepairRepository();
  final LocationRepository _locationRepo = LocationRepository();
  final UserRepository _userRepo = UserRepository();
  final WishlistRepository _wishlistRepo = WishlistRepository(
    initialProducts: [MockData.products.first],
  );

  // Persistent Feature ViewModels
  late final HomeViewModel _homeVM;
  late final CatalogViewModel _catalogVM;
  late final CartViewModel _cartVM;
  late final ProfileViewModel _profileVM;
  late final OrdersViewModel _ordersVM;
  late final RepairsViewModel _repairsVM;
  late final TradeInViewModel _tradeInVM;
  late final SupportViewModel _supportVM;
  late final LocationsViewModel _locationsVM;
  late final ReviewsViewModel _reviewsVM;

  @override
  void initState() {
    super.initState();
    _homeVM = HomeViewModel(productRepository: _productRepo);
    _catalogVM = CatalogViewModel(productRepository: _productRepo);
    _cartVM = CartViewModel(cartRepository: _cartRepo);
    _profileVM = ProfileViewModel(userRepository: _userRepo);
    _ordersVM = OrdersViewModel(orderRepository: _orderRepo);
    _repairsVM = RepairsViewModel(repairRepository: _repairRepo);
    _tradeInVM = TradeInViewModel();
    _supportVM = SupportViewModel();
    _locationsVM = LocationsViewModel(locationRepository: _locationRepo);
    _reviewsVM = ReviewsViewModel();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siaka Phones',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AppRootNavigationHub(
        startAuthenticated: widget.startAuthenticated,
        productRepo: _productRepo,
        cartRepo: _cartRepo,
        orderRepo: _orderRepo,
        wishlistRepo: _wishlistRepo,
        homeVM: _homeVM,
        catalogVM: _catalogVM,
        cartVM: _cartVM,
        profileVM: _profileVM,
        ordersVM: _ordersVM,
        repairsVM: _repairsVM,
        tradeInVM: _tradeInVM,
        supportVM: _supportVM,
        locationsVM: _locationsVM,
        reviewsVM: _reviewsVM,
      ),
    );
  }
}

class AppRootNavigationHub extends StatefulWidget {
  final bool startAuthenticated;
  final ProductRepository productRepo;
  final CartRepository cartRepo;
  final OrderRepository orderRepo;
  final WishlistRepository wishlistRepo;
  final HomeViewModel homeVM;
  final CatalogViewModel catalogVM;
  final CartViewModel cartVM;
  final ProfileViewModel profileVM;
  final OrdersViewModel ordersVM;
  final RepairsViewModel repairsVM;
  final TradeInViewModel tradeInVM;
  final SupportViewModel supportVM;
  final LocationsViewModel locationsVM;
  final ReviewsViewModel reviewsVM;

  const AppRootNavigationHub({
    super.key,
    required this.startAuthenticated,
    required this.productRepo,
    required this.cartRepo,
    required this.orderRepo,
    required this.wishlistRepo,
    required this.homeVM,
    required this.catalogVM,
    required this.cartVM,
    required this.profileVM,
    required this.ordersVM,
    required this.repairsVM,
    required this.tradeInVM,
    required this.supportVM,
    required this.locationsVM,
    required this.reviewsVM,
  });

  @override
  State<AppRootNavigationHub> createState() => _AppRootNavigationHubState();
}

class _AppRootNavigationHubState extends State<AppRootNavigationHub>
    with WidgetsBindingObserver {
  late bool _isAuthenticated;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _isAuthenticated = widget.startAuthenticated;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called whenever app lifecycle changes.
  /// When resumed, refresh the session timestamp so the 1-hour
  /// timer resets while the app is actively being used.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isAuthenticated) {
      SessionManager.refreshSession();
    }
  }

  void _selectRootTab(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() => _currentTabIndex = index);
  }

  void _navigateToProductDetail(Product product) {
    final detailVM = ProductDetailViewModel(
      product: product,
      cartRepository: widget.cartRepo,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailView(
          viewModel: detailVM,
          wishlistRepo: widget.wishlistRepo,
          currentTabIndex: _currentTabIndex,
          onTabSelected: _selectRootTab,
          onReviewsTap: () => _navigateToReviews(),
          onGoToCart: () {
            detailVM.addToCart();
            _selectRootTab(2);
          },
        ),
      ),
    );
  }

  void _navigateToReviews() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewsView(viewModel: widget.reviewsVM),
      ),
    );
  }

  void _navigateToCheckout() {
    final checkoutVM = CheckoutViewModel(
      cartRepository: widget.cartRepo,
      orderRepository: widget.orderRepo,
      userRepository: widget.profileVM.userRepository,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutView(
          viewModel: checkoutVM,
          onTabSelected: _selectRootTab,
          onOrderPlaced: (order) => _navigateToConfirmation(order),
        ),
      ),
    );
  }

  void _navigateToConfirmation(OrderModel order) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConfirmationView(
          order: order,
          onTrackOrder: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TrackOrderView(
                  order: order,
                  onTabSelected: _selectRootTab,
                ),
              ),
            );
          },
          onContinueShopping: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            setState(() => _currentTabIndex = 0);
          },
        ),
      ),
    );
  }

  void _navigateToOrders() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrdersView(viewModel: widget.ordersVM),
      ),
    );
  }

  void _navigateToTradeIn() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TradeInView(
          viewModel: widget.tradeInVM,
          onApplyToPurchase: () {
            Navigator.of(context).pop();
            setState(() => _currentTabIndex = 1);
          },
        ),
      ),
    );
  }

  void _navigateToSupport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupportView(viewModel: widget.supportVM),
      ),
    );
  }

  void _navigateToLocations() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationsView(viewModel: widget.locationsVM),
      ),
    );
  }

  void _navigateToRepairs() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RepairsView(
          viewModel: widget.repairsVM,
          onReturnHome: () => _selectRootTab(0),
        ),
      ),
    );
  }

  void _navigateToBrands() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrandsView(
          onBrandSelected: (brand) {
            Navigator.of(context).pop();
            widget.catalogVM.setSearchQuery(brand);
            _selectRootTab(1);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return LoginView(
        onBack: () {}, // no-op: sign-in is the entry gate
        onSignIn: () async {
          await SessionManager.saveSession();
          setState(() {
            _isAuthenticated = true;
            _currentTabIndex = 0;
          });
        },
        onCreateAccount:
            (name, email, phone, address, country, region, gpsCode) async {
          widget.profileVM.updateProfile(
            name: name,
            email: email,
            phone: phone,
          );
          widget.profileVM.updateAddress(
            detailAddress: address,
            gpsCode: gpsCode,
            region: region,
            country: country,
          );
          await SessionManager.saveSession();
          setState(() {
            _isAuthenticated = true;
            _currentTabIndex = 0;
          });
        },
      );
    }


    return ListenableBuilder(
      listenable: widget.cartRepo,
      builder: (context, _) {
        final List<Widget> pages = [
          HomeView(
            isCurrentTab: _currentTabIndex == 0,
            viewModel: widget.homeVM,
            wishlistRepo: widget.wishlistRepo,
            onProductTap: _navigateToProductDetail,
            onSeeAllCatalog: () => setState(() => _currentTabIndex = 1),
            onSeeAllBrands: _navigateToBrands,
            onBrandTap: (brand) {
              widget.catalogVM.setSearchQuery(brand);
              _selectRootTab(1);
            },
            onCategoryTap: (category) {
              final cat = (category == 'All Products') ? 'All' : category;
              widget.catalogVM.setCategory(cat);
              widget.catalogVM.setSearchQuery('');
              _selectRootTab(1);
            },
            onTradeInTap: _navigateToTradeIn,
            onRepairsTap: _navigateToRepairs,
            onOrdersTap: _navigateToOrders,
            onLocationsTap: _navigateToLocations,
            onSupportTap: _navigateToSupport,
            onProfileTap: () => setState(() => _currentTabIndex = 4),
            onSignOut: () async {
              await SessionManager.clearSession();
              setState(() {
                _isAuthenticated = false;
                _currentTabIndex = 0;
              });
            },
          ),
          CatalogView(
            viewModel: widget.catalogVM,
            wishlistRepo: widget.wishlistRepo,
            onProductTap: _navigateToProductDetail,
          ),
          CartView(
            viewModel: widget.cartVM,
            onCheckout: _navigateToCheckout,
            onBrowseCatalog: () => setState(() => _currentTabIndex = 1),
            onProductTap: _navigateToProductDetail,
          ),
          WishlistView(
            wishlistRepo: widget.wishlistRepo,
            cartRepo: widget.cartRepo,
            onProductTap: _navigateToProductDetail,
            onBrowseCatalog: () => setState(() => _currentTabIndex = 1),
            onGoToCart: () => setState(() => _currentTabIndex = 2),
          ),
          ProfileView(
            viewModel: widget.profileVM,
            onOrdersTap: _navigateToOrders,
            onTradeInTap: _navigateToTradeIn,
            onLocationsTap: _navigateToLocations,
            onSupportTap: _navigateToSupport,
            onWishlistTap: () => setState(() => _currentTabIndex = 3),
            onBack: () => setState(() => _currentTabIndex = 0),
            onSignOut: () async {
              await SessionManager.clearSession();
              setState(() {
                _isAuthenticated = false;
                _currentTabIndex = 0;
              });
            },
          ),
        ];

        return BottomNavScaffold(
          currentIndex: _currentTabIndex,
          cartBadgeCount: widget.cartRepo.itemCount,
          onTabSelected: _selectRootTab,
          body: IndexedStack(
            index: _currentTabIndex,
            children: pages,
          ),
        );
      },
    );
  }
}
