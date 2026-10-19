import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/manager_repository.dart';
import '../../../domain/models/customer_activity.dart';
import '../../../domain/models/customer_message.dart';

class CustomerMessagingView extends StatefulWidget {
  final ManagerRepository repository;

  const CustomerMessagingView({super.key, required this.repository});

  @override
  State<CustomerMessagingView> createState() => _CustomerMessagingViewState();
}

class _CustomerMessagingViewState extends State<CustomerMessagingView> {
  CustomerActivity? _selectedCustomer;
  MessageChannel _selectedChannel = MessageChannel.inApp;
  MessageCategory _selectedCategory = MessageCategory.general;

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _outerScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _chatScrollController = ScrollController();

  String _channelFilter = 'ALL';
  bool _isSending = false;

  final List<Map<String, dynamic>> _quickTemplates = [
    {
      'title': 'Order Dispatched',
      'category': MessageCategory.orderUpdate,
      'subject': 'Order Dispatched for Delivery',
      'body':
          'Dear {name}, your Siaka Phones order has been dispatched with our delivery rider. Please keep your phone reachable for delivery.',
    },
    {
      'title': 'BNPL Due Reminder',
      'category': MessageCategory.paymentReminder,
      'subject': 'Upcoming BNPL Installment Reminder',
      'body':
          'Hello {name}, your monthly BNPL installment is due in 3 days. Please make payment via Mobile Money on your Siaka App to maintain your active credit status.',
    },
    {
      'title': 'Repair Ready',
      'category': MessageCategory.repairNotice,
      'subject': 'Your Device Repair is Ready for Pickup',
      'body':
          'Hi {name}, our technicians have completed your device repair and thorough quality testing. You may collect your device at the {branch} branch.',
    },
    {
      'title': 'VIP Promo Offer',
      'category': MessageCategory.promotional,
      'subject': 'Exclusive VIP Store Discount',
      'body':
          'Special offer for you, {name}! Enjoy an instant 10% discount on all original accessories this week at Siaka Phones. Show this message in-store.',
    },
  ];

  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_onRepositoryChanged);
    _syncSelectedCustomer();
  }

  @override
  void didUpdateWidget(covariant CustomerMessagingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      oldWidget.repository.removeListener(_onRepositoryChanged);
      widget.repository.addListener(_onRepositoryChanged);
    }
    _syncSelectedCustomer();
  }

  void _onRepositoryChanged() {
    if (mounted) {
      setState(() {
        _syncSelectedCustomer();
      });
    }
  }

  void _syncSelectedCustomer() {
    if (widget.repository.activeMessagingCustomer != null) {
      _selectedCustomer = widget.repository.activeMessagingCustomer;
      if (widget.repository.initialMessagingSubject != null) {
        _subjectController.text = widget.repository.initialMessagingSubject!;
      }
      if (widget.repository.initialMessagingBody != null) {
        _messageController.text = widget.repository.initialMessagingBody!;
      }
      if (widget.repository.initialMessagingCategory != null) {
        _selectedCategory = widget.repository.initialMessagingCategory!;
      }
      widget.repository.clearInitialMessagingDraft();
      _scrollToBottom();
    } else if (_selectedCustomer == null && widget.repository.customers.isNotEmpty) {
      _selectedCustomer = widget.repository.customers.first;
    }
  }

  @override
  void dispose() {
    widget.repository.removeListener(_onRepositoryChanged);
    _outerScrollController.dispose();
    _horizontalScrollController.dispose();
    _chatScrollController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _searchController.dispose();
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

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      _selectedCategory = template['category'] as MessageCategory;
      _subjectController.text = template['subject'] as String;

      final custName = _selectedCustomer?.fullName ?? 'Customer';
      final branch = widget.repository.currentBranch;

      var body = template['body'] as String;
      body = body.replaceAll('{name}', custName);
      body = body.replaceAll('{branch}', branch);
      body = body.replaceAll('{phone}', _selectedCustomer?.phone ?? '');
      _messageController.text = body;
    });
  }

  void _insertToken(String token) {
    String resolved = token;
    if (token == '{name}') {
      resolved = _selectedCustomer?.fullName ?? 'Customer';
    } else if (token == '{phone}') {
      resolved = _selectedCustomer?.phone ?? '';
    } else if (token == '{branch}') {
      resolved = widget.repository.currentBranch;
    }

    final text = _messageController.text;
    final selection = _messageController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, resolved);
    _messageController.text = newText;
    _messageController.selection = TextSelection.collapsed(
      offset: start + resolved.length,
    );
  }

  void _handleSendMessage() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a recipient customer first.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message before sending.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    await Future.delayed(const Duration(milliseconds: 250));

    final newMsg = CustomerMessage(
      id: 'MSG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.fullName,
      customerPhone: _selectedCustomer!.phone,
      customerEmail: _selectedCustomer!.email,
      channel: _selectedChannel,
      category: _selectedCategory,
      subject: _subjectController.text.trim().isNotEmpty
          ? _subjectController.text.trim()
          : 'Direct Store Message',
      message: text,
      sentAt: DateTime.now(),
      sentBy: 'Store Manager',
      status: MessageDeliveryStatus.delivered,
      isFromCustomer: false,
    );

    widget.repository.sendCustomerMessage(newMsg);

    if (mounted) {
      setState(() {
        _isSending = false;
        _messageController.clear();
      });

      _scrollToBottom();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Message successfully dispatched to ${_selectedCustomer!.fullName} via ${_selectedChannel.label}!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = widget.repository.customers;
    final sentMessages = widget.repository.sentMessages;

    // Filter customers on the left
    final filteredCustomers = customers.where((c) {
      final q = _searchController.text.trim().toLowerCase();
      final matchQuery = q.isEmpty ||
          c.fullName.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.primaryDevice.toLowerCase().contains(q);

      final hasChannelMessages = _channelFilter == 'ALL' ||
          sentMessages.any((m) =>
              (m.customerId == c.id ||
                  m.customerPhone.replaceAll(' ', '') == c.phone.replaceAll(' ', '')) &&
              m.channel.name.toUpperCase() == _channelFilter);

      return matchQuery && hasChannelMessages;
    }).toList();

    // Stats
    final inAppCount = sentMessages.where((m) => m.channel == MessageChannel.inApp).length;
    final emailCount = sentMessages.where((m) => m.channel == MessageChannel.email).length;

    // Header bar like Service Center
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
                  'Direct Customer Messaging',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Icon(Icons.forum_rounded, color: Color(0xFF1C7BFF), size: 24),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Direct customer communications hub across In-App Notification and Email.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),

        // KPI Counters & Live Sync Badge
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildKpiPill('ALL SENT', '${sentMessages.length}', const Color(0xFF0F172A), const Color(0xFFF1F5F9), channel: null),
            _buildKpiPill('IN-APP', '$inAppCount', const Color(0xFF7C3AED), const Color(0xFFF3E8FF), channel: MessageChannel.inApp),
            _buildKpiPill('EMAIL', '$emailCount', const Color(0xFFB45309), const Color(0xFFFEF3C7), channel: MessageChannel.email),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Inbound Sync Active',
                    style: TextStyle(
                      color: Color(0xFF166534),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    // Left Column: Customer Directory Card (like ticketsListCard in Service Center)
    final customerListCard = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.people_alt_rounded, color: Color(0xFF64748B), size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Customers & Threads',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${customers.length} Total',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          const Text(
            'SELECT RECIPIENT CUSTOMER',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search customers by name, phone, email...',
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

          // Channel Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChannelFilterChip('ALL', 'All Channels'),
                const SizedBox(width: 6),
                _buildChannelFilterChip('INAPP', 'In-App'),
                const SizedBox(width: 6),
                _buildChannelFilterChip('EMAIL', 'Email'),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),

          // Customer Directory List
          Expanded(
            child: filteredCustomers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('No customers match filter', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredCustomers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final c = filteredCustomers[index];
                      final isSelected = _selectedCustomer?.id == c.id;

                      // Find messages for this customer
                      final cMsgs = sentMessages.where((m) =>
                          m.customerId == c.id ||
                          m.customerPhone.replaceAll(' ', '') == c.phone.replaceAll(' ', '')).toList();
                      cMsgs.sort((a, b) => b.sentAt.compareTo(a.sentAt));
                      final lastMsg = cMsgs.isNotEmpty ? cMsgs.first : null;
                      final timeStr = lastMsg != null
                          ? DateFormat('MMM d • HH:mm').format(lastMsg.sentAt)
                          : DateFormat('MMM d').format(c.signupDate);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCustomer = c;
                          });
                          widget.repository.setMessagingCustomer(c);
                          _scrollToBottom();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF1C7BFF)
                                  : const Color(0xFFE2E8F0),
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
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            CircleAvatar(
                                              radius: 13,
                                              backgroundColor: isSelected
                                                  ? const Color(0xFF1C7BFF)
                                                  : const Color(0xFF64748B),
                                              child: Text(
                                                c.fullName.isNotEmpty ? c.fullName[0] : 'C',
                                                style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            if (c.isOnline)
                                              Positioned(
                                                right: -1,
                                                bottom: -1,
                                                child: Container(
                                                  width: 9,
                                                  height: 9,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.white, width: 1.5),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            c.fullName,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                              fontSize: 13,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      c.phone,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      c.email,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (c.isOnline ? '● Online Now • ' : '') +
                                (lastMsg != null
                                    ? (lastMsg.isFromCustomer ? 'Inbound: ' : 'Outbound: ') + lastMsg.message
                                    : 'Registered device: ${c.primaryDevice}'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: c.isOnline ? FontWeight.w600 : FontWeight.normal,
                                  color: c.isOnline
                                      ? const Color(0xFF15803D)
                                      : (isSelected ? const Color(0xFF1E40AF) : const Color(0xFF475569)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        c.status,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (lastMsg != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Color(lastMsg.channel.colorValue).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        lastMsg.channel.label,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(lastMsg.channel.colorValue),
                                        ),
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

    // Right Column: Customer Messaging & Conversation Desk (like chatDeskCard in Service Center)
    final messagingDeskCard = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: _selectedCustomer == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 54, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 12),
                  Text(
                    'Select a customer from the left directory to begin messaging.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Active Customer Header Bar
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
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF1C7BFF),
                            child: Text(
                              _selectedCustomer!.fullName.isNotEmpty
                                  ? _selectedCustomer!.fullName[0]
                                  : 'C',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (_selectedCustomer!.isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
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
                                  _selectedCustomer!.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: _selectedCustomer!.isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedCustomer!.isOnline ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    _selectedCustomer!.isOnline ? '● Active in App' : '○ Offline',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedCustomer!.isOnline ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Text(
                                    _selectedCustomer!.phone,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _selectedCustomer!.email,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _selectedCustomer!.status,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Device: ${_selectedCustomer!.primaryDevice} • Branch: ${widget.repository.currentBranch} • Total Spend: GH₵ ${_selectedCustomer!.totalSpend.toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Channel Dropdown with label for tests & clarity
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'COMMUNICATION CHANNEL',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<MessageChannel>(
                                value: _selectedChannel,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                items: MessageChannel.values.map((ch) {
                                  return DropdownMenuItem(
                                    value: ch,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Color(ch.colorValue),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(ch.label, style: TextStyle(color: Color(ch.colorValue))),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedChannel = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Conversation Message Thread (Stream)
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: Builder(
                      builder: (context) {
                        final threadMessages = sentMessages.where((m) =>
                            m.customerId == _selectedCustomer!.id ||
                            (m.customerPhone.isNotEmpty &&
                                m.customerPhone.replaceAll(' ', '') == _selectedCustomer!.phone.replaceAll(' ', ''))).toList();
                        threadMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

                        if (threadMessages.isEmpty) {
                          return Center(
                            child: Container(
                              margin: const EdgeInsets.all(24),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.mark_chat_read_outlined, size: 42, color: Color(0xFF1C7BFF)),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Start direct conversation with ${_selectedCustomer!.fullName}',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Recipient: ${_selectedCustomer!.phone} • ${_selectedCustomer!.email}',
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Pick a quick template below or type a message in the composer to transmit.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _chatScrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: threadMessages.length,
                          itemBuilder: (context, index) {
                            final msg = threadMessages[index];
                            final isCustomer = msg.isFromCustomer;
                            final timeStr = DateFormat('MMM d • HH:mm').format(msg.sentAt);

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
                                        _selectedCustomer!.fullName.isNotEmpty
                                            ? _selectedCustomer!.fullName[0]
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
                                                      ? '${msg.customerName} (Customer Inbound)'
                                                      : 'Store Manager (Direct Dispatch)',
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
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: isCustomer
                                                      ? const Color(0xFFF1F5F9)
                                                      : Colors.white.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  msg.channel.label,
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: isCustomer
                                                        ? Color(msg.channel.colorValue)
                                                        : Colors.white,
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
                                          if (msg.subject.isNotEmpty && msg.subject != 'Direct Store Message') ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              msg.subject,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                                color: isCustomer
                                                    ? const Color(0xFF0F172A)
                                                    : Colors.white,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            msg.message,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isCustomer
                                                  ? const Color(0xFF0F172A)
                                                  : Colors.white,
                                              height: 1.35,
                                            ),
                                          ),
                                          if (!isCustomer) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  msg.status == MessageDeliveryStatus.read
                                                      ? Icons.done_all_rounded
                                                      : Icons.check_rounded,
                                                  size: 13,
                                                  color: const Color(0xFFBFDBFE),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  msg.status.label,
                                                  style: const TextStyle(fontSize: 10, color: Color(0xFFBFDBFE), fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (!isCustomer) ...[
                                    const SizedBox(width: 10),
                                    const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Color(0xFF1C7BFF),
                                      child: Icon(Icons.send_rounded, size: 14, color: Colors.white),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                // Quick Templates & Tokens Bar (like Quick Replies in Service Center)
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
                          'Quick Templates: ',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                        ),
                        ..._quickTemplates.map((tmpl) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(tmpl['title'] as String),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                              onPressed: () => _applyTemplate(tmpl),
                            ),
                          );
                        }),
                        const SizedBox(width: 6),
                        const Text(
                          'Tokens: ',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ActionChip(
                            label: const Text('+ {name}'),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: const Color(0xFFEFF6FF),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            labelStyle: const TextStyle(fontSize: 10.5, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w700),
                            onPressed: () => _insertToken('{name}'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ActionChip(
                            label: const Text('+ {phone}'),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: const Color(0xFFEFF6FF),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            labelStyle: const TextStyle(fontSize: 10.5, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w700),
                            onPressed: () => _insertToken('{phone}'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ActionChip(
                            label: const Text('+ {branch}'),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: const Color(0xFFEFF6FF),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            labelStyle: const TextStyle(fontSize: 10.5, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w700),
                            onPressed: () => _insertToken('{branch}'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Reply Input Composer Box (with "Compose New Message" header for tests and clarity)
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF1C7BFF)),
                              const Text(
                                'Compose New Message',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(_selectedChannel.colorValue).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _selectedChannel.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(_selectedChannel.colorValue),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Category Selector
                          Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<MessageCategory>(
                                value: _selectedCategory,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                items: MessageCategory.values.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat.label),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedCategory = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _subjectController,
                        style: const TextStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'Subject / Notification Title (e.g. Order #ORD-2026-001 Ready)',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              maxLines: 3,
                              minLines: 2,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Type your message to ${_selectedCustomer!.fullName} via ${_selectedChannel.label}...',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
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
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isSending ? null : _handleSendMessage,
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.send_rounded, size: 16),
                              label: Text(
                                'Send via ${_selectedChannel.label}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
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
        final contentMinWidth = math.max(1040.0, availableWidth);
        final listWidth = math.max(340.0, (contentMinWidth - 20) * 0.38);
        final chatWidth = math.max(580.0, contentMinWidth - 20 - listWidth);

        final workspaceRow = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: listWidth,
              child: customerListCard,
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: chatWidth,
              child: messagingDeskCard,
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

  Widget _buildKpiPill(
    String label,
    String value,
    Color textColor,
    Color bgColor, {
    MessageChannel? channel,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: 'Click to view $label message details & audit trail',
        child: InkWell(
          onTap: () {
            setState(() {
              if (channel == null) {
                _channelFilter = 'ALL';
              } else if (channel == MessageChannel.inApp) {
                _channelFilter = 'INAPP';
              } else if (channel == MessageChannel.email) {
                _channelFilter = 'EMAIL';
              }
            });
            _showChannelDetailsDialog(label: label, initialChannel: channel);
          },
          borderRadius: BorderRadius.circular(6),
          mouseCursor: SystemMouseCursors.click,
          hoverColor: textColor.withValues(alpha: 0.08),
          splashColor: textColor.withValues(alpha: 0.12),
          child: Ink(
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
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 11,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChannelDetailsDialog({
    required String label,
    MessageChannel? initialChannel,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _ChannelMessageDetailsDialog(
        label: label,
        initialChannel: initialChannel,
        repository: widget.repository,
        onSelectCustomer: (customer, targetChannel) {
          Navigator.of(dialogCtx).pop();
          setState(() {
            _selectedCustomer = customer;
            if (targetChannel != null) {
              _selectedChannel = targetChannel;
            }
          });
          _scrollToBottom();
        },
        onComposeNew: (targetChannel) {
          Navigator.of(dialogCtx).pop();
          if (targetChannel != null) {
            setState(() {
              _selectedChannel = targetChannel;
            });
          }
        },
        onFilterWorkspace: (channelFilterKey) {
          Navigator.of(dialogCtx).pop();
          setState(() {
            _channelFilter = channelFilterKey;
          });
        },
      ),
    );
  }

  Widget _buildChannelFilterChip(String value, String label) {
    final isSelected = _channelFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _channelFilter = value);
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

class _ChannelMessageDetailsDialog extends StatefulWidget {
  final String label;
  final MessageChannel? initialChannel;
  final ManagerRepository repository;
  final void Function(CustomerActivity customer, MessageChannel? targetChannel) onSelectCustomer;
  final void Function(MessageChannel? targetChannel) onComposeNew;
  final void Function(String channelFilterKey) onFilterWorkspace;

  const _ChannelMessageDetailsDialog({
    required this.label,
    required this.initialChannel,
    required this.repository,
    required this.onSelectCustomer,
    required this.onComposeNew,
    required this.onFilterWorkspace,
  });

  @override
  State<_ChannelMessageDetailsDialog> createState() => _ChannelMessageDetailsDialogState();
}

class _ChannelMessageDetailsDialogState extends State<_ChannelMessageDetailsDialog> {
  late MessageChannel? _activeChannel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeChannel = widget.initialChannel;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CustomerMessage> get _filteredMessages {
    final allMessages = widget.repository.sentMessages;
    final query = _searchController.text.trim().toLowerCase();

    final filtered = allMessages.where((m) {
      if (_activeChannel != null && m.channel != _activeChannel) {
        return false;
      }
      if (query.isEmpty) return true;
      return m.customerName.toLowerCase().contains(query) ||
          m.customerPhone.toLowerCase().contains(query) ||
          m.customerEmail.toLowerCase().contains(query) ||
          m.subject.toLowerCase().contains(query) ||
          m.message.toLowerCase().contains(query) ||
          m.category.label.toLowerCase().contains(query) ||
          m.customerId.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return filtered;
  }

  String _getChannelTitle() {
    if (_activeChannel == null) {
      return 'All Sent Customer Messages';
    }
    switch (_activeChannel!) {
      case MessageChannel.inApp:
        return 'In-App Notification Messages';
      case MessageChannel.email:
        return 'Email Communications';
    }
  }

  String _getChannelSubtitle() {
    if (_activeChannel == null) {
      return 'Audit log and delivery status of outbound customer communications across In-App Notification and Email.';
    }
    switch (_activeChannel!) {
      case MessageChannel.inApp:
        return 'Direct mobile notifications pushed to registered customers in the Siaka Mobile App.';
      case MessageChannel.email:
        return 'Official receipts, invoices, and service notification emails sent to customer inboxes.';
    }
  }

  IconData _getChannelIcon(MessageChannel? channel) {
    if (channel == null) return Icons.mark_chat_read_rounded;
    switch (channel) {
      case MessageChannel.inApp:
        return Icons.notifications_active_rounded;
      case MessageChannel.email:
        return Icons.email_rounded;
    }
  }

  Color _getChannelColor(MessageChannel? channel) {
    if (channel == null) return const Color(0xFF0F172A);
    return Color(channel.colorValue);
  }

  @override
  Widget build(BuildContext context) {
    final sentMessages = widget.repository.sentMessages;
    final inAppCount = sentMessages.where((m) => m.channel == MessageChannel.inApp).length;
    final emailCount = sentMessages.where((m) => m.channel == MessageChannel.email).length;

    final messages = _filteredMessages;
    final channelColor = _getChannelColor(_activeChannel);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      elevation: 16,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: math.min(740, MediaQuery.of(context).size.height * 0.9),
        ),
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: channelColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getChannelIcon(_activeChannel),
                      color: channelColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            Text(
                              _getChannelTitle(),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: channelColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${messages.length} ${messages.length == 1 ? 'Message' : 'Messages'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: channelColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _getChannelSubtitle(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                    tooltip: 'Close Details Dialog',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Channel Filter Chips & Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9)),
                ),
              ),
              child: Column(
                children: [
                  // Channel Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTabChip(null, 'All Sent', sentMessages.length, const Color(0xFF0F172A)),
                        const SizedBox(width: 8),
                        _buildTabChip(MessageChannel.inApp, 'In-App', inAppCount, const Color(0xFF7C3AED)),
                        const SizedBox(width: 8),
                        _buildTabChip(MessageChannel.email, 'Email', emailCount, const Color(0xFFB45309)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Search by customer name, phone, subject, or message text...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () => setState(() => _searchController.clear()),
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                ],
              ),
            ),

            // Channel Metric Summary Bar
            _buildChannelSummaryBar(messages),

            // Message Cards List
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return _buildMessageCard(context, msg);
                      },
                    ),
            ),

            // Footer Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Text(
                    'Showing ${messages.length} of ${sentMessages.length} total sent messages',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_activeChannel != null)
                        OutlinedButton.icon(
                          onPressed: () {
                            final key = _activeChannel == MessageChannel.inApp
                                ? 'INAPP'
                                : _activeChannel!.name.toUpperCase();
                            widget.onFilterWorkspace(key);
                          },
                          icon: const Icon(Icons.filter_alt_outlined, size: 15),
                          label: Text(
                            'Filter Workspace by ${_activeChannel!.label}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: channelColor,
                            side: BorderSide(color: channelColor.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Close', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(MessageChannel? channel, String label, int count, Color color) {
    final isSelected = _activeChannel == channel;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _activeChannel = channel);
      },
      backgroundColor: const Color(0xFFF1F5F9),
      selectedColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? color : const Color(0xFF475569),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(
        color: isSelected ? color : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildChannelSummaryBar(List<CustomerMessage> messages) {
    final channelColor = _getChannelColor(_activeChannel);
    final deliveredCount = messages
        .where((m) =>
            m.status == MessageDeliveryStatus.delivered ||
            m.status == MessageDeliveryStatus.read)
        .length;
    final deliveryRate =
        messages.isEmpty ? 100 : ((deliveredCount / messages.length) * 100).round();
    final uniqueRecipients = messages.map((m) => m.customerId).toSet().length;

    String gatewayLabel;
    if (_activeChannel == null) {
      gatewayLabel = 'In-App & Email Active';
    } else {
      switch (_activeChannel!) {
        case MessageChannel.inApp:
          gatewayLabel = 'Push Notification Active';
          break;
        case MessageChannel.email:
          gatewayLabel = 'SMTP Mailer Ready';
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: channelColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: channelColor.withValues(alpha: 0.15)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryMetric(
              'TOTAL SENT',
              '${messages.length}',
              Icons.outbox_rounded,
              channelColor,
            ),
            const SizedBox(width: 18),
            Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
            const SizedBox(width: 18),
            _buildSummaryMetric(
              'DELIVERY RATE',
              '$deliveryRate%',
              Icons.verified_rounded,
              const Color(0xFF16A34A),
            ),
            const SizedBox(width: 18),
            Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
            const SizedBox(width: 18),
            _buildSummaryMetric(
              'RECIPIENTS',
              '$uniqueRecipients Customer${uniqueRecipients == 1 ? '' : 's'}',
              Icons.people_alt_rounded,
              const Color(0xFF0F172A),
            ),
            const SizedBox(width: 18),
            Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
            const SizedBox(width: 18),
            _buildSummaryMetric(
              'GATEWAY ROUTE',
              gatewayLabel,
              Icons.hub_rounded,
              const Color(0xFF2563EB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String title, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isEmail = _activeChannel == MessageChannel.email;
    final isSearch = _searchController.text.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                isSearch
                    ? Icons.search_off_rounded
                    : (isEmail ? Icons.mark_email_unread_rounded : Icons.forum_outlined),
                size: 40,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch
                  ? 'No messages found'
                  : (isEmail ? 'No Email Messages Recorded Yet' : 'No Messages in this Channel'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearch
                  ? 'No sent messages match "${_searchController.text}". Try a different keyword.'
                  : (isEmail
                      ? 'Direct official emails sent to customers will be logged, timestamped, and audited here.'
                      : 'Messages sent via this channel will appear here automatically.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            if (isSearch)
              OutlinedButton.icon(
                onPressed: () => setState(() => _searchController.clear()),
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: const Text('Clear Search'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1C7BFF),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => widget.onComposeNew(_activeChannel ?? MessageChannel.inApp),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text(
                  isEmail ? 'Compose New Email Message' : 'Compose Message',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C7BFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context, CustomerMessage msg) {
    final channelColor = Color(msg.channel.colorValue);
    final statusColor = Color(msg.status.textColor);
    final statusBgColor = Color(msg.status.bgColor);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Recipient & Delivery Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: channelColor.withValues(alpha: 0.15),
                  child: Text(
                    msg.customerName.isNotEmpty ? msg.customerName[0].toUpperCase() : 'C',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: channelColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            msg.customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text(
                              msg.customerId,
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            msg.customerPhone,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                          if (msg.customerEmail.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                            const SizedBox(width: 6),
                            Text(
                              msg.customerEmail,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Delivery Status Pill & Sent Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            msg.status == MessageDeliveryStatus.read
                                ? Icons.done_all_rounded
                                : (msg.status == MessageDeliveryStatus.delivered
                                    ? Icons.done_all_rounded
                                    : Icons.check_rounded),
                            size: 13,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            msg.status.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('MMM d, y • HH:mm').format(msg.sentAt),
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Message Subject & Category Badges
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                // Channel Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: channelColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: channelColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getChannelIcon(msg.channel), size: 12, color: channelColor),
                      const SizedBox(width: 4),
                      Text(
                        msg.channel.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: channelColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    msg.category.label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),

                // Subject Text
                Text(
                  msg.subject,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          // Message Body Container
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SelectableText(
                msg.message,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ),

          // Action Toolbar on Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_pin_rounded, size: 14, color: channelColor),
                    const SizedBox(width: 5),
                    Text(
                      'Sent by ${msg.sentBy} • Local & Cloud Synced',
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: msg.message));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Message copied: "${msg.subject}"'),
                            backgroundColor: const Color(0xFF0F172A),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 13),
                      label: const Text('Copy Text', style: TextStyle(fontSize: 11.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        final matching = widget.repository.customers.firstWhere(
                          (c) =>
                              c.id == msg.customerId ||
                              c.phone.replaceAll(' ', '') == msg.customerPhone.replaceAll(' ', ''),
                          orElse: () => CustomerActivity(
                            id: msg.customerId,
                            fullName: msg.customerName,
                            phone: msg.customerPhone,
                            email: msg.customerEmail,
                            signupDate: msg.sentAt,
                            loginCount: 1,
                            lastLogin: msg.sentAt,
                            primaryDevice: 'Registered Device',
                            status: 'Active',
                            totalSpend: 0,
                            totalOrders: 0,
                            branch: widget.repository.currentBranch,
                            isOnline: true,
                          ),
                        );
                        widget.onSelectCustomer(matching, msg.channel);
                      },
                      icon: const Icon(Icons.forum_rounded, size: 13),
                      label: const Text('Open Thread & Reply', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: channelColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

