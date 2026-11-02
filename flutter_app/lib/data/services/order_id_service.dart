import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

/// Provides chronological Order ID numbering (`ORD-000001`, `ORD-000002`, ...)
/// incrementing sequentially across the Customer App, PC Manager Desktop, and Supabase.
class OrderIdService {
  static const String _keyLastOrderSeq = 'last_order_seq_id_v1';

  /// Formats a positive sequence integer into `ORD-000001` (6+ digits).
  static String formatOrderId(int seq) {
    final safeSeq = seq < 1 ? 1 : seq;
    return 'ORD-${safeSeq.toString().padLeft(6, '0')}';
  }

  /// Extracts the numeric sequence from a canonical `ORD-000001` (or `ORDER_ORD-000001`) ID.
  /// Returns `null` for legacy non-`ORD-` IDs (such as `SP-883921`) so random numbers
  /// never skew chronological numbering.
  static int? extractOrderSeq(String rawId) {
    final cleaned = rawId
        .replaceFirst(RegExp(r'^ORDER_', caseSensitive: false), '')
        .replaceAll(' ', '')
        .trim();
    final match = RegExp(r'^ORD-(\d+)$', caseSensitive: false).firstMatch(cleaned);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// Records an observed `ORD-xxxxxx` order ID so future local IDs continue past it.
  static Future<void> observeOrderId(String rawId) async {
    final seq = extractOrderSeq(rawId);
    if (seq == null || seq <= 0) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final prev = prefs.getInt(_keyLastOrderSeq) ?? 0;
      if (seq > prev) {
        await prefs.setInt(_keyLastOrderSeq, seq);
      }
    } catch (_) {}
  }

  /// Generates the next chronological Order ID (`ORD-000001`, `ORD-000002`, ...).
  static Future<String> generateNextOrderId({
    Iterable<String> existingOrderIds = const [],
  }) async {
    int maxExisting = 0;
    for (final id in existingOrderIds) {
      final seq = extractOrderSeq(id);
      if (seq != null && seq > maxExisting) {
        maxExisting = seq;
      }
    }

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return formatOrderId(maxExisting + 1);
    }

    SharedPreferences? prefs;
    int savedSeq = 0;
    try {
      prefs = await SharedPreferences.getInstance();
      savedSeq = prefs.getInt(_keyLastOrderSeq) ?? 0;
    } catch (_) {}

    int baseMax = math.max(maxExisting, savedSeq);
    int? remoteNextSeq;

    // 1. Query PC Manager local sync server if online on local network
    try {
      final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 900);
      final req = await client.getUrl(Uri.parse('http://$host:8088/api/next_order_id'));
      final resp = await req.close().timeout(const Duration(milliseconds: 900));
      if (resp.statusCode == HttpStatus.ok) {
        final body = await resp.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final candidate = json['orderId']?.toString() ?? json['id']?.toString() ?? '';
        remoteNextSeq = extractOrderSeq(candidate);
      }
    } catch (_) {}

    // 2. Fallback: check Supabase order records if PC Manager was unreachable
    if (remoteNextSeq == null && !SupabaseService.isQuotaRestricted) {
      try {
        final records = await SupabaseService()
            .fetchOrderRecords()
            .timeout(const Duration(milliseconds: 1200));
        if (records != null) {
          int remoteMax = 0;
          for (final rec in records) {
            final idStr = (rec['id'] ?? rec['storage'] ?? '').toString();
            final seq = extractOrderSeq(idStr);
            if (seq != null && seq > remoteMax) {
              remoteMax = seq;
            }
          }
          if (remoteMax > 0) {
            remoteNextSeq = remoteMax + 1;
          }
        }
      } catch (_) {}
    }

    final nextSeq = math.max(remoteNextSeq ?? 0, baseMax + 1);
    try {
      await prefs?.setInt(_keyLastOrderSeq, nextSeq);
    } catch (_) {}

    final formatted = formatOrderId(nextSeq);
    debugPrint('✅ Generated chronological order ID: $formatted');
    return formatted;
  }
}

