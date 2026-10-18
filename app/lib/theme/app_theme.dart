import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Static palette accents
  static const Color defaultPrimary = Color(0xFFFF7A7A);
  static const Color mint = Color(0xFF48C78E); // Sleep / calm
  static const Color mintLight = Color(0xFFE8F8F1);

  static const Color lavender = Color(0xFF8C7AE6); // Medicine / diaper
  static const Color lavenderLight = Color(0xFFF1EFFF);

  static const Color sky = Color(0xFF3897F0); // Growth
  static const Color skyLight = Color(0xFFEBF4FF);

  static const Color sun = Color(0xFFFFAA00); // Food
  static const Color sunLight = Color(0xFFFFF7E6);

  static const Color bg = Color(0xFFF9FAFC); // Very clean soft light grey
  static const Color surface = Colors.white;

  static const Color textMain = Color(0xFF1E272E);
  static const Color textMuted = Color(0xFF747D8C);
  static const Color divider = Color(0xFFEEF1F6);

  // Backward compatibility getter
  static Color primary = defaultPrimary;
  static Color primaryLight = const Color(0xFFFFECEB);
  static Color primaryDark = const Color(0xFFE05252);

  static ThemeData light(String locale, [Color? customPrimary]) {
    final activePrimary = customPrimary ?? defaultPrimary;
    primary = activePrimary;
    primaryLight = activePrimary.withValues(alpha: 0.12);
    primaryDark = activePrimary;

    final fontName = GoogleFonts.outfit().fontFamily;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontName,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: activePrimary,
        primary: activePrimary,
        surface: surface,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: IconThemeData(color: textMain),
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textMain),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: activePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: activePrimary,
          side: BorderSide(color: activePrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4F6F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: activePrimary, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
    );
  }
}
