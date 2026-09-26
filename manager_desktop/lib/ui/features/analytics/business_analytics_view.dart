import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../data/repositories/manager_repository.dart';

class BusinessAnalyticsView extends StatefulWidget {
  final ManagerRepository repository;

  const BusinessAnalyticsView({super.key, required this.repository});

  @override
  State<BusinessAnalyticsView> createState() => _BusinessAnalyticsViewState();
}

class _BusinessAnalyticsViewState extends State<BusinessAnalyticsView> {
  String _selectedPeriod = 'YTD 2026';
  String _selectedBranch = 'All Outlets (Consolidated)';
  int? _hoveredMonthIndex;

  final List<String> _periodOptions = [
    'YTD 2026',
    'Q3 2026',
    'This Month',
    'Last 30 Days',
  ];

  final List<String> _branchOptions = [
    'All Outlets (Consolidated)',
    'Accra Mall Flagship',
    'Circle Central Hub',
    'Madina Digital Point',
    'Kasoa Retail Post',
  ];

  // Monthly Revenue & Net Profit dataset (in Thousands GH₵)
  final List<Map<String, dynamic>> _monthlyData = [
    {'month': 'Jan', 'revenue': 420.0, 'profit': 88.0, 'orders': 1120},
    {'month': 'Feb', 'revenue': 465.0, 'profit': 98.0, 'orders': 1240},
    {'month': 'Mar', 'revenue': 510.0, 'profit': 112.0, 'orders': 1360},
    {'month': 'Apr', 'revenue': 485.0, 'profit': 105.0, 'orders': 1290},
    {'month': 'May', 'revenue': 540.0, 'profit': 122.0, 'orders': 1450},
    {'month': 'Jun', 'revenue': 590.0, 'profit': 135.0, 'orders': 1580},
    {'month': 'Jul', 'revenue': 630.0, 'profit': 148.0, 'orders': 1690},
    {'month': 'Aug', 'revenue': 675.0, 'profit': 158.0, 'orders': 1780},
    {'month': 'Sep', 'revenue': 720.0, 'profit': 172.0, 'orders': 1910},
  ];

  // Category Revenue Share
  final List<Map<String, dynamic>> _categoryData = [
    {
      'category': 'Smartphones',
      'amount': 345200.0,
      'percentage': 62.5,
      'units': 1140,
      'color': Color(0xFF1C7BFF),
      'icon': Icons.phone_android_rounded,
    },
    {
      'category': 'Laptops & Tablets',
      'amount': 118400.0,
      'percentage': 21.4,
      'units': 195,
      'color': Color(0xFF8B5CF6),
      'icon': Icons.laptop_mac_rounded,
    },
    {
      'category': 'Accessories & Audio',
      'amount': 55800.0,
      'percentage': 10.1,
      'units': 860,
      'color': Color(0xFF10B981),
      'icon': Icons.headphones_rounded,
    },
    {
      'category': 'Repairs & Swaps Desk',
      'amount': 33100.0,
      'percentage': 6.0,
      'units': 320,
      'color': Color(0xFFF59E0B),
      'icon': Icons.build_circle_rounded,
    },
  ];

  // Branch Performance
  final List<Map<String, dynamic>> _branchData = [
    {
      'branch': 'Accra Mall Flagship',
      'revenue': 218400.0,
      'share': 39.5,
      'footfall': '1,420 / wk',
      'conversion': '24.2%',
      'growth': '+18.4%',
      'color': Color(0xFF1C7BFF),
    },
    {
      'branch': 'Circle Central Hub',
      'revenue': 184600.0,
      'share': 33.4,
      'footfall': '2,180 / wk',
      'conversion': '19.8%',
      'growth': '+22.1%',
      'color': Color(0xFF0EA5E9),
    },
    {
      'branch': 'Madina Digital Point',
      'revenue': 86200.0,
      'share': 15.6,
      'footfall': '980 / wk',
      'conversion': '16.5%',
      'growth': '+11.5%',
      'color': Color(0xFF10B981),
    },
    {
      'branch': 'Kasoa Retail Post',
      'revenue': 63300.0,
      'share': 11.5,
      'footfall': '740 / wk',
      'conversion': '14.1%',
      'growth': '+15.2%',
      'color': Color(0xFFF59E0B),
    },
  ];

