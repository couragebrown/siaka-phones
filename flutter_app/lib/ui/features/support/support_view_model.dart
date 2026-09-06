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
  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          'Hello! I am your Siaka AI Assistant. How can I help with your device, order status, or warranty today?',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages
        .add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    _isTyping = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    String reply =
        'Thank you for reaching out! A Siaka specialist has logged your inquiry. You can also visit our physical boutiques or schedule an express diagnostic.';
    final lower = text.toLowerCase();
    if (lower.contains('track') || lower.contains('order')) {
      reply =
          'You can track all active shipments under your Profile > Order History section in real-time.';
    } else if (lower.contains('warranty') || lower.contains('repair')) {
      reply =
          'All Siaka flagships include 2 years of comprehensive SiakaCare+ accidental damage & liquid coverage.';
    } else if (lower.contains('trade') || lower.contains('price')) {
      reply =
          'Our trade-in valuation tool offers up to ₵800 instant credit toward any new Siaka Titan or Apex device.';
    }

    _messages.add(
        ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()));
    _isTyping = false;
    notifyListeners();
  }
}
