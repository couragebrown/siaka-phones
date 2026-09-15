import 'package:flutter/material.dart';
import '../../core/widgets/bottom_nav_scaffold.dart';
import '../../../domain/models/order.dart';

class TrackOrderView extends StatelessWidget {
  final OrderModel order;
  final ValueChanged<int> onTabSelected;

  const TrackOrderView({
    super.key,
    required this.order,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    void handleBack() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }

    final timeline = [
      const _TimelineStep(
        title: 'Order Placed',
        detail: 'May 24, 2025 • 10:30 AM',
        completed: true,
      ),
      const _TimelineStep(
        title: 'Order Confirmed & Payment Verified',
        detail: 'May 24, 2025 • 11:15 AM',
        completed: true,
      ),
      const _TimelineStep(
        title: 'Shipped from Warehouse',
        detail: 'May 25, 2025 • 08:45 AM • San Francisco Hub',
        completed: true,
      ),
      const _TimelineStep(
        title: 'Out for Delivery',
        detail: 'Today • 09:15 AM • Driver is 4 stops away',
        completed: true,
        current: true,
      ),
      const _TimelineStep(
        title: 'Delivered',
        detail: 'Expected Today by 04:30 PM',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1F2937), size: 28),
          onPressed: handleBack,
        ),
        title: const Text(
          'Track Order',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded,
                color: Color(0xFF1F2937), size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C7BFF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ORDER #SP-89421',
                          style: TextStyle(
                            color: Color(0xFFD8E9FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Out for Delivery',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Estimated arrival: Today by 4:30 PM',
                          style: TextStyle(
                            color: Color(0xFFEAF2FF),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Carrier: FedEx Express (Tracking #FDX-88392014)',
                          style: TextStyle(
                            color: const Color(0xFFEAF2FF).withAlpha(220),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'MR',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Michael R.',
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Siaka Verified Courier',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: const Icon(Icons.phone,
                              color: Color(0xFF1F2937), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded,
                              color: Color(0xFF1F2937), size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 17,
                          top: 10,
                          bottom: 10,
                          width: 2,
                          child: Container(color: const Color(0xFF1C7BFF)),
                        ),
                        Column(
                          children: timeline.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final isLast = index == timeline.length - 1;
                            final badgeColor = item.completed
                                ? const Color(0xFF1C7BFF)
                                : (item.current
                                    ? const Color(0xFF1C7BFF)
                                    : const Color(0xFFF3F4F6));
                            final badgeBorder = item.completed || item.current
                                ? const Color(0xFF1C7BFF)
                                : const Color(0xFFCBD5E1);
                            final badgeText = item.completed
                                ? '✓'
                                : (item.current ? '🚚' : '📦');

                            return Padding(
                              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 34,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: badgeColor,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          border: Border.all(
                                              color: badgeBorder, width: 2),
                                        ),
                                        child: Center(
                                          child: Text(
                                            badgeText,
                                            style: TextStyle(
                                              fontSize: item.current ? 12 : 18,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  item.completed || item.current
                                                      ? Colors.white
                                                      : const Color(0xFF6B7280),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            color: const Color(0xFF1F2937),
                                            fontSize: item.current ? 18 : 16,
                                            fontWeight: item.current
                                                ? FontWeight.w800
                                                : FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.detail,
                                          style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => onTabSelected(0),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1F2937),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppBottomNavBar(
            currentIndex: 0,
            onTabSelected: onTabSelected,
          ),
        ],
      ),
    );
  }
}

class _TimelineStep {
  final String title;
  final String detail;
  final bool completed;
  final bool current;

  const _TimelineStep({
    required this.title,
    required this.detail,
    this.completed = false,
    this.current = false,
  });
}
