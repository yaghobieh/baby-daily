import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/baby.dart';
import '../models/invitation.dart';

class BabyState extends ChangeNotifier {
  final ApiClient api;

  List<BabyModel> _babies = [];
  BabyModel? _currentBaby;
  List<BabyMemberModel> _members = [];
  List<InvitationModel> _pendingInvites = [];
  List<InvitationModel> _receivedInvites = [];
  bool _isLoading = false;
  String? _error;

  BabyState(this.api);

  List<BabyModel> get babies => _babies;
  BabyModel? get currentBaby => _currentBaby;
  List<BabyMemberModel> get members => _members;
  List<InvitationModel> get pendingInvites => _pendingInvites;
  List<InvitationModel> get receivedInvites => _receivedInvites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void selectBaby(BabyModel baby) {
    _currentBaby = baby;
    notifyListeners();
    loadBabyDetails();
  }

  Future<void> loadBabies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await api.get('/babies') as List<dynamic>;
      _babies = res.map((j) => BabyModel.fromJson(j as Map<String, dynamic>)).toList();

      if (_babies.isNotEmpty) {
        if (_currentBaby == null || !_babies.any((b) => b.id == _currentBaby!.id)) {
          _currentBaby = _babies.first;
        } else {
          _currentBaby = _babies.firstWhere((b) => b.id == _currentBaby!.id);
        }
      } else {
        _currentBaby = null;
      }

      await loadReceivedInvites();
      if (_currentBaby != null) {
        await loadBabyDetails();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBabyDetails() async {
    if (_currentBaby == null) return;
    try {
      final memRes = await api.get('/babies/${_currentBaby!.id}/members') as List<dynamic>;
      _members = memRes.map((j) => BabyMemberModel.fromJson(j as Map<String, dynamic>)).toList();

      if (_currentBaby!.isOwner) {
        final invRes = await api.get('/babies/${_currentBaby!.id}/invitations') as List<dynamic>;
        _pendingInvites = invRes.map((j) => InvitationModel.fromJson(j as Map<String, dynamic>)).toList();
      } else {
        _pendingInvites = [];
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadReceivedInvites() async {
    try {
      final res = await api.get('/invitations') as List<dynamic>;
      _receivedInvites = res.map((j) => InvitationModel.fromJson(j as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createBaby({
    required String name,
    DateTime? birthDate,
    String? gender,
    String avatarColor = '#FF7A7A',
  }) async {
    try {
      final res = await api.post('/babies', {
        'name': name,
        'birthDate': birthDate?.toIso8601String(),
        'gender': gender,
        'avatarColor': avatarColor,
      });

      final newBaby = BabyModel.fromJson(res as Map<String, dynamic>);
      _babies.add(newBaby);
      _currentBaby = newBaby;
      notifyListeners();
      await loadBabyDetails();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> inviteMember({
    String? email,
    String? phone,
    String role = 'CAREGIVER',
  }) async {
    if (_currentBaby == null) return null;
    try {
      final res = await api.post('/babies/${_currentBaby!.id}/invitations', {
        if (email?.isNotEmpty == true) 'email': email,
        if (phone?.isNotEmpty == true) 'phone': phone,
        'role': role,
      });
      await loadBabyDetails();
      if (res is Map<String, dynamic>) {
        return res;
      }
      return {'success': true};
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> revokeInvitation(String id) async {
    try {
      await api.delete('/invitations/$id');
      await loadBabyDetails();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> acceptInvitation(String id) async {
    try {
      await api.post('/invitations/$id/accept');
      await loadBabies();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> declineInvitation(String id) async {
    try {
      await api.post('/invitations/$id/decline');
      await loadReceivedInvites();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeMember(String memberId) async {
    if (_currentBaby == null) return;
    try {
      await api.delete('/babies/${_currentBaby!.id}/members/$memberId');
      await loadBabyDetails();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
