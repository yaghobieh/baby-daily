import 'dart:async';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/entry.dart';

class EntryState extends ChangeNotifier {
  final ApiClient api;

  List<EntryModel> _entries = [];
  DailySummaryModel _summary = DailySummaryModel();
  bool _isLoading = false;
  String? _error;
  String? _filterType;

  Timer? _timer;
  Duration _activeSleepDuration = Duration.zero;

  EntryState(this.api);

  List<EntryModel> get entries => _filterType == null
      ? _entries
      : _entries.where((e) => e.type == _filterType).toList();
  DailySummaryModel get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get filterType => _filterType;
  Duration get activeSleepDuration => _activeSleepDuration;
  bool get isSleeping => _summary.activeSleep != null;

  void setFilter(String? type) {
    _filterType = type;
    notifyListeners();
  }

  Future<void> loadForBaby(String babyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final localMidnight = DateTime(now.year, now.month, now.day);
      final nextMidnight = localMidnight.add(const Duration(days: 1));

      final results = await Future.wait([
        api.get('/babies/$babyId/entries', {'limit': 150}),
        api.get('/babies/$babyId/summary', {
          'from': localMidnight.toUtc().toIso8601String(),
          'to': nextMidnight.toUtc().toIso8601String(),
        }),
      ]);

      final entriesList = results[0] as List<dynamic>;
      _entries = entriesList.map((j) => EntryModel.fromJson(j as Map<String, dynamic>)).toList();
      _summary = DailySummaryModel.fromJson(results[1] as Map<String, dynamic>);

      _checkSleepTimer();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _checkSleepTimer() {
    _timer?.cancel();
    if (_summary.activeSleep != null) {
      _updateSleepDuration();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateSleepDuration();
      });
    } else {
      _activeSleepDuration = Duration.zero;
    }
  }

  void _updateSleepDuration() {
    if (_summary.activeSleep == null) return;
    final diff = DateTime.now().difference(_summary.activeSleep!.startedAt);
    _activeSleepDuration = diff.isNegative ? Duration.zero : diff;
    notifyListeners();
  }

  Future<bool> logEntry({
    required String babyId,
    required String type,
    required DateTime startedAt,
    DateTime? endedAt,
    Map<String, dynamic> data = const {},
    String? note,
    String? taggedUserId,
    String? taggedUserName,
  }) async {
    try {
      await api.post('/babies/$babyId/entries', {
        'type': type,
        'startedAt': startedAt.toUtc().toIso8601String(),
        if (endedAt != null) 'endedAt': endedAt.toUtc().toIso8601String(),
        'data': {
          ...data,
          ?taggedUserId: taggedUserId,
          ?taggedUserName: taggedUserName,
        },
        if (note != null && note.isNotEmpty) 'note': note,
        ?taggedUserId: taggedUserId,
        ?taggedUserName: taggedUserName,
      });

      await loadForBaby(babyId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> wakeUp(String babyId) async {
    final active = _summary.activeSleep;
    if (active == null) return false;

    try {
      await api.patch('/entries/${active.id}', {
        'endedAt': DateTime.now().toUtc().toIso8601String(),
      });
      await loadForBaby(babyId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> startSleep(String babyId) async {
    return logEntry(
      babyId: babyId,
      type: 'SLEEP',
      startedAt: DateTime.now(),
    );
  }

  Future<bool> deleteEntry(String babyId, String entryId) async {
    try {
      await api.delete('/entries/$entryId');
      await loadForBaby(babyId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
