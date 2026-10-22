import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manager_desktop/data/repositories/manager_repository.dart';
import 'package:manager_desktop/domain/models/customer_message.dart';
import 'package:manager_desktop/domain/models/manager_bnpl.dart';
import 'package:manager_desktop/domain/models/manager_order.dart';
import 'package:manager_desktop/domain/models/manager_product.dart';
import 'package:manager_desktop/domain/models/manager_repair.dart';
import 'package:manager_desktop/domain/models/manager_shipping.dart';
import 'package:manager_desktop/domain/models/manager_swap.dart';
import 'package:manager_desktop/domain/models/manager_notification.dart';
import 'package:manager_desktop/domain/models/service_ticket.dart';
import 'package:manager_desktop/domain/models/advertisement_banner.dart';
import 'package:manager_desktop/main.dart';
import 'package:manager_desktop/ui/core/desktop_scaffold.dart';

void main() {
  group('ManagerRepository Unit Tests', () {
    late ManagerRepository repository;

    setUp(() {
      repository = ManagerRepository();
    });

    test('Initial repository data is properly populated', () {
      expect(repository.products.isNotEmpty, isTrue);
      expect(repository.orders.isNotEmpty, isTrue);
      expect(repository.bnplApplications.isNotEmpty, isTrue);
      expect(repository.repairs.isNotEmpty, isTrue);
      expect(repository.swaps.isNotEmpty, isTrue);
      expect(repository.customers.isNotEmpty, isTrue);
      expect(repository.sentMessages.isNotEmpty, isTrue);
      expect(repository.serviceTickets.isNotEmpty, isTrue);
      expect(repository.advertisements.isNotEmpty, isTrue);
      expect(repository.currentBranch, equals('Accra Central (Circle)'));
    });

    test('Can add, update, toggle, and reorder advertisement video links', () {
      final initialCount = repository.advertisements.length;
      final newAd = AdvertisementBanner(
        id: 'TEST-AD-1',
        title: 'Easter Promo Clearance',
        description: 'Huge discounts on all Samsung flagships',
        videoUrl: 'https://example.com/easter.mp4',
        badgeText: 'SALE',
        callToActionText: 'Shop Easter Deals',
        createdAt: DateTime.now(),
      );

      repository.addAdvertisement(newAd);
      expect(repository.advertisements.length, equals(initialCount + 1));
      expect(repository.advertisements.any((a) => a.id == 'TEST-AD-1'), isTrue);

      repository.toggleAdvertisementStatus('TEST-AD-1');
      final toggled = repository.advertisements.firstWhere((a) => a.id == 'TEST-AD-1');
      expect(toggled.isActive, isFalse);

      repository.updateAdvertisement(toggled.copyWith(title: 'Updated Easter Mega Promo'));
      final updated = repository.advertisements.firstWhere((a) => a.id == 'TEST-AD-1');
      expect(updated.title, equals('Updated Easter Mega Promo'));

      repository.deleteAdvertisement('TEST-AD-1');
      expect(repository.advertisements.length, equals(initialCount));
    });

    test('Can switch active store branch', () {
      repository.selectBranch('Madina Zongo Junction');
      expect(repository.currentBranch, equals('Madina Zongo Junction'));

      repository.selectBranch('Kasoa Main Market');
      expect(repository.currentBranch, equals('Kasoa Main Market'));
    });

    test('Can update order status', () {
      final firstOrder = repository.orders.first;
      expect(firstOrder.status, equals(OrderStatus.delivered));

      repository.updateOrderStatus(firstOrder.id, OrderStatus.confirmed);
      expect(repository.orders.first.status, equals(OrderStatus.confirmed));

      repository.updateOrderStatus(firstOrder.id, OrderStatus.dispatched);
      expect(repository.orders.first.status, equals(OrderStatus.dispatched));
    });

    test('Inbound customer orders reject notification records, customer records, and deduplicate identical orders', () {
      final initialCount = repository.orders.length;

      // 1. Notification record should be rejected
      repository.processInboundCustomerOrder({
        'id': 'NOTIF_ORDER_SP-999999',
        'category': 'NOTIFICATION_RECORD',
        'customerName': 'Spurious Notification',
        'totalAmount': 0.0,
      });
      expect(repository.orders.length, equals(initialCount));
      expect(repository.orders.any((o) => o.id.contains('999999')), isFalse);

      // 2. Customer record should be rejected
      repository.processInboundCustomerOrder({
        'id': 'CUSTOMER_SK-99999',
        'category': 'CUSTOMER_RECORD',
        'customerName': 'Spurious Customer',
        'totalAmount': 0.0,
      });
      expect(repository.orders.length, equals(initialCount));
      expect(repository.orders.any((o) => o.id.contains('99999')), isFalse);

      // 3. Legitimate order should be accepted
      repository.processInboundCustomerOrder({
        'id': 'ORDER_SP-777888',
        'category': 'ORDER_RECORD',
        'customerName': 'Valid Customer',
        'totalAmount': 2500.0,
      });
      expect(repository.orders.length, equals(initialCount + 1));
      expect(repository.orders.any((o) => o.id == 'ORDER_SP-777888'), isTrue);

      // 4. Duplicate inbound order should be deduplicated (not create another duplicate)
      repository.processInboundCustomerOrder({
        'id': 'ORDER_SP-777888',
        'category': 'ORDER_RECORD',
        'customerName': 'Valid Customer Updated',
        'totalAmount': 2500.0,
      });
      expect(repository.orders.length, equals(initialCount + 1));
    });

    test('Can add and update product inventory with wholesale/retail pricing, color, and specs list', () {
      final initialCount = repository.products.length;
      final newProduct = ManagerProduct(
        id: 'test_product_1',
        name: 'Samsung Galaxy S24 Ultra',
        brand: 'Samsung',
        category: 'Smartphones',
        price: 13500.0,
        originalPrice: 14500.0,
        stock: 8,
        specs: 'Snapdragon 8 Gen 3 • 200MP Camera • Titanium Frame',
        storage: '512GB',
        ram: '12GB',
        color: 'Titanium Gray',
        colors: const ['Titanium Gray', 'Space Black', 'Amber Yellow'],
        imageUrl: 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c',
        specsList: ['Snapdragon 8 Gen 3', '200MP Camera', 'Titanium Frame'],
      );

      expect(newProduct.wholesalePrice, equals(13500.0));
      expect(newProduct.retailPrice, equals(14500.0));
      expect(newProduct.savingsAmount, equals(1000.0));
      expect(newProduct.specsList.length, equals(3));
      expect(newProduct.specsList[0], equals('Snapdragon 8 Gen 3'));
      expect(newProduct.color, equals('Titanium Gray'));
      expect(newProduct.colors.length, equals(3));
      expect(newProduct.colors, contains('Space Black'));
      newProduct.color = 'Titanium Violet';
      newProduct.colors = ['Titanium Violet', 'Space Black'];
      expect(newProduct.color, equals('Titanium Violet'));
      expect(newProduct.colors.length, equals(2));

      newProduct.storages = ['256GB', '512GB', '1TB'];
      newProduct.rams = ['12GB', '16GB'];
      expect(newProduct.storages.length, equals(3));
      expect(newProduct.rams.length, equals(2));
      expect(newProduct.storages, contains('512GB'));
      expect(newProduct.rams, contains('16GB'));

      repository.addProduct(newProduct);
      expect(repository.products.length, equals(initialCount + 1));
      expect(repository.products.first.name, equals('Samsung Galaxy S24 Ultra'));

      // Stock adjustment
      repository.updateStock('test_product_1', 12);
      expect(repository.products.first.stock, equals(12));

      // Deletion
      repository.deleteProduct('test_product_1');
      expect(repository.products.length, equals(initialCount));
    });

    test('Can approve and decline BNPL credit applications', () {
      final app = repository.bnplApplications.first;
      expect(app.status, equals(BnplStatus.pending));

      repository.updateBnplStatus(app.id, BnplStatus.approved, notes: 'Salary and employer verified');
      expect(repository.bnplApplications.first.status, equals(BnplStatus.approved));
      expect(repository.bnplApplications.first.managerNotes, equals('Salary and employer verified'));
    });

    test('Can advance repair service stages', () {
      final repair = repository.repairs.first;
      expect(repair.stage, equals(RepairStage.received));

      repository.updateRepairStage(
        repair.id,
        RepairStage.diagnosing,
        notes: 'Motherboard IC checked',
        cost: 650.0,
      );
      expect(repository.repairs.first.stage, equals(RepairStage.diagnosing));
      expect(repository.repairs.first.technicianNotes, equals('Motherboard IC checked'));
      expect(repository.repairs.first.estimatedCost, equals(650.0));
    });

    test('Can process inbound customer repair booking from mobile app with all details', () {
      final initialRepairCount = repository.repairs.length;
      final repairData = {
        'id': 'REPAIR_REP-9988',
        'name': 'Kwame Mensah - iPhone 14 Pro Max',
        'brand': 'iPhone 14 Pro Max',
        'category': 'REPAIR_RECORD',
        'price': 0.0,
        'original_price': 0.0,
        'stock': 1,
        'specs': '{"customerName":"Kwame Mensah","customerPhone":"024 999 8877","deviceModel":"iPhone 14 Pro Max","issueType":"Screen Replacement","description":"Glass shattered on corner and touch unresponsive in middle","dropOffBranch":"Siaka Phones Osu Mall","timeSlot":"Afternoon (13:00 - 16:00)","photoPath":"damage_screen.jpg","appointmentDate":"2026-10-25T14:00:00.000","status":"Confirmed"}',
        'condition': 'received',
        'created_at': DateTime.now().toIso8601String(),
      };

      repository.processInboundRepair(repairData);

      expect(repository.repairs.length, equals(initialRepairCount + 1));
      final newRepair = repository.repairs.first;
      expect(newRepair.id, equals('REP-9988'));
      expect(newRepair.customerName, equals('Kwame Mensah'));
      expect(newRepair.customerPhone, equals('024 999 8877'));
      expect(newRepair.deviceModel, equals('iPhone 14 Pro Max'));
      expect(newRepair.reportedIssue, equals('Screen Replacement'));
      expect(newRepair.description, contains('touch unresponsive in middle'));
      expect(newRepair.dropOffBranch, equals('Siaka Phones Osu Mall'));
      expect(newRepair.timeSlot, equals('Afternoon (13:00 - 16:00)'));
      expect(newRepair.photoPath, equals('damage_screen.jpg'));
      expect(repository.notifications.any((n) => n.referenceId == 'REP-9988' && n.type == NotificationType.repair), isTrue);
    });

    test('Can update device trade-in valuation status', () {
      final swap = repository.swaps.first;
      expect(swap.status, equals(SwapEvaluationStatus.underReview));

      repository.updateSwapStatus(
        swap.id,
        SwapEvaluationStatus.approved,
        notes: 'Grade A condition verified',
      );
      expect(repository.swaps.first.status, equals(SwapEvaluationStatus.approved));
      expect(repository.swaps.first.inspectionNotes, equals('Grade A condition verified'));
    });

    test('Can process inbound customer device swap request from mobile app instantly', () {
      final initialSwapCount = repository.swaps.length;
      final swapData = {
        'id': 'SWAP_SWAP-GH-5544',
        'name': 'Ama Serwaa - iPhone 12 to iPhone 15 Pro Max',
        'brand': 'iPhone',
        'category': 'SWAP_RECORD',
        'price': 15500.0,
        'original_price': 3800.0,
        'stock': 1,
        'specs': '{"swapId":"SWAP-GH-5544","customerName":"Ama Serwaa","customerPhone":"024 111 2233","targetDevice":"iPhone 15 Pro Max (256 GB, 8 GB)","targetDevicePrice":15500.0,"currentDevice":"iPhone 12 (128 GB)","deviceCondition":"Good (Minor Scratches)","batteryHealth":88,"estimatedTradeInValue":3800.0,"customerCashTopUp":11700.0,"preferredBranch":"Circle Main Branch","notes":"Clean with charger","status":"Under Review by Manager"}',
        'condition': 'underReview',
        'created_at': DateTime.now().toIso8601String(),
      };

      repository.processInboundSwap(swapData);

      expect(repository.swaps.length, equals(initialSwapCount + 1));
      final newSwap = repository.swaps.first;
      expect(newSwap.id, equals('SWAP-GH-5544'));
      expect(newSwap.customerName, equals('Ama Serwaa'));
      expect(newSwap.targetDevice, contains('iPhone 15 Pro Max'));
      expect(newSwap.currentDevice, contains('iPhone 12'));
      expect(newSwap.estimatedTradeInValue, equals(3800.0));
      expect(newSwap.customerCashTopUp, equals(11700.0));
      expect(newSwap.status, equals(SwapEvaluationStatus.underReview));
      expect(repository.notifications.any((n) => n.referenceId == 'SWAP-GH-5544' && n.type == NotificationType.swap), isTrue);
    });

    test('Can review swap request, update offered cost, and set status to approved', () {
      final targetSwap = repository.swaps.first;
      repository.updateSwapStatus(targetSwap.id, SwapEvaluationStatus.approved, offeredCost: 2200.0, notes: 'Screen original, clean device');
      final swap = repository.swaps.firstWhere((s) => s.id == targetSwap.id);
      expect(swap.offeredCost, equals(2200.0));
      expect(swap.status, equals(SwapEvaluationStatus.approved));
      expect(swap.inspectionNotes, equals('Screen original, clean device'));
    });

    test('Can send outbound direct customer messages across channels', () {
      final initialSentCount = repository.sentMessages.length;
      final newMessage = CustomerMessage(
        id: 'msg_test_01',
        customerId: 'SK-90001',
        customerName: 'Kofi Mensah',
        customerPhone: '+233 24 412 3456',
        customerEmail: 'kofi.mensah@gmail.com',
        channel: MessageChannel.inApp,
        category: MessageCategory.orderUpdate,
        subject: 'Order Dispatched for Circle Delivery',
        message: 'Hello Kofi, your iPhone 15 Pro is on the way with our dispatch rider.',
        sentAt: DateTime.now(),
      );

      repository.sendCustomerMessage(newMessage);
      expect(repository.sentMessages.length, equals(initialSentCount + 1));
      expect(repository.sentMessages.first.subject, equals('Order Dispatched for Circle Delivery'));
      expect(repository.sentMessages.first.channel, equals(MessageChannel.inApp));
    });

    test('Incoming customer reply marks customer online, sets lastLogin, and adds message to sentMessages', () {
      final initialCount = repository.sentMessages.length;
      final customer = repository.customers.first;
      repository.setCustomerOnline(customer.id, false);
      expect(repository.customers.firstWhere((c) => c.id == customer.id).isOnline, isFalse);

      repository.addIncomingCustomerReply(
        customer.id,
        'Hello Manager, I have arrived at the Circle boutique!',
        customerName: customer.fullName,
        customerPhone: customer.phone,
        customerEmail: customer.email,
      );

      expect(repository.sentMessages.length, equals(initialCount + 1));
      expect(repository.sentMessages.first.message, equals('Hello Manager, I have arrived at the Circle boutique!'));
      expect(repository.sentMessages.first.isFromCustomer, isTrue);
      expect(repository.customers.firstWhere((c) => c.id == customer.id).isOnline, isTrue);
    });

    test('Can manage service tickets (reply, update status, simulate inbound app message)', () {
      expect(repository.serviceTickets.isNotEmpty, isTrue);
      final ticket = repository.serviceTickets.first;
      final initialMessageCount = ticket.messages.length;

      // Reply as manager
      repository.replyToServiceTicket(ticket.id, 'Our technicians have completed testing on your device.');
      expect(ticket.messages.length, equals(initialMessageCount + 1));
      expect(ticket.messages.last.text, equals('Our technicians have completed testing on your device.'));
      expect(ticket.messages.last.senderType, equals(ServiceSenderType.manager));
      expect(ticket.status, equals(ServiceTicketStatus.waitingCustomer));

      // Update status
      repository.updateServiceTicketStatus(ticket.id, ServiceTicketStatus.resolved);
      expect(ticket.status, equals(ServiceTicketStatus.resolved));

      // Simulate incoming message from customer mobile app
      repository.addIncomingCustomerMessage(ticket.id, 'Thank you! When can I come to pick it up?');
      expect(ticket.messages.last.text, equals('Thank you! When can I come to pick it up?'));
      expect(ticket.messages.last.senderType, equals(ServiceSenderType.customer));
      expect(ticket.messages.last.isRead, isFalse);
      expect(ticket.status, equals(ServiceTicketStatus.open));

      // Mark as read
      repository.markTicketAsRead(ticket.id);
      expect(ticket.unreadCountForManager, equals(0));
    });

    test('Customer message from mobile app automatically synchronizes to Service Center tickets', () {
      final customer = repository.customers.first;
      final uniqueMsg = 'Inquiry from mobile app #${DateTime.now().millisecondsSinceEpoch}';

      repository.addIncomingCustomerReply(
        customer.id,
        uniqueMsg,
        customerName: customer.fullName,
        customerPhone: customer.phone,
        customerEmail: customer.email,
      );

      final matchingTicket = repository.serviceTickets.firstWhere(
        (t) => t.customerId == customer.id || t.customerPhone == customer.phone,
      );
      expect(matchingTicket.messages.any((m) => m.text == uniqueMsg), isTrue);
      expect(matchingTicket.status, equals(ServiceTicketStatus.open));
    });

    test('MessageChannel contains In-App Notification and Email', () {
      expect(MessageChannel.values.length, equals(2));
      expect(MessageChannel.values[0], equals(MessageChannel.inApp));
      expect(MessageChannel.values[0].label, equals('In-App Notification'));
      expect(MessageChannel.values[1], equals(MessageChannel.email));
      expect(MessageChannel.values[1].label, equals('Email'));
    });

    test('BNPL models contain applicant location data', () {
      final app = repository.bnplApplications.first;
      expect(app.location.isNotEmpty, isTrue);
    });

    test('Can select customer for messaging and auto-match or register', () {
      repository.selectCustomerForMessaging(
        customerName: 'Akwasi Mensah',
        phone: '+233 24 555 1234',
        email: 'akwasi@example.com',
      );
      expect(repository.activeMessagingCustomer, isNotNull);
      expect(repository.activeMessagingCustomer!.fullName, equals('Akwasi Mensah'));
      expect(repository.activeMessagingCustomer!.phone, equals('+233 24 555 1234'));
      expect(repository.activeMessagingCustomer!.email, equals('akwasi@example.com'));
      expect(repository.activeMessagingCustomer!.id, startsWith('SK-'));
    });

    test('Chronological customer ID generates and increases by 1 for each customer', () {
      final initialNextId = repository.generateNextCustomerId();
      expect(initialNextId, startsWith('SK-'));
      final num1 = int.parse(initialNextId.replaceAll(RegExp(r'[^0-9]'), ''));

      final c1 = repository.registerCustomer(
        fullName: 'New Customer One',
        phone: '+233 50 111 2222',
        email: 'customer1@siakaphones.com',
      );
      expect(c1.id, equals(initialNextId));

      final secondNextId = repository.generateNextCustomerId();
      final num2 = int.parse(secondNextId.replaceAll(RegExp(r'[^0-9]'), ''));
      expect(num2, equals(num1 + 1));

      final c2 = repository.registerCustomer(
        fullName: 'New Customer Two',
        phone: '+233 50 333 4444',
        email: 'customer2@siakaphones.com',
      );
      expect(c2.id, equals(secondNextId));
      expect(c2.id, equals('SK-${num1 + 1}'));
    });

    test('Can dynamically add brand device models', () {
      expect(repository.brandModels.containsKey('Apple'), isTrue);
      repository.addDeviceModel(brand: 'OnePlus', modelName: 'OnePlus 12');
      expect(repository.brandModels.containsKey('OnePlus'), isTrue);
      expect(repository.brandModels['OnePlus']!.contains('OnePlus 12'), isTrue);

      repository.addDeviceModel(brand: 'Apple', modelName: 'iPhone 17 Pro');
      expect(repository.brandModels['Apple']!.contains('iPhone 17 Pro'), isTrue);
    });

    test('Newly added products always appear at the top of the inventory list', () {
      final p1 = ManagerProduct(
        id: 'prod_sort_1',
        name: 'Older Product',
        brand: 'Apple',
        category: 'Smartphones',
        price: 5000,
        originalPrice: 5500,
        stock: 5,
        specs: 'Old spec',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      repository.addProduct(p1);

      final p2 = ManagerProduct(
        id: 'prod_sort_2',
        name: 'Brand Newest Product',
        brand: 'Apple',
        category: 'Smartphones',
        price: 6000,
        originalPrice: 6500,
        stock: 10,
        specs: 'Newest spec',
        createdAt: DateTime.now(),
      );
      repository.addProduct(p2);

      expect(repository.products.first.id, equals('prod_sort_2'));
      expect(repository.products.first.name, equals('Brand Newest Product'));
    });

    test('Can add new category and it is available in categories list', () {
      expect(repository.categories.contains('Drones & Quadcopters'), isFalse);
      repository.addCategory('Drones & Quadcopters', syncRemote: false);
      expect(repository.categories.contains('Drones & Quadcopters'), isTrue);
    });

    test('Can manage shipping dispatches and update status with checkpoints', () {
      expect(repository.shipments.isNotEmpty, isTrue);
      final initialActive = repository.activeShipmentsCount;
      final shipment = repository.shipments.firstWhere((s) => s.status != ShippingStatus.delivered);

      repository.updateShippingStatus(
        shipment.id,
        ShippingStatus.delivered,
        locationUpdate: 'Delivered to customer front gate',
        notes: 'Signed and confirmed by customer',
      );

      expect(shipment.status, equals(ShippingStatus.delivered));
      expect(shipment.lastLocationUpdate, equals('Delivered to customer front gate'));
      expect(shipment.statusHistory.last.location, equals('Delivered to customer front gate'));
      expect(repository.activeShipmentsCount, equals(initialActive - 1));
    });

    test('Can manage notifications, mark as read, and clear', () {
      expect(repository.notifications.isNotEmpty, isTrue);
      final unreadBefore = repository.unreadNotificationsCount;
      expect(unreadBefore > 0, isTrue);

      final unreadNotif = repository.notifications.firstWhere((n) => !n.isRead);
      repository.markNotificationAsRead(unreadNotif.id);
      expect(unreadNotif.isRead, isTrue);
      expect(repository.unreadNotificationsCount, equals(unreadBefore - 1));

      repository.markAllNotificationsAsRead();
      expect(repository.unreadNotificationsCount, equals(0));

      repository.clearNotifications();
      expect(repository.notifications.isEmpty, isTrue);
      expect(repository.unreadNotificationsCount, equals(0));
    });
  });

  group('SiakaManagerApp Desktop UI Tests', () {
    testWidgets('App renders desktop shell, executive sidebar, and branch header', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SiakaManagerApp());
      await tester.pumpAndSettle();

      // Verify branding in sidebar
      expect(find.text('SiakaPhones'), findsOneWidget);
      expect(find.text('MANAGER PORTAL'), findsOneWidget);

      // Verify navigation items including new Communications & Support section
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Shipping'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('BNPL Approvals'), findsOneWidget);
      expect(find.text('Repairs Desk'), findsOneWidget);
      expect(find.text('Device Swaps'), findsOneWidget);
      expect(find.text('Customer Activity'), findsOneWidget);
      expect(find.text('Business Analytics'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Customer Messaging'), findsOneWidget);
      expect(find.text('Service Center'), findsOneWidget);

      // Verify header status and branch
      expect(find.text('Siaka Phones Enterprise System'), findsOneWidget);
      expect(find.text('Live Sync Ready'), findsOneWidget);
      expect(find.text('Accra Central (Circle)'), findsAtLeast(1));

      // Verify Overview KPIs
      expect(find.text('Executive Store Overview'), findsOneWidget);
      expect(find.text('TOTAL REVENUE'), findsOneWidget);
      expect(find.text('PENDING ORDERS'), findsOneWidget);

      // Verify "Add New Product" has been removed from Overview header
      expect(find.text('Add New Product'), findsNothing);
      expect(find.text('Add a new product'), findsNothing);
    });

    testWidgets('Can navigate to Customer Messaging and Service Center views', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SiakaManagerApp());
      await tester.pumpAndSettle();

      // Tap Customer Messaging in sidebar
      await tester.tap(find.text('Customer Messaging'));
      await tester.pumpAndSettle();

      expect(find.text('Direct Customer Messaging'), findsOneWidget);
      expect(find.text('Compose New Message'), findsOneWidget);
      expect(find.text('SELECT RECIPIENT CUSTOMER'), findsOneWidget);
      expect(find.text('COMMUNICATION CHANNEL'), findsOneWidget);

      // Tap Service Center in sidebar
      await tester.tap(find.text('Service Center'));
      await tester.pumpAndSettle();

      expect(find.text('Service Center & Customer Support Desk'), findsOneWidget);
      expect(find.text('Live App Sync Active'), findsOneWidget);
      expect(find.text('Online'), findsWidgets);
      expect(find.text('● Online in App'), findsWidgets);

      // Tap Orders in sidebar (verify full width layout loaded)
      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();

      expect(find.text('Customer Orders Management'), findsOneWidget);
      expect(find.text('ITEMS ORDERED'), findsOneWidget);
      expect(find.text('GHANA GPS / ADDRESS'), findsOneWidget);

      // Tap BNPL Approvals in sidebar
      await tester.tap(find.text('BNPL Approvals'));
      await tester.pumpAndSettle();

      expect(find.text('Buy Now Pay Later (BNPL) Approvals'), findsOneWidget);
      expect(find.text('APPLICANT'), findsOneWidget);

      // Tap Repairs Desk in sidebar
      await tester.tap(find.text('Repairs Desk'));
      await tester.pumpAndSettle();

      expect(find.text('Hardware Repair & Service Desk'), findsOneWidget);
      expect(find.text('REPORTED FAULT / ISSUE'), findsOneWidget);

      // Tap Device Swaps in sidebar
      await tester.tap(find.text('Device Swaps'));
      await tester.pumpAndSettle();

      expect(find.text('Device Trade-in & Swap Valuation Desk'), findsOneWidget);
      expect(find.text('CURRENT DEVICE'), findsOneWidget);

      // Tap Settings & Branches in sidebar
      final settingsFinder = find.text('Settings & Branches');
      await tester.scrollUntilVisible(
        settingsFinder,
        50.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();

      expect(find.text('System Settings & Branch Control'), findsOneWidget);
      expect(find.text('Physical Store Branches'), findsOneWidget);
    });

    testWidgets('BNPL table displays GHANA CARD & LOCATION column and removes EMPLOYER & SALARY', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SiakaManagerApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('BNPL Approvals'));
      await tester.pumpAndSettle();

      expect(find.text('GHANA CARD & LOCATION'), findsOneWidget);
      expect(find.text('EMPLOYER & SALARY'), findsNothing);
    });

    testWidgets('Customer Activity table displays dedicated EMAIL ADDRESS column', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SiakaManagerApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Customer Activity'));
      await tester.pumpAndSettle();

      expect(find.text('CUSTOMER ID'), findsOneWidget);
      expect(find.text('EMAIL ADDRESS'), findsOneWidget);
      expect(find.text('ID: SK-90001'), findsWidgets);
    });

    testWidgets('Clicking message icon in Orders navigates to Customer Messaging with customer selected', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SiakaManagerApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();

      // Find message icon button on first order
      final messageButtons = find.byTooltip('Send Direct Message to Kwame Asante');
      expect(messageButtons, findsOneWidget);

      await tester.ensureVisible(messageButtons);
      await tester.pumpAndSettle();

      await tester.tap(messageButtons);
      await tester.pumpAndSettle();

      // Should have navigated to Customer Messaging
      expect(find.text('Direct Customer Messaging'), findsOneWidget);
      expect(find.text('Kwame Asante'), findsAtLeast(1));
    });

    testWidgets('Total revenue KPI card hides balance by default and toggles on eye icon click', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SiakaManagerApp());
      await tester.pumpAndSettle();

      // Verify balance is hidden by default
      expect(find.text('GH₵ ••••••••'), findsOneWidget);

      // Find and tap the eye icon button
      final eyeButton = find.byTooltip('Show Revenue Balance');
      expect(eyeButton, findsOneWidget);
      await tester.tap(eyeButton);
      await tester.pumpAndSettle();

      // Now the revenue should be revealed
      expect(find.text('GH₵ ••••••••'), findsNothing);
      expect(find.textContaining('GH₵ '), findsWidgets);

      // Tap to hide again
      final hideEyeButton = find.byTooltip('Hide Revenue Balance');
      expect(hideEyeButton, findsOneWidget);
      await tester.tap(hideEyeButton);
      await tester.pumpAndSettle();

      expect(find.text('GH₵ ••••••••'), findsOneWidget);
    });

    testWidgets('Can navigate to Shipping and Notifications views', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SiakaManagerApp());
      await tester.pumpAndSettle();

      // Tap Shipping in sidebar
      await tester.tap(find.text('Shipping'));
      await tester.pumpAndSettle();

      expect(find.text('Shipping & Delivery Management'), findsOneWidget);
      expect(find.text('New Dispatch Record'), findsOneWidget);
      expect(find.text('TRACKING # & TYPE'), findsOneWidget);

      // Tap Notifications in sidebar
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(find.text('Notifications Hub'), findsOneWidget);
      expect(find.text('ALL NOTIFICATIONS'), findsOneWidget);
      expect(find.text('UNREAD ALERTS'), findsOneWidget);
    });

    testWidgets('Can navigate to Advertisements and open New Video Advertisement dialog', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SiakaManagerApp());
      await tester.pumpAndSettle();

      // Tap Advertisements in sidebar
      await tester.scrollUntilVisible(
        find.text('Advertisements'),
        50.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Advertisements'));
      await tester.pumpAndSettle();

      expect(find.text('Advertisement & Video Banner Hub'), findsOneWidget);
      expect(find.text('New Video Advertisement'), findsOneWidget);
      expect(find.text('The 5 Mobile Banner Playlists'), findsOneWidget);

      // Open New Video Ad dialog
      await tester.tap(find.text('New Video Advertisement'));
      await tester.pumpAndSettle();

      expect(find.text('Create Video Advertisement'), findsOneWidget);
      expect(find.text('Campaign Headline *'), findsOneWidget);
      expect(find.text('Video Link / Network Stream URL *'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Create Video Advertisement'), findsNothing);
    });

    testWidgets('Can open Add Device Model dialog from Inventory', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SiakaManagerApp());
      await tester.pumpAndSettle();

      // Navigate to Inventory
      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();

      expect(find.text('Add Device Model'), findsOneWidget);
      await tester.tap(find.text('Add Device Model'));
      await tester.pumpAndSettle();

      expect(find.text('Device Model Name *'), findsOneWidget);
      expect(find.text('Brand *'), findsNothing);
      expect(find.text('Save Model'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('Can open Add Category dialog from Inventory', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SiakaManagerApp());
      await tester.pumpAndSettle();

      // Navigate to Inventory
      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();

      expect(find.text('Add Category'), findsOneWidget);
      await tester.tap(find.text('Add Category'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Category'), findsOneWidget);
      expect(find.text('Existing categories:'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Add New Category'), findsNothing);
    });

    testWidgets('Can open Add New Product dialog and select multiple storage and RAM options', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SiakaManagerApp());
      await tester.pumpAndSettle();

      // Navigate to Inventory
      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Product'), findsOneWidget);
      await tester.tap(find.text('Add New Product'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Inventory SKU'), findsOneWidget);
      expect(find.text('4. HARDWARE MEMORY & STORAGE (SELECT 1 OR MORE OPTIONS)'), findsOneWidget);
      expect(find.text('Internal Storage (ROM):'), findsOneWidget);
      expect(find.text('System RAM Memory:'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Add New Inventory SKU'), findsNothing);
    });

    testWidgets('App renders without overflow and supports scrolling when window is minimized', (WidgetTester tester) async {
      // Simulate minimized window: narrow width and short height
      tester.view.physicalSize = const Size(700, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SiakaManagerApp());
      await tester.pumpAndSettle();

      // Dashboard should render cleanly with no overflow exceptions
      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollbar), findsWidgets);

      final expectedTitles = [
        'Executive Store Overview',
        'Customer Orders Management',
        'Inventory & Catalog Control',
        'Buy Now Pay Later (BNPL) Approvals',
        'Hardware Repair & Service Desk',
        'Device Trade-in & Swap Valuation Desk',
        'Customer Activity & Registration Intelligence',
        'Business Intelligence & Growth Analytics',
        'Direct Customer Messaging',
        'Service Center & Customer Support Desk',
        'System Settings & Branch Control',
        'Shipping & Delivery Management',
        'Notifications Hub',
        'Advertisement & Video Banner Hub',
      ];

      for (int i = 0; i < expectedTitles.length; i++) {
        final scaffold = tester.widget<DesktopScaffold>(find.byType(DesktopScaffold));
        scaffold.onIndexChanged(i);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow in view $i (${expectedTitles[i]})');
        expect(find.text(expectedTitles[i]), findsOneWidget);
        expect(find.byType(Scrollbar), findsWidgets);
      }
    });

    testWidgets('Can click Customer Messaging KPI banners to view detailed message audit dialogs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SiakaManagerApp());
      await tester.pumpAndSettle();

      // Tap Customer Messaging in sidebar
      await tester.tap(find.text('Customer Messaging'));
      await tester.pumpAndSettle();

      // Click ALL SENT banner
      await tester.tap(find.byTooltip('Click to view ALL SENT message details & audit trail'));
      await tester.pumpAndSettle();

      expect(find.text('All Sent Customer Messages'), findsOneWidget);
      expect(find.text('Order Dispatch Notice'), findsWidgets);
      expect(find.text('Screen Repair Diagnostic Complete'), findsOneWidget);

      // Scroll dialog list to verify remaining items
      await tester.drag(find.byType(ListView).last, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Installment Reminder'), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Click IN-APP banner
      await tester.tap(find.byTooltip('Click to view IN-APP message details & audit trail'));
      await tester.pumpAndSettle();

      expect(find.text('In-App Notification Messages'), findsOneWidget);
      expect(find.text('TOTAL SENT'), findsOneWidget);
      expect(find.text('DELIVERY RATE'), findsOneWidget);
      expect(find.text('Kwame Mensah'), findsWidgets);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Click EMAIL banner
      await tester.tap(find.byTooltip('Click to view EMAIL message details & audit trail'));
      await tester.pumpAndSettle();

      expect(find.text('Email Communications'), findsOneWidget);
      expect(find.text('TOTAL SENT'), findsOneWidget);
      expect(find.text('Abena Osei'), findsWidgets);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('Can click Customer Activity KPI banners to view detailed customer activity intelligence dialogs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SiakaManagerApp());
      await tester.pumpAndSettle();

      // Tap Customer Activity in sidebar
      await tester.tap(find.text('Customer Activity'));
      await tester.pumpAndSettle();

      expect(find.text('Customer Activity & Registration Intelligence'), findsOneWidget);

      // 1. Click USERS ONLINE NOW banner
      await tester.tap(find.byTooltip('Click to view USERS ONLINE NOW details & breakdown'));
      await tester.pumpAndSettle();

      expect(find.text('Users Online Now (Live Store Telemetry)'), findsOneWidget);
      expect(find.text('USERS ONLINE NOW'), findsWidgets);
      expect(find.text('TOTAL REGISTERED'), findsOneWidget);
      expect(find.text('ONLINE SHARE'), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pumpAndSettle();

      // 2. Click NEW SIGNUPS banner
      await tester.tap(find.byTooltip('Click to view NEW SIGNUPS (THIS MONTH) details & breakdown'));
      await tester.pumpAndSettle();

      expect(find.text('New Customer Signups (This Month)'), findsOneWidget);
      expect(find.text('NEW SIGNUPS'), findsWidgets);
      expect(find.text('NEW VALUE'), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pumpAndSettle();

      // 3. Click TOTAL LOGINS RECORDED banner
      await tester.tap(find.byTooltip('Click to view TOTAL LOGINS RECORDED details & breakdown'));
      await tester.pumpAndSettle();

      expect(find.text('Total Logins & Session Intelligence'), findsOneWidget);
      expect(find.text('TOTAL LOGINS'), findsWidgets);
      expect(find.text('TOP USER LOGINS'), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pumpAndSettle();

      // 4. Click AVG LOGINS PER USER banner
      await tester.tap(find.byTooltip('Click to view AVG LOGINS PER USER details & breakdown'));
      await tester.pumpAndSettle();

      expect(find.text('Average Logins & Session Frequency'), findsOneWidget);
      expect(find.text('AVG LOGINS'), findsWidgets);
      expect(find.text('POWER USERS (10+)'), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pumpAndSettle();
    });

    testWidgets('Customer Activity and Business Analytics expose custom date range options', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SiakaManagerApp());
      await tester.pumpAndSettle();

      // Tap Customer Activity
      await tester.tap(find.text('Customer Activity'));
      await tester.pumpAndSettle();

      expect(find.text('FROM'), findsOneWidget);
      expect(find.text('TO'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // Tap Business Analytics
      await tester.tap(find.text('Business Analytics'));
      await tester.pumpAndSettle();

      expect(find.text('Business Intelligence & Growth Analytics'), findsOneWidget);
      expect(find.text('YTD 2026'), findsOneWidget);
      expect(find.text('FROM'), findsOneWidget);
      expect(find.text('TO'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });
  });
}

