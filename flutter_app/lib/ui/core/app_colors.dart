import 'package:flutter/material.dart';

class AppColors {
  // AMOLED Backgrounds
  static const Color background = Color(0xFF060814);
  static const Color surface = Color(0xFF0D1127);
  static const Color surfaceElevated = Color(0xFF151B38);
  static const Color cardBg = Color(0xCC0E142D);

  // Neon & Brand Accents
  static const Color cyan = Color(0xFF00F2FE);
  static const Color electricBlue = Color(0xFF4FACFE);
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color neonPink = Color(0xFFFF2A85);
  static const Color neonAmber = Color(0xFFFFB703);
  static const Color neonEmerald = Color(0xFF06D6A0);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFFFF2A85)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x2200F2FE), Color(0x0A4FACFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Borders & Glows
  static const Color borderLight = Color(0x22FFFFFF);
  static const Color borderCyan = Color(0x6600F2FE);

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
}
