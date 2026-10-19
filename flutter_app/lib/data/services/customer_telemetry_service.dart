import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Sends real-time customer session telemetry (logins, online status, device telemetry)
/// to the local PC Manager and Supabase database.
class CustomerTelemetryService {
  /// Pings session telemetry to database and local sync server.
  /// Fully non-blocking and safe against quota-exceeded or offline errors.
  static Future<void> pingSession({
    required String customerId,
    required String name,
    required String email,
    required String phone,
    String? device,
    bool isLogin = false,
  }) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    final dev = device ??
        (Platform.isAndroid
            ? 'Android Device'
            : Platform.isIOS
                ? 'iPhone (iOS)'
                : 'Mobile Client');

    // 1. Send to local PC Manager if reachable (port 8088)
    try {
      final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1000);
      final req = await client.postUrl(Uri.parse('http://$host:8088/api/telemetry'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'customerId': customerId,
        'name': name,
        'email': email,
        'phone': phone,
        'device': dev,
        'isLogin': isLogin,
      }));
      await req.close().timeout(const Duration(milliseconds: 1000));
    } catch (_) {
      // Local sync server offline, proceed
    }

    // 2. Sync to Supabase in background (safe, non-blocking with 2s timeout)
    if (SupabaseService.isQuotaRestricted) {
      return;
    }
    try {
      final supabase = SupabaseService();
      if (!supabase.isInitialized || supabase.client == null) {
        await supabase.initialize();
      }
      if (supabase.isInitialized && supabase.client != null) {
        // Dedicated 'customers' table if exists
        try {
          await supabase.client!.from('customers').upsert({
            'id': customerId,
            'full_name': name,
            'email': email,
            'phone': phone,
            'last_login': DateTime.now().toIso8601String(),
            'primary_device': dev,
            'is_online': true,
          }).timeout(const Duration(seconds: 2));
        } catch (_) {}

        // Universal 'products' fallback record
        final token = {
          'id': 'CUSTOMER_$customerId',
          'name': name,
          'brand': dev,
          'category': 'CUSTOMER_RECORD',
          'specs': jsonEncode({
            'customerId': customerId,
            'fullName': name,
            'email': email,
            'phone': phone,
            'lastLogin': DateTime.now().toIso8601String(),
            'primaryDevice': dev,
            'isOnline': true,
          }),
          'storage': customerId,
          'ram': phone,
          'color': email,
          'condition': 'Active',
          'is_featured': false,
          'created_at': DateTime.now().toIso8601String(),
        };
        await supabase.upsertRawRecord(token);
      }
    } catch (e) {
      debugPrint('ℹ️ Telemetry sync deferred (quota/offline): $e');
    }
  }
}
