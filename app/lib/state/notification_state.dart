import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/reminder.dart';

class NotificationState extends ChangeNotifier {
  final ApiClient api;

  List<NotificationItemModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  NotificationState(this.api);

  List<NotificationItemModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        api.get('/notifications'),
        api.get('/notifications/unread-count'),
      ]);

      final list = results[0] as List<dynamic>;
      _notifications = list.map((j) => NotificationItemModel.fromJson(j as Map<String, dynamic>)).toList();
      _unreadCount = (results[1] as Map<String, dynamic>)['count'] as int? ?? 0;
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    try {
      await api.post('/notifications/read-all');
      _unreadCount = 0;
      for (int i = 0; i < _notifications.length; i++) {
        final n = _notifications[i];
        if (n.readAt == null) {
          _notifications[i] = NotificationItemModel(
            id: n.id,
            babyId: n.babyId,
            title: n.title,
            body: n.body,
            data: n.data,
            readAt: DateTime.now(),
            createdAt: n.createdAt,
          );
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    try {
      await api.post('/notifications/$id/read');
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && _notifications[index].readAt == null) {
        final n = _notifications[index];
        _notifications[index] = NotificationItemModel(
          id: n.id,
          babyId: n.babyId,
          title: n.title,
          body: n.body,
          data: n.data,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
        );
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> sendTestNotification({String? phone, String? title, String? body}) async {
    try {
      final res = await api.post('/notifications/test', {
        'phone': ?phone,
        'title': ?title,
        'body': ?body,
      }) as Map<String, dynamic>?;
      await load();
      return res;
    } catch (_) {
      return null;
    }
  }
}

class ReminderState extends ChangeNotifier {
  final ApiClient api;

  List<ReminderModel> _reminders = [];
  bool _isLoading = false;

  ReminderState(this.api);

  List<ReminderModel> get reminders => _reminders;
  bool get isLoading => _isLoading;

  Future<void> loadForBaby(String babyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await api.get('/babies/$babyId/reminders') as List<dynamic>;
      _reminders = res.map((j) => ReminderModel.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createReminder({
    required String babyId,
    required String kind,
    required String title,
    String? entryType,
    int? intervalMinutes,
    int? timeOfDay,
    String? taggedUserId,
    String? taggedUserName,
  }) async {
    try {
      await api.post('/babies/$babyId/reminders', {
        'kind': kind,
        'title': title,
        'entryType': ?entryType,
        'intervalMinutes': ?intervalMinutes,
        'timeOfDay': ?timeOfDay,
        'utcOffset': DateTime.now().timeZoneOffset.inMinutes,
        ?taggedUserId: taggedUserId,
        ?taggedUserName: taggedUserName,
      });

      await loadForBaby(babyId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteReminder(String babyId, String id) async {
    try {
      await api.delete('/reminders/$id');
      await loadForBaby(babyId);
    } catch (_) {}
  }
}
