import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

/// Provides chronological Customer ID numbering (e.g. SK-90015, SK-90016...)
/// incrementing by 1 for each customer signup and synchronizing with PC Manager and Supabase.
class CustomerIdService {
  static const String _keyLastCustomerId = 'last_customer_seq_id';
  static const int _defaultBaseSeq = 90014;

  /// Generates the next chronological Customer ID and registers the customer.
  static Future<String> registerAndGenerateId({
    required String name,
    required String email,
    required String phone,
    String? address,
    String? gpsCode,
    String? region,
    String? country,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? registeredId;

    // 1. First attempt to register with local PC Manager (port 8088)
    try {
      final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1200);
      final req = await client.postUrl(Uri.parse('http://$host:8088/api/register'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'address': address ?? '',
        'gpsCode': gpsCode ?? '',
        'region': region ?? '',
        'country': country ?? '',
        'device': Platform.isAndroid
            ? 'Android Device'
            : Platform.isIOS
                ? 'iPhone (iOS)'
                : 'Mobile Client',
      }));
      final resp = await req.close().timeout(const Duration(milliseconds: 1200));
      if (resp.statusCode == HttpStatus.ok) {
        final body = await resp.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final assignedId = json['id']?.toString() ?? json['customerId']?.toString();
        if (assignedId != null && assignedId.isNotEmpty) {
          final digits = assignedId.replaceAll(RegExp(r'[^0-9]'), '');
          final parsed = int.tryParse(digits);
          if (parsed != null) {
            await prefs.setInt(_keyLastCustomerId, parsed);
          }
          debugPrint('✅ Registered customer on PC Manager: $assignedId');
          registeredId = assignedId;
        }
      }
    } catch (_) {
      // Local sync server offline, proceed to persistent chronological local sequence
    }

    // 2. Persistent chronological fallback: starts from base and increases by 1
    if (registeredId == null) {
      int currentSeq = prefs.getInt(_keyLastCustomerId) ?? _defaultBaseSeq;
      if (currentSeq < _defaultBaseSeq) {
        currentSeq = _defaultBaseSeq;
      }
      final nextSeq = currentSeq + 1;
      await prefs.setInt(_keyLastCustomerId, nextSeq);

      registeredId = 'SK-$nextSeq';
      debugPrint('✅ Generated sequential customer ID: $registeredId');
    }

    // 3. Sync customer registration to Supabase database (in background, non-blocking)
    try {
      SupabaseService().upsertCustomerRecord({
        'id': registeredId,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address ?? '',
        'gpsCode': gpsCode ?? '',
        'region': region ?? '',
        'country': country ?? '',
        'device': Platform.isAndroid
            ? 'Android Device'
            : Platform.isIOS
                ? 'iPhone (iOS)'
                : 'Mobile Client',
      });
    } catch (e) {
      debugPrint('ℹ️ Supabase customer registration queued: $e');
    }

    return registeredId;
  }
}
