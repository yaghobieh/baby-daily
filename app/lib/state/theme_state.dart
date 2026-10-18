import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState extends ChangeNotifier {
  static const String _key = 'app_theme_color';
  static const String _modeKey = 'app_theme_mode';

  static const List<String> availableColors = [
    '#FF7A59', // Primary coral
    '#FF6B8B', // Rose
    '#2FBF92', // Mint
    '#8B7BFF', // Lavender
    '#4DA8FF', // Sky
    '#FFB020', // Amber
    '#14B8C4', // Teal
    '#E5484D', // Berry
  ];

  Color _primaryColor = const Color(0xFFFF7A59);
  String _colorHex = '#FF7A59';
  ThemeMode _mode = ThemeMode.system;

  Color get primaryColor => _primaryColor;
  String get colorHex => _colorHex;
  ThemeMode get mode => _mode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHex = prefs.getString(_key);
    if (savedHex != null) {
      setColorHex(savedHex, save: false);
    }
    switch (prefs.getString(_modeKey)) {
      case 'light':
        _mode = ThemeMode.light;
      case 'dark':
        _mode = ThemeMode.dark;
      default:
        _mode = ThemeMode.system;
    }
  }

  void setMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setString(_modeKey, mode.name));
  }

  /// Flips between light and dark based on what is currently shown.
  void toggleDark(bool currentlyDark) => setMode(currentlyDark ? ThemeMode.light : ThemeMode.dark);

  void setColorHex(String hex, {bool save = true}) {
    try {
      final clean = hex.replaceAll('#', '');
      _primaryColor = Color(int.parse('FF$clean', radix: 16));
      _colorHex = hex;
      notifyListeners();

      if (save) {
        SharedPreferences.getInstance().then((prefs) => prefs.setString(_key, hex));
      }
    } catch (_) {}
  }

  void syncWithBabyColor(String? babyColorHex) {
    if (babyColorHex != null && babyColorHex.isNotEmpty) {
      setColorHex(babyColorHex, save: false);
    }
  }
}
