import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/neon_button.dart';
import 'repairs_view_model.dart';

class RepairsView extends StatelessWidget {
  final RepairsViewModel viewModel;

  const RepairsView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.lastBooking != null) {
          return _buildSuccessView(context);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Express Repair Service'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Banner
              GlassContainer(
                padding: const EdgeInsets.all(16),
                borderColor: AppColors.neonAmber.withOpacity(0.4),
                child: const Row(
                  children: [
                    Icon(Icons.verified_outlined, color: AppColors.neonAmber, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Official Certified Technicians', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('100% genuine OEM titanium parts & waterproof seal restoration.', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Device Selector
              const Text('1. Your Device Model', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: viewModel.deviceModel,
                    dropdownColor: AppColors.surfaceElevated,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: [
                      'Siaka Quantum Titan 16 Pro',
                      'Siaka Apex Fold V3',
                      'Siaka Nova Lite 5G',
                      'Siaka Pulse Cyberwatch Ultra',
                    ].map((model) => DropdownMenuItem(value: model, child: Text(model))).toList(),
                    onChanged: (val) {
                      if (val != null) viewModel.setDeviceModel(val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Issue Selector
              const Text('2. Select Issue Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ...viewModel.issuePricing.entries.map((entry) {
                final isSelected = viewModel.selectedIssue == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(12),
                    borderColor: isSelected ? AppColors.cyan : AppColors.borderLight,
                    onTap: () => viewModel.setSelectedIssue(entry.key),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: isSelected ? AppColors.cyan : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '~\$${entry.value.toStringAsFixed(2)}',
                          style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Appointment Time Slot
              const Text('3. Preferred Service Window', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: viewModel.timeSlot,
                    dropdownColor: AppColors.surfaceElevated,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: [
                      '09:00 AM - 11:00 AM',
                      '10:00 AM - 12:00 PM',
                      '01:00 PM - 03:00 PM',
                      '03:00 PM - 05:00 PM',
                      '05:00 PM - 07:00 PM',
                    ].map((slot) => DropdownMenuItem(value: slot, child: Text(slot))).toList(),
                    onChanged: (val) {
                      if (val != null) viewModel.setTimeSlot(val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Total Estimate & Booking CTA
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimated Repair Cost', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        Text('Includes Parts & Labor', style: TextStyle(color: AppColors.neonEmerald, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(
                      '\$${viewModel.estimatedCost.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              NeonButton(
                label: 'Book Same-Day Appointment',
                icon: Icons.calendar_today_rounded,
                isLoading: viewModel.isSubmitting,
                onPressed: () => viewModel.bookAppointment(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final booking = viewModel.lastBooking!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.neonEmerald.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.neonEmerald, width: 2),
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.neonEmerald, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Repair Appointment Reserved!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Booking ID: ${booking.id}',
                style: const TextStyle(color: AppColors.cyan, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildBookingRow('Device', booking.deviceModel),
                    _buildBookingRow('Issue', booking.issueType),
                    _buildBookingRow('Window', booking.timeSlot),
                    _buildBookingRow('Est. Cost', '\$${booking.estimatedCost.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              NeonButton(
                label: 'Done',
                onPressed: () => viewModel.resetBookingState(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
