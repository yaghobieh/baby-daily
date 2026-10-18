import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/user.dart';

class AuthState extends ChangeNotifier {
  final ApiClient api;
  UserModel? _user;
  bool _isLoading = true;
  String? _error;

  AuthState(this.api);

  UserModel? get user => _user;
  bool get isAuthenticated => api.isAuthenticated && _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    if (api.isAuthenticated) {
      try {
        final res = await api.get('/me');
        _user = UserModel.fromJson(res as Map<String, dynamic>);
      } catch (e) {
        // Token expired or invalid
        await api.setToken(null);
        _user = null;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await api.post('/auth/login', {
        'identifier': identifier,
        'password': password,
        'utcOffset': DateTime.now().timeZoneOffset.inMinutes,
      });

      final token = res['token'] as String;
      final userJson = res['user'] as Map<String, dynamic>;

      await api.setToken(token);
      _user = UserModel.fromJson(userJson);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String locale = 'en',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await api.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone?.isNotEmpty == true ? phone : null,
        'locale': locale,
        'utcOffset': DateTime.now().timeZoneOffset.inMinutes,
      });

      final token = res['token'] as String;
      final userJson = res['user'] as Map<String, dynamic>;

      await api.setToken(token);
      _user = UserModel.fromJson(userJson);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await api.setToken(null);
    _user = null;
    notifyListeners();
  }
}
