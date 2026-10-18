import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState extends ChangeNotifier {
  static const String _key = 'app_theme_color';

  static const List<String> availableColors = [
    '#FF7A7A', // Warm coral
    '#F7A8C4', // Soft rose pink
    '#48C78E', // Mint
    '#8C7AE6', // Lavender
    '#3897F0', // Sky blue
    '#FFAA00', // Sun yellow
    '#20BF6B', // Fresh green
    '#EB3B5A', // Berry red
  ];

  Color _primaryColor = const Color(0xFFFF7A7A);
  String _colorHex = '#FF7A7A';

  Color get primaryColor => _primaryColor;
  String get colorHex => _colorHex;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHex = prefs.getString(_key);
    if (savedHex != null) {
      setColorHex(savedHex, save: false);
    }
  }

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
