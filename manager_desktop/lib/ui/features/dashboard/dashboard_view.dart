import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/manager_repository.dart';
import '../../../domain/models/customer_message.dart';
import '../../../domain/models/manager_order.dart';
import '../../core/kpi_card.dart';
import '../../core/status_chip.dart';

class DashboardView extends StatefulWidget {
  final ManagerRepository repository;
  final ValueChanged<int> onNavigate;
  final void Function(
    String name,
    String? phone,
    String? email, {
    String? initialSubject,
    String? initialBody,
    MessageCategory? initialCategory,
  })? onMessageCustomer;

  const DashboardView({
    super.key,
    required this.repository,
    required this.onNavigate,
    this.onMessageCustomer,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _pageHorizontalScrollController = ScrollController();
  final ScrollController _ordersHorizontalScrollController = ScrollController();
  bool _showRevenue = false;

  @override
  void dispose() {
    _pageScrollController.dispose();
    _pageHorizontalScrollController.dispose();
    _ordersHorizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    final revenueFormatted = currencyFormat.format(widget.repository.totalRevenue);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 900;
    final cardWidth = isCompact ? ((screenWidth - 32 - 12) / 2 > 130 ? (screenWidth - 32 - 12) / 2 : screenWidth - 32) : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentMinWidth = math.max(constraints.maxWidth, 850.0);

        return Scrollbar(
          controller: _pageScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _pageScrollController,
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            child: Scrollbar(
              controller: _pageHorizontalScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _pageHorizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: contentMinWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
          // Greeting & Quick Actions
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Executive Store Overview',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time operations summary for ${widget.repository.currentBranch}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // KPI Cards
          if (isCompact)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: KpiCard(
                    title: 'TOTAL REVENUE',
                    value: _showRevenue ? revenueFormatted : 'GH₵ ••••••••',
                    subtitle: 'Active sales across all orders',
                    icon: Icons.payments_rounded,
                    iconColor: const Color(0xFF059669),
                    iconBg: const Color(0xFFD1FAE5),
                    actionWidget: Tooltip(
                      message: _showRevenue ? 'Hide Revenue Balance' : 'Show Revenue Balance',
                      child: InkWell(
                        onTap: () => setState(() => _showRevenue = !_showRevenue),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Icon(
                            _showRevenue ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 16,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: KpiCard(
                    title: "TODAY'S ORDERS",
                    value: '${widget.repository.todayOrdersCount}',
                    subtitle: 'Orders placed today',
                    icon: Icons.calendar_today_rounded,
                    iconColor: const Color(0xFF0284C7),
                    iconBg: const Color(0xFFE0F2FE),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: KpiCard(
                    title: 'PENDING ORDERS',
                    value: '${widget.repository.pendingOrdersCount}',
                    subtitle: 'Awaiting dispatch confirmation',
                    icon: Icons.local_shipping_rounded,
                    iconColor: const Color(0xFFD97706),
                    iconBg: const Color(0xFFFEF3C7),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: KpiCard(
                    title: 'BNPL APPLICATIONS',
                    value: '${widget.repository.pendingBnplCount}',
                    subtitle: 'Installment requests to review',
                    icon: Icons.credit_score_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFFDBEAFE),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: KpiCard(
                    title: 'ACTIVE REPAIRS',
                    value: '${widget.repository.activeRepairsCount}',
                    subtitle: 'Customer devices in lab',
                    icon: Icons.build_circle_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFEDE9FE),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: 'TOTAL REVENUE',
                    value: _showRevenue ? revenueFormatted : 'GH₵ ••••••••',
                    subtitle: 'Active sales across all orders',
                    icon: Icons.payments_rounded,
                    iconColor: const Color(0xFF059669),
                    iconBg: const Color(0xFFD1FAE5),
                    actionWidget: Tooltip(
                      message: _showRevenue ? 'Hide Revenue Balance' : 'Show Revenue Balance',
                      child: InkWell(
                        onTap: () => setState(() => _showRevenue = !_showRevenue),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Icon(
                            _showRevenue ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 16,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    title: "TODAY'S ORDERS",
                    value: '${widget.repository.todayOrdersCount}',
                    subtitle: 'Orders placed today',
                    icon: Icons.calendar_today_rounded,
                    iconColor: const Color(0xFF0284C7),
                    iconBg: const Color(0xFFE0F2FE),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    title: 'PENDING ORDERS',
                    value: '${widget.repository.pendingOrdersCount}',
                    subtitle: 'Awaiting dispatch confirmation',
                    icon: Icons.local_shipping_rounded,
                    iconColor: const Color(0xFFD97706),
                    iconBg: const Color(0xFFFEF3C7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    title: 'BNPL APPLICATIONS',
                    value: '${widget.repository.pendingBnplCount}',
                    subtitle: 'Installment requests to review',
                    icon: Icons.credit_score_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFFDBEAFE),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    title: 'ACTIVE REPAIRS',
                    value: '${widget.repository.activeRepairsCount}',
                    subtitle: 'Customer devices in lab',
                    icon: Icons.build_circle_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFEDE9FE),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Active Advertisements & Customer Home Ads quick strip
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompactStrip = constraints.maxWidth < 680;

              final infoColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Text(
                        'Mobile Home Video Advertisements',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '${widget.repository.activeAdvertisementsCount} LIVE CAMPAIGNS',
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Keep video links updated for promotional banners playing on the customer app home screen.',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              );

              final actionButton = ElevatedButton.icon(
                onPressed: () => widget.onNavigate(13),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Manage Ad Links'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C7BFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              );

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isCompactStrip
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
                                ),
                                child: const Icon(
                                  Icons.campaign_rounded,
                                  color: Color(0xFF38BDF8),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: infoColumn),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: actionButton,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: Color(0xFF38BDF8),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: infoColumn),
                          const SizedBox(width: 12),
                          actionButton,
                        ],
                      ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Recent Customer Orders - extended to the right across the full width
          _buildRecentOrdersCard(context),

          const SizedBox(height: 24),

          // Low Stock Alerts - brought below Recent Customer Orders
          _buildRightColumnCard(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentOrdersCard(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Customer Orders',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigate(1),
                child: const Text('View All Orders >'),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = math.max(constraints.maxWidth, 860.0);

              return Scrollbar(
                controller: _ordersHorizontalScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: _ordersHorizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(1.8),
                        2: FlexColumnWidth(2.2),
                        3: FlexColumnWidth(1.4),
                        4: FlexColumnWidth(1.5),
                        5: FlexColumnWidth(0.8),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                    // Header
                    TableRow(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      children: [
                        _buildTableHeader('ORDER ID'),
                        _buildTableHeader('CUSTOMER'),
                        _buildTableHeader('ITEMS'),
                        _buildTableHeader('TOTAL'),
                        _buildTableHeader('STATUS'),
                        _buildTableHeader('CHAT'),
                      ],
                    ),
                    // Data Rows
                    ...widget.repository.orders.take(5).map((order) {
                      return TableRow(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: InkWell(
                              onTap: () => _showOrderDetailsDialog(context, order),
                              borderRadius: BorderRadius.circular(4),
                              child: Text(
                                order.id,
                                style: const TextStyle(
                                  color: Color(0xFF1C7BFF),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  order.customerPhone,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              order.itemsSummary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              currencyFormat.format(order.totalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: InkWell(
                              onTap: () => _showOrderDetailsDialog(context, order),
                              borderRadius: BorderRadius.circular(12),
                              child: StatusChip(
                                label: order.status.label,
                                textColor: Color(order.status.textColor),
                                bgColor: Color(order.status.bgColor),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: IconButton(
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF1C7BFF)),
                              tooltip: 'Message ${order.customerName}',
                              onPressed: () {
                                final subject = 'Order #${order.id} Notice';
                                final body = 'Hello ${order.customerName}, regarding your order #${order.id} (${order.itemsSummary}) at Siaka Phones: ';
                                if (widget.onMessageCustomer != null) {
                                  widget.onMessageCustomer!(
                                    order.customerName,
                                    order.customerPhone,
                                    order.customerEmail,
                                    initialSubject: subject,
                                    initialBody: body,
                                    initialCategory: MessageCategory.orderUpdate,
                                  );
                                } else {
                                  widget.repository.selectCustomerForMessaging(
                                    customerName: order.customerName,
                                    phone: order.customerPhone,
                                    email: order.customerEmail,
                                    initialSubject: subject,
                                    initialBody: body,
                                    initialCategory: MessageCategory.orderUpdate,
                                  );
                                  widget.onNavigate(8);
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ],
  ),
);
  }

  Widget _buildRightColumnCard(BuildContext context) {
    final lowStockItems = widget.repository.products.where((p) => p.lowStock).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              const Text(
                'Low Stock Alerts',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${lowStockItems.length} items need restock',
                  style: const TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => widget.onNavigate(2),
                child: const Text('Manage Inventory >'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (lowStockItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'All inventory products are sufficiently stocked. No urgent replenishment needed.',
                    style: TextStyle(color: Color(0xFF166534), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: lowStockItems.map((prod) {
                return Container(
                  width: 380,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFEF4444), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prod.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Brand: ${prod.brand} • Cat: ${prod.category}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${prod.stock} left',
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  void _showOrderDetailsDialog(BuildContext context, ManagerOrder order) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 650,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              order.id,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1C7BFF)),
                            ),
                            const SizedBox(width: 10),
                            StatusChip(
                              label: order.status.label,
                              textColor: Color(order.status.textColor),
                              bgColor: Color(order.status.bgColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, MMMM d, y • HH:mm').format(order.date),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),

                const Divider(height: 24, color: Color(0xFFE2E8F0)),

                // Customer & Delivery Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person_outline, size: 16, color: Color(0xFF1C7BFF)),
                                SizedBox(width: 6),
                                Text('Customer Contact', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1E293B))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(order.customerPhone, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                            Text(order.customerEmail, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Delivery Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF10B981)),
                                SizedBox(width: 6),
                                Text('Delivery Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1E293B))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(order.deliveryAddress, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('${order.region} • GPS: ${order.gpsCode}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                            Text('Payment: ${order.paymentMethod}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Items Purchased
                const Text('Items in Order', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: order.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, i) {
                      final item = order.items[i];
                      return ListTile(
                        dense: true,
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('${item.brand} • ${item.specs}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        trailing: Text(
                          '${item.quantity} × ${currencyFormat.format(item.price)} = ${currencyFormat.format(item.subtotal)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0F172A)),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Total Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Total Amount: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    Text(
                      currencyFormat.format(order.totalAmount),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),

                const Divider(height: 24, color: Color(0xFFE2E8F0)),

                // Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                    Wrap(
                      spacing: 8,
                      children: OrderStatus.values.map((status) {
                        final isCurrent = order.status == status;
                        return OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isCurrent ? Color(status.bgColor) : Colors.transparent,
                            side: BorderSide(color: Color(status.textColor)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () {
                            widget.repository.updateOrderStatus(order.id, status);
                            setDialogState(() {});
                            setState(() {});
                          },
                          child: Text(
                            status.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              color: Color(status.textColor),
                            ),
                          ),
                        );
                      }).toList(),
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
}