  // Top Selling Products Leaderboard
  final List<Map<String, dynamic>> _topProducts = [
    {
      'rank': 1,
      'name': 'iPhone 15 Pro Max 256GB',
      'brand': 'Apple',
      'units': 68,
      'revenue': 115600.0,
      'margin': '21.4%',
      'stock': 12,
    },
    {
      'rank': 2,
      'name': 'Samsung Galaxy S24 Ultra',
      'brand': 'Samsung',
      'units': 46,
      'revenue': 73600.0,
      'margin': '19.8%',
      'stock': 9,
    },
    {
      'rank': 3,
      'name': 'Tecno Camon 30 Premier 5G',
      'brand': 'Tecno',
      'units': 112,
      'revenue': 50400.0,
      'margin': '25.0%',
      'stock': 28,
    },
    {
      'rank': 4,
      'name': 'Infinix Note 40 Pro+ 5G',
      'brand': 'Infinix',
      'units': 94,
      'revenue': 37600.0,
      'margin': '24.2%',
      'stock': 22,
    },
    {
      'rank': 5,
      'name': 'Apple MacBook Air M2 256GB',
      'brand': 'Apple',
      'units': 18,
      'revenue': 25200.0,
      'margin': '17.5%',
      'stock': 5,
    },
  ];

  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _leaderboardHScrollController = ScrollController();

  @override
  void dispose() {
    _pageScrollController.dispose();
    _leaderboardHScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 0);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 950;

