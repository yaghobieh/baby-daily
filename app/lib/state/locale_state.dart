import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../utils/app_storage.dart';

class LocaleState extends ChangeNotifier {
  static const String _key = 'app_locale';
  static const List<String> supportedCodes = ['he', 'en', 'es', 'ru'];

  static const Map<String, String> languageNames = {
    'he': 'עברית',
    'en': 'English',
    'es': 'Español',
    'ru': 'Русский',
  };

  String _locale = 'en';

  String get locale => _locale;
  bool get isHe => _locale == 'he';
  String get currentLanguageName => languageNames[_locale] ?? 'English';
  AppStrings get strings => AppStrings(_locale);
  TextDirection get direction => isHe ? TextDirection.rtl : TextDirection.ltr;
  Locale get flutterLocale => Locale(_locale);

  Future<void> init() async {
    final saved = await AppStorage.getString(_key);
    if (saved != null && supportedCodes.contains(saved)) {
      _locale = saved;
    } else {
      _locale = 'en';
    }
    notifyListeners();
  }

  Future<void> setLocale(String lang) async {
    if (!supportedCodes.contains(lang) || _locale == lang) return;
    _locale = lang;
    await AppStorage.setString(_key, lang);
    notifyListeners();
  }

  void toggle() {
    final idx = supportedCodes.indexOf(_locale);
    final nextIdx = (idx + 1) % supportedCodes.length;
    setLocale(supportedCodes[nextIdx]);
  }
}
