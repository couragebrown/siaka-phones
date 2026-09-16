import 'package:flutter/foundation.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class SupportViewModel extends ChangeNotifier {
  static const String customerServicePhone = '+233 (024) 555-0192';
  static const String customerServiceEmail = 'support@siakaphones.com';
  static const String workingHours = 'Mon - Sat: 8:00 AM - 8:00 PM GMT';

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          'Hello! Welcome to the Siaka Phones Support Team. How can we assist you today? You can ask us anything here or speak directly to our team on our Customer Service Line at $customerServicePhone.',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  List<String> get quickTopics => const [
        'Customer service line',
        'Track my order',
        'Warranty & repair',
        'Trade-in value',
        'Store locations',
      ];

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    _messages.add(
        ChatMessage(text: cleanText, isUser: true, timestamp: DateTime.now()));
    _isTyping = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    final lower = cleanText.toLowerCase();
    String reply =
        'Thank you for reaching out! A Siaka specialist has received your inquiry. You can also call our Customer Service Line directly at $customerServicePhone for immediate support.';

    if (lower.contains('call') ||
        lower.contains('phone') ||
        lower.contains('contact') ||
        lower.contains('line') ||
        lower.contains('number') ||
        lower.contains('speak') ||
        lower.contains('agent')) {
      reply =
          'Our Customer Care Team is available on $customerServicePhone during working hours ($workingHours). You can tap the "Call Line" button at the top to connect immediately.';
    } else if (lower.contains('track') || lower.contains('order')) {
      reply =
          'You can track active shipments anytime in the "Track Order" or "My Orders" sections. Enter your order ID (e.g. SP-88421) for instant status.';
    } else if (lower.contains('warranty') || lower.contains('repair')) {
      reply =
          'All flagship phones from Siaka Phones come with 1 year official brand warranty + SiakaCare+ protection. You can book an inspection under "Repairs" in the menu.';
    } else if (lower.contains('trade') || lower.contains('swap')) {
      reply =
          'Our trade-in program gives you instant credit toward any new smartphone or laptop. Select "Swap My Device" in the customer menu to get an instant valuation.';
    } else if (lower.contains('location') ||
        lower.contains('store') ||
        lower.contains('branch') ||
        lower.contains('where')) {
      reply =
          'We have official boutiques at Kwame Nkrumah Circle (Accra), Madina Zongo Junction, and Kasoa Main Highway. Open daily from 8:00 AM to 8:00 PM.';
    }

    _messages.add(
        ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()));
    _isTyping = false;
    notifyListeners();
  }
}
