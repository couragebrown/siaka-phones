enum MessageChannel {
  inApp('In-App Notification', 0xFF7C3AED),
  email('Email', 0xFFD97706),
  sms('SMS / Telco', 0xFF2563EB),
  whatsapp('WhatsApp', 0xFF16A34A);

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
}
