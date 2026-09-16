import 'package:flutter/material.dart';
import 'profile_view_model.dart';

class ProfileView extends StatelessWidget {
  final ProfileViewModel viewModel;
  final VoidCallback onOrdersTap;
  final VoidCallback onTradeInTap;
  final VoidCallback onLocationsTap;
  final VoidCallback onSupportTap;
  final VoidCallback onSignOut;
  final VoidCallback onBack;
  final VoidCallback? onWishlistTap;

  const ProfileView({
    super.key,
    required this.viewModel,
    required this.onOrdersTap,
    required this.onTradeInTap,
    required this.onLocationsTap,
    required this.onSupportTap,
    required this.onSignOut,
    required this.onBack,
    this.onWishlistTap,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'SP';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final profile = viewModel.profile;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F4F6),
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            leading: IconButton(
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF1F2937),
              ),
              onPressed: onBack,
            ),
            title: const Text(
              'My Account',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1C7BFF), Color(0xFF0D5BD8)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(profile.name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.workspace_premium_rounded,
                                    color: Color(0xFF1C7BFF),
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.membershipTier,
                                    style: const TextStyle(
                                      color: Color(0xFF1D4ED8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Quick stats summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      _summaryStat('3', 'Orders'),
                      _verticalDivider(),
                      _summaryStat('4', 'Wishlist'),
                      _verticalDivider(),
                      _summaryStat(
                        profile.savedAddresses.length.toString(),
                        'Addresses',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Account Services',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Action menu list
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      _menuRow(
                        icon: Icons.receipt_long_outlined,
                        label: 'My Orders & Tracking',
                        onTap: onOrdersTap,
                      ),
                      _rowDivider(),
                      _menuRow(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Swap My Device',
                        onTap: onTradeInTap,
                      ),
                      _rowDivider(),
                      _menuRow(
                        icon: Icons.location_on_outlined,
                        label: 'Saved Delivery Address',
                        subtitle:
                            '${profile.detailAddress} • ${profile.gpsCode}',
                        onTap: null, // User must click on Edit button to open edit panel
                        trailing: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showEditAddressSheet(context),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C7BFF).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF1C7BFF).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_outlined,
                                      size: 11, color: Color(0xFF1C7BFF)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: Color(0xFF1C7BFF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      _rowDivider(),
                      _menuRow(
                        icon: Icons.help_outline_rounded,
                        label: 'Customer Support & FAQ',
                        onTap: onSupportTap,
                      ),
                      _rowDivider(),
                      _menuRow(
                        icon: Icons.credit_card_rounded,
                        label: 'Saved Payment Methods',
                        onTap: () {},
                      ),
                      _rowDivider(),
                      _menuRow(
                        icon: Icons.favorite_border_rounded,
                        label: 'My Wishlist',
                        onTap: onWishlistTap ?? () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Sign out button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onSignOut,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: const Color(0xFFFEF2F2),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
                        SizedBox(width: 8),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFFF3F4F6),
    );
  }

  Widget _rowDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      color: Color(0xFFF3F4F6),
    );
  }

  Widget _summaryStat(String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1C7BFF),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String label,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1C7BFF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: const Color(0xFF1C7BFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (trailing != null)
            trailing
          else
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 18,
            ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: content,
    );
  }

  void _showEditAddressSheet(BuildContext context) {
    final detailController =
        TextEditingController(text: viewModel.profile.detailAddress);
    final gpsController =
        TextEditingController(text: viewModel.profile.gpsCode);
    String selectedRegion = viewModel.profile.region.isNotEmpty
        ? viewModel.profile.region
        : 'Greater Accra';

    const regions = [
      'Greater Accra',
      'Ashanti',
      'Central',
      'Eastern',
      'Western',
      'Western North',
      'Volta',
      'Oti',
      'Northern',
      'North East',
      'Savannah',
      'Upper East',
      'Upper West',
      'Bono',
      'Bono East',
      'Ahafo',
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom +
                    24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Saved Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Only 1 Address',
                            style: TextStyle(
                              color: Color(0xFF1C7BFF),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This address will be automatically used for all your orders.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Detail Address
                    const Text(
                      'Detail Address / Street / House No.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: detailController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. House No. 14, Independence Ave, Airport',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 13.5,
                        ),
                        prefixIcon: const Icon(Icons.home_outlined,
                            size: 19, color: Color(0xFF6B7280)),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF1C7BFF), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Ghana GPS Code
                    const Text(
                      'Ghana GPS Digital Address',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: gpsController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. GA-014-2041',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 13.5,
                          letterSpacing: 0,
                        ),
                        prefixIcon: const Icon(Icons.qr_code_rounded,
                            size: 19, color: Color(0xFF1C7BFF)),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF1C7BFF), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Region
                    const Text(
                      'Region (Ghana)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: regions.contains(selectedRegion)
                              ? selectedRegion
                              : regions.first,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF6B7280)),
                          items: regions.map((r) {
                            return DropdownMenuItem(
                              value: r,
                              child: Text(
                                r,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => selectedRegion = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final detail = detailController.text.trim();
                          final gps = gpsController.text.trim().toUpperCase();
                          if (detail.isEmpty || gps.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please provide detail address and GPS code.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          viewModel.updateAddress(
                            detailAddress: detail,
                            gpsCode: gps,
                            region: selectedRegion,
                          );

                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Address updated successfully'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C7BFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Address',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
