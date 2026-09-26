import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/manager_repository.dart';
import '../../../domain/models/service_ticket.dart';

class ServiceCenterView extends StatefulWidget {
  final ManagerRepository repository;

  const ServiceCenterView({super.key, required this.repository});

  @override
  State<ServiceCenterView> createState() => _ServiceCenterViewState();
}

class _ServiceCenterViewState extends State<ServiceCenterView> {
  ServiceTicket? _selectedTicket;
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _outerScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  String _statusFilter = 'ALL';
  bool _isSending = false;

  final List<String> _quickReplies = [
    'Hello! Yes, that item is currently in stock at our Accra Central branch.',
    'Your order is being packaged and our dispatch rider will contact you soon.',
    'Our technician has inspected your device and genuine parts are ready.',
    'You are welcome to visit our branch today before 6:30 PM.',
    'Please bring along your Ghana Card for verification.',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.repository.serviceTickets.isNotEmpty) {
      _selectedTicket = widget.repository.serviceTickets.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedTicket != null) {
          widget.repository.markTicketAsRead(_selectedTicket!.id);
        }
      });
    }
  }

  @override
  void dispose() {
    _outerScrollController.dispose();
    _horizontalScrollController.dispose();
    _replyController.dispose();
    _searchController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _selectedTicket == null) return;

    setState(() => _isSending = true);
    await Future.delayed(const Duration(milliseconds: 200));

    widget.repository.replyToServiceTicket(_selectedTicket!.id, text);

    setState(() {
      _isSending = false;
      _replyController.clear();
      // Keep reference updated
      _selectedTicket = widget.repository.serviceTickets
          .firstWhere((t) => t.id == _selectedTicket!.id);
    });

    _scrollToBottom();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reply transmitted to ${_selectedTicket!.customerName}\'s mobile app!'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _simulateCustomerMessage() {
    if (_selectedTicket == null) return;

    final sampleMessages = [
      'Thank you manager, I will make payment right now on the app.',
      'Could you also check if you have the 20W USB-C adapter in stock?',
      'Alright, I am on my way to Circle right now. See you soon!',
      'Great! Please notify me once the rider is close to my office.',
    ];

    final randomMsg = (sampleMessages..shuffle()).first;
    widget.repository.addIncomingCustomerMessage(_selectedTicket!.id, randomMsg);

    setState(() {
      _selectedTicket = widget.repository.serviceTickets
          .firstWhere((t) => t.id == _selectedTicket!.id);
    });

    _scrollToBottom();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mark_chat_unread_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('New incoming message received from ${_selectedTicket!.customerName}!'),
          ],
        ),
        backgroundColor: const Color(0xFF1C7BFF),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tickets = widget.repository.serviceTickets;

    // Filter tickets
    final filteredTickets = tickets.where((t) {
      final q = _searchController.text.trim().toLowerCase();
      final matchQuery = q.isEmpty ||
          t.customerName.toLowerCase().contains(q) ||
          t.customerPhone.toLowerCase().contains(q) ||
          t.subject.toLowerCase().contains(q) ||
          t.deviceOrTopic.toLowerCase().contains(q);

      final matchStatus = _statusFilter == 'ALL' ||
          t.status.name.toUpperCase() == _statusFilter;

      return matchQuery && matchStatus;
    }).toList();

    final openCount = tickets.where((t) => t.status == ServiceTicketStatus.open).length;
    final waitingCount = tickets.where((t) => t.status == ServiceTicketStatus.waitingCustomer).length;
    final inProgressCount = tickets.where((t) => t.status == ServiceTicketStatus.inProgress).length;
    final resolvedCount = tickets.where((t) => t.status == ServiceTicketStatus.resolved).length;

    final headerBar = Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: const [
                Text(
                  'Service Center & Customer Support Desk',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Icon(Icons.support_agent_rounded, color: Color(0xFF1C7BFF), size: 24),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-time messages sent by customers from the Siaka Mobile App appear here. Reply directly to customer inquiries.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),

        // KPI Counters & Simulation Button
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildStatusBadge('Open / New', openCount, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
            _buildStatusBadge('Waiting', waitingCount, const Color(0xFF7C3AED), const Color(0xFFF3E8FF)),
            _buildStatusBadge('In Progress', inProgressCount, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
            _buildStatusBadge('Resolved', resolvedCount, const Color(0xFF059669), const Color(0xFFECFDF5)),
            OutlinedButton.icon(
              onPressed: _simulateCustomerMessage,
              icon: const Icon(Icons.add_comment_rounded, size: 16),
              label: const Text('Simulate App Message'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1C7BFF),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );

    final ticketsListCard = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Field
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Search customer name, phone, ticket...',
                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Status Filter Tabs
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTicketFilterChip('ALL', 'All (${tickets.length})'),
                              const SizedBox(width: 6),
                              _buildTicketFilterChip('OPEN', 'New ($openCount)'),
                              const SizedBox(width: 6),
                              _buildTicketFilterChip('INPROGRESS', 'Active ($inProgressCount)'),
                              const SizedBox(width: 6),
                              _buildTicketFilterChip('WAITINGCUSTOMER', 'Waiting ($waitingCount)'),
                              const SizedBox(width: 6),
                              _buildTicketFilterChip('RESOLVED', 'Resolved ($resolvedCount)'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 8),

                        // Tickets List
                        Expanded(
                          child: filteredTickets.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
                                      const SizedBox(height: 8),
                                      Text('No tickets found', style: TextStyle(color: Colors.grey.shade600)),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: filteredTickets.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final t = filteredTickets[index];
                                    final isSelected = _selectedTicket?.id == t.id;
                                    final hasUnread = t.unreadCountForManager > 0;
                                    final lastMsg = t.lastMessage;
                                    final timeStr = lastMsg != null
                                        ? DateFormat('HH:mm').format(lastMsg.timestamp)
                                        : '';

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedTicket = t;
                                        });
                                        widget.repository.markTicketAsRead(t.id);
                                        _scrollToBottom();
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFEFF6FF)
                                              : (hasUnread ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC)),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF1C7BFF)
                                                : (hasUnread ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      if (hasUnread) ...[
                                                        Container(
                                                          width: 8,
                                                          height: 8,
                                                          decoration: const BoxDecoration(
                                                            color: Color(0xFF16A34A),
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                      ],
                                                      Flexible(
                                                        child: Text(
                                                          t.customerName,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                                                            fontSize: 13,
                                                            color: const Color(0xFF0F172A),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  timeStr,
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              t.subject,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF334155),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              lastMsg != null ? (lastMsg.isFromCustomer ? 'Customer: ' : 'Manager: ') + lastMsg.text : '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Color(t.status.bgColor),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      t.status.label,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(t.status.textColor),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  t.id,
                                                  style: const TextStyle(
                                                    fontSize: 10.5,
                                                    fontFamily: 'monospace',
                                                    color: Color(0xFF94A3B8),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );

    final chatDeskCard = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
                    child: _selectedTicket == null
                        ? const Center(
                            child: Text(
                              'Select an inbound customer inquiry to view and reply.',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          )
                        : Column(
                            children: [
                              // Ticket Header Bar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFF1C7BFF),
                                      child: Text(
                                        _selectedTicket!.customerName.isNotEmpty
                                            ? _selectedTicket!.customerName[0]
                                            : 'C',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              Text(
                                                _selectedTicket!.customerName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              Text(
                                                _selectedTicket!.customerPhone,
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                              ),
                                              if (_selectedTicket!.relatedReferenceId != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEFF6FF),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                                  ),
                                                  child: Text(
                                                    _selectedTicket!.relatedReferenceId!,
                                                    style: const TextStyle(
                                                      fontFamily: 'monospace',
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 10.5,
                                                      color: Color(0xFF1E40AF),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_selectedTicket!.subject} • Topic: ${_selectedTicket!.deviceOrTopic}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Status Selector
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<ServiceTicketStatus>(
                                          value: _selectedTicket!.status,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                          items: ServiceTicketStatus.values.map((s) {
                                            return DropdownMenuItem(
                                              value: s,
                                              child: Text(s.label, style: TextStyle(color: Color(s.textColor))),
                                            );
                                          }).toList(),
                                          onChanged: (newStatus) {
                                            if (newStatus != null) {
                                              widget.repository.updateServiceTicketStatus(_selectedTicket!.id, newStatus);
                                              setState(() {
                                                _selectedTicket = widget.repository.serviceTickets
                                                    .firstWhere((t) => t.id == _selectedTicket!.id);
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // Mark Resolved Action
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669)),
                                      tooltip: 'Mark as Resolved',
                                      onPressed: () {
                                        widget.repository.updateServiceTicketStatus(
                                          _selectedTicket!.id,
                                          ServiceTicketStatus.resolved,
                                        );
                                        setState(() {
                                          _selectedTicket = widget.repository.serviceTickets
                                              .firstWhere((t) => t.id == _selectedTicket!.id);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // Chat Thread Message Area
                              Expanded(
                                child: Container(
                                  color: const Color(0xFFF8FAFC),
                                  child: ListView.builder(
                                    controller: _chatScrollController,
                                    padding: const EdgeInsets.all(20),
                                    itemCount: _selectedTicket!.messages.length,
                                    itemBuilder: (context, index) {
                                      final msg = _selectedTicket!.messages[index];
                                      final isCustomer = msg.isFromCustomer;
                                      final timeStr = DateFormat('MMM d • HH:mm').format(msg.timestamp);

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 14),
                                        child: Row(
                                          mainAxisAlignment: isCustomer
                                              ? MainAxisAlignment.start
                                              : MainAxisAlignment.end,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (isCustomer) ...[
                                              CircleAvatar(
                                                radius: 14,
                                                backgroundColor: const Color(0xFFE2E8F0),
                                                child: Text(
                                                  _selectedTicket!.customerName.isNotEmpty
                                                      ? _selectedTicket!.customerName[0]
                                                      : 'C',
                                                  style: const TextStyle(
                                                    color: Color(0xFF334155),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                            ],
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 480),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: isCustomer ? Colors.white : const Color(0xFF1C7BFF),
                                                  borderRadius: BorderRadius.only(
                                                    topLeft: const Radius.circular(12),
                                                    topRight: const Radius.circular(12),
                                                    bottomLeft: Radius.circular(isCustomer ? 2 : 12),
                                                    bottomRight: Radius.circular(isCustomer ? 12 : 2),
                                                  ),
                                                  border: isCustomer
                                                      ? Border.all(color: const Color(0xFFE2E8F0))
                                                      : null,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.03),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: isCustomer
                                                      ? CrossAxisAlignment.start
                                                      : CrossAxisAlignment.end,
                                                  children: [
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            isCustomer
                                                                ? '${msg.senderName} (Customer App)'
                                                                : 'Store Manager (Staff Reply)',
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(
                                                              fontSize: 10.5,
                                                              fontWeight: FontWeight.w700,
                                                              color: isCustomer
                                                                  ? const Color(0xFF64748B)
                                                                  : const Color(0xFFBFDBFE),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          timeStr,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: isCustomer
                                                                ? const Color(0xFF94A3B8)
                                                                : const Color(0xFFE0E7FF),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      msg.text,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: isCustomer
                                                            ? const Color(0xFF0F172A)
                                                            : Colors.white,
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (!isCustomer) ...[
                                              const SizedBox(width: 10),
                                              const CircleAvatar(
                                                radius: 14,
                                                backgroundColor: Color(0xFF1C7BFF),
                                                child: Icon(Icons.support_agent_rounded, size: 16, color: Colors.white),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // Quick Canned Replies Bar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFFD97706)),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Quick Replies: ',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                                      ),
                                      ..._quickReplies.map((reply) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: ActionChip(
                                            label: Text(
                                              reply.length > 35 ? '${reply.substring(0, 35)}...' : reply,
                                            ),
                                            visualDensity: VisualDensity.compact,
                                            backgroundColor: Colors.white,
                                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                                            labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                                            onPressed: () {
                                              setState(() {
                                                _replyController.text = reply;
                                              });
                                            },
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),

                              // Reply Input Composer Box
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _replyController,
                                        maxLines: 3,
                                        minLines: 1,
                                        onSubmitted: (_) => _handleSendReply(),
                                        style: const TextStyle(fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: 'Type your reply to ${_selectedTicket!.customerName}...',
                                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      height: 46,
                                      child: ElevatedButton.icon(
                                        onPressed: _isSending ? null : _handleSendReply,
                                        icon: _isSending
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Icon(Icons.send_rounded, size: 16),
                                        label: const Text('Reply to Customer App', style: TextStyle(fontWeight: FontWeight.w700)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1C7BFF),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isShortHeight = constraints.maxHeight < 680;
        final availableWidth = constraints.maxWidth - 48;
        final contentMinWidth = math.max(980.0, availableWidth);
        final listWidth = math.max(340.0, (contentMinWidth - 20) * 0.38);
        final chatWidth = math.max(580.0, contentMinWidth - 20 - listWidth);

        final workspaceRow = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: listWidth,
              child: ticketsListCard,
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: chatWidth,
              child: chatDeskCard,
            ),
          ],
        );

        final horizontalWorkspace = ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: contentMinWidth,
                child: workspaceRow,
              ),
            ),
          ),
        );

        if (isShortHeight) {
          return Scrollbar(
            controller: _outerScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _outerScrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headerBar,
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 640,
                    child: horizontalWorkspace,
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headerBar,
              const SizedBox(height: 20),
              Expanded(
                child: horizontalWorkspace,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String label, int count, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: textColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _statusFilter = value);
      },
      backgroundColor: const Color(0xFFF1F5F9),
      selectedColor: const Color(0xFF1C7BFF).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFF475569),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide(
        color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0),
      ),
    );
  }
}
