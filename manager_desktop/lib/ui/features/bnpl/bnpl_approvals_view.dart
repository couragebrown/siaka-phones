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
                    final tableMinWidth = math.max(1280.0, availableWidth);
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
                                dataRowMinHeight: 58,
                                dataRowMaxHeight: 72,
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                horizontalMargin: 24,
                                columnSpacing: columnSpacing,
                                columns: const [
                                  DataColumn(label: Text('APPLICANT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('GHANA CARD & LOCATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('REQUESTED DEVICE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('DEVICE PRICE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('DOWN PAYMENT (20%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('MONTHLY / TENURE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('DECISION & ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                ],
                                rows: filteredApplications.map((app) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(app.applicantName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                                            Text(app.phone, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
                                        Text(
                                          app.requestedPhone,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          currencyFormat.format(app.phonePrice),
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
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
                                            Text(
                                              '${currencyFormat.format(app.monthlyInstallment)} /mo',
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
                                            ),
                                            Text(
                                              '${app.tenureMonths} months tenure',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
                                            if (app.status == BnplStatus.pending) ...[
                                              IconButton(
                                                icon: const Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF059669)),
                                                tooltip: 'Approve Application',
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
                                                tooltip: 'Decline Application',
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
                                            ],
                                            // Full Details & Audit Dialog
                                            IconButton(
                                              icon: const Icon(Icons.feed_outlined, size: 18, color: Color(0xFF64748B)),
                                              tooltip: 'Review Details & Credit Audit',
                                              onPressed: () => _showBnplDetailDialog(context, app),
                                            ),
                                            // Message Customer
                                            IconButton(
                                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF1C7BFF)),
                                              tooltip: 'Send Direct Message',
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
                          const Text('BNPL Credit Application', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          const SizedBox(width: 10),
                          StatusChip(
                            label: app.status.label,
                            textColor: Color(app.status.textColor),
                            bgColor: Color(app.status.bgColor),
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  Text('Applied on: ${DateFormat('MMMM d, y • HH:mm').format(app.applicationDate)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),

                  // Applicant Info Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Applicant Full Name', app.applicantName),
                        const SizedBox(height: 8),
                        _buildDetailRow('National ID (Ghana Card)', app.nationalId),
                        const SizedBox(height: 8),
                        _buildDetailRow('Applicant Location & Address', app.location),
                        const SizedBox(height: 8),
                        _buildDetailRow('Contact Phone', app.phone),
                        const SizedBox(height: 8),
                        _buildDetailRow('Contact Email', app.email),
                        const SizedBox(height: 8),
                        _buildDetailRow('Employer / Organization', app.employer),
                        const SizedBox(height: 8),
                        _buildDetailRow('Verified Monthly Salary', currencyFormat.format(app.monthlySalary)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Financing Terms Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Financed Device', app.requestedPhone),
                        const SizedBox(height: 8),
                        _buildDetailRow('Device Retail Value', currencyFormat.format(app.phonePrice)),
                        const SizedBox(height: 8),
                        _buildDetailRow('20% Down Payment (Initial)', currencyFormat.format(app.downPayment)),
                        const SizedBox(height: 8),
                        _buildDetailRow('Monthly Installment', currencyFormat.format(app.monthlyInstallment)),
                        const SizedBox(height: 8),
                        _buildDetailRow('Financing Tenure', '${app.tenureMonths} Months'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Manager Notes Field
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Credit Assessment Remarks / Manager Notes',
                      hintText: 'e.g. Verified with HR at Standard Chartered, payslip checked.',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFDC2626)),
                        ),
                        onPressed: () {
                          widget.repository.updateBnplStatus(app.id, BnplStatus.rejected, notes: notesCtrl.text);
                          Navigator.pop(ctx);
                          setState(() {});
                        },
                        child: const Text('Decline Plan'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          widget.repository.updateBnplStatus(app.id, BnplStatus.approved, notes: notesCtrl.text);
                          Navigator.pop(ctx);
                          setState(() {});
                        },
                        child: const Text('Approve Financing'),
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

  Widget _buildDetailRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        Text(val, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ],
    );
  }
}
