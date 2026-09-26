import 'dart:math' as math;
import 'package:flutter/material.dart';
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

  void _simulateCustomerReply() {
    if (_selectedCustomer == null) return;

    final sampleReplies = [
      'Thank you manager! I have received your message and will check the app.',
      'Thank you for the update. Could you please confirm the branch opening hours today?',
      'Understood! I will visit the Circle branch this afternoon with my Ghana Card.',
      'Thank you so much, appreciate the prompt customer support!',
    ];

    final randomReply = (sampleReplies..shuffle()).first;
    widget.repository.addIncomingCustomerReply(
      _selectedCustomer!.id,
      randomReply,
      channel: _selectedChannel,
    );

    _scrollToBottom();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mark_chat_unread_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('New incoming reply from ${_selectedCustomer!.fullName}!'),
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
    final whatsappCount = sentMessages.where((m) => m.channel == MessageChannel.whatsapp).length;
    final smsCount = sentMessages.where((m) => m.channel == MessageChannel.sms).length;
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
              'Direct multi-channel customer communications hub across In-App Notification, WhatsApp, SMS, and Email.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),

        // KPI Counters & Simulation Button
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildKpiPill('ALL SENT', '${sentMessages.length}', const Color(0xFF0F172A), const Color(0xFFF1F5F9)),
            _buildKpiPill('IN-APP', '$inAppCount', const Color(0xFF7C3AED), const Color(0xFFF3E8FF)),
            _buildKpiPill('WHATSAPP', '$whatsappCount', const Color(0xFF15803D), const Color(0xFFDCFCE7)),
            _buildKpiPill('SMS', '$smsCount', const Color(0xFF1D4ED8), const Color(0xFFDBEAFE)),
            _buildKpiPill('EMAIL', '$emailCount', const Color(0xFFB45309), const Color(0xFFFEF3C7)),
            ElevatedButton.icon(
              onPressed: _selectedCustomer == null ? null : _simulateCustomerReply,
              icon: const Icon(Icons.reply_all_rounded, size: 16),
              label: const Text('Simulate Inbound Reply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                _buildChannelFilterChip('WHATSAPP', 'WhatsApp'),
                const SizedBox(width: 6),
                _buildChannelFilterChip('SMS', 'SMS'),
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
                                        const SizedBox(width: 8),
                                        Flexible(
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
                                lastMsg != null
                                    ? (lastMsg.isFromCustomer ? 'Inbound: ' : 'Outbound: ') + lastMsg.message
                                    : 'Registered device: ${c.primaryDevice}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF475569),
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

  Widget _buildKpiPill(String label, String value, Color textColor, Color bgColor) {
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
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
          ),
        ],
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
