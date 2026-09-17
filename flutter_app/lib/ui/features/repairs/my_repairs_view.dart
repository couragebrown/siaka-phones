import 'package:flutter/material.dart';
import '../../../data/services/dialer_service.dart';
import '../../../domain/models/repair_booking.dart';
import 'repairs_view_model.dart';

class MyRepairsView extends StatefulWidget {
  final RepairsViewModel viewModel;
  final VoidCallback onBookNewRepair;

  const MyRepairsView({
    super.key,
    required this.viewModel,
    required this.onBookNewRepair,
  });

  @override
  State<MyRepairsView> createState() => _MyRepairsViewState();
}

class _MyRepairsViewState extends State<MyRepairsView> {
  String _selectedFilter = 'All';

  Future<void> _callTechnician(BuildContext context) async {
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
                'Customer service: +233 (024) 555-0192',
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
    if (s.contains('completed') || s.contains('fixed') || s.contains('done')) {
      return const Color(0xFF16A34A);
    }
    if (s.contains('progress') || s.contains('diagnostic')) {
      return const Color(0xFF1C7BFF);
    }
    return const Color(0xFFD97706);
  }

  Color _getStatusBg(String status) {
    final s = status.toLowerCase();
    if (s.contains('completed') || s.contains('fixed') || s.contains('done')) {
      return const Color(0xFFDCFCE7);
    }
    if (s.contains('progress') || s.contains('diagnostic')) {
      return const Color(0xFFEFF6FF);
    }
    return const Color(0xFFFEF3C7);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        // Read bookings from lastBooking and seeded history
        final bookings = <RepairBooking>[
          if (widget.viewModel.lastBooking != null) widget.viewModel.lastBooking!,
          ...RepairBookingSamples.defaults.where(
            (b) => widget.viewModel.lastBooking?.id != b.id,
          ),
        ];

        final filtered = bookings.where((b) {
          if (_selectedFilter == 'All') return true;
          if (_selectedFilter == 'Completed') {
            return b.status.toLowerCase().contains('completed');
          }
          if (_selectedFilter == 'In Progress / Initiated') {
            return !b.status.toLowerCase().contains('completed');
          }
          return true;
        }).toList();

        final completedCount = bookings.where((b) => b.status.toLowerCase().contains('completed')).length;
        final activeCount = bookings.length - completedCount;

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
                  'My Repairs',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Repairs initiated or completed at Siaka Phones',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Call Support Team',
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
                onPressed: () => _callTechnician(context),
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
                    _buildStatItem('Total Repairs', bookings.length.toString(), const Color(0xFF60A5FA)),
                    _buildStatDivider(),
                    _buildStatItem('In Progress', activeCount.toString(), const Color(0xFFFBBF24)),
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
                    _buildFilterChip('All', bookings.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('In Progress / Initiated', activeCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', completedCount),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Repair list
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
                      const Icon(Icons.build_circle_outlined,
                          size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text(
                        'No repairs found in this category',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Need your screen, battery, or phone fixed? Book a service appointment with our certified technician team.',
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
                        onPressed: widget.onBookNewRepair,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Book a Repair Now'),
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map((b) => _buildRepairCard(context, b)),

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
                  onPressed: widget.onBookNewRepair,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text(
                    'Book a New Device Repair',
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

  Widget _buildRepairCard(BuildContext context, RepairBooking booking) {
    final statusColor = _getStatusColor(booking.status);
    final statusBg = _getStatusBg(booking.status);
    final isCompleted = booking.status.toLowerCase().contains('completed');

    final dateStr =
        '${booking.appointmentDate.day}/${booking.appointmentDate.month}/${booking.appointmentDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            // Top Row: ID & Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.build_outlined,
                        size: 16, color: Color(0xFF1C7BFF)),
                    const SizedBox(width: 6),
                    Text(
                      booking.id,
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
                            : Icons.access_time_filled_rounded,
                        size: 11,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.status,
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
            const SizedBox(height: 10),

            // Device Model & Issue
            Text(
              booking.deviceModel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                booking.issueType,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Description note
            if (booking.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  booking.description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),

            const Divider(color: Color(0xFFF1F5F9), height: 16),

            // Branch & Date metadata
            Row(
              children: [
                const Icon(Icons.storefront_rounded,
                    size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.dropOffBranch ?? 'Siaka Phones Circle',
                    style:
                        const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.calendar_today_rounded,
                    size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style:
                      const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 32),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _callTechnician(context),
                  icon: const Icon(Icons.phone_rounded,
                      size: 13, color: Color(0xFF1C7BFF)),
                  label: const Text(
                    'Call Support',
                    style: TextStyle(
                      fontSize: 11.5,
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

class RepairBookingSamples {
  static final defaults = [
    RepairBooking(
      id: 'REP-GH-8219',
      deviceModel: 'Samsung Galaxy S22 Ultra',
      issueType: 'Screen Replacement / AMOLED Crack',
      description: 'Front glass cracked, display touch working. Genuine replacement requested.',
      dropOffBranch: 'Siaka Phones Circle',
      estimatedCost: 0.0,
      appointmentDate: DateTime.now().subtract(const Duration(days: 4)),
      timeSlot: 'Morning (9:00 AM - 1:00 PM)',
      customerName: 'Kwame Mensah',
      customerPhone: '024 555 0192',
      status: 'Completed',
    ),
    RepairBooking(
      id: 'REP-GH-9442',
      deviceModel: 'iPhone 13 Pro',
      issueType: 'Battery Degradation / Fast Drain',
      description: 'Battery health degraded at 74%. Needs original battery replacement.',
      dropOffBranch: 'Siaka Phones Madina',
      estimatedCost: 0.0,
      appointmentDate: DateTime.now().add(const Duration(days: 1)),
      timeSlot: 'Afternoon (2:00 PM - 5:00 PM)',
      customerName: 'Kwame Mensah',
      customerPhone: '024 555 0192',
      status: 'In Progress / Diagnostic',
    ),
  ];
}
