import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../../domain/models/order.dart';
import 'orders_view_model.dart';

class OrdersView extends StatelessWidget {
  final OrdersViewModel viewModel;

  const OrdersView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final orders = viewModel.orders;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Order History'),
          ),
          body: orders.isEmpty
              ? const Center(
                  child: Text('No orders found',
                      style: TextStyle(color: AppColors.textMuted)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(context, order);
                  },
                ),
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    Color statusColor;
    switch (order.status) {
      case OrderStatus.delivered:
        statusColor = AppColors.neonEmerald;
        break;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        statusColor = AppColors.cyan;
        break;
      case OrderStatus.processing:
      case OrderStatus.placed:
        statusColor = AppColors.neonAmber;
        break;
      case OrderStatus.cancelled:
        statusColor = AppColors.neonPink;
        break;
    }

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.orderId}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  order.statusDisplay,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Placed on ${order.date.month}/${order.date.day}/${order.date.year}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const Divider(color: AppColors.borderLight, height: 20),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.product.images.first,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${item.product.name} (x${item.quantity})',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '₵${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              )),
          const Divider(color: AppColors.borderLight, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tracking: ${order.trackingNumber}',
                style: const TextStyle(color: AppColors.cyan, fontSize: 11),
              ),
              Text(
                'Total: ₵${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
