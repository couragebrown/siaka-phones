import 'package:flutter/material.dart';

class _AppNotification {
  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isUnread;

  const _AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isUnread = false,
  });
}

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  List<_AppNotification> _today = const [
    _AppNotification(
      id: 'n1',
      title: 'Order Shipped! 🚚',
      body: 'Your Samsung Galaxy S25 Ultra is on its way. Expected delivery: Tomorrow.',
      timeLabel: '2 hours ago',
      icon: Icons.local_shipping_rounded,
      iconColor: Color(0xFF1C7BFF),
      iconBg: Color(0xFFEFF6FF),
      isUnread: true,
    ),
    _AppNotification(
      id: 'n2',
      title: 'Flash Sale — 20% Off iPhones',
      body: 'Today only! Save big on iPhone 16 Pro models. Limited stock available.',
      timeLabel: '5 hours ago',
      icon: Icons.local_offer_rounded,
      iconColor: Color(0xFFEF4444),
      iconBg: Color(0xFFFEF2F2),
      isUnread: true,
    ),
  ];

  final List<_AppNotification> _yesterday = const [
    _AppNotification(
      id: 'n3',
      title: 'Payment Confirmed ✅',
      body: 'Your payment of ₵1,299 for iPhone 16 Pro was successfully processed.',
      timeLabel: 'Yesterday, 3:45 PM',
      icon: Icons.check_circle_rounded,
      iconColor: Color(0xFF059669),
      iconBg: Color(0xFFECFDF5),
    ),
    _AppNotification(
      id: 'n4',
      title: 'New Arrival: Pixel 9 Pro',
      body: 'The Google Pixel 9 Pro is now in stock. Check out the latest features.',
      timeLabel: 'Yesterday, 10:12 AM',
      icon: Icons.new_releases_rounded,
      iconColor: Color(0xFF7C3AED),
      iconBg: Color(0xFFF5F3FF),
    ),
  ];

  final List<_AppNotification> _older = const [
    _AppNotification(
      id: 'n5',
      title: 'Wishlist Price Drop 💰',
      body: 'Samsung Galaxy Z Fold 6 on your wishlist dropped by ₵150!',
      timeLabel: '3 days ago',
      icon: Icons.trending_down_rounded,
      iconColor: Color(0xFFD97706),
      iconBg: Color(0xFFFFFBEB),
    ),
    _AppNotification(
      id: 'n6',
      title: 'Repair Status Update',
      body: 'Your screen repair is complete. Visit our Accra store to pick it up.',
      timeLabel: '4 days ago',
      icon: Icons.build_rounded,
      iconColor: Color(0xFF0891B2),
      iconBg: Color(0xFFECFEFF),
    ),
    _AppNotification(
      id: 'n7',
      title: 'Trade-In Offer Ready',
      body: 'We have a new trade-in offer for your old device. Get up to ₵400 credit.',
      timeLabel: '1 week ago',
      icon: Icons.swap_horiz_rounded,
      iconColor: Color(0xFF1C7BFF),
      iconBg: Color(0xFFEFF6FF),
    ),
  ];

  int get _unreadCount =>
      [..._today, ..._yesterday, ..._older].where((n) => n.isUnread).length;

  void _markAllRead() {
    setState(() {
      _today = _today
          .map((n) => _AppNotification(
                id: n.id,
                title: n.title,
                body: n.body,
                timeLabel: n.timeLabel,
                icon: n.icon,
                iconColor: n.iconColor,
                iconBg: n.iconBg,
                isUnread: false,
              ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1F2937), size: 20),
        ),
        title: Column(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount unread',
                style: const TextStyle(
                  color: Color(0xFF1C7BFF),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1C7BFF),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text(
                'Mark all read',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (_today.isNotEmpty) ...[
            _buildSectionHeader('Today'),
            ..._today.map(_buildNotificationCard),
          ],
          if (_yesterday.isNotEmpty) ...[
            _buildSectionHeader('Yesterday'),
            ..._yesterday.map(_buildNotificationCard),
          ],
          if (_older.isNotEmpty) ...[
            _buildSectionHeader('Earlier'),
            ..._older.map(_buildNotificationCard),
          ],
          if (_today.isEmpty && _yesterday.isEmpty && _older.isEmpty)
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(_AppNotification notification) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isUnread
                ? const Color(0xFFBFDBFE)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: notification.isUnread
                  ? const Color(0xFF1C7BFF).withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: notification.isUnread ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notification.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(notification.icon,
                      color: notification.iconColor, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: const Color(0xFF1F2937),
                              fontSize: 13.5,
                              fontWeight: notification.isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        if (notification.isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1C7BFF),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.timeLabel,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Center(
              child: Icon(Icons.notifications_off_outlined,
                  color: Color(0xFF1C7BFF), size: 34),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Notifications Yet',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "You are all caught up! We will notify you about orders, deals, and more.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
