import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 92,
                    height: 92,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDDEEE2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFF22B573),
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Order Placed Successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 33,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      'Thank you for shopping at Siaka Phones. We\'ve sent your order confirmation receipt to john.doe@example.com.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7EAEE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        _receiptRow('Order Number:', '#SP-89421',
                            color: const Color(0xFF1C7BFF)),
                        _receiptRow('Order Date:', 'August 30, 2026'),
                        _receiptRow('Estimated Delivery:', 'May 27, 2025',
                            color: const Color(0xFF22B573)),
                        _receiptRow('Payment Method:', 'Visa (•••• 3456)'),
                        const Divider(height: 18, color: Color(0xFFCBD5E1)),
                        _receiptRow('Total Amount Paid:', '₵1,390.00',
                            color: const Color(0xFF1C7BFF), isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: ElevatedButton.icon(
                      onPressed: onTrackOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C7BFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.local_shipping_outlined, size: 26),
                      label: const Text(
                        'Track Your Order',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: ElevatedButton(
                      onPressed: onContinueShopping,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE7EAEE),
                        foregroundColor: const Color(0xFF1F2937),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Continue Shopping',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color ?? const Color(0xFF1F2937),
                fontSize: isBold ? 18 : 18,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
