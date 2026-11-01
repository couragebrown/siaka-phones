import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPermissionService {
  static const MethodChannel _channel =
      MethodChannel('com.siakaphones.app/notifications');
  static const String _prefKey = 'has_requested_all_app_permissions_v3';

  static bool? _overridePromptInTest;

  /// For unit/widget testing overrides.
  static void setPromptInTestOverride(bool? value) {
    _overridePromptInTest = value;
  }

  /// Determines if the permission prompt should be shown immediately on launch.
  /// Shows automatically on every newly installed launch (and whenever the user
  /// has not yet completed or dismissed the full permission prompt).
  static Future<bool> shouldShowPrompt() async {
    if (_overridePromptInTest != null) {
      return _overridePromptInTest!;
    }
    // In test environment without explicit override, don't block unrelated widget tests
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedPrompt = prefs.getBool(_prefKey) ?? false;
      if (hasCompletedPrompt) {
        return false;
      }
      if (Platform.isAndroid) {
        final allGranted = await hasAllPermissions();
        if (allGranted) {
          await prefs.setBool(_prefKey, true);
          return false;
        }
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Checks with the native Android layer whether every required runtime permission is granted.
  static Future<bool> hasAllPermissions() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    if (!Platform.isAndroid) return true;
    try {
      final granted = await _channel.invokeMethod<bool>('hasAllPermissions');
      return granted ?? false;
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

  /// Requests ALL required Android runtime permissions needed across Siaka Phones
  /// immediately after the in-app permission popup closes, returning per-group status.
  static Future<Map<String, bool>> requestAllPermissions() async {
    await markPromptCompleted();
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return const <String, bool>{};
    }
    if (!Platform.isAndroid) {
      return const <String, bool>{};
    }
    try {
      final raw = await _channel.invokeMethod<dynamic>('requestAllPermissions');
      if (raw is Map) {
        return raw.map(
          (key, value) => MapEntry(key.toString(), value == true),
        );
      }
    } catch (_) {}
    return const <String, bool>{};
  }

  /// Opens the native OS App Settings page for Siaka Phones if the user wants
  /// to manually enable any previously denied permission.
  static Future<void> openAppPermissionSettings() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openAppPermissionSettings');
    } catch (_) {}
  }
}
