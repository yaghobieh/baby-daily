import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which messaging channels the user wants to see for sharing / notifications.
class ChannelState extends ChangeNotifier {
  static const _wa = 'channel_whatsapp';
  static const _tg = 'channel_telegram';

  bool _whatsapp = true;
  bool _telegram = true;

  bool get whatsapp => _whatsapp;
  bool get telegram => _telegram;
  bool get any => _whatsapp || _telegram;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _whatsapp = p.getBool(_wa) ?? true;
    _telegram = p.getBool(_tg) ?? true;
  }

  Future<void> setWhatsapp(bool v) async {
    _whatsapp = v;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool(_wa, v);
  }

  Future<void> setTelegram(bool v) async {
    _telegram = v;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool(_tg, v);
  }
}
