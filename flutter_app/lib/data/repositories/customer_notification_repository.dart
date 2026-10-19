import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/device_notification_service.dart';

class CustomerNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String timeLabel;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  bool isUnread;
  final String? channel;
  final String? referenceId;
  final bool isFromManager;

  CustomerNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.timeLabel = '',
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isUnread = false,
    this.channel,
    this.referenceId,
    this.isFromManager = false,
  });

  String get formattedTime {
    if (timeLabel.isNotEmpty) return timeLabel;
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

class CustomerNotificationRepository extends ChangeNotifier {
  static final CustomerNotificationRepository instance =
      CustomerNotificationRepository._internal();
  factory CustomerNotificationRepository() => instance;

  Timer? _pollTimer;
  StreamSubscription? _remoteSub;
  HttpClient? _sseClient;

  List<CustomerNotification> _notifications = [];

  CustomerNotificationRepository._internal() {
    _initDefaultNotifications();
    _initSync();
  }

  void _initDefaultNotifications() {
    final now = DateTime.now();
    _notifications = [
      CustomerNotification(
        id: 'n1',
        title: 'Order Shipped! 🚚',
        body: 'Your Samsung Galaxy S25 Ultra is on its way. Expected delivery: Tomorrow.',
        timestamp: now.subtract(const Duration(hours: 2)),
        timeLabel: '2 hours ago',
        icon: Icons.local_shipping_rounded,
        iconColor: const Color(0xFF1C7BFF),
        iconBg: const Color(0xFFEFF6FF),
        isUnread: true,
      ),
      CustomerNotification(
        id: 'n2',
        title: 'Flash Sale — 20% Off iPhones',
        body: 'Today only! Save big on iPhone 16 Pro models. Limited stock available.',
        timestamp: now.subtract(const Duration(hours: 5)),
        timeLabel: '5 hours ago',
        icon: Icons.local_offer_rounded,
        iconColor: const Color(0xFFEF4444),
        iconBg: const Color(0xFFFEF2F2),
        isUnread: true,
      ),
      CustomerNotification(
        id: 'n3',
        title: 'Payment Confirmed ✅',
        body: 'Your payment of ₵1,299 for iPhone 16 Pro was successfully processed.',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        timeLabel: 'Yesterday, 3:45 PM',
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF059669),
        iconBg: const Color(0xFFECFDF5),
      ),
      CustomerNotification(
        id: 'n4',
        title: 'New Arrival: Pixel 9 Pro',
        body: 'The Google Pixel 9 Pro is now in stock. Check out the latest features.',
        timestamp: now.subtract(const Duration(days: 1, hours: 8)),
        timeLabel: 'Yesterday, 10:12 AM',
        icon: Icons.new_releases_rounded,
        iconColor: const Color(0xFF7C3AED),
        iconBg: const Color(0xFFF5F3FF),
      ),
      CustomerNotification(
        id: 'n5',
        title: 'Wishlist Price Drop 💰',
        body: 'Samsung Galaxy Z Fold 6 on your wishlist dropped by ₵150!',
        timestamp: now.subtract(const Duration(days: 3)),
        timeLabel: '3 days ago',
        icon: Icons.trending_down_rounded,
        iconColor: const Color(0xFFD97706),
        iconBg: const Color(0xFFFFFBEB),
      ),
      CustomerNotification(
        id: 'n6',
        title: 'Repair Status Update',
        body: 'Your screen repair is complete. Visit our Accra store to pick it up.',
        timestamp: now.subtract(const Duration(days: 4)),
        timeLabel: '4 days ago',
        icon: Icons.build_rounded,
        iconColor: const Color(0xFF0891B2),
        iconBg: const Color(0xFFECFEFF),
      ),
      CustomerNotification(
        id: 'n7',
        title: 'Trade-In Offer Ready',
        body: 'We have a new trade-in offer for your old device. Get up to ₵400 credit.',
        timestamp: now.subtract(const Duration(days: 7)),
        timeLabel: '1 week ago',
        icon: Icons.swap_horiz_rounded,
        iconColor: const Color(0xFF1C7BFF),
        iconBg: const Color(0xFFEFF6FF),
      ),
    ];
  }

  void _initSync() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    fetchRemoteNotifications();

    // 25-second auto-poll (with quota protection)
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!SupabaseService.isQuotaRestricted) {
        fetchRemoteNotifications();
      }
    });

    // Supabase Realtime Stream
    try {
      _remoteSub = SupabaseService().streamNotificationRecords()?.listen((records) {
        _applyRemoteRecords(records);
      }, onError: (_) {});
    } catch (_) {}

    // Local SSE Events listener
    _listenLocalSse();
  }

  void _listenLocalSse() async {
    try {
      final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      _sseClient = HttpClient()..connectionTimeout = const Duration(seconds: 2);
      final request = await _sseClient!.getUrl(Uri.parse('http://$host:8088/api/events'));
      request.headers.set('Accept', 'text/event-stream');
      final response = await request.close();
      if (response.statusCode == 200) {
        response.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
          if (line.startsWith('data:')) {
            try {
              final jsonStr = line.substring(5).trim();
              if (jsonStr.startsWith('{')) {
                final data = jsonDecode(jsonStr) as Map<String, dynamic>;
                _processInboundNotification(data);
              }
            } catch (_) {}
          }
        }, onError: (_) {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _remoteSub?.cancel();
    _sseClient?.close(force: true);
    super.dispose();
  }

  Future<void> fetchRemoteNotifications() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    // 1. Fetch from Supabase
    try {
      final records = await SupabaseService().fetchNotificationRecords();
      if (records != null && records.isNotEmpty) {
        _applyRemoteRecords(records);
      }
    } catch (_) {}

    // 2. Fetch from Local PC Sync Server
    try {
      final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1000);
      final req = await client.getUrl(Uri.parse('http://$host:8088/api/notifications'));
      final res = await req.close().timeout(const Duration(milliseconds: 1000));
      if (res.statusCode == HttpStatus.ok) {
        final body = await res.transform(utf8.decoder).join();
        if (body.isNotEmpty && body.startsWith('[')) {
          final list = jsonDecode(body) as List;
          final maps = list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          _applyRemoteRecords(maps);
        }
      }
    } catch (_) {}
  }

  void _applyRemoteRecords(List<Map<String, dynamic>> records) {
    bool hasChanges = false;
    for (final map in records) {
      if (_processInboundNotification(map, notify: false)) {
        hasChanges = true;
      }
    }
    if (hasChanges) {
      _sortNotifications();
      notifyListeners();
    }
  }

  bool _processInboundNotification(Map<String, dynamic> data, {bool notify = true}) {
    try {
      final id = data['id']?.toString() ?? '';
      if (id.isEmpty) return false;

      Map<String, dynamic> specs = {};
      if (data['specs'] != null) {
        final specsStr = data['specs'].toString();
        if (specsStr.startsWith('{')) {
          specs = jsonDecode(specsStr);
        }
      }

      final target = specs['target']?.toString() ?? data['target']?.toString() ?? '';
      // If target is specifically manager, customer app ignores
      if (target == 'manager') return false;

      final title = specs['title']?.toString() ?? data['name']?.toString() ?? data['title']?.toString() ?? 'Store Notification';
      final body = specs['body']?.toString() ?? data['message']?.toString() ?? data['body']?.toString() ?? '';
      final channel = specs['channelLabel']?.toString() ?? specs['channel']?.toString() ?? data['brand']?.toString() ?? 'Store Manager';
      final timestampStr = specs['timestamp']?.toString() ?? data['created_at']?.toString();
      final dt = timestampStr != null ? DateTime.tryParse(timestampStr) ?? DateTime.now() : DateTime.now();

      final isFromManager = id.startsWith('NOTIF_MSG_') || target == 'customer' || data['category'] == 'NOTIFICATION_RECORD';
      final isUnread = specs['isUnread'] == true || data['condition'] == 'unread' || data['is_read'] == false;

      final notif = CustomerNotification(
        id: id,
        title: title,
        body: body,
        timestamp: dt,
        icon: isFromManager ? Icons.chat_bubble_rounded : Icons.notifications_rounded,
        iconColor: const Color(0xFF1C7BFF),
        iconBg: const Color(0xFFEFF6FF),
        isUnread: isUnread,
        channel: channel,
        referenceId: specs['id']?.toString() ?? id,
        isFromManager: isFromManager,
      );

      final existingIdx = _notifications.indexWhere((n) => n.id == id);
      if (existingIdx != -1) {
        return false;
      } else {
        _notifications.insert(0, notif);
        if (notif.isUnread) {
          DeviceNotificationService.instance
              .showNotification(title: notif.title, body: notif.body);
        }
        if (notify) {
          _sortNotifications();
          notifyListeners();
        }
        return true;
      }
    } catch (_) {
      return false;
    }
  }

  void _sortNotifications() {
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Getters
  List<CustomerNotification> get notifications => List.unmodifiable(_notifications);

  List<CustomerNotification> get today {
    final now = DateTime.now();
    return _notifications.where((n) {
      final diff = now.difference(n.timestamp);
      return diff.inDays == 0 && n.timestamp.day == now.day;
    }).toList();
  }

  List<CustomerNotification> get yesterday {
    final now = DateTime.now();
    return _notifications.where((n) {
      final diff = now.difference(n.timestamp);
      return (diff.inDays == 1 || (diff.inHours >= 20 && diff.inHours < 48 && n.timestamp.day != now.day));
    }).toList();
  }

  List<CustomerNotification> get older {
    final now = DateTime.now();
    return _notifications.where((n) {
      final diff = now.difference(n.timestamp);
      return diff.inDays > 1 && n.timestamp.day != now.day && n.timestamp.day != now.subtract(const Duration(days: 1)).day;
    }).toList();
  }

  int get unreadCount => _notifications.where((n) => n.isUnread).length;

  void markAllRead() {
    for (final n in _notifications) {
      n.isUnread = false;
    }
    notifyListeners();
  }

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && _notifications[idx].isUnread) {
      _notifications[idx].isUnread = false;
      notifyListeners();
    }
  }

  void addNotification(CustomerNotification notif) {
    _notifications.insert(0, notif);
    _sortNotifications();
    if (notif.isUnread) {
      DeviceNotificationService.instance
          .showNotification(title: notif.title, body: notif.body);
    }
    notifyListeners();
  }

  void addOrderPlacedNotification({required String orderId, required double totalAmount}) {
    final notif = CustomerNotification(
      id: 'NOTIF_ORDER_CONFIRM_$orderId',
      title: 'Order Placed! 📦',
      body: 'Your order #$orderId for ₵${totalAmount.toStringAsFixed(2)} has been confirmed and dispatched to our fulfillment queue.',
      timestamp: DateTime.now(),
      timeLabel: 'Just now',
      icon: Icons.shopping_bag_rounded,
      iconColor: const Color(0xFF059669),
      iconBg: const Color(0xFFECFDF5),
      isUnread: true,
      referenceId: orderId,
    );
    addNotification(notif);
  }
}
