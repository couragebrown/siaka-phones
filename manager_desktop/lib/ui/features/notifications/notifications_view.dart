import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/manager_repository.dart';
import '../../../domain/models/manager_notification.dart';

class NotificationsView extends StatefulWidget {
  final ManagerRepository repository;
  final ValueChanged<int>? onNavigate;

  const NotificationsView({
    super.key,
    required this.repository,
    this.onNavigate,
  });

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _outerScrollController = ScrollController();
  String _selectedFilter = 'All';

  final List<String> _filterCategories = [
    'All',
    'Unread',
    'Orders',
    'BNPL Credit',
    'Repairs',
    'Shipping',
    'Low Stock',
    'Inquiries',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _outerScrollController.dispose();
    super.dispose();
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  List<ManagerNotification> _getFilteredNotifications() {
    return widget.repository.notifications.where((n) {
      if (_selectedFilter == 'Unread' && n.isRead) return false;
      if (_selectedFilter == 'Orders' && n.type != NotificationType.order) return false;
      if (_selectedFilter == 'BNPL Credit' && n.type != NotificationType.bnpl) return false;
      if (_selectedFilter == 'Repairs' && n.type != NotificationType.repair) return false;
      if (_selectedFilter == 'Shipping' && n.type != NotificationType.shipping) return false;
      if (_selectedFilter == 'Low Stock' && n.type != NotificationType.inventory) return false;
      if (_selectedFilter == 'Inquiries' && n.type != NotificationType.customerMessage) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.repository,
      builder: (context, _) {
        final filteredList = _getFilteredNotifications();
        final unreadCount = widget.repository.unreadNotificationsCount;
        final totalCount = widget.repository.notifications.length;
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 900;

        final header = Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isCompact ? (screenWidth - 48 > 280 ? screenWidth - 48 : 280) : 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Notifications Hub',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unreadCount UNREAD',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time operational alerts, customer interactions, orders, and system logs',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (unreadCount > 0)
                  OutlinedButton.icon(
                    onPressed: () {
                      widget.repository.markAllNotificationsAsRead();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All notifications marked as read.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark All as Read'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1C7BFF),
                      side: const BorderSide(color: Color(0xFF93C5FD)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                if (totalCount > 0)
                  TextButton.icon(
                    onPressed: () {
                      widget.repository.clearNotifications();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All notifications cleared.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Color(0xFF64748B)),
                    label: const Text('Clear All', style: TextStyle(color: Color(0xFF64748B))),
                  ),
              ],
            ),
          ],
        );

        final metricCards = isCompact
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: _buildMetric(
                        label: 'ALL NOTIFICATIONS',
                        value: '$totalCount',
                        icon: Icons.notifications_active_outlined,
                        color: const Color(0xFF1C7BFF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 200,
                      child: _buildMetric(
                        label: 'UNREAD ALERTS',
                        value: '$unreadCount',
                        icon: Icons.mark_email_unread_outlined,
                        color: const Color(0xFFDC2626),
                        hasWarning: unreadCount > 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 200,
                      child: _buildMetric(
                        label: 'ORDERS & BNPL',
                        value: '${widget.repository.notifications.where((n) => n.type == NotificationType.order || n.type == NotificationType.bnpl).length}',
                        icon: Icons.shopping_bag_outlined,
                        color: const Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 200,
                      child: _buildMetric(
                        label: 'SHIPPING & STOCK',
                        value: '${widget.repository.notifications.where((n) => n.type == NotificationType.shipping || n.type == NotificationType.inventory).length}',
                        icon: Icons.local_shipping_outlined,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildMetric(
                      label: 'ALL NOTIFICATIONS',
                      value: '$totalCount',
                      icon: Icons.notifications_active_outlined,
                      color: const Color(0xFF1C7BFF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetric(
                      label: 'UNREAD ALERTS',
                      value: '$unreadCount',
                      icon: Icons.mark_email_unread_outlined,
                      color: const Color(0xFFDC2626),
                      hasWarning: unreadCount > 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetric(
                      label: 'ORDERS & BNPL',
                      value: '${widget.repository.notifications.where((n) => n.type == NotificationType.order || n.type == NotificationType.bnpl).length}',
                      icon: Icons.shopping_bag_outlined,
                      color: const Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetric(
                      label: 'SHIPPING & STOCK',
                      value: '${widget.repository.notifications.where((n) => n.type == NotificationType.shipping || n.type == NotificationType.inventory).length}',
                      icon: Icons.local_shipping_outlined,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ],
              );

        final filterChips = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 10),
                ..._filterCategories.map((cat) {
                  final isSel = _selectedFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSel,
                      label: Text(cat),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? Colors.white : const Color(0xFF334155),
                      ),
                      backgroundColor: const Color(0xFFF1F5F9),
                      selectedColor: const Color(0xFF1C7BFF),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      onSelected: (_) => setState(() => _selectedFilter = cat),
                    ),
                  );
                }),
              ],
            ),
          ),
        );

        final feedList = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: filteredList.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No notifications found',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedFilter == 'Unread'
                              ? 'You have caught up with all alerts!'
                              : 'There are currently no alerts matching this filter category.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                )
              : Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredList.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, idx) {
                      final notif = filteredList[idx];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: notif.isRead ? Colors.white : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: notif.isRead ? Colors.transparent : const Color(0xFFDBEAFE),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type Icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color(notif.type.bgColorValue),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                notif.type.icon,
                                size: 20,
                                color: Color(notif.type.colorValue),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Body
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      // Category pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Color(notif.type.bgColorValue),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          notif.type.label,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(notif.type.colorValue),
                                          ),
                                        ),
                                      ),

                                      // Severity pill if critical or warning
                                      if (notif.severity == NotificationSeverity.critical ||
                                          notif.severity == NotificationSeverity.warning) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Color(notif.severity.colorValue).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            notif.severity.label.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(notif.severity.colorValue),
                                            ),
                                          ),
                                        ),
                                      ],

                                      // Relative Timestamp
                                      Text(
                                        _formatRelativeTime(notif.timestamp),
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),

                                      // Unread indicator dot
                                      if (!notif.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF1C7BFF),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Title
                                  Text(
                                    notif.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),

                                  // Message
                                  Text(
                                    notif.message,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey.shade700,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Actions row
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      if (notif.actionRouteIndex != null && widget.onNavigate != null)
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            widget.repository.markNotificationAsRead(notif.id);
                                            widget.onNavigate!(notif.actionRouteIndex!);
                                          },
                                          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                          label: const Text('Open Details'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0F172A),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            elevation: 0,
                                            textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      if (!notif.isRead)
                                        OutlinedButton(
                                          onPressed: () => widget.repository.markNotificationAsRead(notif.id),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF475569),
                                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
                                          ),
                                          child: const Text('Mark Read'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isShortHeight = constraints.maxHeight < 680;

            if (isShortHeight) {
              return Scrollbar(
                controller: _outerScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _outerScrollController,
                  padding: EdgeInsets.all(isCompact ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      const SizedBox(height: 20),
                      metricCards,
                      const SizedBox(height: 20),
                      filterChips,
                      const SizedBox(height: 16),
                      SizedBox(height: 520, child: feedList),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.all(isCompact ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 20),
                  metricCards,
                  const SizedBox(height: 20),
                  filterChips,
                  const SizedBox(height: 16),
                  Expanded(child: feedList),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool hasWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasWarning ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: hasWarning ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
