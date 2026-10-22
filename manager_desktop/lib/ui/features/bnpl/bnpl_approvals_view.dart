import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/manager_repository.dart';
import '../../../domain/models/customer_message.dart';
import '../../../domain/models/manager_bnpl.dart';
import '../../core/status_chip.dart';

class BnplApprovalsView extends StatefulWidget {
  final ManagerRepository repository;
  final void Function(
    String name,
    String? phone,
    String? email, {
    String? initialSubject,
    String? initialBody,
    MessageCategory? initialCategory,
  })? onMessageCustomer;

  const BnplApprovalsView({
    super.key,
    required this.repository,
    this.onMessageCustomer,
  });

  @override
  State<BnplApprovalsView> createState() => _BnplApprovalsViewState();
}

class _BnplApprovalsViewState extends State<BnplApprovalsView> {
  String _searchQuery = '';
  BnplStatus? _statusFilter;
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

  List<ManagerBnpl> _getFilteredApplications() {
    return widget.repository.bnplApplications.where((app) {
      if (_statusFilter != null && app.status != _statusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = app.applicantName.toLowerCase().contains(query);
        final matchesPhone = app.phone.toLowerCase().contains(query);
        final matchesEmployer = app.employer.toLowerCase().contains(query);
        final matchesPhoneModel = app.requestedPhone.toLowerCase().contains(query);
        final matchesId = app.nationalId.toLowerCase().contains(query);
        final matchesLocation = app.location.toLowerCase().contains(query);
        return matchesName || matchesPhone || matchesEmployer || matchesPhoneModel || matchesId || matchesLocation;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    final filteredApplications = _getFilteredApplications();

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
                  'Buy Now Pay Later (BNPL) Approvals',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review creditworthiness, salary verification, and approve installment plans for ${widget.repository.currentBranch}',
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
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pending_actions_rounded, size: 18, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.repository.pendingBnplCount} Awaiting Review',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFFB45309),
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
                  hintText: 'Search applicant name, phone, Ghana Card, location, or requested device...',
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
                    label: const Text('All Applications'),
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
                  ...BnplStatus.values.map((status) {
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

        // Applications Table Card
        final tableCard = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: filteredApplications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card_off_rounded, size: 54, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No BNPL applications found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No installment requests match your active search or filter.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, tableConstraints) {
                    final availableWidth = tableConstraints.maxWidth;
                    final tableMinWidth = math.max(1100.0, availableWidth);
                    final columnSpacing = ((tableMinWidth - 960.0 - 48) / 6).clamp(20.0, 110.0);

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
                                  DataColumn(label: Text('APPLICANT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('GHANA CARD & LOCATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('REQUESTED DEVICE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('DOWN PAYMENT (20%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('PLAN SCHEDULE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('DECISION & ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                ],
                                rows: filteredApplications.map((app) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        InkWell(
                                          onTap: () => _showBnplDetailDialog(context, app),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '#${app.id}',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFF7C3AED),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      app.applicantName,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 13,
                                                        color: Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(app.phone, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                              ],
                                            ),
                                          ),
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
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.badge_outlined, size: 12, color: Color(0xFF0F172A)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    app.nationalId,
                                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: 0.2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  app.location,
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                                                ),
                                              ],
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
                                              app.requestedPhone,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                                            ),
                                            Text(
                                              [
                                                if (app.storage.isNotEmpty) app.storage,
                                                if (app.ram.isNotEmpty) app.ram,
                                                if (app.preferredColor.isNotEmpty && app.preferredColor != 'Default') app.preferredColor,
                                                if (app.deviceCondition.isNotEmpty) app.deviceCondition,
                                              ].join(' • '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          currencyFormat.format(app.downPayment),
                                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF059669), fontSize: 13),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFBFDBFE)),
                                              ),
                                              child: Text(
                                                '${app.planDuration} Plan',
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Color(0xFF1D4ED8)),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.storefront_rounded, size: 12, color: Color(0xFF64748B)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  app.preferredBranch,
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        StatusChip(
                                          label: app.status.label,
                                          textColor: Color(app.status.textColor),
                                          bgColor: Color(app.status.bgColor),
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
                                                backgroundColor: const Color(0xFF7C3AED),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                visualDensity: VisualDensity.compact,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              onPressed: () => _showBnplDetailDialog(context, app),
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF1C7BFF)),
                                              tooltip: 'Send Direct Message to ${app.applicantName}',
                                              onPressed: () {
                                                final subject = 'BNPL Application #${app.id} Update';
                                                final body = 'Hello ${app.applicantName}, regarding your BNPL installment application #${app.id} for ${app.requestedPhone} (${app.location}): ';
                                                if (widget.onMessageCustomer != null) {
                                                  widget.onMessageCustomer!(
                                                    app.applicantName,
                                                    app.phone,
                                                    app.email,
                                                    initialSubject: subject,
                                                    initialBody: body,
                                                    initialCategory: MessageCategory.paymentReminder,
                                                  );
                                                } else {
                                                  widget.repository.selectCustomerForMessaging(
                                                    customerName: app.applicantName,
                                                    phone: app.phone,
                                                    email: app.email,
                                                    initialSubject: subject,
                                                    initialBody: body,
                                                    initialCategory: MessageCategory.paymentReminder,
                                                  );
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF1C7BFF)),
                                              tooltip: 'Manage Terms & Credit Review',
                                              onPressed: () => _showBnplDetailDialog(context, app),
                                            ),
                                            if (app.status == BnplStatus.pending) ...[
                                              IconButton(
                                                icon: const Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF059669)),
                                                tooltip: 'Quick Approve Application',
                                                onPressed: () {
                                                  widget.repository.updateBnplStatus(app.id, BnplStatus.approved, notes: 'Income & KYC cleared.');
                                                  setState(() {});
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('BNPL Plan approved for ${app.applicantName}!'),
                                                      backgroundColor: const Color(0xFF059669),
                                                    ),
                                                  );
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.cancel_rounded, size: 20, color: Color(0xFFDC2626)),
                                                tooltip: 'Quick Decline Application',
                                                onPressed: () {
                                                  widget.repository.updateBnplStatus(app.id, BnplStatus.rejected, notes: 'Credit threshold requirement not met.');
                                                  setState(() {});
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('BNPL Plan declined for ${app.applicantName}'),
                                                      backgroundColor: const Color(0xFFDC2626),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ] else ...[
                                              PopupMenuButton<BnplStatus>(
                                                tooltip: 'Change Status',
                                                icon: const Icon(Icons.arrow_circle_right_outlined, size: 18, color: Color(0xFF64748B)),
                                                onSelected: (newStatus) {
                                                  widget.repository.updateBnplStatus(app.id, newStatus);
                                                  setState(() {});
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Status updated to ${newStatus.label} for ${app.applicantName}'),
                                                      backgroundColor: Color(newStatus.bgColor),
                                                    ),
                                                  );
                                                },
                                                itemBuilder: (context) => BnplStatus.values.map((status) {
                                                  return PopupMenuItem<BnplStatus>(
                                                    value: status,
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 10,
                                                          height: 10,
                                                          decoration: BoxDecoration(
                                                            color: Color(status.textColor),
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(status.label, style: const TextStyle(fontSize: 13)),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ],
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

  void _showBnplDetailDialog(BuildContext context, ManagerBnpl app) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    final notesCtrl = TextEditingController(text: app.managerNotes);
    final priceCtrl = TextEditingController(text: app.phonePrice.toStringAsFixed(2));
    final downPaymentCtrl = TextEditingController(text: app.downPayment.toStringAsFixed(2));
    final installmentCtrl = TextEditingController(text: app.monthlyInstallment.toStringAsFixed(2));
    final messageCtrl = TextEditingController();
    bool sendPlanToCustomer = true;
    BnplStatus selectedStatus = app.status;

    void updateDraftMessage() {
      final parsedPrice = double.tryParse(priceCtrl.text.replaceAll(',', '').trim()) ?? app.phonePrice;
      final parsedDown = double.tryParse(downPaymentCtrl.text.replaceAll(',', '').trim()) ?? app.downPayment;
      final parsedInst = double.tryParse(installmentCtrl.text.replaceAll(',', '').trim()) ?? app.monthlyInstallment;
      final periodUnit = app.planDuration.toLowerCase().startsWith('day')
          ? 'daily'
          : (app.planDuration.toLowerCase().startsWith('week') ? 'weekly' : 'monthly');

      if (selectedStatus == BnplStatus.approved) {
        messageCtrl.text =
            'Hello ${app.applicantName}, your Buy Now Pay Later installment plan (#${app.id}) for ${app.requestedPhone} at Siaka Phones has been APPROVED! Terms: Total Retail: ${currencyFormat.format(parsedPrice)}, Down Payment: ${currencyFormat.format(parsedDown)}, ${app.planDuration} Installment: ${currencyFormat.format(parsedInst)} ($periodUnit for ${app.tenureMonths} months). Please visit ${app.preferredBranch.isNotEmpty ? app.preferredBranch : 'our store'} with your Ghana Card to complete KYC verification and receive your device.';
      } else if (selectedStatus == BnplStatus.rejected) {
        messageCtrl.text =
            'Hello ${app.applicantName}, regarding your BNPL installment application (#${app.id}) for ${app.requestedPhone} at Siaka Phones: Your application has been declined at this time. Remarks: "${notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : 'Credit eligibility criteria not met'}". You may re-apply with an increased down payment or contact our credit team.';
      } else {
        messageCtrl.text =
            'Hello ${app.applicantName}, your BNPL installment application (#${app.id}) for ${app.requestedPhone} is currently under review by the Store Manager at Siaka Phones. We will verify your details and notify you promptly.';
      }
    }

    updateDraftMessage();

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
                // Header (matches repairs desk dialog)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF7C3AED), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'BNPL Application #${app.id}',
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
                              'Submitted on ${DateFormat('MMMM d, y • HH:mm').format(app.applicationDate)}',
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
                        // Card 1: Customer Information Card (styled exactly like Repairs Desk)
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
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_rounded, size: 16, color: Color(0xFF334155)),
                                            const SizedBox(width: 6),
                                            Text(app.applicantName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone_rounded, size: 15, color: Color(0xFF64748B)),
                                            const SizedBox(width: 6),
                                            Text(app.phone, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
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
                                      final subject = 'BNPL Financing Plan #${app.id} - ${app.requestedPhone}';
                                      final body = 'Hello ${app.applicantName}, regarding your BNPL installment application for ${app.requestedPhone}: ';
                                      if (widget.onMessageCustomer != null) {
                                        widget.onMessageCustomer!(
                                          app.applicantName,
                                          app.phone,
                                          app.email,
                                          initialSubject: subject,
                                          initialBody: body,
                                          initialCategory: MessageCategory.paymentReminder,
                                        );
                                      } else {
                                        widget.repository.selectCustomerForMessaging(
                                          customerName: app.applicantName,
                                          phone: app.phone,
                                          email: app.email,
                                          initialSubject: subject,
                                          initialBody: body,
                                          initialCategory: MessageCategory.paymentReminder,
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'REQUESTED DEVICE MODEL',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone_android_rounded, size: 16, color: Color(0xFF7C3AED)),
                                            const SizedBox(width: 6),
                                            if (app.brand.isNotEmpty) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEDE9FE),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  app.brand,
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6D28D9)),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                            ],
                                            Expanded(
                                              child: Text(
                                                app.modelName.isNotEmpty ? app.modelName : app.requestedPhone,
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                                overflow: TextOverflow.ellipsis,
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
                                          'INSTALLMENT SCHEDULE',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.event_repeat_rounded, size: 15, color: Color(0xFF0284C7)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '${app.planDuration.isNotEmpty ? app.planDuration : "Monthly"} Plan (${app.tenureMonths} Months)',
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
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

                        // Card 2: Customer Selected Phone Specifications Card
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
                              const Row(
                                children: [
                                  Icon(Icons.tune_rounded, size: 16, color: Color(0xFF7C3AED)),
                                  SizedBox(width: 8),
                                  Text(
                                    'CUSTOMER SELECTED PHONE SPECIFICATIONS',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildSpecTag(
                                    Icons.storage_rounded,
                                    'Internal Storage',
                                    app.storage.isNotEmpty ? app.storage : '256 GB',
                                    color: const Color(0xFF2563EB),
                                  ),
                                  _buildSpecTag(
                                    Icons.memory_rounded,
                                    'RAM / Memory',
                                    app.ram.isNotEmpty ? app.ram : '8 GB',
                                    color: const Color(0xFF7C3AED),
                                  ),
                                  _buildSpecTag(
                                    Icons.verified_outlined,
                                    'Device Condition',
                                    app.deviceCondition.isNotEmpty ? app.deviceCondition : 'Brand New (Sealed)',
                                    color: const Color(0xFF059669),
                                  ),
                                  _buildSpecTag(
                                    Icons.palette_outlined,
                                    'Preferred Color',
                                    app.preferredColor.isNotEmpty ? app.preferredColor : 'Any Available Color',
                                    color: const Color(0xFFD97706),
                                  ),
                                  _buildSpecTag(
                                    Icons.calendar_month_rounded,
                                    'Financing Plan',
                                    app.planDuration.isNotEmpty ? '${app.planDuration} Plan' : 'Monthly Plan',
                                    color: const Color(0xFF0284C7),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Card 3: Customer Problem Explanation & Description / Special Instructions
                        const Text('Customer Problem Explanation & Special Instructions',
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
                                  app.customerNotes.trim().isNotEmpty
                                      ? app.customerNotes
                                      : 'No additional instructions or notes provided by customer.',
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

                        // Card 4: Store Pickup & Logistics Details Card (3 Columns matching Repairs Desk)
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
                              const Text('DROP-OFF & APPOINTMENT / PICKUP DETAILS',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5)),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('STORE BRANCH', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.storefront_rounded, size: 15, color: Color(0xFF0284C7)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                app.preferredBranch.isNotEmpty ? app.preferredBranch : 'Siaka Phones Circle (Main Hub)',
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
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
                                        const Text('SUBMISSION DATE', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF475569)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                DateFormat('EEEE, MMMM d, y').format(app.applicationDate),
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
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
                                        const Text('INSTALLMENT SCHEDULE', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.schedule_rounded, size: 15, color: Color(0xFF7C3AED)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '${app.planDuration} Financing Plan',
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
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

                        // Card 5: Financing Terms & Installment Breakdown Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'FINANCING TERMS & INSTALLMENT PLAN',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF), letterSpacing: 0.5),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${app.planDuration} Plan',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildFinanceKpi('DOWN PAYMENT (20%)', currencyFormat.format(app.downPayment), const Color(0xFF059669)),
                                  _buildFinanceKpi(
                                    'PERIODIC INSTALLMENT',
                                    '${currencyFormat.format(app.monthlyInstallment)} /${app.planDuration.toLowerCase().startsWith('day') ? 'day' : (app.planDuration.toLowerCase().startsWith('week') ? 'wk' : 'mo')}',
                                    const Color(0xFF2563EB),
                                  ),
                                  _buildFinanceKpi('PLAN SCHEDULE', '${app.planDuration} Plan', const Color(0xFF7C3AED)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Card 6: Manager Credit Appraisal & Decision Controls Card (matches repairs quote/manager section)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MANAGER CREDIT APPRAISAL & DECISION CONTROLS',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 12),

                              // Status radio selection
                              Row(
                                children: BnplStatus.values.map((s) {
                                  final isSelected = selectedStatus == s;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: InkWell(
                                        onTap: () {
                                          setDialogState(() {
                                            selectedStatus = s;
                                            updateDraftMessage();
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Color(s.bgColor) : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isSelected ? Color(s.textColor) : const Color(0xFFE2E8F0),
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                                size: 16,
                                                color: Color(s.textColor),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                s.label,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                  color: Color(s.textColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 14),

                              // Editable Financial Quote (Retail Price, Down Payment, Periodic Installment)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: priceCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Retail Price (GH₵)',
                                        prefixText: 'GH₵ ',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                      onChanged: (_) => setDialogState(updateDraftMessage),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: downPaymentCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Down Payment (GH₵)',
                                        prefixText: 'GH₵ ',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                      onChanged: (_) => setDialogState(updateDraftMessage),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: installmentCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        labelText: '${app.planDuration} Inst. (GH₵)',
                                        prefixText: 'GH₵ ',
                                        border: const OutlineInputBorder(),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                      onChanged: (_) => setDialogState(updateDraftMessage),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Manager Credit Remarks Field
                              TextField(
                                controller: notesCtrl,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Manager Notes & Credit Assessment Remarks',
                                  hintText: 'e.g. Verified employer ID, 3-month payslip, down payment received.',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(12),
                                ),
                                onChanged: (_) => setDialogState(updateDraftMessage),
                              ),

                              const SizedBox(height: 14),

                              // Customer Live Notice Preview
                              const Text(
                                'CUSTOMER NOTICE MESSAGE PREVIEW (VIA IN-APP NOTIFICATION)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: messageCtrl,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Send notification checkbox
                              Row(
                                children: [
                                  Checkbox(
                                    value: sendPlanToCustomer,
                                    activeColor: const Color(0xFF1C7BFF),
                                    onChanged: (val) => setDialogState(() => sendPlanToCustomer = val ?? true),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      'Send Plan Decision & Message to Customer in Mobile App',
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                    ),
                                  ),
                                ],
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
                const SizedBox(height: 16),

                // Footer (matches repairs desk dialog)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Save & Send Plan to Customer', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        final parsedPrice = double.tryParse(priceCtrl.text.replaceAll(',', '').trim()) ?? app.phonePrice;
                        final parsedDown = double.tryParse(downPaymentCtrl.text.replaceAll(',', '').trim()) ?? app.downPayment;
                        final parsedInst = double.tryParse(installmentCtrl.text.replaceAll(',', '').trim()) ?? app.monthlyInstallment;

                        widget.repository.updateBnplStatus(
                          app.id,
                          selectedStatus,
                          notes: notesCtrl.text.trim(),
                          phonePrice: parsedPrice,
                          downPayment: parsedDown,
                          monthlyInstallment: parsedInst,
                        );

                        if (sendPlanToCustomer && messageCtrl.text.trim().isNotEmpty) {
                          final subject = selectedStatus == BnplStatus.approved
                              ? 'BNPL Plan #${app.id} Approved - ${app.requestedPhone}'
                              : (selectedStatus == BnplStatus.rejected
                                  ? 'BNPL Plan #${app.id} Declined'
                                  : 'BNPL Plan #${app.id} Update');
                          final custId = widget.repository.customers
                              .where((c) =>
                                  c.fullName.toLowerCase() == app.applicantName.toLowerCase() ||
                                  c.phone.replaceAll(' ', '') == app.phone.replaceAll(' ', ''))
                              .firstOrNull
                              ?.id ??
                              'CUST-${app.id}';

                          widget.repository.sendCustomerMessage(
                            CustomerMessage(
                              id: 'MSG-BNPL-${DateTime.now().millisecondsSinceEpoch % 100000}',
                              customerId: custId,
                              customerName: app.applicantName,
                              customerPhone: app.phone,
                              customerEmail: app.email,
                              message: messageCtrl.text.trim(),
                              subject: subject,
                              category: MessageCategory.paymentReminder,
                              channel: MessageChannel.inApp,
                              sentAt: DateTime.now(),
                              status: MessageDeliveryStatus.delivered,
                            ),
                          );
                        }

                        Navigator.pop(ctx);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('BNPL Plan #${app.id} updated to ${selectedStatus.label} and dispatched to customer!'),
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


  Widget _buildSpecTag(IconData icon, String label, String value, {Color color = const Color(0xFF7C3AED)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceKpi(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF), letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}
