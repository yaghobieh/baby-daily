import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fault-tolerant key-value storage that uses a direct Android MethodChannel
/// on Android (avoiding AndroidX DataStore / JNI exceptions in release builds)
/// and falls back to an in-memory map if platform storage is unavailable.
class AppStorage {
  static const MethodChannel _channel = MethodChannel('com.babydaily/storage');
  static final Map<String, Object?> _memory = <String, Object?>{};

  static bool get _useAndroidChannel =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<String?> getString(String key) async {
    if (_useAndroidChannel) {
      try {
        final val = await _channel.invokeMethod<String>('getString', {'key': key});
        if (val != null) _memory[key] = val;
        return val ?? (_memory[key] as String?);
      } catch (_) {
        return _memory[key] as String?;
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(key);
      if (val != null) _memory[key] = val;
      return val ?? (_memory[key] as String?);
    } catch (_) {
      return _memory[key] as String?;
    }
  }

  static Future<void> setString(String key, String value) async {
    _memory[key] = value;
    if (_useAndroidChannel) {
      try {
        await _channel.invokeMethod('setString', {'key': key, 'value': value});
      } catch (_) {}
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  static Future<bool?> getBool(String key) async {
    if (_useAndroidChannel) {
      try {
        final val = await _channel.invokeMethod<bool>('getBool', {'key': key});
        if (val != null) _memory[key] = val;
        return val ?? (_memory[key] as bool?);
      } catch (_) {
        return _memory[key] as bool?;
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool(key);
      if (val != null) _memory[key] = val;
      return val ?? (_memory[key] as bool?);
    } catch (_) {
      return _memory[key] as bool?;
    }
  }

  static Future<void> setBool(String key, bool value) async {
    _memory[key] = value;
    if (_useAndroidChannel) {
      try {
        await _channel.invokeMethod('setBool', {'key': key, 'value': value});
      } catch (_) {}
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  static Future<void> remove(String key) async {
    _memory.remove(key);
    if (_useAndroidChannel) {
      try {
        await _channel.invokeMethod('remove', {'key': key});
      } catch (_) {}
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }
}

