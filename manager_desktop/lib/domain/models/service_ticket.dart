enum ServiceSenderType {
  customer,
  manager,
}

enum ServiceTicketStatus {
  open('New Inquiry', 0xFF2563EB, 0xFFEFF6FF),
  inProgress('In Progress', 0xFFD97706, 0xFFFEF3C7),
  waitingCustomer('Waiting for Customer', 0xFF7C3AED, 0xFFF3E8FF),
  resolved('Resolved', 0xFF059669, 0xFFECFDF5);

  final String label;
  final int textColor;
  final int bgColor;
  const ServiceTicketStatus(this.label, this.textColor, this.bgColor);
}

enum ServiceTicketPriority {
  normal('Normal', 0xFF64748B),
  high('High Priority', 0xFFD97706),
  urgent('Urgent', 0xFFDC2626);

  final String label;
  final int colorValue;
  const ServiceTicketPriority(this.label, this.colorValue);
}

class ServiceMessage {
  final String id;
  final ServiceSenderType senderType;
  final String senderName;
  final String text;
  final DateTime timestamp;
  bool isRead;

  ServiceMessage({
    required this.id,
    required this.senderType,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = true,
  });

  bool get isFromCustomer => senderType == ServiceSenderType.customer;
}

class ServiceTicket {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String subject;
  final String deviceOrTopic;
  final String? relatedReferenceId;
  final DateTime createdAt;
  ServiceTicketStatus status;
  ServiceTicketPriority priority;
  final List<ServiceMessage> messages;

  ServiceTicket({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.subject,
    required this.deviceOrTopic,
    this.relatedReferenceId,
    required this.createdAt,
    this.status = ServiceTicketStatus.open,
    this.priority = ServiceTicketPriority.normal,
    required this.messages,
  });

  ServiceMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  int get unreadCountForManager =>
      messages.where((m) => m.isFromCustomer && !m.isRead).length;
}
