import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/manager_repository.dart';
import '../../../domain/models/customer_activity.dart';
import '../../../domain/models/customer_message.dart';
import '../../core/custom_date_range_picker.dart';

class CustomerActivityView extends StatefulWidget {
  final ManagerRepository repository;
  final void Function(
    String name,
    String? phone,
    String? email, {
    String? initialSubject,
    String? initialBody,
    MessageCategory? initialCategory,
  })? onMessageCustomer;

  const CustomerActivityView({
    super.key,
    required this.repository,
    this.onMessageCustomer,
  });

  @override
  State<CustomerActivityView> createState() => _CustomerActivityViewState();
}

class _CustomerActivityViewState extends State<CustomerActivityView> {
  String _timeFilter = 'This Month';
  String _statusFilter = 'All';
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _outerScrollController = ScrollController();

  final List<String> _timeFilters = [
    'All Time',
    'Today',
    'Yesterday',
    'This Week',
    'This Month',
  ];

  final List<String> _statusFilters = [
    'All',
    'Active',
    'Frequent Buyer',
    'VIP Customer',
    'Dormant',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _outerScrollController.dispose();
    super.dispose();
  }

  bool _matchesTimeFilter(DateTime date) {
    if (_fromDate != null || _toDate != null) {
      if (_fromDate != null) {
        final start = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day, 0, 0, 0);
        if (date.isBefore(start)) return false;
      }
      if (_toDate != null) {
        final end = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59, 999);
        if (date.isAfter(end)) return false;
      }
      return true;
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    if (_timeFilter == 'All Time') return true;

    if (_timeFilter == 'Today') {
      return date.isAfter(todayStart);
    }

