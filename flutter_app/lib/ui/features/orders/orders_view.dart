import 'package:flutter/material.dart';
import '../../core/widgets/featured_phone_card.dart';
import '../../../domain/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../track_order/track_order_view.dart';
import 'orders_view_model.dart';

class OrdersView extends StatefulWidget {
  final OrdersViewModel viewModel;
  final OrderRepository? orderRepo;
  final Function(OrderModel)? onTrackOrder;
  final VoidCallback? onBrowseCatalog;

  const OrdersView({
    super.key,
    required this.viewModel,
    this.orderRepo,
    this.onTrackOrder,
    this.onBrowseCatalog,
  });

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  String _selectedFilter = 'All';

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '₵$formatted';
  }

  void _handleTrackOrder(OrderModel order) {
    if (widget.onTrackOrder != null) {
      widget.onTrackOrder!(order);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrackOrderView(
            order: order,
            orderRepository: widget.orderRepo,
            onTabSelected: (_) {},
          ),
        ),
      );
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.delivered:
        return const Color(0xFF059669);
      case OrderStatus.processing:
        return const Color(0xFFD97706);
      case OrderStatus.shipped:
        return const Color(0xFF1D4ED8);
      case OrderStatus.outForDelivery:
        return const Color(0xFF7C3AED);
      case OrderStatus.cancelled:
        return const Color(0xFFDC2626);
    }
  }

  Color _getStatusBg(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.delivered:
        return const Color(0xFFECFDF5);
      case OrderStatus.processing:
        return const Color(0xFFFEF3C7);
      case OrderStatus.shipped:
        return const Color(0xFFEFF6FF);
      case OrderStatus.outForDelivery:
        return const Color(0xFFF5F3FF);
      case OrderStatus.cancelled:
        return const Color(0xFFFEF2F2);
    }
  }

  Color _getStatusBorder(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.delivered:
        return const Color(0xFFA7F3D0);
      case OrderStatus.processing:
        return const Color(0xFFFDE68A);
      case OrderStatus.shipped:
        return const Color(0xFFBFDBFE);
      case OrderStatus.outForDelivery:
        return const Color(0xFFDDD6FE);
      case OrderStatus.cancelled:
        return const Color(0xFFFECACA);
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.processing:
        return Icons.inventory_2_outlined;
      case OrderStatus.shipped:
        return Icons.local_shipping_outlined;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining_rounded;
      case OrderStatus.delivered:
        return Icons.task_alt_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final orders = widget.viewModel.orders;

        final activeOrders = orders
            .where((o) =>
                o.status != OrderStatus.delivered &&
                o.status != OrderStatus.cancelled)
            .toList();

        final deliveredOrders =
            orders.where((o) => o.status == OrderStatus.delivered).toList();

        List<OrderModel> displayedOrders;
        if (_selectedFilter == 'Active') {
          displayedOrders = activeOrders;
        } else if (_selectedFilter == 'Delivered') {
          displayedOrders = deliveredOrders;
        } else {
          displayedOrders = orders;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF1E293B),
                size: 18,
              ),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
            ),
            title: const Text(
              'My Orders & Tracking',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      '${orders.length} ${orders.length == 1 ? 'Order' : 'Orders'}',
                      style: const TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            ),
          ),
          body: Column(
            children: [
              // Filter Chips Row
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    _filterChip('All', 'All (${orders.length})'),
                    const SizedBox(width: 8),
                    _filterChip('Active', 'In Progress (${activeOrders.length})'),
                    const SizedBox(width: 8),
                    _filterChip(
                        'Delivered', 'Delivered (${deliveredOrders.length})'),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Orders List
              Expanded(
                child: displayedOrders.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: displayedOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final order = displayedOrders[index];
                          return _buildOrderCard(order);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = filterKey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1C7BFF)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF475569),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    final statusBg = _getStatusBg(order.status);
    final statusBorder = _getStatusBorder(order.status);
    final statusIcon = _getStatusIcon(order.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _handleTrackOrder(order),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Order ID, Date & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '#${order.orderId}',
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  order.paymentMethod.split('(').first.trim(),
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Placed on ${_formatDate(order.date)} at ${_formatTime(order.date)}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            order.statusDisplay.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Order Items
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Center(
                            child: ProductPhoneGraphic(
                              product: item.product,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.selectedColor} • ${item.selectedStorage} • Qty: ${item.quantity}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatCurrency(item.totalPrice),
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 6),
                // Tracking & Shipping details preview
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        size: 15,
                        color: Color(0xFF1C7BFF),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tracking: ${order.trackingNumber}',
                          style: const TextStyle(
                            color: Color(0xFF1C7BFF),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Bottom: Total & Track Order Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Total',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatCurrency(order.totalAmount),
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Quick Manager Status Advance (for interactive testing & live move)
                        PopupMenuButton<OrderStatus>(
                          tooltip: 'Manager Status Update',
                          icon: const Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          onSelected: (newStatus) {
                            widget.viewModel.updateOrderStatus(
                                order.orderId, newStatus);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Order #${order.orderId} updated to ${newStatus.name.toUpperCase()}'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              enabled: false,
                              child: Text(
                                'STORE MANAGER STATUS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            const PopupMenuItem(
                              value: OrderStatus.placed,
                              child: Text('1. Order Placed & Confirmed'),
                            ),
                            const PopupMenuItem(
                              value: OrderStatus.processing,
                              child: Text('2. Processing & Packed'),
                            ),
                            const PopupMenuItem(
                              value: OrderStatus.shipped,
                              child: Text('3. Dispatched / In Transit'),
                            ),
                            const PopupMenuItem(
                              value: OrderStatus.outForDelivery,
                              child: Text('4. Out for Delivery'),
                            ),
                            const PopupMenuItem(
                              value: OrderStatus.delivered,
                              child: Text('5. Delivered'),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        // Track Order Button
                        ElevatedButton.icon(
                          onPressed: () => _handleTrackOrder(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C7BFF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.radar_rounded, size: 15),
                          label: const Text(
                            'Track Order',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 30,
                color: Color(0xFF1C7BFF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Orders Found',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You have not placed any orders under this category yet. Explore our phone store for the latest devices.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (widget.onBrowseCatalog != null)
              ElevatedButton.icon(
                onPressed: widget.onBrowseCatalog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C7BFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                label: const Text(
                  'Browse Phones & Accessories',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
