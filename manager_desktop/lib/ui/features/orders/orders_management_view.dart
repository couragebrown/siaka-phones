import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/manager_repository.dart';
import '../../../data/services/order_print_service.dart';
import '../../../domain/models/customer_message.dart';
import '../../../domain/models/manager_order.dart';
import '../../core/custom_date_range_picker.dart';
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
  String _datePreset = 'All Dates';
  DateTime? _fromDate;
  DateTime? _toDate;
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

  bool _matchesDateFilter(DateTime orderDate) {
    if (_fromDate == null && _toDate == null) return true;
    final day = DateTime(orderDate.year, orderDate.month, orderDate.day);
    if (_fromDate != null) {
      final start = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
      if (day.isBefore(start)) return false;
    }
    if (_toDate != null) {
      final end = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
      if (day.isAfter(end)) return false;
    }
    return true;
  }

  Future<void> _pickSingleOrderDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(2023, 1, 1);
    final lastDate = DateTime(now.year + 5, 12, 31);
    final initial = _fromDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(lastDate)
          ? lastDate
          : (initial.isBefore(firstDate) ? firstDate : initial),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Order Date (View Orders on That Day)',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: const Color(0xFF1C7BFF),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: const Color(0xFF0F172A),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        _toDate = picked;
        _datePreset = 'Single Day';
      });
    }
  }

  void _applyDatePreset(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _datePreset = preset;
      switch (preset) {
        case 'Today':
          _fromDate = today;
          _toDate = today;
          break;
        case 'Yesterday':
          final y = today.subtract(const Duration(days: 1));
          _fromDate = y;
          _toDate = y;
          break;
        case 'Last 7 Days':
          _fromDate = today.subtract(const Duration(days: 6));
          _toDate = today;
          break;
        case 'All Dates':
        default:
          _fromDate = null;
          _toDate = null;
          _datePreset = 'All Dates';
          break;
      }
    });
  }

  String _activeDateLabel() {
    if (_fromDate == null && _toDate == null) return '';
    final fmt = DateFormat('MMM d, y');
    if (_fromDate != null &&
        _toDate != null &&
        _fromDate!.year == _toDate!.year &&
        _fromDate!.month == _toDate!.month &&
        _fromDate!.day == _toDate!.day) {
      return fmt.format(_fromDate!);
    }
    final startStr = _fromDate != null ? fmt.format(_fromDate!) : 'Start';
    final endStr = _toDate != null ? fmt.format(_toDate!) : 'Present';
    return '$startStr – $endStr';
  }

  List<ManagerOrder> _getDateAndSearchFilteredOrders() {
    return widget.repository.orders.where((order) {
      if (!_matchesDateFilter(order.date)) {
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

  List<ManagerOrder> _getFilteredOrders() {
    return _getDateAndSearchFilteredOrders().where((order) {
      if (_selectedStatusFilter != null && order.status != _selectedStatusFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  List<OrderItem> _effectiveItemsForOrder(ManagerOrder order) {
    if (order.items.isNotEmpty) {
      return order.items;
    }
    return [
      OrderItem(
        title: 'Device / Merchandise Order',
        brand: '',
        price: 0,
        quantity: order.status == OrderStatus.cancelled ? 0 : 1,
      ),
    ];
  }

  void _triggerDirectMessage(ManagerOrder order) {
    final cleanId = order.id.startsWith('ORDER_') ? order.id.substring(6) : order.id;
    final subject = 'Order #$cleanId Notice';
    final body =
        'Hello ${order.customerName}, regarding your order #$cleanId (${order.itemsSummary}) at Siaka Phones: ';
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
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    final filteredOrders = _getFilteredOrders();
    final totalUnitsAcrossAll = widget.repository.orders.fold<int>(
      0,
      (sum, o) => sum + (o.totalQuantity > 0 ? o.totalQuantity : (o.status == OrderStatus.cancelled ? 0 : 1)),
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 900;
    final hasDateFilter = _fromDate != null || _toDate != null;
    final filteredUnits = filteredOrders.fold<int>(
      0,
      (sum, o) => sum + (o.totalQuantity > 0 ? o.totalQuantity : (o.status == OrderStatus.cancelled ? 0 : 1)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isShortHeight = constraints.maxHeight < 740;

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
                  'Track quantities, inspect order details, print amount-free item lists, and verify GhanaPostGPS delivery',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton.icon(
                  key: const ValueKey('print_orders_list_btn'),
                  icon: const Icon(Icons.print_rounded, size: 17),
                  label: const Text(
                    'Print Order Placed List',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showPrintOrdersPageSheetDialog(
                    context,
                    displayedOrders: filteredOrders,
                  ),
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
                        hasDateFilter
                            ? 'Showing: ${filteredOrders.length} Orders ($filteredUnits Qty)'
                            : 'Total: ${widget.repository.orders.length} Orders ($totalUnitsAcrossAll Qty)',
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
            ),
          ],
        );

        final filterChipsWrap = Wrap(
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
                  hintText: 'Search order ID, customer name, phone, GPS code, or ordered item...',
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

              // Date & Custom Date Range Filter Row (select a single day or multiple days)
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: ['All Dates', 'Today', 'Yesterday', 'Last 7 Days'].map((preset) {
                          final isSelected = _datePreset == preset &&
                              (preset == 'All Dates' ? !hasDateFilter : hasDateFilter);
                          return InkWell(
                            onTap: () => _applyDatePreset(preset),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF1C7BFF) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                preset,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  InkWell(
                    key: const ValueKey('orders_pick_single_day_btn'),
                    onTap: () => _pickSingleOrderDate(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _datePreset == 'Single Day' && hasDateFilter
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _datePreset == 'Single Day' && hasDateFilter
                              ? const Color(0xFF1C7BFF)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_rounded,
                            size: 16,
                            color: _datePreset == 'Single Day' && hasDateFilter
                                ? const Color(0xFF1C7BFF)
                                : const Color(0xFF0F172A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _datePreset == 'Single Day' && _fromDate != null
                                ? 'Day: ${DateFormat('dd/MM/yyyy').format(_fromDate!)}'
                                : 'Pick Single Day',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _datePreset == 'Single Day' && hasDateFilter
                                  ? const Color(0xFF1D4ED8)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: CustomDateRangePicker(
                      fromDate: _fromDate,
                      toDate: _toDate,
                      onFromDateSelected: (picked) {
                        setState(() {
                          _fromDate = picked;
                          if (picked != null && _toDate != null && picked.isAfter(_toDate!)) {
                            _toDate = picked;
                          }
                          _datePreset = 'Custom';
                        });
                      },
                      onToDateSelected: (picked) {
                        setState(() {
                          _toDate = picked;
                          if (picked != null && _fromDate != null && picked.isBefore(_fromDate!)) {
                            _fromDate = picked;
                          }
                          _datePreset = 'Custom';
                        });
                      },
                      onReset: () {
                        setState(() {
                          _fromDate = null;
                          _toDate = null;
                          _datePreset = 'All Dates';
                        });
                      },
                    ),
                  ),
                  if (hasDateFilter)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.filter_alt_rounded, size: 14, color: Color(0xFF1D4ED8)),
                          const SizedBox(width: 5),
                          Text(
                            'Date: ${_activeDateLabel()} (${filteredOrders.length})',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Status Filter Chips
              filterChipsWrap,
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
                    final tableMinWidth = math.max(1280.0, availableWidth);
                    final columnSpacing = ((tableMinWidth - 1200.0) / 8).clamp(10.0, 24.0);

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
                                  dataRowMinHeight: 62,
                                  dataRowMaxHeight: 96,
                                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                  horizontalMargin: 24,
                                  columnSpacing: columnSpacing,
                                  columns: const [
                                    DataColumn(label: Text('ORDER ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                    DataColumn(label: Text('DATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                    DataColumn(label: Text('CUSTOMER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                    DataColumn(label: Text('GHANA GPS / ADDRESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                    DataColumn(label: Text('ITEMS ORDERED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                    DataColumn(label: Text('QUANTITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                    DataColumn(label: Text('TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                    DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                    DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  ],
                                  rows: filteredOrders.map((order) {
                                    final cleanId =
                                        order.id.startsWith('ORDER_') ? order.id.substring(6) : order.id;
                                    final dateFormatted = DateFormat('MMM d, y • HH:mm').format(order.date);
                                    final qty = order.totalQuantity > 0
                                        ? order.totalQuantity
                                        : (order.status == OrderStatus.cancelled ? 0 : 1);
                                    final summaryText = order.itemsSummary.isNotEmpty
                                        ? order.itemsSummary
                                        : '1x Device / Merchandise Order';
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          InkWell(
                                            onTap: () => _showOrderDetailsDialog(context, order),
                                            borderRadius: BorderRadius.circular(4),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                              child: Text(
                                                cleanId,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1C7BFF),
                                                  fontSize: 13,
                                                  decoration: TextDecoration.underline,
                                                  decorationColor: Color(0xFFBFDBFE),
                                                ),
                                              ),
                                            ),
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
                                                order.customerName.trim().isNotEmpty
                                                    ? order.customerName
                                                    : 'Customer',
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
                                                      order.gpsCode.trim().isNotEmpty ? order.gpsCode : '—',
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 165),
                                                child: Text(
                                                  order.deliveryAddress,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 215),
                                            child: order.items.length > 1
                                                ? Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      for (var idx = 0;
                                                          idx < math.min(2, order.items.length);
                                                          idx++)
                                                        Padding(
                                                          padding: EdgeInsets.only(top: idx > 0 ? 3 : 0),
                                                          child: Text(
                                                            'Item ${idx + 1}: ${order.items[idx].title}',
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: const TextStyle(
                                                              fontSize: 11.5,
                                                              fontWeight: FontWeight.w700,
                                                              color: Color(0xFF1E293B),
                                                            ),
                                                          ),
                                                        ),
                                                      if (order.items.length > 2)
                                                        Padding(
                                                          padding: const EdgeInsets.only(top: 2),
                                                          child: Text(
                                                            '+${order.items.length - 2} more (click Details)',
                                                            style: const TextStyle(
                                                              fontSize: 10.5,
                                                              fontWeight: FontWeight.w600,
                                                              color: Color(0xFF1C7BFF),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  )
                                                : Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        order.items.isNotEmpty
                                                            ? order.items.first.title
                                                            : summaryText,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF334155),
                                                        ),
                                                      ),
                                                      Text(
                                                        order.items
                                                            .map((i) => i.specs.isNotEmpty ? i.specs : i.brand)
                                                            .where((s) => s.isNotEmpty)
                                                            .join(' • '),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                        DataCell(
                                          order.items.length > 1
                                              ? Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    for (var idx = 0;
                                                        idx < math.min(2, order.items.length);
                                                        idx++)
                                                      Padding(
                                                        padding: EdgeInsets.only(top: idx > 0 ? 3 : 0),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFEFF6FF),
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: Border.all(color: const Color(0xFFBFDBFE)),
                                                          ),
                                                          child: Text(
                                                            'Item ${idx + 1} → Qty: ${order.items[idx].quantity}',
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.w800,
                                                              fontSize: 10.5,
                                                              color: Color(0xFF1E40AF),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 3, left: 2),
                                                      child: Text(
                                                        'Total: $qty Items',
                                                        style: const TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.w700,
                                                          color: Color(0xFF475569),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEFF6FF),
                                                    borderRadius: BorderRadius.circular(999),
                                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.inventory_2_outlined, size: 13, color: Color(0xFF1D4ED8)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Qty: $qty',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w800,
                                                          fontSize: 11.5,
                                                          color: Color(0xFF1E40AF),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
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
                                              ElevatedButton.icon(
                                                icon: const Icon(Icons.info_outline_rounded, size: 14),
                                                label: const Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF1C7BFF),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  visualDensity: VisualDensity.compact,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                ),
                                                onPressed: () => _showOrderDetailsDialog(context, order),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                visualDensity: VisualDensity.compact,
                                                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                                padding: const EdgeInsets.all(6),
                                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF1C7BFF)),
                                                tooltip: 'Send Direct Message to ${order.customerName}',
                                                onPressed: () => _triggerDirectMessage(order),
                                              ),
                                              const SizedBox(width: 4),
                                              ElevatedButton.icon(
                                                key: ValueKey('order_receipt_btn_$cleanId'),
                                                icon: const Icon(Icons.receipt_long_rounded, size: 14),
                                                label: const Text('Receipt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF0F172A),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  visualDensity: VisualDensity.compact,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                ),
                                                onPressed: () => _showOrderReceiptDialog(context, order),
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

  /// Repair-Desk-style Order Details dialog showing customer info,
  /// GhanaPost GPS logistics, and itemized quantities.
  void _showOrderDetailsDialog(BuildContext context, ManagerOrder order) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    final cleanId = order.id.startsWith('ORDER_') ? order.id.substring(6) : order.id;
    final totalQty = order.totalQuantity > 0
        ? order.totalQuantity
        : (order.status == OrderStatus.cancelled ? 0 : 1);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 700,
          constraints: const BoxConstraints(maxHeight: 780),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (matching Repairs Desk Details dialog)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_rounded,
                            color: Color(0xFF1C7BFF),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Order #$cleanId',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  StatusChip(
                                    label: order.status.label,
                                    textColor: Color(order.status.textColor),
                                    bgColor: Color(order.status.bgColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Placed on ${DateFormat('EEEE, MMMM d, y • HH:mm').format(order.date)}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close Order Details Dialog',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),

              // Scrollable Details Body
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer & Order Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CUSTOMER INFORMATION',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF64748B),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_rounded, size: 16, color: Color(0xFF334155)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              order.customerName.trim().isNotEmpty
                                                  ? order.customerName
                                                  : 'Customer',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone_rounded, size: 15, color: Color(0xFF64748B)),
                                          const SizedBox(width: 6),
                                          Text(
                                            order.customerPhone,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (order.customerEmail.trim().isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            const Icon(Icons.email_outlined, size: 14, color: Color(0xFF64748B)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                order.customerEmail,
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF1C7BFF)),
                                  label: const Text(
                                    'Message Customer',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1C7BFF)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _triggerDirectMessage(order);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'TOTAL QUANTITY ORDERED',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF64748B),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.inventory_2_rounded, size: 16, color: Color(0xFF1C7BFF)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '$totalQty ${totalQty == 1 ? 'Unit' : 'Units'} (${order.items.isNotEmpty ? order.items.length : 1} ${order.items.length == 1 ? 'Product' : 'Products'})',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PAYMENT METHOD',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF64748B),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.account_balance_wallet_rounded, size: 15, color: Color(0xFF059669)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              order.paymentMethod,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Delivery & GhanaPost GPS Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GHANA DELIVERY & LOCATION DETAILS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('GhanaPost GPS', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                            Text(
                                              order.gpsCode.trim().isNotEmpty ? order.gpsCode : '—',
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1E40AF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.map_rounded, size: 16, color: Color(0xFF059669)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Region', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                            Text(
                                              order.region,
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF7C3AED)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Delivery Street Address', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                            Text(
                                              order.deliveryAddress,
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Order Placed Items & Quantities Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Order Placed — List of Items & Quantities',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text(
                              'Total Qty: $totalQty',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text('ITEM / DEVICE MODEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                                  ),
                                  SizedBox(
                                    width: 90,
                                    child: Center(
                                      child: Text('QUANTITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text('AMOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            if (order.items.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 28,
                                      child: Text('1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                                    ),
                                    const Expanded(
                                      flex: 4,
                                      child: Text(
                                        'Device / Merchandise Order',
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 90,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(999),
                                            border: Border.all(color: const Color(0xFFBFDBFE)),
                                          ),
                                          child: Text(
                                            'Qty: $totalQty',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF1E40AF),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          currencyFormat.format(order.totalAmount),
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              for (var i = 0; i < order.items.length; i++) ...[
                                if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          '${i + 1}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              order.items[i].title,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              [
                                                if (order.items[i].brand.trim().isNotEmpty) order.items[i].brand.trim(),
                                                if (order.items[i].specs.trim().isNotEmpty) order.items[i].specs.trim(),
                                              ].join(' • '),
                                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 90,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(999),
                                              border: Border.all(color: const Color(0xFFBFDBFE)),
                                            ),
                                            child: Text(
                                              'Qty: ${order.items[i].quantity}',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1E40AF),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              currencyFormat.format(order.items[i].subtotal),
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A)),
                                            ),
                                            Text(
                                              '${order.items[i].quantity} × ${currencyFormat.format(order.items[i].price)}',
                                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Total Amount: ',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                          Text(
                            currencyFormat.format(order.totalAmount),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Delivery & courier progression can strictly only be updated in the Shipping Hub.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // Footer Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C7BFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.local_shipping_rounded, size: 16),
                    label: const Text(
                      'Manage in Shipping Hub',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
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
    );
  }

  /// Displays ALL items on the Orders page in the Print Order Placed — List of Items
  /// popup (strictly without any prices, subtotals, totals, or GH₵ amounts).
  void _showPrintOrdersPageSheetDialog(
    BuildContext context, {
    required List<ManagerOrder> displayedOrders,
  }) {
    final placedOnlyOrders = _getDateAndSearchFilteredOrders()
        .where((o) => o.status == OrderStatus.placed)
        .toList();
    bool filterPlacedOnly = false;
    final dateSuffix = _activeDateLabel();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final ordersToPrint = filterPlacedOnly ? placedOnlyOrders : displayedOrders;
          final baseScope = filterPlacedOnly
              ? 'Order Placed Only'
              : (_selectedStatusFilter?.label ?? 'All Displayed Orders');
          final scopeTitle = dateSuffix.isNotEmpty ? '$baseScope • $dateSuffix' : baseScope;
          final totalUnits = ordersToPrint.fold<int>(
            0,
            (sum, o) => sum + _effectiveItemsForOrder(o).fold<int>(0, (s, it) => s + it.quantity),
          );
          final branch = widget.repository.currentBranch;

          return Dialog(
            key: const ValueKey('orders_list_print_preview_dialog'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Container(
              width: 760,
              constraints: const BoxConstraints(maxHeight: 780),
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.print_rounded, color: Color(0xFF0F172A), size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Print Order Placed — List of Items',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Scope Selector + Amount-Free Notice (exact design from screenshot)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ChoiceChip(
                        label: Text('Order Placed Only (${placedOnlyOrders.length})'),
                        selected: filterPlacedOnly,
                        onSelected: (_) => setDialogState(() => filterPlacedOnly = true),
                      ),
                      ChoiceChip(
                        label: Text('All Displayed Orders (${displayedOrders.length})'),
                        selected: !filterPlacedOnly,
                        onSelected: (_) => setDialogState(() => filterPlacedOnly = false),
                      ),
                      const SizedBox(width: 6),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 15, color: Color(0xFF059669)),
                          SizedBox(width: 5),
                          Text(
                            'Amounts & prices hidden on printout',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Flexible(
                    child: ordersToPrint.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'No orders match the selected print scope.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'SIAKA PHONES',
                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                            ),
                                            Text(
                                              'Order Placed — List of Items ($scopeTitle)',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                                            ),
                                            Text(
                                              'Branch: $branch',
                                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Orders: ${ordersToPrint.length}',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                          ),
                                          Text(
                                            'Total Quantity: $totalUnits',
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 22, thickness: 1.4, color: Color(0xFF0F172A)),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          color: const Color(0xFFF1F5F9),
                                          child: const Row(
                                            children: [
                                              SizedBox(
                                                width: 96,
                                                child: Text('ORDER ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                              ),
                                              Expanded(
                                                flex: 3,
                                                child: Text('CUSTOMER & GPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                              ),
                                              Expanded(
                                                flex: 5,
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text('ITEM ORDERED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                                    ),
                                                    SizedBox(
                                                      width: 82,
                                                      child: Center(
                                                        child: Text('QTY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        for (final order in ordersToPrint) ...[
                                          const Divider(height: 1, thickness: 1.2, color: Color(0xFF94A3B8)),
                                          Builder(
                                            builder: (_) {
                                              final cleanId = order.id.startsWith('ORDER_')
                                                  ? order.id.substring(6)
                                                  : order.id;
                                              final custName = order.customerName.trim().isNotEmpty
                                                  ? order.customerName.trim()
                                                  : 'Customer';
                                              final custPhone = order.customerPhone.trim();
                                              final gpsCode = order.gpsCode.trim().isNotEmpty
                                                  ? order.gpsCode.trim()
                                                  : '—';
                                              final effectiveItems = _effectiveItemsForOrder(order);
                                              final isMultiItem = effectiveItems.length > 1;
                                              final orderQty = effectiveItems.fold<int>(
                                                0,
                                                (s, it) => s + it.quantity,
                                              );

                                              return Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      width: 96,
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            cleanId,
                                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                                          ),
                                                          if (isMultiItem)
                                                            Container(
                                                              margin: const EdgeInsets.only(top: 4, right: 6),
                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFFEFF6FF),
                                                                borderRadius: BorderRadius.circular(4),
                                                                border: Border.all(color: const Color(0xFFBFDBFE)),
                                                              ),
                                                              child: Text(
                                                                '${effectiveItems.length} Items • Qty: $orderQty',
                                                                style: const TextStyle(
                                                                  fontSize: 9.5,
                                                                  fontWeight: FontWeight.w800,
                                                                  color: Color(0xFF1E40AF),
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 3,
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(right: 8),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              custName,
                                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                                            ),
                                                            Text(
                                                              [
                                                                if (gpsCode.isNotEmpty) gpsCode,
                                                                if (custPhone.isNotEmpty) custPhone,
                                                              ].join(' • '),
                                                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 5,
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          for (var idx = 0; idx < effectiveItems.length; idx++) ...[
                                                            if (idx > 0)
                                                              const Padding(
                                                                padding: EdgeInsets.symmetric(vertical: 6),
                                                                child: Divider(height: 1, color: Color(0xFFCBD5E1)),
                                                              ),
                                                            Row(
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: [
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      if (isMultiItem)
                                                                        Container(
                                                                          margin: const EdgeInsets.only(bottom: 3),
                                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                                          decoration: BoxDecoration(
                                                                            color: const Color(0xFFE2E8F0),
                                                                            borderRadius: BorderRadius.circular(4),
                                                                          ),
                                                                          child: Text(
                                                                            'Item ${idx + 1} of ${effectiveItems.length}',
                                                                            style: const TextStyle(
                                                                              fontSize: 9.5,
                                                                              fontWeight: FontWeight.w800,
                                                                              color: Color(0xFF0F172A),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      Text(
                                                                        effectiveItems[idx].title,
                                                                        style: const TextStyle(
                                                                          fontSize: 12,
                                                                          fontWeight: FontWeight.w700,
                                                                        ),
                                                                      ),
                                                                      if (effectiveItems[idx].brand.trim().isNotEmpty ||
                                                                          effectiveItems[idx].specs.trim().isNotEmpty)
                                                                        Text(
                                                                          [
                                                                            if (effectiveItems[idx].brand.trim().isNotEmpty)
                                                                              effectiveItems[idx].brand.trim(),
                                                                            if (effectiveItems[idx].specs.trim().isNotEmpty)
                                                                              effectiveItems[idx].specs.trim(),
                                                                          ].join(' • '),
                                                                          style: const TextStyle(
                                                                            fontSize: 10.5,
                                                                            color: Color(0xFF475569),
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: 82,
                                                                  child: Column(
                                                                    children: [
                                                                      Container(
                                                                        padding: const EdgeInsets.symmetric(
                                                                          horizontal: 8,
                                                                          vertical: 3,
                                                                        ),
                                                                        decoration: BoxDecoration(
                                                                          color: const Color(0xFFF1F5F9),
                                                                          borderRadius: BorderRadius.circular(5),
                                                                          border: Border.all(
                                                                            color: const Color(0xFF0F172A),
                                                                            width: 1.1,
                                                                          ),
                                                                        ),
                                                                        child: Text(
                                                                          'Qty: ${effectiveItems[idx].quantity}',
                                                                          style: const TextStyle(
                                                                            fontSize: 11.5,
                                                                            fontWeight: FontWeight.w900,
                                                                            color: Color(0xFF0F172A),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      if (isMultiItem)
                                                                        Padding(
                                                                          padding: const EdgeInsets.only(top: 2),
                                                                          child: Text(
                                                                            'Item ${idx + 1}',
                                                                            style: const TextStyle(
                                                                              fontSize: 9.5,
                                                                              fontWeight: FontWeight.w700,
                                                                              color: Color(0xFF475569),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                        const Divider(height: 1, thickness: 1.2, color: Color(0xFF94A3B8)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                          color: const Color(0xFFF8FAFC),
                                          child: Row(
                                            children: [
                                              const Expanded(
                                                child: Text(
                                                  'TOTAL QUANTITY ORDERED',
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              SizedBox(
                                                width: 82,
                                                child: Center(
                                                  child: Text(
                                                    'Qty: $totalUnits',
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                                                  ),
                                                ),
                                              ),
                                            ],
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

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        key: const ValueKey('confirm_print_orders_list_btn'),
                        icon: const Icon(Icons.print_rounded, size: 17),
                        label: const Text(
                          'Print Now',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C7BFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: ordersToPrint.isEmpty
                            ? null
                            : () async {
                                final ok = await OrderPrintService.printOrdersPlacedItemsList(
                                  ordersToPrint,
                                  branchName: branch,
                                  scopeTitle: scopeTitle,
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? 'Opened print dialog for ${ordersToPrint.length} order(s) items list (without amounts).'
                                            : 'Could not launch system print dialog.',
                                      ),
                                      backgroundColor: ok ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                    ),
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Displays a compact thermal/POS receipt preview (`80mm` standard or `58mm`
  /// mini roll) for an individual [order] so the manager can print a customer
  /// receipt for proof of purchase or return/exchange verification.
  void _showOrderReceiptDialog(BuildContext context, ManagerOrder order) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    final cleanId = order.id.startsWith('ORDER_') ? order.id.substring(6) : order.id;
    final seqDigits = cleanId.replaceAll(RegExp(r'[^0-9]'), '');
    final receiptNo = seqDigits.isNotEmpty ? 'RCP-$seqDigits' : 'RCP-$cleanId';
    final effectiveItems = order.items.isNotEmpty
        ? order.items
        : [
            OrderItem(
              title: 'Device / Merchandise Order',
              brand: '',
              price: order.totalAmount,
              quantity: order.status == OrderStatus.cancelled ? 0 : 1,
            ),
          ];
    final totalQty = effectiveItems.fold<int>(0, (s, it) => s + it.quantity);
    final computedSubtotal = effectiveItems.fold<double>(
      0.0,
      (sum, it) {
        final unit = it.price > 0
            ? it.price
            : (effectiveItems.length == 1 && it.quantity > 0
                ? order.totalAmount / it.quantity
                : 0.0);
        return sum + (unit * it.quantity);
      },
    );
    final displayTotal = order.totalAmount > 0 ? order.totalAmount : computedSubtotal;
    final branch = widget.repository.currentBranch;
    final custName =
        order.customerName.trim().isNotEmpty ? order.customerName.trim() : 'Walk-in / App Customer';
    int paperWidthMm = 80;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final slipPreviewWidth = paperWidthMm == 58 ? 270.0 : 324.0;

          return Dialog(
            key: const ValueKey('order_receipt_preview_dialog'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Container(
              width: 480,
              constraints: const BoxConstraints(maxHeight: 760),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Color(0xFF0F172A),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order Receipt — #$cleanId',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Text(
                                    'Compact POS slip for customer & return verification',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close Receipt Preview',
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Receipt Paper Size Selector (80mm Standard Thermal vs 58mm Mini Roll)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Paper Size:',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      ChoiceChip(
                        key: const ValueKey('receipt_size_80mm_chip'),
                        label: const Text('80mm Thermal (Standard)', style: TextStyle(fontSize: 11.5)),
                        selected: paperWidthMm == 80,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => setDialogState(() => paperWidthMm = 80),
                      ),
                      ChoiceChip(
                        key: const ValueKey('receipt_size_58mm_chip'),
                        label: const Text('58mm Mini Roll', style: TextStyle(fontSize: 11.5)),
                        selected: paperWidthMm == 58,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => setDialogState(() => paperWidthMm = 58),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Compact Thermal Slip Preview Area
                  Flexible(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: SingleChildScrollView(
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: slipPreviewWidth,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x140F172A),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'SIAKA PHONES',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  branch,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 5),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFF0F172A)),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'OFFICIAL SALES RECEIPT',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(height: 1, color: Color(0xFF94A3B8)),
                                ),
                                _receiptMetaRow('Receipt No:', receiptNo, boldValue: true),
                                _receiptMetaRow('Order ID:', cleanId, boldValue: true),
                                _receiptMetaRow(
                                  'Order Date:',
                                  DateFormat('MMM d, y • HH:mm').format(order.date),
                                ),
                                _receiptMetaRow('Status:', order.status.label),
                                _receiptMetaRow('Payment:', order.paymentMethod),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(height: 1, color: Color(0xFF94A3B8)),
                                ),
                                const Text(
                                  'CUSTOMER',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  custName,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (order.customerPhone.trim().isNotEmpty)
                                  Text(
                                    'Tel: ${order.customerPhone.trim()}',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                if (order.gpsCode.trim().isNotEmpty ||
                                    order.deliveryAddress.trim().isNotEmpty)
                                  Text(
                                    [
                                      if (order.gpsCode.trim().isNotEmpty) order.gpsCode.trim(),
                                      if (order.deliveryAddress.trim().isNotEmpty)
                                        order.deliveryAddress.trim(),
                                    ].join(' • '),
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 9.5,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(height: 1, color: Color(0xFF94A3B8)),
                                ),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'ITEM / QTY × UNIT',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'AMOUNT',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                for (var i = 0; i < effectiveItems.length; i++) ...[
                                  if (i > 0)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 4),
                                      child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                                    ),
                                  Builder(
                                    builder: (_) {
                                      final it = effectiveItems[i];
                                      final unitPrice = it.price > 0
                                          ? it.price
                                          : (effectiveItems.length == 1 && it.quantity > 0
                                              ? order.totalAmount / it.quantity
                                              : 0.0);
                                      final lineTotal = unitPrice * it.quantity;
                                      final meta = [
                                        if (it.brand.trim().isNotEmpty) it.brand.trim(),
                                        if (it.specs.trim().isNotEmpty) it.specs.trim(),
                                      ].join(' • ');
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${i + 1}. ${it.title}',
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          if (meta.isNotEmpty)
                                            Text(
                                              meta,
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 9,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Qty: ${it.quantity} × ${currencyFormat.format(unitPrice)}',
                                                  style: const TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontSize: 9.8,
                                                    color: Color(0xFF334155),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  currencyFormat.format(lineTotal),
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(height: 1, thickness: 1.2, color: Color(0xFF0F172A)),
                                ),
                                _receiptMetaRow(
                                  'Items / Total Qty:',
                                  '${effectiveItems.length} ($totalQty ${totalQty == 1 ? 'Unit' : 'Units'})',
                                  boldValue: true,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'TOTAL',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        currencyFormat.format(displayTotal),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'RETURN & EXCHANGE VERIFICATION',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        'Keep receipt with original box & accessories for any returns or warranty support.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 8.8,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '*$cleanId*',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.4,
                                          color: Color(0xFF0F172A),
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
                    ),
                  ),

                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton.icon(
                          key: const ValueKey('confirm_print_order_receipt_btn'),
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: Text(
                            'Print Receipt (${paperWidthMm}mm)',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final ok = await OrderPrintService.printOrderReceipt(
                              order,
                              branchName: branch,
                              paperWidthMm: paperWidthMm,
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? 'Opened compact ${paperWidthMm}mm receipt print dialog for #$cleanId.'
                                        : 'Could not launch system print dialog.',
                                  ),
                                  backgroundColor: ok ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _receiptMetaRow(String label, String value, {bool boldValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 9.8,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9.8,
                fontWeight: boldValue ? FontWeight.w800 : FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
