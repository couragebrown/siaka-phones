import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/neon_button.dart';
import '../../../domain/models/order.dart';

class ConfirmationView extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTrackOrder;
  final VoidCallback onContinueShopping;

  const ConfirmationView({
    super.key,
    required this.order,
    required this.onTrackOrder,
    required this.onContinueShopping,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Success Animated Check Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonEmerald.withOpacity(0.15),
                  border: Border.all(color: AppColors.neonEmerald, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.check_rounded, color: AppColors.neonEmerald, size: 50),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Payment Confirmed!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Order ID: #${order.orderId}',
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your brand-new device is being prepped in our cleanroom and packaged for insured dispatch.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Order Summary Card
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery Info', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.cyan),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.shippingAddress,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.cyan),
                        const SizedBox(width: 8),
                        Text(
                          'Tracking: ${order.trackingNumber}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.borderLight, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Charged', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(
                          '\$${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              NeonButton(
                label: 'View in Order History',
                icon: Icons.receipt_long_rounded,
                onPressed: onTrackOrder,
              ),
              const SizedBox(height: 12),
              NeonButton(
                label: 'Back to Home Store',
                isSecondary: true,
                onPressed: onContinueShopping,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
