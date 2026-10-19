import 'package:flutter/material.dart';
import '../../../data/repositories/customer_notification_repository.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final CustomerNotificationRepository _repo =
      CustomerNotificationRepository.instance;

  @override
  void initState() {
    super.initState();
    // Trigger remote fetch on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo.fetchRemoteNotifications();
    });
  }

  void _markAllRead() {
    _repo.markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _repo,
      builder: (context, _) {
        final unreadCount = _repo.unreadCount;
        final today = _repo.today;
        final yesterday = _repo.yesterday;
        final older = _repo.older;
        final isEmpty = today.isEmpty && yesterday.isEmpty && older.isEmpty;

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
                if (unreadCount > 0)
                  Text(
                    '$unreadCount unread',
                    style: const TextStyle(
                      color: Color(0xFF1C7BFF),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            actions: [
              if (unreadCount > 0)
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
          body: RefreshIndicator(
            onRefresh: () => _repo.fetchRemoteNotifications(),
            color: const Color(0xFF1C7BFF),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                if (today.isNotEmpty) ...[
                  _buildSectionHeader('Today'),
                  ...today.map(_buildNotificationCard),
                ],
                if (yesterday.isNotEmpty) ...[
                  _buildSectionHeader('Yesterday'),
                  ...yesterday.map(_buildNotificationCard),
                ],
                if (older.isNotEmpty) ...[
                  _buildSectionHeader('Earlier'),
                  ...older.map(_buildNotificationCard),
                ],
                if (isEmpty) _buildEmptyState(),
              ],
            ),
          ),
        );
      },
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

  Widget _buildNotificationCard(CustomerNotification notification) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          _repo.markAsRead(notification.id);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notification.isUnread
                  ? const Color(0xFFBFDBFE)
                  : const Color(0xFFE5E7EB),
              width: notification.isUnread ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: notification.isUnread
                    ? const Color(0xFF1C7BFF).withValues(alpha: 0.08)
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
                          color: Color(0xFF4B5563),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.formattedTime,
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
            "You are all caught up! We will notify you about orders, deals, and store messages.",
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
