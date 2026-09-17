import 'package:flutter/material.dart';
import '../../../data/services/dialer_service.dart';
import '../../../domain/models/swap_model.dart';
import 'tradein_view_model.dart';

class DevicesSwappedView extends StatefulWidget {
  final TradeInViewModel viewModel;
  final VoidCallback onInitiateNewSwap;

  const DevicesSwappedView({
    super.key,
    required this.viewModel,
    required this.onInitiateNewSwap,
  });

  @override
  State<DevicesSwappedView> createState() => _DevicesSwappedViewState();
}

class _DevicesSwappedViewState extends State<DevicesSwappedView> {
  String _selectedFilter = 'All';

  Future<void> _callManager(BuildContext context) async {
    final success = await DialerService.openDialer('+2330245550192');
    if (success) return;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Store Manager number: +233 (024) 555-0192',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('completed') || s.contains('swapped') || s.contains('done')) {
      return const Color(0xFF16A34A);
    }
    if (s.contains('approved') || s.contains('ready')) {
      return const Color(0xFF1C7BFF);
    }
    return const Color(0xFFD97706);
  }

  Color _getStatusBg(String status) {
    final s = status.toLowerCase();
    if (s.contains('completed') || s.contains('swapped') || s.contains('done')) {
      return const Color(0xFFDCFCE7);
    }
    if (s.contains('approved') || s.contains('ready')) {
      return const Color(0xFFEFF6FF);
    }
    return const Color(0xFFFEF3C7);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final swaps = widget.viewModel.swapApplications;

        final filtered = swaps.where((s) {
          if (_selectedFilter == 'All') return true;
          if (_selectedFilter == 'Completed') {
            return s.status.toLowerCase().contains('completed') ||
                s.status.toLowerCase().contains('swapped');
          }
          if (_selectedFilter == 'Under Review') {
            return s.status.toLowerCase().contains('review');
          }
          return true;
        }).toList();

        final completedCount = swaps
            .where((s) =>
                s.status.toLowerCase().contains('completed') ||
                s.status.toLowerCase().contains('swapped'))
            .length;
        final reviewCount = swaps.length - completedCount;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1E293B), size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Devices Swapped',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'All device swaps initiated or completed',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Call Store Manager',
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const Icon(Icons.phone_outlined,
                      color: Color(0xFF1C7BFF), size: 18),
                ),
                onPressed: () => _callManager(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
              // Summary stats card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildStatItem('Total Swaps', swaps.length.toString(), const Color(0xFF60A5FA)),
                    _buildStatDivider(),
                    _buildStatItem('Under Review', reviewCount.toString(), const Color(0xFFFBBF24)),
                    _buildStatDivider(),
                    _buildStatItem('Completed', completedCount.toString(), const Color(0xFF4ADE80)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Filter pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', swaps.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Under Review', reviewCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', completedCount),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.swap_horiz_rounded,
                          size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text(
                        'No swap requests in this category',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Want to upgrade your phone? Pick the device you want, tell us what you have, and our Store Manager will quote you the best trade-in deal!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C7BFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: widget.onInitiateNewSwap,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Initiate a Swap Now'),
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map((s) => _buildSwapCard(context, s)),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C7BFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: widget.onInitiateNewSwap,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                  label: const Text(
                    'Initiate New Device Swap',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1C7BFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 26,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  Widget _buildSwapCard(BuildContext context, SwapApplication app) {
    final statusColor = _getStatusColor(app.status);
    final statusBg = _getStatusBg(app.status);
    final isCompleted = app.status.toLowerCase().contains('completed') ||
        app.status.toLowerCase().contains('swapped');

    final wantedTitle = app.desiredModel.toLowerCase().startsWith(app.desiredBrand.toLowerCase())
        ? app.desiredModel
        : '${app.desiredBrand} ${app.desiredModel}';

    final swappedTitle = app.currentModel.toLowerCase().startsWith(app.currentBrand.toLowerCase())
        ? app.currentModel
        : '${app.currentBrand} ${app.currentModel}';

    final dateStr = '${app.createdAt.day}/${app.createdAt.month}/${app.createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: ID & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded,
                        size: 18, color: Color(0xFF1C7BFF)),
                    const SizedBox(width: 6),
                    Text(
                      app.id,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        size: 11,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        app.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Wanted Device Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smartphone_rounded,
                      color: Color(0xFF16A34A), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phone Wanted (Target Device):',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          wantedTitle,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${app.desiredStorage} • ${app.desiredRam} • ${app.desiredCondition}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Swapped Device Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horizontal_circle_outlined,
                      color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phone Swapped / Traded-In:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          swappedTitle,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${app.currentStorage} • ${app.currentCondition}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Cost & Valuation Notice (No artificial prices!)
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_pin_rounded,
                      size: 16, color: Color(0xFF1C7BFF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCompleted
                          ? 'Swap completed at ${app.preferredBranch}.'
                          : 'Manager will contact you via phone/WhatsApp with final trade-in valuation & top-up cost.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFFF1F5F9), height: 16),

            // Branch, Date, and Call Manager action
            Row(
              children: [
                const Icon(Icons.storefront_rounded,
                    size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    app.preferredBranch,
                    style:
                        const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  dateStr,
                  style:
                      const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 30),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _callManager(context),
                  icon: const Icon(Icons.phone_rounded,
                      size: 12, color: Color(0xFF1C7BFF)),
                  label: const Text(
                    'Call Manager',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C7BFF),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
