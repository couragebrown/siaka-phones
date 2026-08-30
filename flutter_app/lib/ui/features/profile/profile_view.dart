import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/neon_button.dart';
import 'profile_view_model.dart';

class ProfileView extends StatelessWidget {
  final ProfileViewModel viewModel;
  final VoidCallback onOrdersTap;
  final VoidCallback onTradeInTap;
  final VoidCallback onLocationsTap;
  final VoidCallback onSupportTap;

  const ProfileView({
    super.key,
    required this.viewModel,
    required this.onOrdersTap,
    required this.onTradeInTap,
    required this.onLocationsTap,
    required this.onSupportTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final profile = viewModel.profile;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('My Account'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings & Biometric Security are active')),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Header Card
              GlassContainer(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage(profile.avatarUrl),
                      backgroundColor: AppColors.surfaceElevated,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.email,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              profile.membershipTier,
                              style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Reward Points Card
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Siaka VIP Club Points', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${profile.rewardPoints} pts',
                          style: const TextStyle(color: AppColors.cyan, fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: AppColors.cyan,
                        side: const BorderSide(color: AppColors.borderCyan),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Points can be redeemed at checkout for discounts!')),
                        );
                      },
                      child: const Text('Redeem'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Navigation Links
              const Text('Menu & Services', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              GlassContainer(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildMenuTile(Icons.receipt_long_outlined, 'Order History & Receipts', 'Track current shipments', onOrdersTap),
                    const Divider(color: AppColors.borderLight, height: 1),
                    _buildMenuTile(Icons.swap_horizontal_circle_outlined, 'Trade-In Valuation', 'Calculate value of your phone', onTradeInTap),
                    const Divider(color: AppColors.borderLight, height: 1),
                    _buildMenuTile(Icons.location_on_outlined, 'Store Locator & Repair Hubs', 'Find a physical boutique', onLocationsTap),
                    const Divider(color: AppColors.borderLight, height: 1),
                    _buildMenuTile(Icons.headset_mic_outlined, '24/7 VIP Concierge & Support', 'AI Assistant & Live Agent', onSupportTap),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Saved Addresses Card
              const Text('Saved Addresses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              ...profile.savedAddresses.map((addr) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassContainer(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.home_outlined, color: AppColors.cyan, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(addr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 24),

              NeonButton(
                label: 'Sign Out of Device',
                isSecondary: true,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out of Siaka session')),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.cyan, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
      onTap: onTap,
    );
  }
}
