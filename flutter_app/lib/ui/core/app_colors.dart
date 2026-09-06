import 'package:flutter/material.dart';

class AppColors {
  // Core background palette matching the web storefront
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF3F4F6);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Brand accents matching the live web app
  static const Color cyan = Color(0xFF0066FF);
  static const Color electricBlue = Color(0xFF0052CC);
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color neonPink = Color(0xFFFF2A85);
  static const Color neonAmber = Color(0xFFF59E0B);
  static const Color neonEmerald = Color(0xFF16A34A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFFFF2A85)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x1A0066FF), Color(0x0A0052CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Borders & glows
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderCyan = Color(0xFFBFD8FF);

  // Typography matching the web brand
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF6B7280);
}
