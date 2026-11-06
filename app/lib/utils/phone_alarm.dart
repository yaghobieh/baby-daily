import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native bridge for setting real phone Clock alarms, timers, and system notifications.
class PhoneAlarm {
  static const MethodChannel _channel = MethodChannel('com.babydaily/storage');

  /// Sets a real alarm in the phone's Clock app for [hour]:[minute] and triggers a notification.
  static Future<bool> setAlarm({
    required int hour,
    required int minute,
    required String message,
    bool skipUi = false,
  }) async {
    if (kIsWeb) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('setAlarm', {
        'hour': hour,
        'minute': minute,
        'message': message,
        'skipUi': skipUi,
      });
      final now = DateTime.now();
      var target = DateTime(now.year, now.month, now.day, hour, minute);
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }
      final delayMs = target.difference(now).inMilliseconds;
      if (delayMs > 0) {
        await scheduleNotification(
          delayMs: delayMs,
          title: '⏰ $message',
          body: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        );
      }
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sets a phone Clock alarm [duration] from now (e.g., 3 hours for next meal).
  static Future<DateTime> setAlarmAfter({
    required Duration duration,
    required String message,
    bool skipUi = false,
  }) async {
    final target = DateTime.now().add(duration);
    await setAlarm(
      hour: target.hour,
      minute: target.minute,
      message: message,
      skipUi: skipUi,
    );
    return target;
  }

  /// Shows an immediate system notification on the current phone.
  static Future<bool> showNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('showNotification', {
        'title': title,
        'body': body,
      });
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Schedules a system notification on the current phone after [delayMs].
  static Future<bool> scheduleNotification({
    required int delayMs,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('scheduleNotification', {
        'delayMs': delayMs,
        'title': title,
        'body': body,
      });
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}

