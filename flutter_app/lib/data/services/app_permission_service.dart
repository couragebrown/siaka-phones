import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPermissionService {
  static const MethodChannel _channel =
      MethodChannel('com.siakaphones.app/notifications');
  static const String _prefKey = 'has_requested_app_permissions_v1';

  static bool? _overridePromptInTest;

  /// For unit/widget testing overrides
  static void setPromptInTestOverride(bool? value) {
    _overridePromptInTest = value;
  }

  /// Determines if the permission prompt should be shown immediately on fresh install.
  static Future<bool> shouldShowPrompt() async {
    if (_overridePromptInTest != null) {
      return _overridePromptInTest!;
    }
    // In test environment without explicit override, don't block existing widget tests
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_prefKey) ?? false);
    } catch (_) {
      return false;
    }
  }

  /// Marks that the permission prompt was displayed and acknowledged.
  static Future<void> markPromptCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    } catch (_) {}
  }

  /// Requests all core Android permissions needed by Siaka Phones via native platform channel.
  static Future<void> requestAllPermissions() async {
    await markPromptCompleted();
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestAllPermissions');
    } catch (_) {}
  }
}
