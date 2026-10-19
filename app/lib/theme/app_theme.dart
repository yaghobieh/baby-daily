import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Strong + soft tint pair for one activity type (see the BabyDaily color system).
class ActStyle {
  final Color strong;
  final Color softLight;
  final Color softDark;
  final String emoji;
  const ActStyle(this.strong, this.softLight, this.softDark, this.emoji);

  Color soft(bool dark) => dark ? softDark : softLight;
}

class AppTheme {
  // ---- Brand ---------------------------------------------------------------
  static const Color defaultPrimary = Color(0xFFFF7A59); // Primary Coral

  // ---- Activity colors (each activity owns one color) -----------------------
  static const Color sun = Color(0xFFFFB020); // Feeding Amber
  static const Color mint = Color(0xFF2FBF92); // Sleep Mint
  static const Color lavender = Color(0xFF8B7BFF); // Diaper Lavender
  static const Color rose = Color(0xFFFF6B8B); // Medicine Rose
  static const Color sky = Color(0xFF4DA8FF); // Growth Sky
  static const Color teal = Color(0xFF14B8C4); // Note Teal
  static const Color danger = Color(0xFFE5484D);

  static const Color sunLight = Color(0xFFFFF1D1);
  static const Color mintLight = Color(0xFFDDF6EC);
  static const Color lavenderLight = Color(0xFFE9E6FF);
  static const Color roseLight = Color(0xFFFFE3EA);
  static const Color skyLight = Color(0xFFDFEFFF);
  static const Color tealLight = Color(0xFFD9F4F6);

  static const Map<String, ActStyle> acts = {
    'FEED': ActStyle(sun, sunLight, Color(0xFF46371A), '🍼'),
    'SLEEP': ActStyle(mint, mintLight, Color(0xFF1D4036), '😴'),
    'DIAPER': ActStyle(lavender, lavenderLight, Color(0xFF35305F), '🧷'),
    'MEDICINE': ActStyle(rose, roseLight, Color(0xFF4A2634), '💊'),
    'GROWTH': ActStyle(sky, skyLight, Color(0xFF22405E), '📏'),
    'NOTE': ActStyle(teal, tealLight, Color(0xFF1B4247), '📝'),
  };

  static ActStyle act(String type) => acts[type] ?? acts['NOTE']!;

  // ---- Surfaces / text ------------------------------------------------------
  static const Color bgLight = Color(0xFFFFF9F4);
  static const Color bgDark = Color(0xFF1B1A26);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF26243A);
  static const Color inkLight = Color(0xFF2B2A3D);
  static const Color inkDark = Color(0xFFF4F2FF);
  static const Color mutedLight = Color(0xFF8C8AA0);
  static const Color mutedDark = Color(0xFFA5A2BD);
  static const Color lineLight = Color(0xFFF0E8E0);
  static const Color lineDark = Color(0xFF37344E);

  /// Legacy const aliases (mode-agnostic so they stay usable in const widgets).
  static const Color textMuted = Color(0xFF8C8AA0);
  static const Color divider = Color(0x338C8AA0);

  // Primary is user-selectable at runtime (Settings -> theme color).
  static Color primary = defaultPrimary;
  static Color primaryLight = const Color(0xFFFFE6DE);
  static Color primaryDark = defaultPrimary;

  static bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
  static Color ink(BuildContext c) => Theme.of(c).colorScheme.onSurface;
  static Color card(BuildContext c) => Theme.of(c).colorScheme.surface;
  static Color line(BuildContext c) => Theme.of(c).colorScheme.outlineVariant;

  static ThemeData build(Brightness brightness, [Color? customPrimary]) {
    final dark = brightness == Brightness.dark;
    final activePrimary = customPrimary ?? defaultPrimary;
    primary = activePrimary;
    primaryLight = dark ? const Color(0xFF4A2E2B) : activePrimary.withValues(alpha: 0.14);
    primaryDark = activePrimary;

    final bg = dark ? bgDark : bgLight;
    final card = dark ? cardDark : cardLight;
    final ink = dark ? inkDark : inkLight;
    final muted = dark ? mutedDark : mutedLight;
    final line = dark ? lineDark : lineLight;

    final fontName = GoogleFonts.nunito().fontFamily;

    final scheme = ColorScheme.fromSeed(seedColor: activePrimary, brightness: brightness).copyWith(
      primary: activePrimary,
      onPrimary: Colors.white,
      surface: card,
      onSurface: ink,
      onSurfaceVariant: muted,
      outlineVariant: line,
      surfaceContainerHighest: dark ? const Color(0xFF302E48) : const Color(0xFFF6F0EA),
    );

    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontName,
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      canvasColor: bg,
      dividerColor: line,
      dividerTheme: DividerThemeData(color: line, space: 1),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: line)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ink),
        titleTextStyle: TextStyle(fontFamily: fontName, fontSize: 20, fontWeight: FontWeight.w800, color: ink),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : muted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? activePrimary : line),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: primaryLight,
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: ink),
        showCheckmark: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: activePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: activePrimary,
          side: BorderSide(color: activePrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: activePrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: border(line),
        enabledBorder: border(line),
        focusedBorder: border(activePrimary, 2),
        hintStyle: TextStyle(color: muted, fontSize: 14),
        labelStyle: TextStyle(color: muted),
      ),
    );
  }

  /// Backwards-compatible alias.
  static ThemeData light(String locale, [Color? customPrimary]) => build(Brightness.light, customPrimary);
}
