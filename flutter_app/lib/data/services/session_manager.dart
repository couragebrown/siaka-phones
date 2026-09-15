import 'package:shared_preferences/shared_preferences.dart';

/// Manages user session persistence.
/// After login the current timestamp is stored. On next launch,
/// if more than [sessionTimeoutDuration] has passed, the session is expired.
class SessionManager {
  static const _keyLoggedIn = 'session_logged_in';
  static const _keyLastActive = 'session_last_active_ms';

  /// Session expires after this duration of inactivity (app closed).
  static const sessionTimeoutDuration = Duration(hours: 1);

  /// Returns true if the user has an active, non-expired session.
  /// On any platform error, returns false (force login — safe default).
  static Future<bool> hasValidSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
      if (!loggedIn) return false;

      final lastActiveMs = prefs.getInt(_keyLastActive);
      if (lastActiveMs == null) return false;

      final lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveMs);
      final elapsed = DateTime.now().difference(lastActive);
      return elapsed < sessionTimeoutDuration;
    } catch (_) {
      return false;
    }
  }

  /// Call this when the user successfully signs in or creates an account.
  static Future<void> saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyLoggedIn, true);
      await prefs.setInt(
        _keyLastActive,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  /// Call this whenever the app comes to the foreground to refresh the
  /// last-active timestamp (so the timer resets while the app is open).
  static Future<void> refreshSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
      if (!loggedIn) return;
      await prefs.setInt(
        _keyLastActive,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  /// Call this on sign-out to clear the session completely.
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLoggedIn);
      await prefs.remove(_keyLastActive);
    } catch (_) {}
  }
}
