import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return _buildTheme(Brightness.light);
  }

  static ThemeData get darkTheme {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.deepPurple,
      brightness: brightness,
      primary: isDark ? AppColors.electricBlue : AppColors.deepPurple,
      surface: isDark ? AppColors.premiumNavy : const Color(0xFFF8F9FF),
      onSurface: isDark ? AppColors.textLight : AppColors.textDark,
      secondary: AppColors.premiumGold,
      error: AppColors.crimsonRed,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      
      // Modern Typography with Google Fonts
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textDark,
        ),
      ),

      // Premium Card Design
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.darkNavy.withOpacity(0.4) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Pill-shaped Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: AppColors.deepPurple.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),

      // Modern Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkNavy.withOpacity(0.5) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.deepPurple, width: 2),
        ),
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
      ),

      // Stylish Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.deepPurple.withOpacity(0.12),
        labelStyle: TextStyle(
          color: isDark ? AppColors.electricBlue : AppColors.deepPurple,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
    );
  }
}
