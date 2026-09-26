import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/manager_repository.dart';
import '../../../domain/models/customer_message.dart';
import '../../../domain/models/manager_swap.dart';
import '../../core/status_chip.dart';

class TradeInDeskView extends StatefulWidget {
  final ManagerRepository repository;
  final void Function(
    String name,
    String? phone,
    String? email, {
    String? initialSubject,
    String? initialBody,
    MessageCategory? initialCategory,
  })? onMessageCustomer;

  const TradeInDeskView({
    super.key,
    required this.repository,
    this.onMessageCustomer,
  });

  @override
  State<TradeInDeskView> createState() => _TradeInDeskViewState();
}

class _TradeInDeskViewState extends State<TradeInDeskView> {
  String _searchQuery = '';
  SwapEvaluationStatus? _statusFilter;
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

  List<ManagerSwap> _getFilteredSwaps() {
    return widget.repository.swaps.where((swap) {
      if (_statusFilter != null && swap.status != _statusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesId = swap.id.toLowerCase().contains(query);
        final matchesName = swap.customerName.toLowerCase().contains(query);
        final matchesPhone = swap.customerPhone.toLowerCase().contains(query);
        final matchesCurrent = swap.currentDevice.toLowerCase().contains(query);
        final matchesTarget = swap.targetDevice.toLowerCase().contains(query);
        return matchesId || matchesName || matchesPhone || matchesCurrent || matchesTarget;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    final filteredSwaps = _getFilteredSwaps();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 900;
        final isShortHeight = constraints.maxHeight < 680;

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
                  'Device Trade-in & Swap Valuation Desk',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Physical device inspection, battery health grading, trade-in valuations, and customer cash top-up calculations',
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
                  const Icon(Icons.swap_horiz_rounded, size: 20, color: Color(0xFF1C7BFF)),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${widget.repository.swaps.length} Evaluations',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
          ],
        );

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
                  hintText: 'Search swap ID, customer name, phone, trade-in or target phone...',
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

              // Status Filter
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  FilterChip(
                    label: const Text('All Swaps'),
                    selected: _statusFilter == null,
                    onSelected: (_) => setState(() => _statusFilter = null),
                    backgroundColor: const Color(0xFFF1F5F9),
                    selectedColor: const Color(0xFF1C7BFF).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _statusFilter == null ? FontWeight.w700 : FontWeight.w500,
                      color: _statusFilter == null ? const Color(0xFF1C7BFF) : const Color(0xFF475569),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    side: BorderSide(
                      color: _statusFilter == null ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  ...SwapEvaluationStatus.values.map((status) {
                    final isSelected = _statusFilter == status;
                    return FilterChip(
                      label: Text(status.label),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _statusFilter = isSelected ? null : status),
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

        final tableCard = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: filteredSwaps.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 54, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No trade-in submissions found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try clearing the filters or searching with different terms.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, tableConstraints) {
                    final availableWidth = tableConstraints.maxWidth;
                    final tableMinWidth = math.max(1300.0, availableWidth);
                    const baseContentWidth = 1180.0;
                    final columnSpacing = ((tableMinWidth - baseContentWidth - 48) / 8).clamp(18.0, 100.0);

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
                                dataRowMinHeight: 58,
                                dataRowMaxHeight: 72,
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                horizontalMargin: 24,
                                columnSpacing: columnSpacing,
                                columns: const [
                                  DataColumn(label: Text('SWAP ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('CUSTOMER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('CURRENT DEVICE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('CONDITION / BATTERY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('TRADE-IN VALUE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('TARGET DEVICE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('CASH TOP-UP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                ],
                                rows: filteredSwaps.map((swap) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          swap.id,
                                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1C7BFF), fontSize: 13),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              swap.customerName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                                            ),
                                            Text(swap.customerPhone, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          swap.currentDevice,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(swap.deviceCondition, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: swap.batteryHealth >= 80 ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${swap.batteryHealth}% Batt',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: swap.batteryHealth >= 80 ? const Color(0xFF059669) : const Color(0xFFD97706),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          currencyFormat.format(swap.estimatedTradeInValue),
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF059669)),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              swap.targetDevice,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF0F172A)),
                                            ),
                                            Text(currencyFormat.format(swap.targetDevicePrice), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFFBFDBFE)),
                                          ),
                                          child: Text(
                                            currencyFormat.format(swap.customerCashTopUp),
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1D4ED8)),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        StatusChip(
                                          label: swap.status.label,
                                          textColor: Color(swap.status.textColor),
                                          bgColor: Color(swap.status.bgColor),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF1C7BFF)),
                                              tooltip: 'Send Direct Message to ${swap.customerName}',
                                              onPressed: () {
                                                final matchedCust = widget.repository.customers.where((c) =>
                                                    c.fullName.toLowerCase() == swap.customerName.toLowerCase() ||
                                                    c.phone.replaceAll(' ', '') == swap.customerPhone.replaceAll(' ', '')).firstOrNull;
                                                final email = matchedCust?.email;
                                                final subject = 'Trade-in Valuation #${swap.id} - ${swap.currentDevice}';
                                                final body = 'Hello ${swap.customerName}, regarding your trade-in assessment for ${swap.currentDevice} (Estimated Value: ${currencyFormat.format(swap.estimatedTradeInValue)}) at Siaka Phones: ';

                                                if (widget.onMessageCustomer != null) {
                                                  widget.onMessageCustomer!(
                                                    swap.customerName,
                                                    swap.customerPhone,
                                                    email,
                                                    initialSubject: subject,
                                                    initialBody: body,
                                                    initialCategory: MessageCategory.promotional,
                                                  );
                                                } else {
                                                  widget.repository.selectCustomerForMessaging(
                                                    customerName: swap.customerName,
                                                    phone: swap.customerPhone,
                                                    email: email,
                                                    initialSubject: subject,
                                                    initialBody: body,
                                                    initialCategory: MessageCategory.promotional,
                                                  );
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.rate_review_outlined, size: 18, color: Color(0xFF1C7BFF)),
                                              tooltip: 'Inspect & Valuate',
                                              onPressed: () => _showSwapInspectionDialog(context, swap),
                                            ),
                                            PopupMenuButton<SwapEvaluationStatus>(
                                              tooltip: 'Quick Update Status',
                                              icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF64748B)),
                                              onSelected: (newStatus) {
                                                widget.repository.updateSwapStatus(swap.id, newStatus);
                                                setState(() {});
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Swap evaluation ${swap.id} updated to ${newStatus.label}'),
                                                    backgroundColor: const Color(0xFF1E293B),
                                                  ),
                                                );
                                              },
                                              itemBuilder: (ctx) => SwapEvaluationStatus.values.map((s) {
                                                return PopupMenuItem<SwapEvaluationStatus>(
                                                  value: s,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        swap.status == s ? Icons.check_circle_rounded : Icons.circle_outlined,
                                                        size: 16,
                                                        color: Color(s.textColor),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(s.label, style: const TextStyle(fontSize: 13)),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
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

  void _showSwapInspectionDialog(BuildContext context, ManagerSwap swap) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    final notesCtrl = TextEditingController(text: swap.inspectionNotes);
    SwapEvaluationStatus selectedStatus = swap.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 620,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(swap.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1C7BFF))),
                          const SizedBox(width: 10),
                          StatusChip(
                            label: selectedStatus.label,
                            textColor: Color(selectedStatus.textColor),
                            bgColor: Color(selectedStatus.bgColor),
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  Text(
                    'Submitted on ${DateFormat('MMMM d, y • HH:mm').format(swap.submissionDate)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),

                  // Trade-in Comparison Box
                  Row(
                    children: [
                      // Current phone
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
                              const Text('TRADE-IN DEVICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                              const SizedBox(height: 6),
                              Text(swap.currentDevice, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              Text('Condition: ${swap.deviceCondition}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                              Text('Battery: ${swap.batteryHealth}%', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              Text(
                                'Valuation: ${currencyFormat.format(swap.estimatedTradeInValue)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF94A3B8)),
                      ),

                      // Target phone
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TARGET NEW DEVICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
                              const SizedBox(height: 6),
                              Text(swap.targetDevice, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              Text('Retail Price: ${currencyFormat.format(swap.targetDevicePrice)}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              Text(
                                'Top-up Due: ${currencyFormat.format(swap.customerCashTopUp)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Customer Details
                  Text('Customer: ${swap.customerName} (${swap.customerPhone})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),

                  const SizedBox(height: 12),

                  // Update Status Selector
                  DropdownButtonFormField<SwapEvaluationStatus>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Evaluation Decision', border: OutlineInputBorder()),
                    items: SwapEvaluationStatus.values.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedStatus = val);
                    },
                  ),

                  const SizedBox(height: 14),

                  // Notes
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Device Inspection Checklist & Appraiser Notes',
                      hintText: 'e.g. Minor scratches on back glass, original screen, FaceID functional, iCloud removed.',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C7BFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          widget.repository.updateSwapStatus(
                            swap.id,
                            selectedStatus,
                            notes: notesCtrl.text,
                          );
                          Navigator.pop(ctx);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Swap evaluation ${swap.id} saved'),
                              backgroundColor: const Color(0xFF059669),
                            ),
                          );
                        },
                        child: const Text('Save Evaluation'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
