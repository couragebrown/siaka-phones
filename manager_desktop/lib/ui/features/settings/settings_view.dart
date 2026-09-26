import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../data/repositories/manager_repository.dart';

class SettingsView extends StatefulWidget {
  final ManagerRepository repository;

  const SettingsView({super.key, required this.repository});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _autoSyncEnabled = true;
  bool _soundAlertsEnabled = true;
  bool _emailNotifications = true;

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 900;
        final paddingVal = isCompact ? 16.0 : 24.0;
        final availableWidth = constraints.maxWidth - (paddingVal * 2);
        final contentMinWidth = math.max(680.0, availableWidth);

        return Scrollbar(
          controller: _verticalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            padding: EdgeInsets.all(paddingVal),
            child: Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: contentMinWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      const Text(
                        'System Settings & Branch Control',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage physical store branches, database synchronization parameters, and enterprise preferences',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Grid
                      if (isCompact)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLeftColumn(),
                            const SizedBox(height: 20),
                            _buildRightColumn(),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildLeftColumn(),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: _buildRightColumn(),
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
      },
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      children: [
        // Physical Store Branches Card
        _buildSettingsCard(
          title: 'Physical Store Branches',
          subtitle: 'Active retail branches and distribution hubs across Greater Accra and Central Regions',
          icon: Icons.storefront_rounded,
          iconColor: const Color(0xFF1C7BFF),
          child: Column(
            children: widget.repository.branches.map((branch) {
              final isSelected = widget.repository.currentBranch == branch;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            branch.contains('Circle')
                                ? 'Flagship Mega Store • Kwame Nkrumah Avenue'
                                : branch.contains('Madina')
                                    ? 'Retail & Repair Hub • Zongo Junction'
                                    : 'Regional Distribution Center • Kasoa Highway',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C7BFF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ACTIVE WORKSTATION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () {
                          setState(() {
                            widget.repository.selectBranch(branch);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched active branch to $branch'),
                              backgroundColor: const Color(0xFF0F172A),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('Switch Branch'),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // Branch Operational Controls Card
        _buildSettingsCard(
          title: 'Store Operations & Automation',
          subtitle: 'Automated POS order dispatching, sync intervals, and notification preferences',
          icon: Icons.tune_rounded,
          iconColor: const Color(0xFF059669),
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-Sync Offline Changes', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Instantly upload transactions when Internet connection is restored', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  value: _autoSyncEnabled,
                  activeTrackColor: const Color(0xFF1C7BFF),
                  onChanged: (val) => setState(() => _autoSyncEnabled = val),
                ),
              ),
              const Divider(height: 16),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Audible Notifications for Orders', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Play chime alert when a customer places an order via the mobile app', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  value: _soundAlertsEnabled,
                  activeTrackColor: const Color(0xFF1C7BFF),
                  onChanged: (val) => setState(() => _soundAlertsEnabled = val),
                ),
              ),
              const Divider(height: 16),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Manager Daily Summary Email', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Send EOD sales, low stock, and BNPL approval ledger at 9:00 PM', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  value: _emailNotifications,
                  activeTrackColor: const Color(0xFF1C7BFF),
                  onChanged: (val) => setState(() => _emailNotifications = val),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      children: [
        // Manager Profile Card
        _buildSettingsCard(
          title: 'Manager Profile',
          subtitle: 'Active workstation session',
          icon: Icons.badge_outlined,
          iconColor: const Color(0xFF7C3AED),
          child: Column(
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFF1C7BFF),
                    child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('General Manager', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                      Text('manager@siakaphones.com', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      SizedBox(height: 2),
                      Text('Role: Enterprise Administrator', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Terminal Version', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ),
                        Text('v2.0.0 (Enterprise)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Currency Setting', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ),
                        Text('Ghana Cedis (GH₵)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Data Export & Audit Ledger
        _buildSettingsCard(
          title: 'Data Export & Audit Logs',
          subtitle: 'Generate management spreadsheets and fiscal ledgers',
          icon: Icons.file_download_outlined,
          iconColor: const Color(0xFF0284C7),
          child: Column(
            children: [
              _buildExportButton(
                title: 'Export Customer Orders (CSV)',
                icon: Icons.receipt_long_rounded,
                onPressed: () => _simulateExport(context, 'Customer Orders Report'),
              ),
              const SizedBox(height: 10),
              _buildExportButton(
                title: 'Export Inventory Valuation',
                icon: Icons.inventory_rounded,
                onPressed: () => _simulateExport(context, 'Inventory Valuation Ledger'),
              ),
              const SizedBox(height: 10),
              _buildExportButton(
                title: 'Export BNPL Financing Ledger',
                icon: Icons.credit_score_rounded,
                onPressed: () => _simulateExport(context, 'BNPL Credit Ledger'),
              ),
              const SizedBox(height: 10),
              _buildExportButton(
                title: 'Export Service & Repair Logs',
                icon: Icons.build_circle_rounded,
                onPressed: () => _simulateExport(context, 'Technician Repair Logs'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          child,
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1E293B),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(double.infinity, 44),
        alignment: Alignment.centerLeft,
      ),
      icon: Icon(icon, size: 18, color: const Color(0xFF1C7BFF)),
      label: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
      onPressed: onPressed,
    );
  }

  void _simulateExport(BuildContext context, String reportName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('$reportName generated and saved successfully'),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
