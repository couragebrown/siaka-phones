import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/manager_repository.dart';
import '../../../domain/models/customer_message.dart';
import '../../../domain/models/manager_order.dart';
import '../../core/status_chip.dart';

class OrdersManagementView extends StatefulWidget {
  final ManagerRepository repository;
  final void Function(
    String name,
    String? phone,
    String? email, {
    String? initialSubject,
    String? initialBody,
    MessageCategory? initialCategory,
  })? onMessageCustomer;
  final ValueChanged<int>? onNavigate;

  const OrdersManagementView({
    super.key,
    required this.repository,
    this.onMessageCustomer,
    this.onNavigate,
  });

  @override
  State<OrdersManagementView> createState() => _OrdersManagementViewState();
}

class _OrdersManagementViewState extends State<OrdersManagementView> {
  String _searchQuery = '';
  OrderStatus? _selectedStatusFilter;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalTableScrollController = ScrollController();
  final ScrollController _outerScrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalTableScrollController.dispose();
    _outerScrollController.dispose();
    super.dispose();
  }

  List<ManagerOrder> _getFilteredOrders() {
    return widget.repository.orders.where((order) {
      if (_selectedStatusFilter != null && order.status != _selectedStatusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesId = order.id.toLowerCase().contains(query);
        final matchesName = order.customerName.toLowerCase().contains(query);
        final matchesPhone = order.customerPhone.toLowerCase().contains(query);
        final matchesGps = order.gpsCode.toLowerCase().contains(query);
        final matchesItem = order.items.any((i) => i.title.toLowerCase().contains(query));
        return matchesId || matchesName || matchesPhone || matchesGps || matchesItem;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    final filteredOrders = _getFilteredOrders();

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 900;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isShortHeight = constraints.maxHeight < 680;

        // Header Row
        final headerRow = Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Orders Management',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track, verify GhanaPostGPS delivery locations, and update fulfillment status',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 18, color: Color(0xFF1C7BFF)),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${widget.repository.orders.length} Orders',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        // Search & Filter Toolbar
        final toolbar = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search order ID, customer name, phone, GPS code...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF1C7BFF), width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Status Filter Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedStatusFilter == null,
                    onSelected: (_) => setState(() => _selectedStatusFilter = null),
                    backgroundColor: const Color(0xFFF1F5F9),
                    selectedColor: const Color(0xFF1C7BFF).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _selectedStatusFilter == null ? FontWeight.w700 : FontWeight.w500,
                      color: _selectedStatusFilter == null ? const Color(0xFF1C7BFF) : const Color(0xFF475569),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    side: BorderSide(
                      color: _selectedStatusFilter == null ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  ...OrderStatus.values.map((status) {
                    final isSelected = _selectedStatusFilter == status;
                    return FilterChip(
                      label: Text(status.label),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedStatusFilter = isSelected ? null : status),
                      backgroundColor: const Color(0xFFF1F5F9),
                      selectedColor: Color(status.bgColor),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Color(status.textColor) : const Color(0xFF475569),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      side: BorderSide(
                        color: isSelected ? Color(status.textColor) : const Color(0xFFE2E8F0),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        );

        // Orders Data Table Card
        final tableCard = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: filteredOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, size: 54, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No orders found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try adjusting your search criteria or status filter.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, tableConstraints) {
                    final availableWidth = tableConstraints.maxWidth;
                    final tableMinWidth = math.max(1260.0, availableWidth);
                    final columnSpacing = ((tableMinWidth - 1140.0 - 48) / 7).clamp(20.0, 110.0);

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Scrollbar(
                        controller: _verticalTableScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _verticalTableScrollController,
                          child: Scrollbar(
                            controller: _horizontalScrollController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
                            child: SingleChildScrollView(
                              controller: _horizontalScrollController,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: tableMinWidth),
                              child: DataTable(
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 74,
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                horizontalMargin: 24,
                                columnSpacing: columnSpacing,
                                columns: const [
                                  DataColumn(label: Text('ORDER ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('DATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('CUSTOMER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('GHANA GPS / ADDRESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('ITEMS ORDERED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                ],
                                rows: filteredOrders.map((order) {
                                  final dateFormatted = DateFormat('MMM d, y • HH:mm').format(order.date);
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          order.id,
                                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1C7BFF), fontSize: 13),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          dateFormatted,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              order.customerName,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                                            ),
                                            Text(
                                              order.customerPhone,
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: const Color(0xFFBFDBFE)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF1C7BFF)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    order.gpsCode,
                                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              order.deliveryAddress,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              order.itemsSummary,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                                            ),
                                            Text(
                                              '${order.items.fold(0, (acc, i) => acc + i.quantity)} items',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          currencyFormat.format(order.totalAmount),
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                      DataCell(
                                        StatusChip(
                                          label: order.status.label,
                                          textColor: Color(order.status.textColor),
                                          bgColor: Color(order.status.bgColor),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF1C7BFF)),
                                              tooltip: 'Send Direct Message to ${order.customerName}',
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
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF64748B)),
                                              tooltip: 'View Order Details',
                                              onPressed: () => _showOrderDetailsDialog(context, order),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFF1C7BFF)),
                                              tooltip: 'Manage Delivery in Shipping Hub',
                                              onPressed: () {
                                                if (widget.onNavigate != null) {
                                                  widget.onNavigate!(11);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  },
                ),
        );

        if (isShortHeight) {
          return Scrollbar(
            controller: _outerScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _outerScrollController,
              padding: EdgeInsets.all(isCompact ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headerRow,
                  const SizedBox(height: 20),
                  toolbar,
                  const SizedBox(height: 16),
                  SizedBox(height: 520, child: tableCard),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(isCompact ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headerRow,
              const SizedBox(height: 20),
              toolbar,
              const SizedBox(height: 16),
              Expanded(child: tableCard),
            ],
          ),
        );
      },
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
                                Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF059669)),
                                SizedBox(width: 6),
                                Text('Ghana Delivery Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1E293B))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Text(
                                    order.gpsCode,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(order.region, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(order.deliveryAddress, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                            const SizedBox(height: 2),
                            Text('Payment: ${order.paymentMethod}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF059669))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                const Text('Order Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),

                // Items List
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
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
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                        SizedBox(width: 6),
                        Text(
                          'Delivery status can strictly only be updated in the Shipping Hub.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C7BFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.local_shipping_rounded, size: 16),
                      label: const Text('Manage in Shipping Hub'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (widget.onNavigate != null) {
                          widget.onNavigate!(11);
                        }
                      },
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
