import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../api/api_client.dart';
import '../models/user.dart';

class AuthState extends ChangeNotifier {
  static const String _googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '465653534147-2j97qb01btip30m5kqo02jglsgfuir98.apps.googleusercontent.com',
  );

  final ApiClient api;
  UserModel? _user;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  AuthState(this.api);

  UserModel? get user => _user;
  bool get isAuthenticated => api.isAuthenticated && _user != null;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (api.isAuthenticated) {
        final res = await api.get('/me').timeout(const Duration(seconds: 6));
        _user = UserModel.fromJson(res as Map<String, dynamic>);
      }
    } catch (e) {
      // Token expired, invalid, or network unreachable on startup
      try {
        await api.setToken(null);
      } catch (_) {}
      _user = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
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

  /// Opens the native/web Google Sign-In picker (`accounts.google.com`) and authenticates with the backend.
  Future<bool> signInWithGoogle({String locale = 'en'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cleanLocale = locale.length >= 2 ? locale.substring(0, 2) : 'en';

    try {
      GoogleSignInAccount? account;

      // 1. First attempt with serverClientId
      try {
        final googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          clientId: kIsWeb ? _googleClientId : null,
          serverClientId: !kIsWeb ? _googleClientId : null,
        );
        account = await googleSignIn.signIn();
      } catch (_) {
        // Fallback without serverClientId in case SHA-1 or server client is not recognized
        try {
          final fallbackSignIn = GoogleSignIn(scopes: ['email', 'profile']);
          account = await fallbackSignIn.signIn();
        } catch (_) {
          account = null;
        }
      }

      if (account == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      GoogleSignInAuthentication? googleAuth;
      try {
        googleAuth = await account.authentication;
      } catch (_) {}

      final res = await api.post('/auth/google', {
        'email': account.email,
        if (account.displayName != null && account.displayName!.isNotEmpty)
          'name': account.displayName,
        if (googleAuth?.idToken != null) 'idToken': googleAuth!.idToken,
        if (googleAuth?.accessToken != null) 'accessToken': googleAuth!.accessToken,
        'locale': cleanLocale,
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

  Future<bool> loginWithGoogle({
    required String email,
    String? name,
    String locale = 'en',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cleanLocale = locale.length >= 2 ? locale.substring(0, 2) : 'en';

    try {
      final res = await api.post('/auth/google', {
        'email': email.trim().toLowerCase(),
        if (name != null && name.isNotEmpty) 'name': name.trim(),
        'locale': cleanLocale,
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

  Future<void> refreshUser() async {
    try {
      if (api.isAuthenticated) {
        final res = await api.get('/me');
        _user = UserModel.fromJson(res as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> updateSubscription(String plan) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await api.post('/me/subscription', {'plan': plan});
      _user = UserModel.fromJson(res as Map<String, dynamic>);
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
    try {
      if (!kIsWeb || _googleClientId.isNotEmpty) {
        await GoogleSignIn(
          clientId: _googleClientId.isNotEmpty ? _googleClientId : null,
        ).signOut();
      }
    } catch (_) {}
    await api.setToken(null);
    _user = null;
    notifyListeners();
  }
}
