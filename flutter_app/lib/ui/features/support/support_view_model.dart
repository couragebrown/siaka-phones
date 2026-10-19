import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/customer_telemetry_service.dart';
import '../../../data/services/supabase_service.dart';

class ChatMessage {
  final String? id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class SupportViewModel extends ChangeNotifier {
  static const String customerServicePhone = '+233 (024) 555-0192';
  static const String customerServiceEmail = 'support@siakaphones.com';
  static const String workingHours = 'Mon - Sat: 8:00 AM - 8:00 PM GMT';

  final UserRepository? _userRepo;
  final List<ChatMessage> _messages = [];
  final Set<String> _processedMessageKeys = {};

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  Timer? _presenceTimer;
  StreamSubscription? _supabaseSub;
  HttpClient? _sseClient;

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  List<String> get quickTopics => const [
        'Customer service line',
        'Track my order',
        'Warranty & repair',
        'Trade-in value',
        'Store locations',
      ];

  String get _effectiveCustomerId {
    try {
      final p = _userRepo?.profile ?? UserRepository.instance.profile;
      if (p.id.isNotEmpty) return p.id;
    } catch (_) {}
    return 'SK-90001';
  }

  String get _effectiveCustomerName {
    try {
      final p = _userRepo?.profile ?? UserRepository.instance.profile;
      if (p.fullName.isNotEmpty) return p.fullName;
    } catch (_) {}
    return 'Courage Brown';
  }

  String get _effectiveCustomerPhone {
    try {
      final p = _userRepo?.profile ?? UserRepository.instance.profile;
      if (p.phone.isNotEmpty) return p.phone;
    } catch (_) {}
    return '+233 (024) 555-0192';
  }

  String get _effectiveCustomerEmail {
    try {
      final p = _userRepo?.profile ?? UserRepository.instance.profile;
      if (p.email.isNotEmpty) return p.email;
    } catch (_) {}
    return 'courage@siakaphones.com';
  }

  SupportViewModel({UserRepository? userRepository}) : _userRepo = userRepository {
    // Initial welcome message
    final initialMsg = ChatMessage(
      id: 'MSG_WELCOME_INITIAL',
      text:
          'Hello! Welcome to the Siaka Phones Support Team. How can we assist you today? You can ask us anything here or speak directly to our team on our Customer Service Line at $customerServicePhone.',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    );
    _messages.add(initialMsg);
    _processedMessageKeys.add('MSG_WELCOME_INITIAL');

    // Only start background timers and network streams when NOT in a test environment
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _initRealtimeChatSync();
      _presenceTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        _pingPresence();
      });
    }
  }

  void _pingPresence() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    CustomerTelemetryService.pingSession(
      customerId: _effectiveCustomerId,
      name: _effectiveCustomerName,
      email: _effectiveCustomerEmail,
      phone: _effectiveCustomerPhone,
    );
  }

  Future<void> _initRealtimeChatSync() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    // 1. Immediate presence ping to mark customer online on manager desktop
    _pingPresence();

    // 2. Fetch existing history from local PC manager & Supabase
    await _fetchInitialHistory();

    // 3. Start local SSE event stream for live instant messages
    _startSseListener();

    // 4. Start Supabase real-time stream
    _startSupabaseStream();
  }

  Future<void> _fetchInitialHistory() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    // A. Local PC Manager HTTP GET /api/messages?customerId=...
    try {
      final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1200);
      final req = await client.getUrl(Uri.parse('http://$host:8088/api/messages?customerId=$_effectiveCustomerId'));
      final res = await req.close().timeout(const Duration(milliseconds: 1200));
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final decoded = jsonDecode(body);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              _handleIncomingMessageMap(item, notify: false);
            }
          }
        }
      }
    } catch (_) {}

    // B. Supabase fetchChatMessageRecords
    try {
      final supabase = SupabaseService();
      if (!supabase.isInitialized || supabase.client == null) {
        await supabase.initialize();
      }
      final records = await supabase.fetchChatMessageRecords(customerId: _effectiveCustomerId);
      if (records != null && records.isNotEmpty) {
        // Oldest first
        records.sort((a, b) {
          final aTime = a['created_at']?.toString() ?? '';
          final bTime = b['created_at']?.toString() ?? '';
          return aTime.compareTo(bTime);
        });
        for (final rec in records) {
          _parseSupabaseRecord(rec, notify: false);
        }
      }
    } catch (_) {}

    notifyListeners();
  }

  void _startSseListener() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      _sseClient = HttpClient()..connectionTimeout = const Duration(seconds: 2);
      _sseClient!.getUrl(Uri.parse('http://$host:8088/api/events')).then((request) {
        request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
        return request.close();
      }).then((response) {
        if (response.statusCode == 200) {
          response.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
            if (line.startsWith('data:')) {
              try {
                final jsonStr = line.substring(5).trim();
                final payload = jsonDecode(jsonStr);
                if (payload is Map<String, dynamic> && payload['type'] == 'chat_message') {
                  final data = payload['data'];
                  if (data is Map<String, dynamic>) {
                    _handleIncomingMessageMap(data, notify: true);
                  }
                }
              } catch (_) {}
            }
          }, onError: (_) {});
        }
      }).catchError((_) {});
    } catch (_) {}
  }

  void _startSupabaseStream() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final supabase = SupabaseService();
      _supabaseSub = supabase.streamChatMessageRecords(customerId: _effectiveCustomerId)?.listen((records) {
        for (final rec in records) {
          _parseSupabaseRecord(rec, notify: true);
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  void _parseSupabaseRecord(Map<String, dynamic> rec, {bool notify = true}) {
    if (rec.containsKey('specs') && rec['specs'] != null) {
      try {
        final parsed = jsonDecode(rec['specs'].toString());
        if (parsed is Map<String, dynamic>) {
          _handleIncomingMessageMap(parsed, notify: notify);
          return;
        }
      } catch (_) {}
    }
    _handleIncomingMessageMap(rec, notify: notify);
  }

  void _handleIncomingMessageMap(Map<String, dynamic> map, {bool notify = true}) {
    final custId = map['customerId']?.toString() ?? map['customer_id']?.toString() ?? map['storage']?.toString() ?? '';
    if (custId.isNotEmpty && custId != _effectiveCustomerId) {
      return;
    }

    final msgText = map['message']?.toString() ?? map['text']?.toString() ?? '';
    if (msgText.trim().isEmpty) return;

    final id = map['id']?.toString() ?? '${map['sentAt']}_$msgText';
    if (_processedMessageKeys.contains(id)) return;
    _processedMessageKeys.add(id);

    final isUser = map['isFromCustomer'] == true || map['is_from_customer'] == true;
    final timeStr = map['sentAt']?.toString() ?? map['created_at']?.toString() ?? '';
    final time = DateTime.tryParse(timeStr) ?? DateTime.now();

    _messages.add(ChatMessage(
      id: id,
      text: msgText,
      isUser: isUser,
      timestamp: time,
    ));

    if (!isUser) {
      _isTyping = false;
    }

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final now = DateTime.now();
    final msgId = 'MSG_${now.millisecondsSinceEpoch}';
    _processedMessageKeys.add(msgId);

    _messages.add(ChatMessage(
      id: msgId,
      text: cleanText,
      isUser: true,
      timestamp: now,
    ));
    _isTyping = true;
    notifyListeners();

    // 1. Dispatch in background to local sync server and Supabase
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _dispatchMessageRemotely(msgId: msgId, text: cleanText, timestamp: now);
    }

    // 2. Automated assistant heuristics for immediate response / fallback
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

    // In unit/widget tests or if auto-reply is needed
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _messages.add(
          ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()));
      _isTyping = false;
      notifyListeners();
    } else {
      // In production, keep typing indicator or add automated reply only if manager hasn't replied yet
      if (_isTyping) {
        _messages.add(ChatMessage(
          id: 'MSG_AUTO_${DateTime.now().millisecondsSinceEpoch}',
          text: reply,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
        notifyListeners();
      }
    }
  }

  Future<void> _dispatchMessageRemotely({
    required String msgId,
    required String text,
    required DateTime timestamp,
  }) async {
    final payload = {
      'id': msgId,
      'customerId': _effectiveCustomerId,
      'customerName': _effectiveCustomerName,
      'customerPhone': _effectiveCustomerPhone,
      'customerEmail': _effectiveCustomerEmail,
      'message': text,
      'subject': 'Support Chat',
      'channel': 'inApp',
      'isFromCustomer': true,
      'sentBy': _effectiveCustomerName,
      'sentAt': timestamp.toIso8601String(),
      'status': 'sent',
    };

    // A. Local PC Manager HTTP POST /api/messages
    try {
      final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1200);
      final req = await client.postUrl(Uri.parse('http://$host:8088/api/messages'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(payload));
      await req.close().timeout(const Duration(milliseconds: 1200));
    } catch (_) {}

    // B. Supabase primary & fallback sync
    try {
      final supabase = SupabaseService();
      if (!supabase.isInitialized || supabase.client == null) {
        await supabase.initialize();
      }
      await supabase.upsertChatMessageRaw(payload);
    } catch (_) {}

    // C. Presence ping
    _pingPresence();
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _supabaseSub?.cancel();
    try {
      _sseClient?.close(force: true);
    } catch (_) {}
    super.dispose();
  }
}
