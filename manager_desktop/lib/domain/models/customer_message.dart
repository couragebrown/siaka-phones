enum MessageChannel {
  inApp('In-App Notification', 0xFF7C3AED),
  email('Email', 0xFFD97706);

  final String label;
  final int colorValue;
  const MessageChannel(this.label, this.colorValue);
}

enum MessageCategory {
  orderUpdate('Order Update'),
  paymentReminder('BNPL Installment Reminder'),
  promotional('Promo / VIP Offer'),
  repairNotice('Repair Status Notice'),
  general('General Inquiry');

  final String label;
  const MessageCategory(this.label);
}

enum MessageDeliveryStatus {
  sent('Sent', 0xFF64748B, 0xFFF1F5F9),
  delivered('Delivered', 0xFF0284C7, 0xFFE0F2FE),
  read('Read', 0xFF059669, 0xFFECFDF5);

  final String label;
  final int textColor;
  final int bgColor;
  const MessageDeliveryStatus(this.label, this.textColor, this.bgColor);
}

class CustomerMessage {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final MessageChannel channel;
  final MessageCategory category;
  final String subject;
  final String message;
  final DateTime sentAt;
  final String sentBy;
  MessageDeliveryStatus status;
  final bool isFromCustomer;

  CustomerMessage({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.channel,
    required this.category,
    required this.subject,
    required this.message,
    required this.sentAt,
    this.sentBy = 'Store Manager',
    this.status = MessageDeliveryStatus.delivered,
    this.isFromCustomer = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerEmail': customerEmail,
    'channel': channel.name,
    'channelLabel': channel.label,
    'category': category.name,
    'subject': subject,
    'message': message,
    'sentAt': sentAt.toIso8601String(),
    'sentBy': sentBy,
    'status': status.name,
    'isFromCustomer': isFromCustomer,
  };

  factory CustomerMessage.fromJson(Map<String, dynamic> map) {
    MessageChannel chan = MessageChannel.inApp;
    final chName = map['channel']?.toString().toLowerCase() ?? '';
    for (final c in MessageChannel.values) {
      if (c.name.toLowerCase() == chName) {
        chan = c;
        break;
      }
    }

    MessageCategory cat = MessageCategory.general;
    final catName = map['category']?.toString().toLowerCase() ?? '';
    for (final c in MessageCategory.values) {
      if (c.name.toLowerCase() == catName) {
        cat = c;
        break;
      }
    }

    MessageDeliveryStatus stat = MessageDeliveryStatus.delivered;
    final statName = map['status']?.toString().toLowerCase() ?? '';
    for (final s in MessageDeliveryStatus.values) {
      if (s.name.toLowerCase() == statName) {
        stat = s;
        break;
      }
    }

    return CustomerMessage(
      id: map['id']?.toString() ?? 'MSG-${DateTime.now().millisecondsSinceEpoch}',
      customerId: map['customerId']?.toString() ?? map['customer_id']?.toString() ?? 'CUST-001',
      customerName: map['customerName']?.toString() ?? map['customer_name']?.toString() ?? 'Customer',
      customerPhone: map['customerPhone']?.toString() ?? map['customer_phone']?.toString() ?? '',
      customerEmail: map['customerEmail']?.toString() ?? map['customer_email']?.toString() ?? '',
      channel: chan,
      category: cat,
      subject: map['subject']?.toString() ?? 'Customer Chat',
      message: map['message']?.toString() ?? map['text']?.toString() ?? '',
      sentAt: map['sentAt'] != null
          ? DateTime.tryParse(map['sentAt'].toString())?.toLocal() ?? DateTime.now()
          : map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString())?.toLocal() ?? DateTime.now()
              : DateTime.now(),
      sentBy: map['sentBy']?.toString() ?? (map['isFromCustomer'] == true ? 'Customer' : 'Store Manager'),
      status: stat,
      isFromCustomer: map['isFromCustomer'] == true || map['is_from_customer'] == true,
    );
  }

  CustomerMessage copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    MessageChannel? channel,
    MessageCategory? category,
    String? subject,
    String? message,
    DateTime? sentAt,
    String? sentBy,
    MessageDeliveryStatus? status,
    bool? isFromCustomer,
  }) {
    return CustomerMessage(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      channel: channel ?? this.channel,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      sentAt: sentAt ?? this.sentAt,
      sentBy: sentBy ?? this.sentBy,
      status: status ?? this.status,
      isFromCustomer: isFromCustomer ?? this.isFromCustomer,
    );
  }
}
