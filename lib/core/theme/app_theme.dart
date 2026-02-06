import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Modern Professional Color Palette ---

  // Primary Brand Colors (Trust, Professionalism)
  static const Color primaryBrand = Color(0xFF4F46E5); // Deep Indigo
  static const Color primaryBrandLight = Color(0xFF818CF8); // Soft Indigo
  static const Color primaryBrandDark = Color(0xFF3730A3); // Dark Indigo

  // Crisis/Emergency Colors (Urgency, Alert)
  static const Color crisisRed = Color(0xFFDC2626); // Strong Red
  static const Color crisisRedSoft = Color(0xFFFCA5A5); // Soft Red

  // Secondary Functional Colors
  static const Color alertOrange = Color(0xFFEA580C); // Orange
  static const Color safeGreen = Color(0xFF059669); // Emerald Green

  // Neutrals (Clean, Minimal)
  static const Color neutralBlack = Color(0xFF111827); // Almost Black
  static const Color neutralGrey = Color(0xFF6B7280); // Cool Grey
  static const Color surfaceLight = Color(0xFFF9FAFB); // Off-white/Cool Grey 50
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Pure White

  // Dark Mode Neutrals
  static const Color surfaceDark = Color(0xFF1F2937); // Grey 800
  static const Color backgroundDark = Color(0xFF111827); // Grey 900
  static const Color textLight = Color(0xFFF3F4F6); // Grey 100

  // Role Accents (Refined)
  static const Color citizenAccent = Color(0xFF2563EB); // Royal Blue
  static const Color volunteerAccent = Color(0xFF059669); // Emerald
  static const Color authorityAccent = Color(0xFF7C3AED); // Violet

  // --- Legacy Compatibility (Aliases) ---
  static const Color primaryRed = crisisRed;
  static const Color primaryOrange = alertOrange;
  static const Color primaryGreen = safeGreen;
  static const Color neutralGray = neutralGrey;
  static const Color backgroundLight = surfaceLight;
  // surfaceLight is already defined
  static const Color textDark = neutralBlack;
  // backgroundDark is already defined
  // surfaceDark is already defined
  static const Color cardDark = surfaceDark;
  // textLight is already defined

  // --- Helpers ---
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getBackgroundColor(BuildContext context) {
    return isDarkMode(context) ? backgroundDark : surfaceLight;
  }

  static Color getSurfaceColor(BuildContext context) {
    return isDarkMode(context) ? surfaceDark : surfaceWhite;
  }

  static Color getCardColor(BuildContext context) {
    return isDarkMode(context) ? surfaceDark : surfaceWhite;
  }

  static Color getTextColor(BuildContext context) {
    return isDarkMode(context) ? textLight : neutralBlack;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return isDarkMode(context) ? Colors.white70 : neutralGrey;
  }

  static List<BoxShadow> getSoftShadow([Color? color]) {
    return [
      BoxShadow(
        color: (color ?? Colors.black).withOpacity(0.06),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: (color ?? Colors.black).withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // --- Themes ---

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: surfaceLight,

    // Modern Typography
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: neutralBlack,
      displayColor: neutralBlack,
    ),

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBrand,
      primary: primaryBrand,
      secondary: alertOrange,
      tertiary: safeGreen,
      surface: surfaceWhite,
      error: crisisRed,
      brightness: Brightness.light,
    ),

    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: surfaceLight,
      surfaceTintColor: Colors.transparent,
      foregroundColor: neutralBlack,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: neutralBlack,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0, // Using manual soft shadows instead
      color: surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryBrand,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle:
            GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: neutralGrey.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryBrand, width: 2),
      ),
      hintStyle: GoogleFonts.outfit(color: neutralGrey.withOpacity(0.6)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: textLight,
      displayColor: textLight,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBrand,
      primary: primaryBrandLight,
      secondary: alertOrange,
      tertiary: safeGreen,
      surface: surfaceDark,
      error: crisisRedSoft,
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: backgroundDark,
      surfaceTintColor: Colors.transparent,
      foregroundColor: textLight,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textLight,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryBrand,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle:
            GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceDark,
      titleTextStyle: GoogleFonts.outfit(
        color: textLight,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: GoogleFonts.outfit(color: Colors.white70),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark, // slightly lighter than bg
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        borderSide: const BorderSide(color: primaryBrandLight, width: 2),
      ),
      hintStyle: GoogleFonts.outfit(color: Colors.white30),
    ),
  );
}
