import 'dart:io';
import 'package:flutter/services.dart';

class DeviceNotificationService {
  static final DeviceNotificationService instance =
      DeviceNotificationService._internal();
  factory DeviceNotificationService() => instance;

  static const MethodChannel _channel =
      MethodChannel('com.siakaphones.app/notifications');

  DeviceNotificationService._internal() {
    init();
  }

  void init() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (!Platform.isAndroid) return;
    try {
      _channel.invokeMethod('requestPermission');
    } catch (_) {}
  }

  Future<void> showNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('showNotification', {
        'title': title,
        'body': body,
        'id': id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      });
    } catch (_) {}
  }
}
