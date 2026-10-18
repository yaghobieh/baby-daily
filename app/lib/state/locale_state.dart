import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

class LocaleState extends ChangeNotifier {
  static const String _key = 'app_locale';
  String _locale = 'en';

  String get locale => _locale;
  bool get isHe => _locale == 'he';
  AppStrings get strings => AppStrings(_locale);
  TextDirection get direction => isHe ? TextDirection.rtl : TextDirection.ltr;
  Locale get flutterLocale => Locale(_locale);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString(_key) ?? 'en';
    notifyListeners();
  }

  Future<void> setLocale(String lang) async {
    if (_locale == lang) return;
    _locale = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang);
    notifyListeners();
  }

  void toggle() {
    setLocale(_locale == 'en' ? 'he' : 'en');
  }
}
