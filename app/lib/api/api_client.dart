import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  ApiException(this.statusCode, this.code, this.message);

  @override
  String toString() => '$code: $message';
}

class ApiClient {
  /// Explicit API URL override via: --dart-define=API_URL=https://...
  static const String _envUrl = String.fromEnvironment('API_URL');

  /// Production API (Vercel). Override with: --dart-define=API_URL=https://...
  static const String prodUrl = String.fromEnvironment('API_URL', defaultValue: 'https://baby-daily-api.vercel.app');

  /// Local API used while developing (debug / profile builds).
  static const String localUrl = 'http://localhost:5050';

  /// Release builds talk to Vercel; debug builds talk to the local backend
  /// unless overridden with --dart-define=API_URL=...
  /// When the debug web app is opened from another device (e.g. an iPhone on the
  /// same Wi-Fi) the local backend is reached through the same host as the page.
  static String get defaultUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (kReleaseMode) return prodUrl;
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        return 'http://$host:5050';
      }
    }
    return localUrl;
  }

  static const String _tokenKey = 'auth_token';
  static const String _urlKey = 'api_base_url';

  String _baseUrl = defaultUrl;
  String? _token;

  String get baseUrl => _baseUrl;
  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Future<void> init() async {
    _token = await AppStorage.getString(_tokenKey);
    _baseUrl = defaultUrl;
    await AppStorage.remove(_urlKey); // legacy: URL used to be editable in Settings
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), '');
    await AppStorage.setString(_urlKey, _baseUrl);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    if (token == null) {
      await AppStorage.remove(_tokenKey);
    } else {
      await AppStorage.setString(_tokenKey, token);
    }
  }

  Map<String, String> _headers({bool hasBody = false}) {
    return {
      if (hasBody) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final baseUri = Uri.parse(_baseUrl);

    // Filter out null query params and stringify
    Map<String, String>? queryParams;
    if (query != null) {
      queryParams = {};
      query.forEach((key, value) {
        if (value != null) {
          queryParams![key] = value.toString();
        }
      });
    }

    return Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: '${baseUri.path}$cleanPath'.replaceAll('//', '/'),
      queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
    );
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }

    String code = 'error';
    String message = 'HTTP ${response.statusCode}';
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      code = json['error'] as String? ?? 'error';
      message = json['message'] as String? ?? message;
    } catch (_) {}

    throw ApiException(response.statusCode, code, message);
  }

  static const Duration _timeout = Duration(seconds: 12);

  Future<dynamic> get(String path, [Map<String, dynamic>? query]) async {
    final uri = _buildUri(path, query);
    final res = await http.get(uri, headers: _headers(hasBody: false)).timeout(_timeout);
    return _processResponse(res);
  }

  Future<dynamic> post(String path, [dynamic body]) async {
    final uri = _buildUri(path);
    final res = await http
        .post(
          uri,
          headers: _headers(hasBody: body != null),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _processResponse(res);
  }

  Future<dynamic> patch(String path, [dynamic body]) async {
    final uri = _buildUri(path);
    final res = await http
        .patch(
          uri,
          headers: _headers(hasBody: body != null),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _processResponse(res);
  }

  Future<dynamic> put(String path, [dynamic body]) async {
    final uri = _buildUri(path);
    final res = await http
        .put(
          uri,
          headers: _headers(hasBody: body != null),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _processResponse(res);
  }

  Future<dynamic> delete(String path) async {
    final uri = _buildUri(path);
    final res = await http.delete(uri, headers: _headers(hasBody: false)).timeout(_timeout);
    return _processResponse(res);
  }
}
