import 'package:flutter/material.dart';

class AppColors {
  // Premium Palette
  static const Color premiumNavy = Color(0xFF0A122A);
  static const Color darkNavy = Color(0xFF0D1B3E);
  static const Color deepPurple = Color(0xFF6A4CFF);
  static const Color premiumGold = Color(0xFFEBC111);
  static const Color electricBlue = Color(0xFF2979FF);
  
  // Primary Reference (for backward compatibility where needed)
  static const Color primaryIndigo = Color(0xFF1A1F3D);

  // Status Colors
  static const Color crimsonRed = Color(0xFFE53935);
  static const Color emeraldGreen = Color(0xFF43A047);
  static const Color amberWarning = Color(0xFFFB8C00);

  // Background Gradients
  static const List<Color> premiumGradient = [
    Color(0xFF0A122A),
    Color(0xFF121B33),
    Color(0xFF1A1F3D),
  ];

  // Text Colors
  static const Color textLight = Color(0xFFF8F9FF);
  static const Color textDark = Color(0xFF121212);
  static const Color textMuted = Color(0xFFA0A5BA);
  
  // Glassmorphism Base Colors
  static final Color glassBorder = Colors.white.withOpacity(0.12);
  static final Color glassBackground = Colors.white.withOpacity(0.06);
  static final Color glassBackgroundDark = Colors.black.withOpacity(0.3);
}
