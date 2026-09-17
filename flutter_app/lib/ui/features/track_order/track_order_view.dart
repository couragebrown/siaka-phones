import 'package:flutter/material.dart';
import '../../core/widgets/bottom_nav_scaffold.dart';
import '../../core/widgets/featured_phone_card.dart';
import '../../../domain/models/order.dart';
import '../../../data/repositories/order_repository.dart';

class TrackOrderView extends StatefulWidget {
  final OrderModel order;
  final OrderRepository? orderRepository;
  final ValueChanged<int> onTabSelected;

  const TrackOrderView({
    super.key,
    required this.order,
    this.orderRepository,
    required this.onTabSelected,
  });

  @override
  State<TrackOrderView> createState() => _TrackOrderViewState();
}

class _TrackOrderViewState extends State<TrackOrderView> {
  late OrderModel _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    widget.orderRepository?.addListener(_onRepoChanged);
  }

  @override
  void didUpdateWidget(TrackOrderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order != widget.order) {
      _order = widget.order;
    }
    if (oldWidget.orderRepository != widget.orderRepository) {
      oldWidget.orderRepository?.removeListener(_onRepoChanged);
      widget.orderRepository?.addListener(_onRepoChanged);
    }
  }

  @override
  void dispose() {
    widget.orderRepository?.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (widget.orderRepository != null) {
      final updated = widget.orderRepository!.getOrderById(_order.orderId);
      if (updated != null && mounted) {
        setState(() {
          _order = updated;
        });
      }
    }
  }



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

  String _formatEstimatedDelivery(DateTime dt) {
    final start = dt.add(const Duration(days: 2));
    final end = dt.add(const Duration(days: 4));
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
    return '${months[start.month - 1]} ${start.day} – ${months[end.month - 1]} ${end.day}, ${end.year}';
  }

  List<_TrackingStepData> _buildSteps() {
    final orderDateStr = _formatDate(_order.date);
    final orderTimeStr = _formatTime(_order.date);
    final estDeliveryStr = _formatEstimatedDelivery(_order.date);

    switch (_order.status) {
      case OrderStatus.placed:
        return [
          _TrackingStepData(
            title: 'Order Placed & Confirmed',
            description: '$orderDateStr • $orderTimeStr • Siaka Online Store',
            status: _StepStatus.completed,
          ),
          const _TrackingStepData(
            title: 'Processed & Packed',
            description: 'Awaiting fulfillment at Siaka Accra Hub',
            status: _StepStatus.upcoming,
          ),
          _TrackingStepData(
            title: 'Dispatched with Courier',
            description:
                'Assigned upon packaging (Tracking #${_order.trackingNumber})',
            status: _StepStatus.upcoming,
          ),
          const _TrackingStepData(
            title: 'Out for Delivery',
            description: 'Courier assigned on scheduled delivery day',
            status: _StepStatus.upcoming,
          ),
          _TrackingStepData(
            title: 'Delivered to Destination',
            description: 'Expected $estDeliveryStr',
            status: _StepStatus.upcoming,
          ),
        ];

      case OrderStatus.processing:
        return [
          _TrackingStepData(
            title: 'Order Placed & Confirmed',
            description: '$orderDateStr • $orderTimeStr • Siaka Online Store',
            status: _StepStatus.completed,
          ),
          _TrackingStepData(
            title: 'Processed & Packed',
            description:
                '$orderDateStr • Quality inspection & packaging in progress',
            status: _StepStatus.active,
          ),
          _TrackingStepData(
            title: 'Dispatched with Courier',
            description:
                'Carrier assigned on dispatch (Tracking #${_order.trackingNumber})',
            status: _StepStatus.upcoming,
          ),
          const _TrackingStepData(
            title: 'Out for Delivery',
            description: 'Courier assigned on scheduled delivery day',
            status: _StepStatus.upcoming,
          ),
          _TrackingStepData(
            title: 'Delivered to Destination',
            description: 'Expected $estDeliveryStr',
            status: _StepStatus.upcoming,
          ),
        ];

      case OrderStatus.shipped:
        return [
          _TrackingStepData(
            title: 'Order Placed & Confirmed',
            description: '$orderDateStr • $orderTimeStr • Siaka Online Store',
            status: _StepStatus.completed,
          ),
          _TrackingStepData(
            title: 'Processed & Packed',
            description: '$orderDateStr • Siaka Accra Hub',
            status: _StepStatus.completed,
          ),
          _TrackingStepData(
            title: 'Dispatched with Carrier',
            description:
                'Carrier: FedEx Express (Tracking #${_order.trackingNumber})',
            status: _StepStatus.active,
          ),
          const _TrackingStepData(
            title: 'Out for Delivery',
            description: 'Courier assigned on scheduled delivery day',
            status: _StepStatus.upcoming,
          ),
          _TrackingStepData(
            title: 'Delivered to Destination',
            description: 'Expected $estDeliveryStr',
            status: _StepStatus.upcoming,
          ),
        ];

      case OrderStatus.outForDelivery:
        return [
          _TrackingStepData(
            title: 'Order Placed & Confirmed',
            description: '$orderDateStr • $orderTimeStr • Siaka Online Store',
            status: _StepStatus.completed,
          ),
          _TrackingStepData(
            title: 'Processed & Packed',
            description: '$orderDateStr • Siaka Accra Hub',
            status: _StepStatus.completed,
          ),
          _TrackingStepData(
            title: 'Dispatched with Courier',
            description:
                'Dispatched from Siaka Hub (Tracking #${_order.trackingNumber})',
            status: _StepStatus.completed,
          ),
          const _TrackingStepData(
            title: 'Out for Delivery',
            description:
                'Courier Michael R. is on the way to your delivery address',
            status: _StepStatus.active,
          ),
          _TrackingStepData(
            title: 'Delivered to Destination',
            description: 'Expected $estDeliveryStr',
            status: _StepStatus.upcoming,
          ),
        ];

      case OrderStatus.delivered:
        return [
          _TrackingStepData(
            title: 'Order Placed & Confirmed',
            description: '$orderDateStr • $orderTimeStr • Siaka Online Store',
            status: _StepStatus.completed,
          ),
          _TrackingStepData(
            title: 'Processed & Packed',
            description: '$orderDateStr • Siaka Accra Hub',
            status: _StepStatus.completed,
          ),
          _TrackingStepData(
            title: 'Dispatched with Courier',
            description:
                'Dispatched from Siaka Hub (Tracking #${_order.trackingNumber})',
            status: _StepStatus.completed,
          ),
          const _TrackingStepData(
            title: 'Out for Delivery',
            description: 'Courier Michael R. arrived at delivery area',
            status: _StepStatus.completed,
          ),
          _TrackingStepData(
            title: 'Delivered to Destination',
            description: 'Delivered and verified at ${_order.shippingAddress}',
            status: _StepStatus.completed,
          ),
        ];

      case OrderStatus.cancelled:
        return [
          _TrackingStepData(
            title: 'Order Placed',
            description: '$orderDateStr • $orderTimeStr',
            status: _StepStatus.completed,
          ),
          const _TrackingStepData(
            title: 'Order Cancelled',
            description: 'Order was cancelled per customer or manager request',
            status: _StepStatus.active,
          ),
          const _TrackingStepData(
            title: 'Fulfillment Stopped',
            description: 'No further delivery actions scheduled',
            status: _StepStatus.upcoming,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    void handleBack() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }

    final hasItems = _order.items.isNotEmpty;
    final steps = _buildSteps();

    // Summary badge and headline logic
    final String badgeText;
    final IconData badgeIcon;
    final Color badgeColor;
    final Color badgeBg;
    final Color badgeBorder;
    final String headlineText;
    final String carrierText;

    switch (_order.status) {
      case OrderStatus.placed:
        badgeText = 'ORDER PLACED & CONFIRMED';
        badgeIcon = Icons.check_circle_outline_rounded;
        badgeColor = const Color(0xFF059669);
        badgeBg = const Color(0xFFECFDF5);
        badgeBorder = const Color(0xFFA7F3D0);
        headlineText = 'Order Placed & Confirmed';
        carrierText = 'Siaka Express Delivery';
        break;

      case OrderStatus.processing:
        badgeText = 'PROCESSING & PACKING';
        badgeIcon = Icons.inventory_2_outlined;
        badgeColor = const Color(0xFFD97706);
        badgeBg = const Color(0xFFFEF3C7);
        badgeBorder = const Color(0xFFFDE68A);
        headlineText = 'Order is Being Packed';
        carrierText = 'Siaka Fulfillment Hub';
        break;

      case OrderStatus.shipped:
        badgeText = 'IN TRANSIT';
        badgeIcon = Icons.local_shipping_rounded;
        badgeColor = const Color(0xFF1D4ED8);
        badgeBg = const Color(0xFFEFF6FF);
        badgeBorder = const Color(0xFFBFDBFE);
        headlineText = 'Package is on the way';
        carrierText = 'FedEx Express';
        break;

      case OrderStatus.outForDelivery:
        badgeText = 'OUT FOR DELIVERY';
        badgeIcon = Icons.delivery_dining_rounded;
        badgeColor = const Color(0xFF7C3AED);
        badgeBg = const Color(0xFFF5F3FF);
        badgeBorder = const Color(0xFFDDD6FE);
        headlineText = 'Package Out for Delivery';
        carrierText = 'Michael R. (Courier)';
        break;

      case OrderStatus.delivered:
        badgeText = 'DELIVERED';
        badgeIcon = Icons.task_alt_rounded;
        badgeColor = const Color(0xFF059669);
        badgeBg = const Color(0xFFECFDF5);
        badgeBorder = const Color(0xFFA7F3D0);
        headlineText = 'Package Delivered';
        carrierText = 'Delivered by Michael R.';
        break;

      case OrderStatus.cancelled:
        badgeText = 'ORDER CANCELLED';
        badgeIcon = Icons.cancel_outlined;
        badgeColor = const Color(0xFFDC2626);
        badgeBg = const Color(0xFFFEF2F2);
        badgeBorder = const Color(0xFFFECACA);
        headlineText = 'Order Cancelled';
        carrierText = 'Order Closed';
        break;
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
          onPressed: handleBack,
        ),
        title: const Text(
          'Track Order',
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  '#${_order.orderId}',
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
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 1. Order Status Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: badgeBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(badgeIcon,
                                          size: 13, color: badgeColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        badgeText,
                                        style: TextStyle(
                                          color: badgeColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    carrierText,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              headlineText,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _order.status == OrderStatus.delivered
                                  ? 'Delivered on ${_formatDate(_order.date)}'
                                  : 'Estimated Delivery: ${_formatEstimatedDelivery(_order.date)}',
                              style: TextStyle(
                                color: _order.status == OrderStatus.delivered
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF1D4ED8),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Divider(height: 20, color: Color(0xFFF1F5F9)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Row(
                                    children: [
                                      Icon(Icons.qr_code_rounded,
                                          size: 15, color: Color(0xFF64748B)),
                                      SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          'Tracking Number:',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _order.trackingNumber,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF1C7BFF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 2. Timeline Progress Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Shipment Progress',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...List.generate(steps.length, (index) {
                              final step = steps[index];
                              final isLast = index == steps.length - 1;
                              final nextStep =
                                  !isLast ? steps[index + 1] : null;
                              final isConnectorGreen = step.status ==
                                      _StepStatus.completed &&
                                  (nextStep?.status == _StepStatus.completed ||
                                      nextStep?.status == _StepStatus.active);

                              return _buildTimelineItem(
                                step: step,
                                isLast: isLast,
                                isConnectorGreen: isConnectorGreen,
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 3. Delivery Address & Recipient Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFF1C7BFF),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Delivery Address',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _order.shippingAddress,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 4. Purchased Item Preview (if present)
                      if (hasItems) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Items in Package',
                                      style: TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_order.items.length} ${_order.items.length == 1 ? 'item' : 'items'}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                  height: 16, color: Color(0xFFF1F5F9)),
                              ...List.generate(_order.items.length, (index) {
                                final item = _order.items[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                      bottom: index == _order.items.length - 1
                                          ? 0
                                          : 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Center(
                                          child: ProductPhoneGraphic(
                                              product: item.product),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.product.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF1E293B),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              '${item.selectedStorage} • ${item.selectedColor} • Qty: ${item.quantity}',
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₵${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // 5. Courier Assistance Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'MR',
                                  style: TextStyle(
                                    color: Color(0xFF1C7BFF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Michael R.',
                                    style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Siaka Verified Courier',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Calling courier Michael R...'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.phone_outlined,
                                  size: 16,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Opening chat with courier...'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 16,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 6. Action Button: Back to Home (48dp height, standard)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                            widget.onTabSelected(0);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C7BFF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.home_outlined, size: 18),
                          label: const Text(
                            'Back to Home',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AppBottomNavBar(
            currentIndex: 0,
            onTabSelected: widget.onTabSelected,
          ),
        ],
      ),
    );
  }



  Widget _buildTimelineItem({
    required _TrackingStepData step,
    required bool isLast,
    required bool isConnectorGreen,
  }) {
    final isDone = step.status == _StepStatus.completed;
    final isActive = step.status == _StepStatus.active;

    final Color circleColor;
    final Color borderColor;
    final Widget iconWidget;

    if (isDone) {
      circleColor = const Color(0xFF059669);
      borderColor = const Color(0xFF059669);
      iconWidget =
          const Icon(Icons.check_rounded, size: 13, color: Colors.white);
    } else if (isActive) {
      circleColor = const Color(0xFF1C7BFF);
      borderColor = const Color(0xFF1C7BFF);
      iconWidget = const Icon(Icons.local_shipping_rounded,
          size: 12, color: Colors.white);
    } else {
      circleColor = Colors.white;
      borderColor = const Color(0xFFCBD5E1);
      iconWidget = Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF94A3B8),
          shape: BoxShape.circle,
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator column with node and connecting line
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1C7BFF)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(child: iconWidget),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: isConnectorGreen
                          ? const Color(0xFF059669)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content column
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: TextStyle(
                            color: isDone
                                ? const Color(0xFF059669)
                                : (isActive
                                    ? const Color(0xFF1C7BFF)
                                    : const Color(0xFF0F172A)),
                            fontSize: 13,
                            fontWeight: (isActive || isDone)
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isDone)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Text(
                            'CONFIRMED',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      else if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CURRENT',
                            style: TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.description,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF334155)
                          : const Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight:
                          isActive ? FontWeight.w500 : FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _StepStatus { completed, active, upcoming }

class _TrackingStepData {
  final String title;
  final String description;
  final _StepStatus status;

  const _TrackingStepData({
    required this.title,
    required this.description,
    required this.status,
  });
}
