import 'package:flutter/services.dart';

/// Service to launch native device phone dialer with a pre-filled phone number.
class DialerService {
  static const MethodChannel _channel = MethodChannel('com.siakaphones.app/dialer');

  /// Opens the phone's native dial pad with [phoneNumber] pre-filled.
  /// Returns `true` if successfully dispatched to the native dialer, `false` otherwise.
  static Future<bool> openDialer(String phoneNumber) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final bool? result = await _channel.invokeMethod<bool>('openDialer', {
        'number': cleanNumber,
      });
      return result ?? true;
    } catch (_) {
      return false;
    }
  }
}
