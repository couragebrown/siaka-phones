import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/manager_repository.dart';
import '../../../domain/models/customer_message.dart';
import '../../../domain/models/manager_repair.dart';
import '../../core/status_chip.dart';

class RepairsDeskView extends StatefulWidget {
  final ManagerRepository repository;
  final void Function(
    String name,
    String? phone,
    String? email, {
    String? initialSubject,
    String? initialBody,
    MessageCategory? initialCategory,
  })? onMessageCustomer;

  const RepairsDeskView({
    super.key,
    required this.repository,
    this.onMessageCustomer,
  });

  @override
  State<RepairsDeskView> createState() => _RepairsDeskViewState();
}

class _RepairsDeskViewState extends State<RepairsDeskView> {
  String _searchQuery = '';
  RepairStage? _stageFilter;
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

  List<ManagerRepair> _getFilteredRepairs() {
    return widget.repository.repairs.where((repair) {
      if (_stageFilter != null && repair.stage != _stageFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesId = repair.id.toLowerCase().contains(query);
        final matchesName = repair.customerName.toLowerCase().contains(query);
        final matchesPhone = repair.customerPhone.toLowerCase().contains(query);
        final matchesModel = repair.deviceModel.toLowerCase().contains(query);
        final matchesIssue = repair.reportedIssue.toLowerCase().contains(query);
        return matchesId || matchesName || matchesPhone || matchesModel || matchesIssue;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    final filteredRepairs = _getFilteredRepairs();

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
                  'Hardware Repair & Service Desk',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track device diagnosis, parts requisition, technician updates, and customer pickup readiness',
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
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.build_rounded, size: 18, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.repository.activeRepairsCount} In Service Lab',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF6D28D9),
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
              // Search
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search ticket ID, customer name, phone, device model, or fault...',
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
                    borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Stage Filter Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All Stages'),
                    selected: _stageFilter == null,
                    onSelected: (_) => setState(() => _stageFilter = null),
                    backgroundColor: const Color(0xFFF1F5F9),
                    selectedColor: const Color(0xFFEDE9FE),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _stageFilter == null ? FontWeight.w700 : FontWeight.w500,
                      color: _stageFilter == null ? const Color(0xFF7C3AED) : const Color(0xFF475569),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    side: BorderSide(
                      color: _stageFilter == null ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  ...RepairStage.values.map((stage) {
                    final isSelected = _stageFilter == stage;
                    return FilterChip(
                      label: Text(stage.label),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _stageFilter = isSelected ? null : stage),
                      backgroundColor: const Color(0xFFF1F5F9),
                      selectedColor: Color(stage.bgColor),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Color(stage.textColor) : const Color(0xFF475569),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      side: BorderSide(
                        color: isSelected ? Color(stage.textColor) : const Color(0xFFE2E8F0),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        );

        // Repairs Table Card
        final tableCard = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: filteredRepairs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.build_circle_outlined, size: 54, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No repair tickets found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try selecting another stage or clearing your search filters.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, tableConstraints) {
                    final availableWidth = tableConstraints.maxWidth;
                    final tableMinWidth = math.max(1240.0, availableWidth);
                    final columnSpacing = ((tableMinWidth - 1120.0 - 48) / 7).clamp(20.0, 110.0);

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
                                  DataColumn(label: Text('TICKET ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('DATE BOOKED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('CUSTOMER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('DEVICE MODEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('REPORTED FAULT / ISSUE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('STAGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('ESTIMATED COST', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                ],
                                rows: filteredRepairs.map((repair) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          repair.id,
                                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF7C3AED), fontSize: 13),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          DateFormat('MMM d, y • HH:mm').format(repair.bookedDate),
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(repair.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A))),
                                            Text(repair.customerPhone, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.phone_android_rounded, size: 16, color: Color(0xFF475569)),
                                            const SizedBox(width: 6),
                                            Text(repair.deviceModel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          constraints: const BoxConstraints(maxWidth: 220),
                                          child: Text(
                                            repair.reportedIssue,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        StatusChip(
                                          label: repair.stage.label,
                                          textColor: Color(repair.stage.textColor),
                                          bgColor: Color(repair.stage.bgColor),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          currencyFormat.format(repair.estimatedCost),
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF1C7BFF)),
                                              tooltip: 'Send Direct Message to ${repair.customerName}',
                                              onPressed: () {
                                                final matchedCust = widget.repository.customers.where((c) =>
                                                    c.fullName.toLowerCase() == repair.customerName.toLowerCase() ||
                                                    c.phone.replaceAll(' ', '') == repair.customerPhone.replaceAll(' ', '')).firstOrNull;
                                                final email = matchedCust?.email;
                                                final subject = 'Repair Ticket #${repair.id} - ${repair.deviceModel}';
                                                final body = 'Hello ${repair.customerName}, regarding your ${repair.deviceModel} (${repair.reportedIssue}) currently at stage [${repair.stage.label}]: ';

                                                if (widget.onMessageCustomer != null) {
                                                  widget.onMessageCustomer!(
                                                    repair.customerName,
                                                    repair.customerPhone,
                                                    email,
                                                    initialSubject: subject,
                                                    initialBody: body,
                                                    initialCategory: MessageCategory.repairNotice,
                                                  );
                                                } else {
                                                  widget.repository.selectCustomerForMessaging(
                                                    customerName: repair.customerName,
                                                    phone: repair.customerPhone,
                                                    email: email,
                                                    initialSubject: subject,
                                                    initialBody: body,
                                                    initialCategory: MessageCategory.repairNotice,
                                                  );
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF1C7BFF)),
                                              tooltip: 'Manage Ticket & Technician Notes',
                                              onPressed: () => _showRepairDetailDialog(context, repair),
                                            ),
                                            PopupMenuButton<RepairStage>(
                                              tooltip: 'Quick Advance Stage',
                                              icon: const Icon(Icons.arrow_circle_right_outlined, size: 18, color: Color(0xFF64748B)),
                                              onSelected: (newStage) {
                                                widget.repository.updateRepairStage(repair.id, newStage);
                                                setState(() {});
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Ticket ${repair.id} advanced to ${newStage.label}'),
                                                    backgroundColor: const Color(0xFF1E293B),
                                                  ),
                                                );
                                              },
                                              itemBuilder: (ctx) => RepairStage.values.map((s) {
                                                return PopupMenuItem<RepairStage>(
                                                  value: s,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        repair.stage == s ? Icons.check_circle_rounded : Icons.circle_outlined,
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

  void _showRepairDetailDialog(BuildContext context, ManagerRepair repair) {
    final notesCtrl = TextEditingController(text: repair.technicianNotes);
    final costCtrl = TextEditingController(text: repair.estimatedCost.toStringAsFixed(0));
    RepairStage selectedStage = repair.stage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 600,
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
                          Text(repair.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED))),
                          const SizedBox(width: 10),
                          StatusChip(
                            label: selectedStage.label,
                            textColor: Color(selectedStage.textColor),
                            bgColor: Color(selectedStage.bgColor),
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  Text(
                    'Booked on ${DateFormat('MMMM d, y • HH:mm').format(repair.bookedDate)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),

                  // Device & Customer Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(repair.deviceModel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A))),
                            Text('${repair.customerName} (${repair.customerPhone})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF475569))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Reported Fault:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(repair.reportedIssue, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stage Progression
                  const Text('Update Service Stage', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<RepairStage>(
                    initialValue: selectedStage,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                    items: RepairStage.values.map((s) {
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
                      if (val != null) setDialogState(() => selectedStage = val);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Cost Field
                  TextField(
                    controller: costCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total Estimated Repair Cost (GH₵)',
                      prefixText: 'GH₵ ',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Technician Notes Field
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Technician Work Log & Diagnostic Notes',
                      hintText: 'e.g. Screen replaced with genuine OLED panel, adhesive cured, tested touch response.',
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
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          final cost = double.tryParse(costCtrl.text) ?? repair.estimatedCost;
                          widget.repository.updateRepairStage(
                            repair.id,
                            selectedStage,
                            notes: notesCtrl.text,
                            cost: cost,
                          );
                          Navigator.pop(ctx);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Repair ticket ${repair.id} updated'),
                              backgroundColor: const Color(0xFF059669),
                            ),
                          );
                        },
                        child: const Text('Save Ticket Updates'),
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
