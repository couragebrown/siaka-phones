import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/manager_repository.dart';
import '../../../domain/models/customer_message.dart';
import '../../../domain/models/manager_shipping.dart';

class ShippingView extends StatefulWidget {
  final ManagerRepository repository;
  final void Function(
    String name,
    String? phone,
    String? email, {
    String? initialSubject,
    String? initialBody,
    MessageCategory? initialCategory,
  })? onMessageCustomer;

  const ShippingView({
    super.key,
    required this.repository,
    this.onMessageCustomer,
  });

  @override
  State<ShippingView> createState() => _ShippingViewState();
}

class _ShippingViewState extends State<ShippingView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _outerScrollController = ScrollController();

  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedProcess = 'All';

  final List<String> _statusFilters = [
    'All',
    'Delivered (Done)',
    'In Transit',
    'Out for Delivery',
    'Pending Pickup',
    'Failed / Returned',
  ];

  final List<String> _processFilters = [
    'All',
    'Customer Order',
    'BNPL Device',
    'Repaired Device Return',
    'Trade-in Exchange',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _outerScrollController.dispose();
    super.dispose();
  }

  List<ManagerShippingItem> _getFilteredShipments() {
    return widget.repository.shipments.where((item) {
      // Status filter
      if (_selectedStatus != 'All') {
        if ((_selectedStatus == 'Delivered' || _selectedStatus == 'Delivered (Done)') &&
            item.status != ShippingStatus.delivered) {
          return false;
        }
        if (_selectedStatus == 'In Transit' && item.status != ShippingStatus.inTransit) return false;
        if (_selectedStatus == 'Out for Delivery' && item.status != ShippingStatus.outForDelivery) return false;
        if (_selectedStatus == 'Pending Pickup' && item.status != ShippingStatus.pendingPickup) return false;
        if (_selectedStatus == 'Failed / Returned' &&
            item.status != ShippingStatus.failedDelivery &&
            item.status != ShippingStatus.returned) {
          return false;
        }
      }

      // Process filter
      if (_selectedProcess != 'All') {
        if (item.processType.label != _selectedProcess) return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTracking = item.trackingNumber.toLowerCase().contains(query);
        final matchesName = item.customerName.toLowerCase().contains(query);
        final matchesPhone = item.customerPhone.replaceAll(' ', '').contains(query.replaceAll(' ', ''));
        final matchesCity = item.destinationCity.toLowerCase().contains(query);
        final matchesProcessId = item.orderOrProcessId.toLowerCase().contains(query);
        final matchesCourier = item.courier.toLowerCase().contains(query);
        final matchesItems = item.itemsDescription.toLowerCase().contains(query);

        if (!matchesTracking && !matchesName && !matchesPhone && !matchesCity && !matchesProcessId && !matchesCourier && !matchesItems) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.repository,
      builder: (context, _) {
        final filteredShipments = _getFilteredShipments();
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 900;

        final inTransitCount = widget.repository.shipments.where((s) => s.status == ShippingStatus.inTransit).length;
        final outForDeliveryCount = widget.repository.shipments.where((s) => s.status == ShippingStatus.outForDelivery).length;
        final deliveredCount = widget.repository.shipments.where((s) => s.status == ShippingStatus.delivered).length;
        final pendingCount = widget.repository.shipments.where((s) => s.status == ShippingStatus.pendingPickup).length;

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
                  const Text(
                    'Shipping & Delivery Management',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track dispatches, rider checkpoints, and delivery logs',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddDispatchDialog(context),
              icon: const Icon(Icons.add_location_alt_rounded, size: 18),
              label: const Text('New Dispatch Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C7BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
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
                        label: 'IN TRANSIT',
                        value: '$inTransitCount',
                        icon: Icons.local_shipping_rounded,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 200,
                      child: _buildMetric(
                        label: 'OUT FOR DELIVERY',
                        value: '$outForDeliveryCount',
                        icon: Icons.delivery_dining_rounded,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 200,
                      child: _buildMetric(
                        label: 'DELIVERED (DONE)',
                        value: '$deliveredCount',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 200,
                      child: _buildMetric(
                        label: 'PENDING PICKUP',
                        value: '$pendingCount',
                        icon: Icons.access_time_rounded,
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
                      label: 'IN TRANSIT',
                      value: '$inTransitCount',
                      icon: Icons.local_shipping_rounded,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetric(
                      label: 'OUT FOR DELIVERY',
                      value: '$outForDeliveryCount',
                      icon: Icons.delivery_dining_rounded,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetric(
                      label: 'DELIVERED (DONE)',
                      value: '$deliveredCount',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetric(
                      label: 'PENDING PICKUP',
                      value: '$pendingCount',
                      icon: Icons.access_time_rounded,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ],
              );

        final filterBar = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search input
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by tracking #, customer name, phone, destination, process ID...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
              const SizedBox(height: 12),
              // Status and process filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Status: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    const SizedBox(width: 6),
                    ..._statusFilters.map((s) {
                      final isSel = _selectedStatus == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isSel,
                          label: Text(s),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : const Color(0xFF334155),
                          ),
                          backgroundColor: const Color(0xFFF1F5F9),
                          selectedColor: const Color(0xFF1C7BFF),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          onSelected: (_) => setState(() => _selectedStatus = s),
                        ),
                      );
                    }),
                    const SizedBox(width: 12),
                    const Text('Process: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    const SizedBox(width: 6),
                    ..._processFilters.map((p) {
                      final isSel = _selectedProcess == p;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isSel,
                          label: Text(p),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? const Color(0xFF1C7BFF) : const Color(0xFF475569),
                          ),
                          backgroundColor: isSel ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                          selectedColor: const Color(0xFFDBEAFE),
                          side: BorderSide(
                            color: isSel ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
                          ),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          onSelected: (_) => setState(() => _selectedProcess = p),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );

        final tableCard = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      'All Dispatches (${filteredShipments.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Auto-synced with branch delivery log',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Table Body
              Expanded(
                child: filteredShipments.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text(
                                'No matching shipments found',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try clearing your search query or selecting "All" statuses.',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Scrollbar(
                        controller: _verticalScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _verticalScrollController,
                          child: Scrollbar(
                            controller: _horizontalScrollController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
                            child: SingleChildScrollView(
                              controller: _horizontalScrollController,
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                dataRowMinHeight: 70,
                                dataRowMaxHeight: 76,
                                horizontalMargin: 20,
                                columnSpacing: 24,
                                columns: const [
                                  DataColumn(label: Text('TRACKING # & TYPE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('CUSTOMER & CONTACT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('DESTINATION & COURIER', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('ITEMS / PACKAGE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('CURRENT LOCATION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                ],
                                rows: filteredShipments.map((shipment) {
                                  return DataRow(
                                    cells: [
                                      // Tracking # & Process
                                      DataCell(
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              shipment.trackingNumber,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(shipment.processType.icon, size: 12, color: Color(shipment.processType.colorValue)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${shipment.processType.label} (${shipment.orderOrProcessId})',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(shipment.processType.colorValue),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Customer & Contact
                                      DataCell(
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              shipment.customerName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              shipment.customerPhone,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Destination & Courier
                                      DataCell(
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${shipment.destinationCity} • ${shipment.destinationAddress}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1E293B),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${shipment.courier} ${shipment.dispatchRiderPhone.isNotEmpty ? "(${shipment.dispatchRiderPhone})" : ""}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Items
                                      DataCell(
                                        SizedBox(
                                          width: 180,
                                          child: Text(
                                            shipment.itemsDescription,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF334155),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),

                                      // Current Location
                                      DataCell(
                                        SizedBox(
                                          width: 190,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.pin_drop_rounded, size: 13, color: Color(0xFFE11D48)),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      shipment.lastLocationUpdate,
                                                      style: const TextStyle(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: Color(0xFF0F172A),
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'ETA: ${DateFormat('h:mm a, d MMM').format(shipment.estimatedDelivery)}',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Status Badge
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Color(shipment.status.bgColor),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: Color(shipment.status.textColor).withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            shipment.status.label,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(shipment.status.textColor),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Actions
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Update Shipping Button
                                            OutlinedButton.icon(
                                              onPressed: () => _showUpdateShippingDialog(context, shipment),
                                              icon: const Icon(Icons.edit_location_alt_rounded, size: 14),
                                              label: const Text('Update Status'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFF1C7BFF),
                                                side: const BorderSide(color: Color(0xFF93C5FD)),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                            ),
                                            const SizedBox(width: 6),

                                            // Message Customer Button
                                            IconButton(
                                              tooltip: 'Send Shipping Update to Customer',
                                              icon: const Icon(Icons.mark_chat_unread_rounded, size: 18, color: Color(0xFF4F46E5)),
                                              onPressed: () {
                                                if (widget.onMessageCustomer != null) {
                                                  final subject = 'Delivery Update: Shipment #${shipment.trackingNumber}';
                                                  final body = 'Hello ${shipment.customerName},\n\nThis is an update from Siaka Phones regarding your shipment (#${shipment.trackingNumber}).\nStatus: ${shipment.status.label}\nCurrent Location: ${shipment.lastLocationUpdate}\nCourier: ${shipment.courier} (Rider: ${shipment.dispatchRiderPhone})\n\nPlease contact us if you need any assistance.';
                                                  widget.onMessageCustomer!(
                                                    shipment.customerName,
                                                    shipment.customerPhone,
                                                    shipment.customerEmail,
                                                    initialSubject: subject,
                                                    initialBody: body,
                                                    initialCategory: MessageCategory.orderUpdate,
                                                  );
                                                }
                                              },
                                            ),

                                            // View History / Timeline
                                            IconButton(
                                              tooltip: 'View Checkpoint Timeline',
                                              icon: const Icon(Icons.history_rounded, size: 18, color: Color(0xFF64748B)),
                                              onPressed: () => _showTimelineDialog(context, shipment),
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
            ],
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
                      filterBar,
                      const SizedBox(height: 16),
                      SizedBox(height: 520, child: tableCard),
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
                  filterBar,
                  const SizedBox(height: 16),
                  Expanded(child: tableCard),
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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

  // Dialog: Update Shipping Status & Location
  void _showUpdateShippingDialog(BuildContext context, ManagerShippingItem shipment) {
    ShippingStatus selectedStatus = shipment.status;
    final locationCtrl = TextEditingController(text: shipment.lastLocationUpdate);
    final notesCtrl = TextEditingController(text: shipment.managerNotes);
    final courierCtrl = TextEditingController(text: shipment.courier);
    final riderCtrl = TextEditingController(text: shipment.dispatchRiderPhone);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                const Icon(Icons.local_shipping_rounded, color: Color(0xFF1C7BFF)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Update Shipping #${shipment.trackingNumber}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(shipment.processType.icon, size: 20, color: Color(shipment.processType.colorValue)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${shipment.customerName} • ${shipment.destinationCity}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  shipment.itemsDescription,
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Status Dropdown
                    const Text('Shipping Status *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<ShippingStatus>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: ShippingStatus.values.map((st) {
                        return DropdownMenuItem(
                          value: st,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Color(st.textColor),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(st.label),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedStatus = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Location update
                    const Text('Current Location / Checkpoint *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Near Madina Zongo Junction, handed to recipient...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin_drop_rounded, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Courier & Rider Phone
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Courier Service', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: courierCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Express Moto Logistics',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Rider Phone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: riderCtrl,
                                decoration: const InputDecoration(
                                  hintText: '+233 24 000 0000',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Manager Notes
                    const Text('Checkpoint / Manager Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Any special instructions, delivery confirmation details...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final loc = locationCtrl.text.trim();
                  if (loc.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a location checkpoint update.')),
                    );
                    return;
                  }

                  widget.repository.updateShippingStatus(
                    shipment.id,
                    selectedStatus,
                    locationUpdate: loc,
                    notes: notesCtrl.text.trim(),
                    courier: courierCtrl.text.trim(),
                    riderPhone: riderCtrl.text.trim(),
                  );

                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF059669),
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Shipment #${shipment.trackingNumber} updated to ${selectedStatus.label}!')),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save & Notify Customer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C7BFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Dialog: Add New Dispatch Record
  void _showAddDispatchDialog(BuildContext context) {
    final trackingCtrl = TextEditingController(text: 'SP-GH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final customerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Accra');
    final itemsCtrl = TextEditingController();
    final courierCtrl = TextEditingController(text: 'Express Moto Logistics');
    final riderCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Dispatched from Accra Central Hub');
    ShippingProcessType processType = ShippingProcessType.orderFulfillment;
    final processIdCtrl = TextEditingController(text: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Row(
              children: [
                Icon(Icons.add_location_alt_rounded, color: Color(0xFF1C7BFF)),
                SizedBox(width: 10),
                Text('Create New Dispatch Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            content: SizedBox(
              width: 540,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dispatch packages for completed orders, BNPL deliveries, repaired phones, or device swaps.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),

                    // Process Type & Process ID
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<ShippingProcessType>(
                            initialValue: processType,
                            decoration: const InputDecoration(
                              labelText: 'Process Type *',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: ShippingProcessType.values.map((pt) {
                              return DropdownMenuItem(value: pt, child: Text(pt.label));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  processType = val;
                                  final prefix = val == ShippingProcessType.orderFulfillment
                                      ? 'ORD'
                                      : val == ShippingProcessType.bnplDispatch
                                          ? 'BNPL'
                                          : val == ShippingProcessType.repairReturn
                                              ? 'REP'
                                              : 'SWAP';
                                  processIdCtrl.text = '$prefix-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: processIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Ref / Process ID *',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Customer Name & Phone
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customerCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Customer Full Name *',
                              hintText: 'e.g. Kwame Mensah',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: phoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Customer Phone *',
                              hintText: '+233 24 123 4567',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone_outlined, size: 18),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Destination Address & City
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: addressCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Delivery Address *',
                              hintText: 'e.g. Plot 12, Ring Road Central',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.home_outlined, size: 18),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: cityCtrl,
                            decoration: const InputDecoration(
                              labelText: 'City / Region *',
                              hintText: 'e.g. Accra, Kumasi',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Items Description
                    TextField(
                      controller: itemsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Items / Package Content *',
                        hintText: 'e.g. 1x iPhone 15 Pro Max 256GB + 1x 20W Charger',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2_outlined, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Courier & Rider
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: courierCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Courier / Service *',
                              hintText: 'e.g. Speedy Dispatch',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: riderCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Rider Phone',
                              hintText: '+233 20 555 1234',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Initial Location Update
                    TextField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Initial Checkpoint / Location *',
                        hintText: 'e.g. Dispatched from Accra Central Hub',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin_drop_rounded, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final customer = customerCtrl.text.trim();
                  final phone = phoneCtrl.text.trim();
                  final items = itemsCtrl.text.trim();
                  final address = addressCtrl.text.trim();
                  final city = cityCtrl.text.trim();

                  if (customer.isEmpty || phone.isEmpty || items.isEmpty || address.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all required customer and delivery fields.')),
                    );
                    return;
                  }

                  final newShipment = ManagerShippingItem(
                    id: 'SHIP-${DateTime.now().millisecondsSinceEpoch}',
                    trackingNumber: trackingCtrl.text.trim(),
                    orderOrProcessId: processIdCtrl.text.trim(),
                    processType: processType,
                    customerName: customer,
                    customerPhone: phone,
                    customerEmail: emailCtrl.text.trim().isNotEmpty
                        ? emailCtrl.text.trim()
                        : '${customer.toLowerCase().replaceAll(' ', '.')}@gmail.com',
                    destinationAddress: address,
                    destinationCity: city,
                    courier: courierCtrl.text.trim(),
                    dispatchRiderPhone: riderCtrl.text.trim(),
                    status: ShippingStatus.inTransit,
                    itemsDescription: items,
                    lastLocationUpdate: locationCtrl.text.trim(),
                    estimatedDelivery: DateTime.now().add(const Duration(hours: 4)),
                    dispatchedAt: DateTime.now(),
                    statusHistory: [
                      ShippingCheckpoint(
                        timestamp: DateTime.now(),
                        location: locationCtrl.text.trim(),
                        status: ShippingStatus.inTransit,
                        note: 'Dispatch initiated from branch.',
                        updatedBy: 'Store Manager',
                      ),
                    ],
                  );

                  widget.repository.addShippingRecord(newShipment);
                  Navigator.of(ctx).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF059669),
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Dispatch created with Tracking #${newShipment.trackingNumber}!')),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.local_shipping_rounded, size: 18),
                label: const Text('Create Dispatch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C7BFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Dialog: Checkpoint Timeline
  void _showTimelineDialog(BuildContext context, ManagerShippingItem shipment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.timeline_rounded, color: Color(0xFF1C7BFF)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tracking Timeline #${shipment.trackingNumber}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery checkpoints for ${shipment.customerName} (${shipment.destinationCity})',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                if (shipment.statusHistory.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No checkpoints logged yet.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  )
                else
                  ...shipment.statusHistory.reversed.map((cp) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(cp.status.textColor),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      cp.status.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(cp.status.textColor),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM d, h:mm a').format(cp.timestamp),
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cp.location,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                                if (cp.note.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    cp.note,
                                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