    if (_timeFilter == 'Yesterday') {
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));
      return date.isAfter(yesterdayStart) && date.isBefore(todayStart);
    }

    if (_timeFilter == 'This Week') {
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      return date.isAfter(weekStart);
    }

    if (_timeFilter == 'This Month') {
      final monthStart = DateTime(now.year, now.month, 1);
      return date.isAfter(monthStart);
    }

    return true;
  }

  List<CustomerActivity> _getFilteredCustomers() {
    final list = widget.repository.customers.where((cust) {
      if (!_matchesTimeFilter(cust.signupDate)) return false;

      if (_statusFilter != 'All' && cust.status != _statusFilter) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesId = cust.id.toLowerCase().contains(q);
        final matchesName = cust.fullName.toLowerCase().contains(q);
        final matchesPhone = cust.phone.toLowerCase().contains(q);
        final matchesEmail = cust.email.toLowerCase().contains(q);
        final matchesDevice = cust.primaryDevice.toLowerCase().contains(q);
        return matchesId || matchesName || matchesPhone || matchesEmail || matchesDevice;
      }

      return true;
    }).toList();

    // Chronologically arranged by customer ID sequence (e.g. SK-90001, SK-90002...)
    list.sort((a, b) {
      final numA = int.tryParse(a.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final numB = int.tryParse(b.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (numA != numB) return numA.compareTo(numB);
      return a.signupDate.compareTo(b.signupDate);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final shortDateFormat = DateFormat('MMM dd, yyyy');

    final filteredCustomers = _getFilteredCustomers();
    final onlineCount = widget.repository.onlineCustomersCount;
    final totalSignups = filteredCustomers.length;
    final totalLogins = filteredCustomers.fold<int>(0, (sum, c) => sum + c.loginCount);
    final avgLogins = totalSignups > 0 ? (totalLogins / totalSignups).toStringAsFixed(1) : '0';
    final activeCount = filteredCustomers.where((c) => c.status != 'Dormant').length;
    final activeRate = totalSignups > 0 ? ((activeCount / totalSignups) * 100).toStringAsFixed(0) : '100';

    final displayTimeFilter = (_fromDate != null || _toDate != null)
        ? '${_fromDate != null ? DateFormat('dd/MM/yyyy').format(_fromDate!) : 'Start'} – ${_toDate != null ? DateFormat('dd/MM/yyyy').format(_toDate!) : 'Present'}'
        : _timeFilter;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 950;
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
                    'Customer Activity & Registration Intelligence',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor customer acquisition rate, login sessions, device telemetry, and engagement frequency',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Time filter quick picker buttons
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _timeFilters.map((tf) {
                          final isSel = (_fromDate == null && _toDate == null) && _timeFilter == tf;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _timeFilter = tf;
                                _fromDate = null;
                                _toDate = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF1C7BFF) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tf,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Custom Date Range Picker: [ FROM  dd/mm/yyyy  📅 ]  →  [ TO  dd/mm/yyyy  📅 ]  [ ✕ Reset ]
                  CustomDateRangePicker(
                    fromDate: _fromDate,
                    toDate: _toDate,
                    onFromDateSelected: (date) {
                      setState(() {
                        _fromDate = date;
                        _timeFilter = 'Custom';
                      });
                    },
                    onToDateSelected: (date) {
                      setState(() {
                        _toDate = date;
                        _timeFilter = 'Custom';
                      });
                    },
                    onReset: () {
                      setState(() {
                        _fromDate = null;
                        _toDate = null;
                        _timeFilter = 'This Month';
                      });
                    },
                  ),
                  // Sync with Database button
                  InkWell(
                    onTap: () async {
                      await widget.repository.refreshCustomerActivityFromDatabase();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Customer activity metrics synchronized with database'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Color(0xFF1C7BFF),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync_rounded, size: 14, color: Color(0xFF1C7BFF)),
                          SizedBox(width: 5),
                          Text(
                            'Sync DB',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
        );

        // Top Metric Cards (Responsive row/wrap)
        final metricCards = LayoutBuilder(
            builder: (context, cardConstraints) {
              final cards = [
                _buildMetricCard(
                  label: 'USERS ONLINE NOW',
                  value: '$onlineCount',
                  subtext: 'Live active store browsing',
                  icon: Icons.sensors_rounded,
                  color: const Color(0xFF10B981),
                  showLiveDot: true,
                  onTap: () => _showMetricDetailsDialog(CustomerActivityMetricType.onlineUsers),
                ),
                _buildMetricCard(
                  label: 'NEW SIGNUPS (${displayTimeFilter.toUpperCase()})',
                  value: '$totalSignups',
                  subtext: 'Registered accounts in window',
                  icon: Icons.person_add_alt_1_rounded,
                  color: const Color(0xFF1C7BFF),
                  onTap: () => _showMetricDetailsDialog(CustomerActivityMetricType.newSignups),
                ),
                _buildMetricCard(
                  label: 'TOTAL LOGINS RECORDED',
                  value: '$totalLogins',
                  subtext: 'Active authentication sessions',
                  icon: Icons.login_rounded,
                  color: const Color(0xFF059669),
                  onTap: () => _showMetricDetailsDialog(CustomerActivityMetricType.totalLogins),
                ),
                _buildMetricCard(
                  label: 'AVG LOGINS PER USER',
                  value: avgLogins,
                  subtext: 'Session frequency per customer',
                  icon: Icons.repeat_rounded,
                  color: const Color(0xFF7C3AED),
                  onTap: () => _showMetricDetailsDialog(CustomerActivityMetricType.avgLogins),
                ),
                _buildMetricCard(
                  label: 'ENGAGED RETENTION',
                  value: '$activeRate%',
                  subtext: '$activeCount active / VIP customers',
                  icon: Icons.verified_user_rounded,
                  color: const Color(0xFFD97706),
                  onTap: () => _showMetricDetailsDialog(CustomerActivityMetricType.retention),
                ),
              ];

              if (cardConstraints.maxWidth < 800) {
                final cardWidth = (cardConstraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
                );
              }

              return Row(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            },
          );

        // Search and Status Filters Bar
        // Search and Status Filters Bar
        final isNarrowFilter = constraints.maxWidth < 900;
        final filterBar = Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: isNarrowFilter
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search customers by ID (e.g. SK-90001), name, phone, email, or device...',
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1C7BFF), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _statusFilters.map((st) {
                            final isSel = _statusFilter == st;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(st),
                                selected: isSel,
                                onSelected: (val) {
                                  if (val) setState(() => _statusFilter = st);
                                },
                                backgroundColor: const Color(0xFFF1F5F9),
                                selectedColor: const Color(0xFF1C7BFF).withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel ? const Color(0xFF1C7BFF) : const Color(0xFF475569),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                side: BorderSide(color: isSel ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search customers by ID (e.g. SK-90001), name, phone, email, or device...',
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
                            contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1C7BFF), width: 1.5)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Wrap(
                        spacing: 6,
                        children: _statusFilters.map((st) {
                          final isSel = _statusFilter == st;
                          return ChoiceChip(
                            label: Text(st),
                            selected: isSel,
                            onSelected: (val) {
                              if (val) setState(() => _statusFilter = st);
                            },
                            backgroundColor: const Color(0xFFF1F5F9),
                            selectedColor: const Color(0xFF1C7BFF).withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? const Color(0xFF1C7BFF) : const Color(0xFF475569),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            side: BorderSide(color: isSel ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
          );

        // Customers Activity Data Table with horizontal and vertical scrollbars
        final tableCard = Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: filteredCustomers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_rounded, size: 54, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No customer signups or activities found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try adjusting your time window or status filters.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth;
                        // Provide ample minWidth so columns don't crunch when window is minimized
                        final tableMinWidth = math.max(1520.0, availableWidth);

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                                PointerDeviceKind.stylus,
                              },
                            ),
                            child: Scrollbar(
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
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(minWidth: tableMinWidth),
                                    child: DataTable(
                                      dataRowMinHeight: 58,
                                      dataRowMaxHeight: 70,
                                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                      horizontalMargin: 20,
                                      columnSpacing: 24,
                                      columns: const [
                                        DataColumn(label: Text('CUSTOMER ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                        DataColumn(label: Text('CUSTOMER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                        DataColumn(label: Text('EMAIL ADDRESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                        DataColumn(label: Text('PHONE NUMBER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                        DataColumn(label: Text('SIGNUP DATE & TIME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                        DataColumn(label: Text('LOGIN FREQUENCY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                        DataColumn(label: Text('LAST ACTIVE SESSION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                        DataColumn(label: Text('PRIMARY DEVICE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                        DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                        DataColumn(label: Text('TOTAL VALUE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                        DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                      ],
                                      rows: filteredCustomers.map((cust) {
                                        final initials = cust.fullName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join();
                                        final isFrequent = cust.loginCount >= 10;
                                        final isSuperActive = cust.loginCount >= 20;

                                        return DataRow(
                                          cells: [
                                            // Customer ID Badge
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: const Color(0xFFCBD5E1),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.badge_outlined,
                                                      size: 11,
                                                      color: Color(0xFF475569),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'ID: ${cust.id}',
                                                      style: const TextStyle(
                                                        color: Color(0xFF334155),
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 0.2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // Customer Name & Avatar
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 17,
                                                    backgroundColor: isSuperActive
                                                        ? const Color(0xFF7C3AED)
                                                        : isFrequent
                                                            ? const Color(0xFF1C7BFF)
                                                            : const Color(0xFF64748B),
                                                    child: Text(
                                                      initials,
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    cust.fullName,
                                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                                  ),
                                                  if (cust.isOnline) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFD1FAE5),
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(color: const Color(0xFFA7F3D0)),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 6,
                                                            height: 6,
                                                            decoration: const BoxDecoration(
                                                              color: Color(0xFF10B981),
                                                              shape: BoxShape.circle,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          const Text(
                                                            'ONLINE',
                                                            style: TextStyle(
                                                              fontSize: 9.5,
                                                              fontWeight: FontWeight.w800,
                                                              color: Color(0xFF047857),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),

                                            // Dedicated Email Address Column
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.email_outlined, size: 13, color: Color(0xFF1C7BFF)),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      cust.email,
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // Phone Number
                                            DataCell(
                                              Text(
                                                cust.phone,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                              ),
                                            ),

                                            // Signup Date & Time
                                            DataCell(
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    shortDateFormat.format(cust.signupDate),
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0F172A)),
                                                  ),
                                                  Text(
                                                    DateFormat('hh:mm a').format(cust.signupDate),
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Number of times logged in
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isSuperActive
                                                      ? const Color(0xFFF3E8FF)
                                                      : isFrequent
                                                          ? const Color(0xFFEFF6FF)
                                                          : const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: isSuperActive
                                                        ? const Color(0xFFDDD6FE)
                                                        : isFrequent
                                                            ? const Color(0xFFBFDBFE)
                                                            : const Color(0xFFE2E8F0),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      isSuperActive
                                                          ? Icons.local_fire_department_rounded
                                                          : isFrequent
                                                              ? Icons.trending_up_rounded
                                                              : Icons.login_rounded,
                                                      size: 14,
                                                      color: isSuperActive
                                                          ? const Color(0xFF7C3AED)
                                                          : isFrequent
                                                              ? const Color(0xFF1D4ED8)
                                                              : const Color(0xFF475569),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      '${cust.loginCount} logins',
                                                      style: TextStyle(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: isSuperActive
                                                            ? const Color(0xFF6D28D9)
                                                            : isFrequent
                                                                ? const Color(0xFF1E40AF)
                                                                : const Color(0xFF334155),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // Last Active Session
                                            DataCell(
                                              Text(
                                                dateFormat.format(cust.lastLogin),
                                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                              ),
                                            ),

                                            // Primary Device
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    cust.primaryDevice.contains('iPhone') || cust.primaryDevice.contains('iOS')
                                                        ? Icons.phone_iphone_rounded
                                                        : cust.primaryDevice.contains('MacBook') || cust.primaryDevice.contains('Windows')
                                                            ? Icons.laptop_mac_rounded
                                                            : Icons.phone_android_rounded,
                                                    size: 15,
                                                    color: const Color(0xFF64748B),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    cust.primaryDevice,
                                                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Status
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: cust.status == 'VIP Customer'
                                                      ? const Color(0xFFFEF3C7)
                                                      : cust.status == 'Frequent Buyer'
                                                          ? const Color(0xFFDCFCE7)
                                                          : cust.status == 'Active'
                                                              ? const Color(0xFFEFF6FF)
                                                              : const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  cust.status,
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: cust.status == 'VIP Customer'
                                                        ? const Color(0xFFB45309)
                                                        : cust.status == 'Frequent Buyer'
                                                            ? const Color(0xFF15803D)
                                                            : cust.status == 'Active'
                                                                ? const Color(0xFF1D4ED8)
                                                                : const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Total Value
                                            DataCell(
                                              Text(
                                                currencyFormat.format(cust.totalSpend),
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A)),
                                              ),
                                            ),

                                            // Message Direct Action
                                            DataCell(
                                              IconButton(
                                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF1C7BFF)),
                                                tooltip: 'Send Direct Message to ${cust.fullName}',
                                                onPressed: () {
                                                  final subject = 'Siaka Phones Direct Customer Service';
                                                  final body = 'Hello ${cust.fullName}, thank you for being a valued customer at Siaka Phones (${widget.repository.currentBranch} branch). How may we assist you today? ';
                                                  if (widget.onMessageCustomer != null) {
                                                    widget.onMessageCustomer!(
                                                      cust.fullName,
                                                      cust.phone,
                                                      cust.email,
                                                      initialSubject: subject,
                                                      initialBody: body,
                                                      initialCategory: MessageCategory.general,
                                                    );
                                                  } else {
                                                    widget.repository.selectCustomerForMessaging(
                                                      customerName: cust.fullName,
                                                      phone: cust.phone,
                                                      email: cust.email,
                                                      initialSubject: subject,
                                                      initialBody: body,
                                                      initialCategory: MessageCategory.general,
                                                    );
                                                  }
                                                },
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
                  metricCards,
                  const SizedBox(height: 18),
                  filterBar,
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
              metricCards,
              const SizedBox(height: 18),
              filterBar,
              const SizedBox(height: 16),
              Expanded(child: tableCard),
            ],
          ),
        );
      },
    );
  }

  void _messageCustomer(CustomerActivity cust) {
    final subject = 'Siaka Phones Direct Customer Service';
    final body =
        'Hello ${cust.fullName}, thank you for being a valued customer at Siaka Phones (${widget.repository.currentBranch} branch). How may we assist you today? ';
    if (widget.onMessageCustomer != null) {
      widget.onMessageCustomer!(
        cust.fullName,
        cust.phone,
        cust.email,
        initialSubject: subject,
        initialBody: body,
        initialCategory: MessageCategory.general,
      );
    } else {
      widget.repository.selectCustomerForMessaging(
        customerName: cust.fullName,
        phone: cust.phone,
        email: cust.email,
        initialSubject: subject,
        initialBody: body,
        initialCategory: MessageCategory.general,
      );
    }
  }

  void _filterTableToCustomer(CustomerActivity cust) {
    setState(() {
      _searchController.text = cust.id;
      _searchQuery = cust.id;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Focused activity table on ${cust.fullName} (${cust.id})'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF1C7BFF),
        ),
      );
    }
  }

  void _showMetricDetailsDialog(CustomerActivityMetricType metricType) {
    final displayTimeFilter = (_fromDate != null || _toDate != null)
        ? '${_fromDate != null ? DateFormat('dd/MM/yyyy').format(_fromDate!) : 'Start'} – ${_toDate != null ? DateFormat('dd/MM/yyyy').format(_toDate!) : 'Present'}'
        : _timeFilter;

    showDialog(
      context: context,
      builder: (ctx) => _CustomerActivityMetricDetailsDialog(
        metricType: metricType,
        timeFilter: displayTimeFilter,
        repository: widget.repository,
        allCustomers: widget.repository.customers,
        filteredCustomers: _getFilteredCustomers(),
        onMessageCustomer: (cust) {
          Navigator.of(ctx).pop();
          _messageCustomer(cust);
        },
        onFilterTable: (cust) {
          Navigator.of(ctx).pop();
          _filterTableToCustomer(cust);
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    bool showLiveDot = false,
    VoidCallback? onTap,
    String? tooltip,
  }) {
    return _MetricCardWidget(
      label: label,
      value: value,
      subtext: subtext,
      icon: icon,
      color: color,
      showLiveDot: showLiveDot,
      onTap: onTap,
      tooltip: tooltip,
    );
  }
}

enum CustomerActivityMetricType {
  onlineUsers,
  newSignups,
  totalLogins,
  avgLogins,
  retention,
}

class _MetricCardWidget extends StatefulWidget {
  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;
  final bool showLiveDot;
  final VoidCallback? onTap;
  final String? tooltip;

  const _MetricCardWidget({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
    this.showLiveDot = false,
    this.onTap,
    this.tooltip,
  });

  @override
  State<_MetricCardWidget> createState() => _MetricCardWidgetState();
}

class _MetricCardWidgetState extends State<_MetricCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveTooltip = widget.tooltip ?? 'Click to view ${widget.label} details & breakdown';

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: effectiveTooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered ? widget.color.withValues(alpha: 0.65) : const Color(0xFFE2E8F0),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(10),
              hoverColor: widget.color.withValues(alpha: 0.04),
              splashColor: widget.color.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: _isHovered ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.icon, size: 22, color: widget.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (widget.showLiveDot) ...[
                                Container(
                                  width: 7,
                                  height: 7,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              if (widget.onTap != null)
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 180),
                                  opacity: _isHovered ? 1.0 : 0.45,
                                  child: Icon(
                                    Icons.open_in_new_rounded,
                                    size: 13,
                                    color: _isHovered ? widget.color : const Color(0xFF94A3B8),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.subtext,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                                ),
                              ),
                              if (widget.onTap != null && _isHovered) ...[
                                const SizedBox(width: 4),
                                Text(
                                  'Details →',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: widget.color,
                                  ),
                                ),
                              ],
                            ],
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
    );
  }
}

class _CustomerActivityMetricDetailsDialog extends StatefulWidget {
  final CustomerActivityMetricType metricType;
  final String timeFilter;
  final ManagerRepository repository;
  final List<CustomerActivity> allCustomers;
  final List<CustomerActivity> filteredCustomers;
  final void Function(CustomerActivity) onMessageCustomer;
  final void Function(CustomerActivity) onFilterTable;

  const _CustomerActivityMetricDetailsDialog({
    required this.metricType,
    required this.timeFilter,
    required this.repository,
    required this.allCustomers,
    required this.filteredCustomers,
    required this.onMessageCustomer,
    required this.onFilterTable,
  });

  @override
  State<_CustomerActivityMetricDetailsDialog> createState() =>
      _CustomerActivityMetricDetailsDialogState();
}

class _CustomerActivityMetricDetailsDialogState
    extends State<_CustomerActivityMetricDetailsDialog> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getTitle() {
    switch (widget.metricType) {
      case CustomerActivityMetricType.onlineUsers:
        return 'Users Online Now (Live Store Telemetry)';
      case CustomerActivityMetricType.newSignups:
        return 'New Customer Signups (${widget.timeFilter})';
      case CustomerActivityMetricType.totalLogins:
        return 'Total Logins & Session Intelligence';
      case CustomerActivityMetricType.avgLogins:
        return 'Average Logins & Session Frequency';
      case CustomerActivityMetricType.retention:
        return 'Customer Retention & Engagement Breakdown';
    }
  }

  String _getSubtitle() {
    switch (widget.metricType) {
      case CustomerActivityMetricType.onlineUsers:
        return 'Real-time storefront visitors and authenticated customers active in the past 45 minutes across all branches.';
      case CustomerActivityMetricType.newSignups:
        return 'Detailed audit of customer accounts registered during the selected ${widget.timeFilter.toLowerCase()} window.';
      case CustomerActivityMetricType.totalLogins:
        return 'Comprehensive authentication volume, session frequency rankings, and active customer device breakdown.';
      case CustomerActivityMetricType.avgLogins:
        return 'Analysis of login frequency tiers, customer return rates, and storefront engagement depth.';
      case CustomerActivityMetricType.retention:
        return 'Loyalty distribution across VIP, Frequent Buyers, Active, and Dormant customer accounts.';
    }
  }

  IconData _getIcon() {
    switch (widget.metricType) {
      case CustomerActivityMetricType.onlineUsers:
        return Icons.sensors_rounded;
      case CustomerActivityMetricType.newSignups:
        return Icons.person_add_alt_1_rounded;
      case CustomerActivityMetricType.totalLogins:
        return Icons.login_rounded;
      case CustomerActivityMetricType.avgLogins:
        return Icons.repeat_rounded;
      case CustomerActivityMetricType.retention:
        return Icons.verified_user_rounded;
    }
  }

  Color _getColor() {
    switch (widget.metricType) {
      case CustomerActivityMetricType.onlineUsers:
        return const Color(0xFF10B981);
      case CustomerActivityMetricType.newSignups:
        return const Color(0xFF1C7BFF);
      case CustomerActivityMetricType.totalLogins:
        return const Color(0xFF059669);
      case CustomerActivityMetricType.avgLogins:
        return const Color(0xFF7C3AED);
      case CustomerActivityMetricType.retention:
        return const Color(0xFFD97706);
    }
  }

  List<CustomerActivity> get _displayedCustomers {
    List<CustomerActivity> baseList;
    switch (widget.metricType) {
      case CustomerActivityMetricType.onlineUsers:
        baseList = widget.allCustomers
            .where((c) =>
                c.isOnline || DateTime.now().difference(c.lastLogin).inMinutes < 45)
            .toList()
          ..sort((a, b) => b.lastLogin.compareTo(a.lastLogin));
        break;
      case CustomerActivityMetricType.newSignups:
        baseList = List<CustomerActivity>.from(widget.filteredCustomers)
          ..sort((a, b) => b.signupDate.compareTo(a.signupDate));
        break;
      case CustomerActivityMetricType.totalLogins:
        baseList = List<CustomerActivity>.from(widget.filteredCustomers)
          ..sort((a, b) => b.loginCount.compareTo(a.loginCount));
        break;
      case CustomerActivityMetricType.avgLogins:
        baseList = List<CustomerActivity>.from(widget.filteredCustomers)
          ..sort((a, b) => b.loginCount.compareTo(a.loginCount));
        if (_selectedCategory == 'Power (10+)') {
          baseList = baseList.where((c) => c.loginCount >= 10).toList();
        } else if (_selectedCategory == 'Regular (3-9)') {
          baseList =
              baseList.where((c) => c.loginCount >= 3 && c.loginCount < 10).toList();
        } else if (_selectedCategory == 'Occasional (1-2)') {
          baseList = baseList.where((c) => c.loginCount <= 2).toList();
        }
        break;
      case CustomerActivityMetricType.retention:
        baseList = List<CustomerActivity>.from(widget.filteredCustomers)
          ..sort((a, b) => b.totalSpend.compareTo(a.totalSpend));
        if (_selectedCategory != 'All') {
          baseList = baseList.where((c) => c.status == _selectedCategory).toList();
        }
        break;
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return baseList;

    return baseList.where((c) {
      return c.fullName.toLowerCase().contains(query) ||
          c.id.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query) ||
          c.primaryDevice.toLowerCase().contains(query) ||
          c.branch.toLowerCase().contains(query);
    }).toList();
  }

  IconData _getDeviceIcon(String device) {
    final d = device.toLowerCase();
    if (d.contains('iphone') || d.contains('ios')) {
      return Icons.phone_iphone_rounded;
    }
    if (d.contains('mac') ||
        d.contains('windows') ||
        d.contains('pc') ||
        d.contains('desktop')) {
      return Icons.laptop_mac_rounded;
    }
    return Icons.phone_android_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final shortDateFormat = DateFormat('MMM dd, yyyy');

    final themeColor = _getColor();
    final displayedList = _displayedCustomers;

    // Calculate metric-specific stats for header pills
    final onlinePool = widget.allCustomers
        .where((c) =>
            c.isOnline || DateTime.now().difference(c.lastLogin).inMinutes < 45)
        .toList();
    final totalInWindow = widget.filteredCustomers.length;
    final totalLogins =
        widget.filteredCustomers.fold<int>(0, (sum, c) => sum + c.loginCount);
    final avgLogins = totalInWindow > 0
        ? (totalLogins / totalInWindow).toStringAsFixed(1)
        : '0';
    final activeCount =
        widget.filteredCustomers.where((c) => c.status != 'Dormant').length;
    final dormantCount = totalInWindow - activeCount;
    final activeRate = totalInWindow > 0
        ? ((activeCount / totalInWindow) * 100).toStringAsFixed(0)
        : '100';

    final totalSpendInWindow = widget.filteredCustomers
        .fold<double>(0.0, (sum, c) => sum + c.totalSpend);

    final powerUsersCount =
        widget.filteredCustomers.where((c) => c.loginCount >= 10).length;
    final regularUsersCount = widget.filteredCustomers
        .where((c) => c.loginCount >= 3 && c.loginCount < 10)
        .length;
    final occasionalUsersCount =
        widget.filteredCustomers.where((c) => c.loginCount <= 2).length;

    CustomerActivity? topActiveCustomer;
    if (widget.filteredCustomers.isNotEmpty) {
      topActiveCustomer = widget.filteredCustomers.reduce(
          (curr, next) => curr.loginCount >= next.loginCount ? curr : next);
    }

    final modalWidth = math.min(880.0, MediaQuery.of(context).size.width * 0.92);
    final modalHeight =
        math.min(740.0, MediaQuery.of(context).size.height * 0.88);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      elevation: 20,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: modalWidth,
          maxHeight: modalHeight,
        ),
        child: Column(
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: themeColor.withValues(alpha: 0.25)),
                    ),
                    child: Icon(_getIcon(), size: 22, color: themeColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (widget.metricType ==
                                CustomerActivityMetricType.onlineUsers) ...[
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                            Flexible(
                              child: Text(
                                _getTitle(),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _getSubtitle(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close details',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Top KPI Summary Cards Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9)),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, kpiConstraints) {
                  List<Widget> kpiWidgets;
                  if (widget.metricType == CustomerActivityMetricType.onlineUsers) {
                    final onlinePct = widget.allCustomers.isNotEmpty
                        ? ((onlinePool.length / widget.allCustomers.length) * 100)
                            .toStringAsFixed(1)
                        : '0';
                    kpiWidgets = [
                      _buildDialogKpiPill(
                        'USERS ONLINE NOW',
                        '${onlinePool.length}',
                        themeColor,
                        showDot: true,
                      ),
                      _buildDialogKpiPill(
                        'TOTAL REGISTERED',
                        '${widget.allCustomers.length}',
                        const Color(0xFF475569),
                      ),
                      _buildDialogKpiPill(
                        'ONLINE SHARE',
                        '$onlinePct%',
                        const Color(0xFF059669),
                      ),
                      _buildDialogKpiPill(
                        'STORE BRANCH',
                        widget.repository.currentBranch,
                        const Color(0xFF1C7BFF),
                      ),
                    ];
                  } else if (widget.metricType == CustomerActivityMetricType.newSignups) {
                    kpiWidgets = [
                      _buildDialogKpiPill(
                        'NEW SIGNUPS',
                        '$totalInWindow',
                        themeColor,
                      ),
                      _buildDialogKpiPill(
                        'WINDOW',
                        widget.timeFilter,
                        const Color(0xFF475569),
                      ),
                      _buildDialogKpiPill(
                        'ENGAGED / VIP',
                        '$activeCount',
                        const Color(0xFF059669),
                      ),
                      _buildDialogKpiPill(
                        'NEW VALUE',
                        currencyFormat.format(totalSpendInWindow),
                        const Color(0xFFD97706),
                      ),
                    ];
                  } else if (widget.metricType == CustomerActivityMetricType.totalLogins) {
                    kpiWidgets = [
                      _buildDialogKpiPill(
                        'TOTAL LOGINS',
                        '$totalLogins',
                        themeColor,
                      ),
                      _buildDialogKpiPill(
                        'AVG PER USER',
                        '$avgLogins / user',
                        const Color(0xFF7C3AED),
                      ),
                      _buildDialogKpiPill(
                        'TOP USER LOGINS',
                        topActiveCustomer != null
                            ? '${topActiveCustomer.loginCount}'
                            : '0',
                        const Color(0xFF059669),
                      ),
                      _buildDialogKpiPill(
                        'ACCOUNTS TRACKED',
                        '$totalInWindow',
                        const Color(0xFF475569),
                      ),
                    ];
                  } else if (widget.metricType == CustomerActivityMetricType.avgLogins) {
                    kpiWidgets = [
                      _buildDialogKpiPill(
                        'AVG LOGINS',
                        '$avgLogins / user',
                        themeColor,
                      ),
                      _buildDialogKpiPill(
                        'POWER USERS (10+)',
                        '$powerUsersCount',
                        const Color(0xFF6D28D9),
                      ),
                      _buildDialogKpiPill(
                        'REGULAR (3-9)',
                        '$regularUsersCount',
                        const Color(0xFF1D4ED8),
                      ),
                      _buildDialogKpiPill(
                        'OCCASIONAL (1-2)',
                        '$occasionalUsersCount',
                        const Color(0xFF64748B),
                      ),
                    ];
                  } else {
                    kpiWidgets = [
                      _buildDialogKpiPill(
                        'RETENTION RATE',
                        '$activeRate%',
                        themeColor,
                      ),
                      _buildDialogKpiPill(
                        'ACTIVE & VIP',
                        '$activeCount',
                        const Color(0xFF059669),
                      ),
                      _buildDialogKpiPill(
                        'DORMANT ACCOUNTS',
                        '$dormantCount',
                        const Color(0xFFEF4444),
                      ),
                      _buildDialogKpiPill(
                        'TOTAL EVALUATED',
                        '$totalInWindow',
                        const Color(0xFF475569),
                      ),
                    ];
                  }

                  if (kpiConstraints.maxWidth < 650) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kpiWidgets,
                    );
                  }

                  return Row(
                    children: [
                      for (int i = 0; i < kpiWidgets.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: kpiWidgets[i]),
                      ],
                    ],
                  );
                },
              ),
            ),

            // Filter and Search Toolbar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText:
                            'Search customer by ID, name, phone, email, device, or branch...',
                        hintStyle:
                            const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: Color(0xFF64748B)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
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
                          borderSide:
                              BorderSide(color: themeColor, width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  // Category filter chips for Avg Logins
                  if (widget.metricType ==
                      CustomerActivityMetricType.avgLogins) ...[
                    const SizedBox(width: 12),
                    Wrap(
                      spacing: 6,
                      children: [
                        'All',
                        'Power (10+)',
                        'Regular (3-9)',
                        'Occasional (1-2)'
                      ].map((cat) {
                        final isSel = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategory = cat);
                          },
                          backgroundColor: const Color(0xFFF1F5F9),
                          selectedColor: themeColor.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? themeColor : const Color(0xFF475569),
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          side: BorderSide(
                            color: isSel
                                ? themeColor
                                : const Color(0xFFE2E8F0),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Category filter chips for Retention
                  if (widget.metricType ==
                      CustomerActivityMetricType.retention) ...[
                    const SizedBox(width: 12),
                    Wrap(
                      spacing: 6,
                      children: [
                        'All',
                        'VIP Customer',
                        'Frequent Buyer',
                        'Active',
                        'Dormant'
                      ].map((cat) {
                        final isSel = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategory = cat);
                          },
                          backgroundColor: const Color(0xFFF1F5F9),
                          selectedColor: themeColor.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? themeColor : const Color(0xFF475569),
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          side: BorderSide(
                            color: isSel
                                ? themeColor
                                : const Color(0xFFE2E8F0),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Scrollable Customer List
            Expanded(
              child: displayedList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_rounded,
                                size: 50, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No matching customer records found',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try adjusting your search query or segment filters.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 8),
                        itemCount: displayedList.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final c = displayedList[index];
                          final isOnline = c.isOnline ||
                              DateTime.now()
                                      .difference(c.lastLogin)
                                      .inMinutes <
                                  45;

                          final initials = c.fullName.trim().split(' ').length > 1
                              ? '${c.fullName.trim().split(' ')[0][0]}${c.fullName.trim().split(' ')[1][0]}'
                              : c.fullName.isNotEmpty
                                  ? c.fullName.substring(0, 1)
                                  : 'C';

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFCFF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Rank / Avatar with Online dot
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          themeColor.withValues(alpha: 0.12),
                                      child: Text(
                                        initials.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: themeColor,
                                        ),
                                      ),
                                    ),
                                    if (isOnline)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 14),

                                // Main Customer Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Name + Customer ID + Status Chip
                                      Row(
                                        children: [
                                          Text(
                                            c.fullName,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                  color: const Color(0xFFDBEAFE)),
                                            ),
                                            child: Text(
                                              c.id,
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1D4ED8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          _buildStatusBadge(c.status),
                                        ],
                                      ),
                                      const SizedBox(height: 5),

                                      // Phone, Email, Device, Branch
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.phone_rounded,
                                                  size: 13,
                                                  color: Color(0xFF64748B)),
                                              const SizedBox(width: 4),
                                              Text(
                                                c.phone,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Color(0xFF475569),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.email_outlined,
                                                  size: 13,
                                                  color: Color(0xFF64748B)),
                                              const SizedBox(width: 4),
                                              Text(
                                                c.email,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Color(0xFF475569),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getDeviceIcon(c.primaryDevice),
                                                size: 13,
                                                color: const Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                c.primaryDevice,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Color(0xFF475569),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.storefront_rounded,
                                                  size: 13,
                                                  color: Color(0xFF64748B)),
                                              const SizedBox(width: 4),
                                              Text(
                                                c.branch,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // Metric Context Pill
                                      _buildMetricContextBadge(
                                        customer: c,
                                        index: index,
                                        metricType: widget.metricType,
                                        dateFormat: dateFormat,
                                        shortDateFormat: shortDateFormat,
                                        currencyFormat: currencyFormat,
                                        avgLoginsNum: double.tryParse(avgLogins) ?? 0,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Action Buttons
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1C7BFF),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 7),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 13),
                                      label: const Text(
                                        'Message',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      onPressed: () =>
                                          widget.onMessageCustomer(c),
                                    ),
                                    const SizedBox(height: 6),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF475569),
                                        side: const BorderSide(
                                            color: Color(0xFFCBD5E1)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 9, vertical: 6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                      icon: const Icon(Icons.filter_list_rounded,
                                          size: 13),
                                      label: const Text(
                                        'Focus Table',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onPressed: () =>
                                          widget.onFilterTable(c),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${displayedList.length} customer records',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Close Details'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogKpiPill(
    String label,
    String value,
    Color color, {
    bool showDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (showDot) ...[
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    if (status == 'VIP Customer') {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFB45309);
    } else if (status == 'Frequent Buyer') {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF15803D);
    } else if (status == 'Active') {
      bg = const Color(0xFFEFF6FF);
      text = const Color(0xFF1D4ED8);
    } else {
      bg = const Color(0xFFF1F5F9);
      text = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  Widget _buildMetricContextBadge({
    required CustomerActivity customer,
    required int index,
    required CustomerActivityMetricType metricType,
    required DateFormat dateFormat,
    required DateFormat shortDateFormat,
    required NumberFormat currencyFormat,
    required double avgLoginsNum,
  }) {
    Color bg;
    Color border;
    Color textColor;
    IconData icon;
    String text;

    switch (metricType) {
      case CustomerActivityMetricType.onlineUsers:
        bg = const Color(0xFFECFDF5);
        border = const Color(0xFFA7F3D0);
        textColor = const Color(0xFF065F46);
        icon = Icons.sensors_rounded;
        text = 'Active store browsing session • Last active ${dateFormat.format(customer.lastLogin)}';
        break;
      case CustomerActivityMetricType.newSignups:
        bg = const Color(0xFFEFF6FF);
        border = const Color(0xFFBFDBFE);
        textColor = const Color(0xFF1E40AF);
        icon = Icons.person_add_alt_1_rounded;
        text = 'Registered on ${dateFormat.format(customer.signupDate)} • Lifetime Spend: ${currencyFormat.format(customer.totalSpend)}';
        break;
      case CustomerActivityMetricType.totalLogins:
        final isTop = index < 3;
        bg = isTop ? const Color(0xFFFEF3C7) : const Color(0xFFF0FDF4);
        border = isTop ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0);
        textColor = isTop ? const Color(0xFF92400E) : const Color(0xFF166534);
        icon = isTop ? Icons.emoji_events_rounded : Icons.login_rounded;
        text = 'Rank #${index + 1} • ${customer.loginCount} Logins Recorded • Last session: ${dateFormat.format(customer.lastLogin)}';
        break;
      case CustomerActivityMetricType.avgLogins:
        final diff = customer.loginCount - avgLoginsNum;
        final diffStr = diff >= 0
            ? '+${diff.toStringAsFixed(1)} above avg'
            : '${diff.toStringAsFixed(1)} below avg';
        bg = const Color(0xFFF5F3FF);
        border = const Color(0xFFDDD6FE);
        textColor = const Color(0xFF5B21B6);
        icon = Icons.repeat_rounded;
        text = '${customer.loginCount} logins ($diffStr) • Last: ${shortDateFormat.format(customer.lastLogin)}';
        break;
      case CustomerActivityMetricType.retention:
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        textColor = const Color(0xFF92400E);
        icon = Icons.verified_user_rounded;
        text = '${customer.status} • Total Spend: ${currencyFormat.format(customer.totalSpend)} (${customer.totalOrders} orders) • ${customer.loginCount} logins';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

