import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/repositories/manager_repository.dart';
import 'domain/models/customer_message.dart';
import 'ui/core/desktop_scaffold.dart';
import 'ui/features/analytics/business_analytics_view.dart';
import 'ui/features/bnpl/bnpl_approvals_view.dart';
import 'ui/features/customers/customer_activity_view.dart';
import 'ui/features/dashboard/dashboard_view.dart';
import 'ui/features/inventory/inventory_view.dart';
import 'ui/features/messaging/customer_messaging_view.dart';
import 'ui/features/notifications/notifications_view.dart';
import 'ui/features/orders/orders_management_view.dart';
import 'ui/features/repairs/repairs_desk_view.dart';
import 'ui/features/service_center/service_center_view.dart';
import 'ui/features/settings/settings_view.dart';
import 'ui/features/shipping/shipping_view.dart';
import 'ui/features/swaps/tradein_desk_view.dart';
import 'ui/features/auth/manager_splash_view.dart';
import 'ui/features/auth/manager_login_view.dart';
import 'ui/features/advertisements/advertisements_management_view.dart';
import 'data/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseService().initialize();
  } catch (e) {
    debugPrint('Supabase pre-init notice: $e');
  }
  runApp(const SiakaManagerApp(showSplash: true));
}

class SiakaManagerApp extends StatefulWidget {
  final bool showSplash;
  const SiakaManagerApp({super.key, this.showSplash = false});

  @override
  State<SiakaManagerApp> createState() => _SiakaManagerAppState();
}

class _SiakaManagerAppState extends State<SiakaManagerApp> {
  late final ManagerRepository _repository;
  int _selectedIndex = 0;
  late bool _showSplash;

  @override
  void initState() {
    super.initState();
    _showSplash = widget.showSplash;
    _repository = ManagerRepository();
    // Start by checking if we have a valid session
    if (_showSplash) {
      _initSession();
    }
  }

  Future<void> _initSession() async {
    // Artificial delay to ensure splash shows for at least 2 seconds 
    // and session logic completes
    await Future.wait([
      _repository.loadSavedSession(),
      Future.delayed(const Duration(milliseconds: 2200)),
    ]);
    
    // Check if the loaded session is still valid (under 24h)
    if (!_repository.checkSessionValid()) {
      _repository.logout();
    }
    
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  void _handleMessageCustomer(
    String name,
    String? phone,
    String? email, {
    String? initialSubject,
    String? initialBody,
    MessageCategory? initialCategory,
  }) {
    _repository.selectCustomerForMessaging(
      customerName: name,
      phone: phone,
      email: email,
      initialSubject: initialSubject,
      initialBody: initialBody,
      initialCategory: initialCategory,
    );
    setState(() => _selectedIndex = 8);
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return DashboardView(
          repository: _repository,
          onNavigate: (index) => setState(() => _selectedIndex = index),
          onMessageCustomer: _handleMessageCustomer,
        );
      case 1:
        return OrdersManagementView(
          repository: _repository,
          onMessageCustomer: _handleMessageCustomer,
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
      case 2:
        return InventoryView(repository: _repository);
      case 3:
        return BnplApprovalsView(
          repository: _repository,
          onMessageCustomer: _handleMessageCustomer,
        );
      case 4:
        return RepairsDeskView(
          repository: _repository,
          onMessageCustomer: _handleMessageCustomer,
        );
      case 5:
        return TradeInDeskView(
          repository: _repository,
          onMessageCustomer: _handleMessageCustomer,
        );
      case 6:
        return CustomerActivityView(
          repository: _repository,
          onMessageCustomer: _handleMessageCustomer,
        );
      case 7:
        return BusinessAnalyticsView(repository: _repository);
      case 8:
        return CustomerMessagingView(repository: _repository);
      case 9:
        return ServiceCenterView(repository: _repository);
      case 10:
        return SettingsView(repository: _repository);
      case 11:
        return ShippingView(
          repository: _repository,
          onMessageCustomer: _handleMessageCustomer,
        );
      case 12:
        return NotificationsView(
          repository: _repository,
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
      case 13:
        return AdvertisementsManagementView(
          repository: _repository,
        );
      default:
        return DashboardView(
          repository: _repository,
          onNavigate: (index) => setState(() => _selectedIndex = index),
          onMessageCustomer: _handleMessageCustomer,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siaka Phones Manager Desktop',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1C7BFF),
          primary: const Color(0xFF1C7BFF),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: const WidgetStatePropertyAll(true),
          trackVisibility: const WidgetStatePropertyAll(true),
          interactive: true,
          thickness: const WidgetStatePropertyAll(12.0),
          radius: const Radius.circular(6),
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.dragged)) return const Color(0xFF1D4ED8);
            if (states.contains(WidgetState.hovered)) return const Color(0xFF2563EB);
            return const Color(0xFF64748B);
          }),
          trackColor: const WidgetStatePropertyAll(Color(0xFFE2E8F0)),
          trackBorderColor: const WidgetStatePropertyAll(Color(0xFFCBD5E1)),
        ),
      ),
      home: ListenableBuilder(
        listenable: _repository,
        builder: (context, _) {
          if (_showSplash) {
            return ManagerSplashView(
              onLoaded: () {
                // Splash duration handled in _initSession, but we can also use this callback if needed
              },
            );
          }

          if (!_repository.isAuthenticated) {
            return ManagerLoginView(
              repository: _repository,
              onLoginSuccess: () {
                setState(() {});
              },
            );
          }

          return DesktopScaffold(
            selectedIndex: _selectedIndex,
            onIndexChanged: (index) {
              setState(() => _selectedIndex = index);
            },
            repository: _repository,
            body: _buildCurrentView(),
          );
        },
      ),
    );
  }
}
