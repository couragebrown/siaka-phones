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
                  'Review customer device swap requests, inspect submitted phone specifications, and send direct cost quotes to customers',
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
                                  DataColumn(label: Text('CONDITION & STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('TARGET DEVICE WANTED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('BRANCH / NOTES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('OFFERED COST', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
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
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              swap.currentDevice,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A)),
                                            ),
                                            Text(
                                              'Storage: ${swap.currentStorage.isNotEmpty ? swap.currentStorage : '128 GB'}',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                              ),
                                              child: Text(swap.deviceCondition, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: swap.turnsOn ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: swap.turnsOn ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
                                              ),
                                              child: Text(
                                                swap.turnsOn ? 'Powers On' : 'No Power',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: swap.turnsOn ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: swap.screenIntact ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: swap.screenIntact ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A)),
                                              ),
                                              child: Text(
                                                swap.screenIntact ? 'Screen Intact' : 'Screen Broken',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: swap.screenIntact ? const Color(0xFF1D4ED8) : const Color(0xFFD97706),
                                                ),
                                              ),
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
                                              swap.targetDevice,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A)),
                                            ),
                                            Text(
                                              [
                                                if (swap.desiredStorage.isNotEmpty) swap.desiredStorage,
                                                if (swap.desiredRam.isNotEmpty) swap.desiredRam,
                                                if (swap.desiredCondition.isNotEmpty) swap.desiredCondition,
                                                if (swap.desiredColor.isNotEmpty && swap.desiredColor != 'Default') swap.desiredColor,
                                              ].join(' • '),
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
                                              swap.preferredBranch,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF334155)),
                                            ),
                                            if (swap.customerNotes.isNotEmpty)
                                              Text(
                                                swap.customerNotes,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                                              ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        swap.offeredCost != null && swap.offeredCost! > 0
                                            ? Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFECFDF5),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                                ),
                                                child: Text(
                                                  currencyFormat.format(swap.offeredCost!),
                                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF059669)),
                                                ),
                                              )
                                            : Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFFBEB),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.pending_actions_rounded, size: 14, color: Color(0xFFD97706)),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Awaiting Review',
                                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFFD97706)),
                                                    ),
                                                  ],
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
                                              onPressed: () => _showSwapDetailDialog(context, swap),
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF1C7BFF)),
                                              tooltip: 'Send Direct Message to ${swap.customerName}',
                                              onPressed: () {
                                                final matchedCust = widget.repository.customers.where((c) =>
                                                    c.fullName.toLowerCase() == swap.customerName.toLowerCase() ||
                                                    c.phone.replaceAll(' ', '') == swap.customerPhone.replaceAll(' ', '')).firstOrNull;
                                                final email = matchedCust?.email;
                                                final subject = 'Device Swap #${swap.id} - ${swap.currentDevice} to ${swap.targetDevice}';
                                                final body = 'Hello ${swap.customerName}, regarding your device swap request for ${swap.currentDevice} to ${swap.targetDevice} at Siaka Phones: ';

                                                if (widget.onMessageCustomer != null) {
                                                  widget.onMessageCustomer!(
                                                    swap.customerName,
                                                    swap.customerPhone,
                                                    email,
                                                    initialSubject: subject,
                                                    initialBody: body,
                                                    initialCategory: MessageCategory.swapQuote,
                                                  );
                                                } else {
                                                  widget.repository.selectCustomerForMessaging(
                                                    customerName: swap.customerName,
                                                    phone: swap.customerPhone,
                                                    email: email,
                                                    initialSubject: subject,
                                                    initialBody: body,
                                                    initialCategory: MessageCategory.swapQuote,
                                                  );
                                                }
                                              },
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

  void _showSwapDetailDialog(BuildContext context, ManagerSwap swap) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    final notesCtrl = TextEditingController(text: swap.inspectionNotes);
    final costCtrl = TextEditingController(
      text: swap.offeredCost != null && swap.offeredCost! > 0
          ? swap.offeredCost!.toStringAsFixed(2)
          : '0',
    );
    final messageCtrl = TextEditingController();
    bool sendCostToCustomer = true;
    SwapEvaluationStatus selectedStatus = swap.status;

    void updateDraftMessage(String costInput) {
      final parsedCost = double.tryParse(costInput.replaceAll(',', '').trim());
      final costString = (parsedCost != null && parsedCost > 0)
          ? currencyFormat.format(parsedCost)
          : 'GH₵ 0.00 (valuation quote pending)';
      final noteStr = notesCtrl.text.trim().isNotEmpty
          ? ' Appraiser notes: "${notesCtrl.text.trim()}".'
          : '';
      messageCtrl.text =
          'Hello ${swap.customerName}, regarding your device swap request #${swap.id} for ${swap.currentDevice} to ${swap.targetDevice} at Siaka Phones: Your swap evaluation has been reviewed. The required cost / cash top-up is $costString.$noteStr Please visit our ${swap.preferredBranch} branch to inspect the device and complete your swap.';
    }

    updateDraftMessage(costCtrl.text);

    final formattedSubDate = DateFormat('EEEE, MMMM d, y • HH:mm').format(swap.submissionDate);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 680,
            constraints: const BoxConstraints(maxHeight: 780),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF1C7BFF), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Swap Request #${swap.id}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 10),
                                StatusChip(
                                  label: selectedStatus.label,
                                  textColor: Color(selectedStatus.textColor),
                                  bgColor: Color(selectedStatus.bgColor),
                                ),
                              ],
                            ),
                            Text(
                              'Submitted on $formattedSubDate',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close Details Dialog',
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 16),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer & Devices Information Card
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
                                        const Text('CUSTOMER INFORMATION',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_rounded, size: 16, color: Color(0xFF334155)),
                                            const SizedBox(width: 6),
                                            Text(swap.customerName,
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone_rounded, size: 15, color: Color(0xFF64748B)),
                                            const SizedBox(width: 6),
                                            Text(swap.customerPhone,
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF1C7BFF)),
                                    label: const Text('Message Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1C7BFF))),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                                      backgroundColor: const Color(0xFFEFF6FF),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      final matchedCust = widget.repository.customers.where((c) =>
                                          c.fullName.toLowerCase() == swap.customerName.toLowerCase() ||
                                          c.phone.replaceAll(' ', '') == swap.customerPhone.replaceAll(' ', '')).firstOrNull;
                                      final email = matchedCust?.email;
                                      final subject = 'Device Swap #${swap.id} - ${swap.currentDevice} to ${swap.targetDevice}';
                                      final body = 'Hello ${swap.customerName}, regarding your swap request for ${swap.currentDevice} to ${swap.targetDevice}: ';

                                      if (widget.onMessageCustomer != null) {
                                        widget.onMessageCustomer!(
                                          swap.customerName,
                                          swap.customerPhone,
                                          email,
                                          initialSubject: subject,
                                          initialBody: body,
                                          initialCategory: MessageCategory.swapQuote,
                                        );
                                      } else {
                                        widget.repository.selectCustomerForMessaging(
                                          customerName: swap.customerName,
                                          phone: swap.customerPhone,
                                          email: email,
                                          initialSubject: subject,
                                          initialBody: body,
                                          initialCategory: MessageCategory.swapQuote,
                                        );
                                      }
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
                                  // Current Device
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('DEVICE TO SWAP (TRADE-IN)',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone_android_rounded, size: 16, color: Color(0xFFD97706)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(swap.currentDevice,
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Storage: ${swap.currentStorage.isNotEmpty ? swap.currentStorage : '128 GB'} • Condition: ${swap.deviceCondition}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: swap.turnsOn ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: swap.turnsOn ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
                                              ),
                                              child: Text(
                                                swap.turnsOn ? '✓ Turns On' : '✗ No Power',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: swap.turnsOn ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: swap.screenIntact ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: swap.screenIntact ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A)),
                                              ),
                                              child: Text(
                                                swap.screenIntact ? '✓ Screen Intact' : '✗ Screen Damaged',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: swap.screenIntact ? const Color(0xFF1D4ED8) : const Color(0xFFD97706),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Target Device
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('TARGET DEVICE WANTED',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.smartphone_rounded, size: 16, color: Color(0xFF1C7BFF)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(swap.targetDevice,
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          [
                                            if (swap.desiredStorage.isNotEmpty) swap.desiredStorage,
                                            if (swap.desiredRam.isNotEmpty) swap.desiredRam,
                                            if (swap.desiredCondition.isNotEmpty) swap.desiredCondition,
                                            if (swap.desiredColor.isNotEmpty && swap.desiredColor != 'Default') swap.desiredColor,
                                          ].join(' • '),
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFFBFDBFE)),
                                          ),
                                          child: Text(
                                            'Preferred Branch: ${swap.preferredBranch}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
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

                        const SizedBox(height: 16),

                        // Customer Notes & Reason Box
                        const Text('Customer Trade-in Notes & Description',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.format_quote_rounded, size: 20, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  swap.customerNotes.trim().isNotEmpty
                                      ? swap.customerNotes
                                      : 'No additional trade-in notes provided by customer.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                    height: 1.45,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Logistics: Branch, Submission Date, Initial Trade-in Est
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
                              const Text('DROP-OFF & TRADE-IN BRANCH DETAILS',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF2563EB)),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Drop-off Store', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                            Text(swap.preferredBranch, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF059669)),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Submitted Date', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                            Text(DateFormat('EEEE, MMMM d, y').format(swap.submissionDate), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.verified_outlined, size: 16, color: Color(0xFF1C7BFF)),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Current Status', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                            Text(selectedStatus.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
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

                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 16),

                        // Appraiser Valuation Controls
                        const Text('Appraiser Valuation & Service Controls',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                        const SizedBox(height: 12),

                        // Status Progression
                        const Text('Update Evaluation Decision', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF334155))),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<SwapEvaluationStatus>(
                          initialValue: selectedStatus,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                          items: SwapEvaluationStatus.values.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  Icon(Icons.circle, size: 12, color: Color(s.textColor)),
                                  const SizedBox(width: 8),
                                  Text(s.label),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedStatus = val);
                          },
                        ),

                        const SizedBox(height: 14),

                        // Cost Field
                        TextField(
                          controller: costCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Official Swap Valuation / Top-up Cost (GH₵)',
                            prefixText: 'GH₵ ',
                            border: OutlineInputBorder(),
                            helperText: 'Enter reviewed cash top-up or device trade-in cost to quote customer',
                          ),
                          onChanged: (val) {
                            updateDraftMessage(val);
                            setDialogState(() {});
                          },
                        ),

                        const SizedBox(height: 14),

                        // Appraiser Notes Field
                        TextField(
                          controller: notesCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Appraiser Work Log & Inspection Notes',
                            hintText: 'e.g. Original display verified, minor hairline scratches on frame, FaceID and cameras 100% operational.',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            updateDraftMessage(costCtrl.text);
                            setDialogState(() {});
                          },
                        ),

                        const SizedBox(height: 14),

                        // Editable Customer Quote Notice
                        TextField(
                          controller: messageCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Customer Cost Quote Message (Delivered to Customer App)',
                            border: OutlineInputBorder(),
                            helperText: 'Auto-composed quote notice sent directly to customer on submit',
                          ),
                        ),

                        const SizedBox(height: 8),

                        CheckboxListTile(
                          value: sendCostToCustomer,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            'Send estimated top-up quote to ${swap.customerName}\'s app (${swap.customerPhone})',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                          subtitle: const Text(
                            'Updates swap evaluation and pushes top-up quote notice directly to customer just like repairs',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (val) => setDialogState(() => sendCostToCustomer = val ?? true),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: Text(
                        sendCostToCustomer ? 'Save & Send Cost to Customer' : 'Save Swap Updates',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C7BFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        final parsedCost = double.tryParse(costCtrl.text.replaceAll(',', '').trim()) ?? swap.offeredCost;
                        swap.offeredCost = parsedCost;
                        widget.repository.updateSwapStatus(
                          swap.id,
                          selectedStatus,
                          notes: notesCtrl.text.trim(),
                          offeredCost: parsedCost,
                        );

                        if (sendCostToCustomer) {
                          final matchedCust = widget.repository.customers.where((c) =>
                              c.fullName.toLowerCase() == swap.customerName.toLowerCase() ||
                              c.phone.replaceAll(' ', '') == swap.customerPhone.replaceAll(' ', '')).firstOrNull;
                          final custId = matchedCust?.id ?? 'CUST_${swap.customerPhone.replaceAll(RegExp(r'\D'), '')}';
                          final email = matchedCust?.email;
                          final subject = 'Device Swap Quote #${swap.id} - ${swap.currentDevice} to ${swap.targetDevice}';
                          final body = messageCtrl.text.trim();

                          final quoteMsg = CustomerMessage(
                            id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
                            customerId: custId,
                            customerName: swap.customerName,
                            customerPhone: swap.customerPhone,
                            customerEmail: email ?? '',
                            subject: subject,
                            message: body,
                            category: MessageCategory.swapQuote,
                            channel: MessageChannel.inApp,
                            sentBy: 'Siaka Trade-In Desk',
                            sentAt: DateTime.now(),
                          );
                          widget.repository.sendCustomerMessage(quoteMsg);
                        }

                        Navigator.pop(ctx);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              sendCostToCustomer
                                  ? 'Updated swap #${swap.id} and sent top-up cost (${parsedCost != null ? currencyFormat.format(parsedCost) : 'GH₵ 0.00'}) to ${swap.customerName}\'s app'
                                  : 'Swap evaluation #${swap.id} updated successfully',
                            ),
                            backgroundColor: const Color(0xFF059669),
                          ),
                        );
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
