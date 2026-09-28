import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/manager_repository.dart';
import 'desktop_sidebar.dart';

class DesktopScaffold extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final Widget body;
  final ManagerRepository repository;

  const DesktopScaffold({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.body,
    required this.repository,
  });

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends State<DesktopScaffold> {
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nowFormatted = DateFormat('EEEE, MMMM d, y').format(DateTime.now());
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 900;

    final sidebarWidget = DesktopSidebar(
      selectedIndex: widget.selectedIndex,
      onDestinationSelected: (idx) {
        if (isCompact) {
          Navigator.of(context).maybePop();
        }
        widget.onIndexChanged(idx);
      },
      pendingOrders: widget.repository.pendingOrdersCount,
      pendingBnpl: widget.repository.pendingBnplCount,
      activeRepairs: widget.repository.activeRepairsCount,
      unreadServiceTickets: widget.repository.unreadServiceTicketsCount,
      activeShipments: widget.repository.activeShipmentsCount,
      unreadNotifications: widget.repository.unreadNotificationsCount,
      activeAds: widget.repository.activeAdvertisementsCount,
      onLogout: widget.repository.logout,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isCompact ? Drawer(width: 280, child: sidebarWidget) : null,
      body: Row(
        children: [
          // Sidebar (desktop only)
          if (!isCompact) sidebarWidget,

          // Main Workspace
          Expanded(
            child: Column(
              children: [
                // Top Global Header
                Container(
                  height: 64,
                  padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Hamburger menu button for compact/mobile view
                      if (isCompact) ...[
                        Builder(
                          builder: (scaffoldContext) => IconButton(
                            icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
                            tooltip: 'Open Navigation',
                            onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],

                      // Date & Branch Info
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nowFormatted,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Siaka Phones Enterprise System',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      IconButton(
                        tooltip: 'Notifications Hub',
                        icon: Badge.count(
                          count: widget.repository.unreadNotificationsCount,
                          isLabelVisible: widget.repository.unreadNotificationsCount > 0,
                          backgroundColor: const Color(0xFFDC2626),
                          child: const Icon(Icons.notifications_outlined, color: Color(0xFF475569), size: 20),
                        ),
                        onPressed: () => widget.onIndexChanged(12),
                      ),
                      const SizedBox(width: 8),

                      // Branch Switcher
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: widget.repository.currentBranch,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF475569)),
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            items: widget.repository.branches.map((branch) {
                              return DropdownMenuItem(
                                value: branch,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.storefront_rounded, size: 15, color: Color(0xFF1C7BFF)),
                                    const SizedBox(width: 6),
                                    Text(branch),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) widget.repository.selectBranch(val);
                            },
                          ),
                        ),
                      ),

                      if (!isCompact) ...[
                        const SizedBox(width: 12),

                        // Live Database Status Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.cloud_done_rounded, size: 16, color: Color(0xFF059669)),
                              SizedBox(width: 6),
                              Text(
                                'Live Sync Ready',
                                style: TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Content View with persistent bottom horizontal scrollbar
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final minContentWidth = isCompact ? 950.0 : 1200.0;
                      return Scrollbar(
                        controller: _horizontalScrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        interactive: true,
                        thickness: 12.0,
                        notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: SizedBox(
                            width: math.max(constraints.maxWidth, minContentWidth),
                            height: constraints.maxHeight,
                            child: widget.body,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
