import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/manager_repository.dart';
import '../../../domain/models/customer_activity.dart';
import '../../../domain/models/customer_message.dart';

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
  DateTime? _customSelectedDate;

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
    'Custom Date...',
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

    if (_timeFilter == 'Custom Date...' && _customSelectedDate != null) {
      final start = DateTime(_customSelectedDate!.year, _customSelectedDate!.month, _customSelectedDate!.day);
      final end = start.add(const Duration(days: 1));
      return date.isAfter(start) && date.isBefore(end);
    }

    return true;
  }

  List<CustomerActivity> _getFilteredCustomers() {
    return widget.repository.customers.where((cust) {
      if (!_matchesTimeFilter(cust.signupDate)) return false;

      if (_statusFilter != 'All' && cust.status != _statusFilter) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = cust.fullName.toLowerCase().contains(q);
        final matchesPhone = cust.phone.toLowerCase().contains(q);
        final matchesEmail = cust.email.toLowerCase().contains(q);
        final matchesDevice = cust.primaryDevice.toLowerCase().contains(q);
        return matchesName || matchesPhone || matchesEmail || matchesDevice;
      }

      return true;
    }).toList();
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

              // Time filter picker buttons
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
                      final isSel = _timeFilter == tf;
                      return InkWell(
                        onTap: () async {
                          if (tf == 'Custom Date...') {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _customSelectedDate ?? DateTime.now(),
                              firstDate: DateTime(2025),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _customSelectedDate = picked;
                                _timeFilter = tf;
                              });
                            }
                          } else {
                            setState(() {
                              _timeFilter = tf;
                              _customSelectedDate = null;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF1C7BFF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tf == 'Custom Date...' && _customSelectedDate != null
                                ? shortDateFormat.format(_customSelectedDate!)
                                : tf,
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
                ),
                _buildMetricCard(
                  label: 'NEW SIGNUPS (${_timeFilter.toUpperCase()})',
                  value: '$totalSignups',
                  subtext: 'Registered accounts in window',
                  icon: Icons.person_add_alt_1_rounded,
                  color: const Color(0xFF1C7BFF),
                ),
                _buildMetricCard(
                  label: 'TOTAL LOGINS RECORDED',
                  value: '$totalLogins',
                  subtext: 'Active authentication sessions',
                  icon: Icons.login_rounded,
                  color: const Color(0xFF059669),
                ),
                _buildMetricCard(
                  label: 'AVG LOGINS PER USER',
                  value: avgLogins,
                  subtext: 'Session frequency per customer',
                  icon: Icons.repeat_rounded,
                  color: const Color(0xFF7C3AED),
                ),
                _buildMetricCard(
                  label: 'ENGAGED RETENTION',
                  value: '$activeRate%',
                  subtext: '$activeCount active / VIP customers',
                  icon: Icons.verified_user_rounded,
                  color: const Color(0xFFD97706),
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
                          hintText: 'Search customers by name, phone (+233...), email, or device...',
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
                            hintText: 'Search customers by name, phone (+233...), email, or device...',
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
                        final tableMinWidth = math.max(1400.0, availableWidth);

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

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    bool showLiveDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (showLiveDot) ...[
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
                        label,
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
                  ],
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
                const SizedBox(height: 2),
                Text(
                  subtext,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