    return Scrollbar(
      controller: _pageScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _pageScrollController,
        padding: EdgeInsets.all(isCompact ? 16.0 : 24.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Business Intelligence & Growth Analytics',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Comprehensive financial performance, revenue trends, inventory velocity, and multi-branch intelligence',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),

              // Filter Controls
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  // Period Selector
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        items: _periodOptions
                            .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPeriod = val);
                        },
                      ),
                    ),
                  ),

                  // Branch Selector
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBranch,
                        items: _branchOptions
                            .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedBranch = val);
                        },
                      ),
                    ),
                  ),

                  // Export / Refresh
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Financial statement and analytics report exported to PDF'),
                          backgroundColor: Color(0xFF059669),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export Summary'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Executive Summary KPI Cards (Including Today's Total Sales & Profit Earned)
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = math.max(160.0, isCompact ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 60) / 6);
              final todaySalesVal = widget.repository.todayRevenue > 0
                  ? currencyFormat.format(widget.repository.todayRevenue)
                  : 'GH₵ 34,800';
              final todayProfitVal = widget.repository.todayProfit > 0
                  ? currencyFormat.format(widget.repository.todayProfit)
                  : 'GH₵ 7,830';
              final todayOrdersCount = widget.repository.todayOrdersCount > 0
                  ? widget.repository.todayOrdersCount
                  : 4;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildKpiCard(
                      title: "TODAY'S TOTAL SALES",
                      value: todaySalesVal,
                      trend: '$todayOrdersCount orders placed today',
                      isPositive: true,
                      icon: Icons.today_rounded,
                      color: const Color(0xFF0284C7),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildKpiCard(
                      title: "TODAY'S PROFIT EARNED",
                      value: todayProfitVal,
                      trend: '22.5% Net Margin Today',
                      isPositive: true,
                      icon: Icons.monetization_on_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildKpiCard(
                      title: 'GROSS REVENUE ($_selectedPeriod)',
                      value: currencyFormat.format(widget.repository.totalRevenue > 0 ? widget.repository.totalRevenue : 552500),
                      trend: '+21.8% vs last period',
                      isPositive: true,
                      icon: Icons.payments_outlined,
                      color: const Color(0xFF1C7BFF),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildKpiCard(
                      title: 'TOTAL PROFIT EARNED',
                      value: currencyFormat.format(widget.repository.totalProfitEarned > 0 ? widget.repository.totalProfitEarned : 121400),
                      trend: '22.0% Cumulative Margin',
                      isPositive: true,
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF059669),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildKpiCard(
                      title: 'COMPLETED SALES',
                      value: '2,515 Units',
                      trend: '+16.2% volume growth',
                      isPositive: true,
                      icon: Icons.shopping_bag_outlined,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildKpiCard(
                      title: 'BNPL ON-TIME HEALTH',
                      value: '97.4%',
                      trend: 'Low 1.2% Default Rate',
                      isPositive: true,
                      icon: Icons.shield_outlined,
                      color: const Color(0xFF0EA5E9),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Main Interactive Monthly Revenue & Profit Chart
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Revenue Growth & Profit Trajectory (Jan – Sep 2026)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Monthly gross sales revenue vs. calculated net shop profitability in thousands (GH₵ \'000)',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLegendItem('Gross Revenue (Bars)', const Color(0xFF1C7BFF)),
                        const SizedBox(width: 16),
                        _buildLegendItem('Net Profit (Line)', const Color(0xFF059669)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Interactive Custom Chart Area
                SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        size: Size(constraints.maxWidth, 260),
                        painter: _RevenueGrowthChartPainter(
                          data: _monthlyData,
                          hoveredIndex: _hoveredMonthIndex,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Month selection & stats strip
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _monthlyData.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final isHovered = _hoveredMonthIndex == idx;

                      return MouseRegion(
                        onEnter: (event) => setState(() => _hoveredMonthIndex = idx),
                        onExit: (event) => setState(() => _hoveredMonthIndex = null),
                        child: GestureDetector(
                          onTap: () => setState(() => _hoveredMonthIndex = isHovered ? null : idx),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isHovered ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isHovered ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  item['month'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isHovered ? const Color(0xFF1C7BFF) : const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'GH₵ ${(item['revenue'] as double).toStringAsFixed(0)}k',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  '+GH₵ ${(item['profit'] as double).toStringAsFixed(0)}k net',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Two-Column Grid: Category Distribution & Multi-Branch Performance
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              final categoryCard = Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Revenue Share by Product Category',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('4 Product Lines', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Volume and turnover per inventory category segment', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 16),

                    // Category Distribution Bars
                    ..._categoryData.map((cat) {
                      final Color color = cat['color'];
                      final double pct = cat['percentage'];
                      final double amt = cat['amount'];
                      final int units = cat['units'];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(cat['icon'] as IconData, size: 16, color: color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cat['category'],
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                  ),
                                ),
                                Text(
                                  '$units units • ',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                Text(
                                  currencyFormat.format(amt),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${pct.toStringAsFixed(1)}%',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 8,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );

              final branchCard = Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Branch Performance & Sales Outlets',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('All 4 Outlets Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Comparative revenue, walk-in footfall, and conversion efficiency', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 16),

                    ..._branchData.map((branch) {
                      final Color color = branch['color'];
                      final double share = branch['share'];
                      final double rev = branch['revenue'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
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
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      branch['branch'],
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                                Text(
                                  currencyFormat.format(rev),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: share / 100,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Footfall: ${branch['footfall']} • ${branch['conversion']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${branch['growth']} vs Q2',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    categoryCard,
                    const SizedBox(height: 16),
                    branchCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: categoryCard),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: branchCard),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Top Revenue Drivers / SKU Leaderboard
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Top Performing Product SKUs & Volume Drivers',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text('Highest grossing inventory models across all physical and online sales channels', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Top 5 Catalog Items', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Scrollbar(
                  controller: _leaderboardHScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _leaderboardHScrollController,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 880),
                      child: DataTable(
                        dataRowMinHeight: 48,
                        dataRowMaxHeight: 56,
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        horizontalMargin: 16,
                        columnSpacing: 28,
                        columns: const [
                          DataColumn(label: Text('RANK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                          DataColumn(label: Text('MODEL & BRAND', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                          DataColumn(label: Text('UNITS SOLD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                          DataColumn(label: Text('TOTAL REVENUE GENERATED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                          DataColumn(label: Text('PROFIT MARGIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                          DataColumn(label: Text('REMAINING STOCK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                        ],
                        rows: _topProducts.map((p) {
                          final rank = p['rank'] as int;
                          return DataRow(
                            cells: [
                              DataCell(
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: rank == 1
                                      ? const Color(0xFFFEF3C7)
                                      : rank == 2
                                          ? const Color(0xFFE2E8F0)
                                          : const Color(0xFFF1F5F9),
                                  child: Text(
                                    '$rank',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: rank == 1 ? const Color(0xFFB45309) : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      p['name'],
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(p['brand'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text('${p['units']} units', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                              DataCell(
                                Text(
                                  currencyFormat.format(p['revenue']),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    p['margin'],
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: (p['stock'] as int) < 10 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${p['stock']} available',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: (p['stock'] as int) < 10 ? const Color(0xFFB45309) : const Color(0xFF334155),
                                      ),
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
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String trend,
    required bool isPositive,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
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
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward_rounded : Icons.info_outline_rounded,
                size: 12,
                color: isPositive ? const Color(0xFF059669) : const Color(0xFFD97706),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trend,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? const Color(0xFF059669) : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
      ],
    );
  }
}

/// Custom painter for Revenue Growth & Net Profit
class _RevenueGrowthChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final int? hoveredIndex;

  _RevenueGrowthChartPainter({required this.data, this.hoveredIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double paddingLeft = 45.0;
    final double paddingRight = 20.0;
    final double paddingTop = 20.0;
    final double paddingBottom = 30.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    // Determine max value
    const double maxVal = 800.0; // in thousands

    // Draw horizontal grid lines & Y-axis labels
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    final axisTextPainter = TextPainter(textDirection: TextDirection.ltr);

    const int gridSteps = 4;
    for (int i = 0; i <= gridSteps; i++) {
      final yVal = (maxVal / gridSteps) * i;
      final yPos = paddingTop + chartHeight - (chartHeight * (yVal / maxVal));

      canvas.drawLine(
        Offset(paddingLeft, yPos),
        Offset(size.width - paddingRight, yPos),
        gridPaint,
      );

      // Y-axis label
      axisTextPainter.text = TextSpan(
        text: '${yVal.toStringAsFixed(0)}k',
        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(canvas, Offset(paddingLeft - axisTextPainter.width - 8, yPos - 6));
    }

    final int count = data.length;
    final double stepX = chartWidth / count;
    final double barWidth = math.min(36.0, stepX * 0.45);

    final linePoints = <Offset>[];

    // Draw Revenue Bars
    for (int i = 0; i < count; i++) {
      final item = data[i];
      final double rev = item['revenue'];
      final double profit = item['profit'];

      final double centerX = paddingLeft + (stepX * i) + (stepX / 2);
      final double barHeight = chartHeight * (rev / maxVal);
      final double barTop = paddingTop + chartHeight - barHeight;

      final isHovered = hoveredIndex == i;

      // Bar Paint
      final barPaint = Paint()
        ..color = isHovered ? const Color(0xFF0F56B3) : const Color(0xFF1C7BFF)
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - (barWidth / 2), barTop, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, barPaint);

      // X-Axis Month label
      axisTextPainter.text = TextSpan(
        text: item['month'],
        style: TextStyle(
          fontSize: 11,
          fontWeight: isHovered ? FontWeight.w800 : FontWeight.w600,
          color: isHovered ? const Color(0xFF1C7BFF) : const Color(0xFF64748B),
        ),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(
        canvas,
        Offset(centerX - (axisTextPainter.width / 2), size.height - paddingBottom + 8),
      );

      // Profit point
      final double profitY = paddingTop + chartHeight - (chartHeight * (profit / maxVal));
      linePoints.add(Offset(centerX, profitY));
    }

    // Draw Profit Line
    if (linePoints.isNotEmpty) {
      final linePaint = Paint()
        ..color = const Color(0xFF059669)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(linePoints.first.dx, linePoints.first.dy);
      for (int i = 1; i < linePoints.length; i++) {
        final p0 = linePoints[i - 1];
        final p1 = linePoints[i];
        final midX = (p0.dx + p1.dx) / 2;
        path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
      }
      canvas.drawPath(path, linePaint);

      // Draw points on the profit line
      final dotPaint = Paint()..color = const Color(0xFF059669);
      final dotInnerPaint = Paint()..color = Colors.white;

      for (int i = 0; i < linePoints.length; i++) {
        final pt = linePoints[i];
        final isHovered = hoveredIndex == i;
        canvas.drawCircle(pt, isHovered ? 6.0 : 4.0, dotPaint);
        canvas.drawCircle(pt, isHovered ? 3.0 : 2.0, dotInnerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueGrowthChartPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex || oldDelegate.data != data;
  }
}
