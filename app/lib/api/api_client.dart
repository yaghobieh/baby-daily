import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  ApiException(this.statusCode, this.code, this.message);

  @override
  String toString() => '$code: $message';
}

class ApiClient {
  static const String _defaultUrl = 'http://localhost:5050';
  static const String _tokenKey = 'auth_token';
  static const String _urlKey = 'api_base_url';

  String _baseUrl = _defaultUrl;
  String? _token;

  String get baseUrl => _baseUrl;
  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _baseUrl = prefs.getString(_urlKey) ?? _defaultUrl;
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, _baseUrl);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
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

  Future<dynamic> get(String path, [Map<String, dynamic>? query]) async {
    final uri = _buildUri(path, query);
    final res = await http.get(uri, headers: _headers());
    return _processResponse(res);
  }

  Future<dynamic> post(String path, [dynamic body]) async {
    final uri = _buildUri(path);
    final res = await http.post(
      uri,
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(res);
  }

  Future<dynamic> patch(String path, [dynamic body]) async {
    final uri = _buildUri(path);
    final res = await http.patch(
      uri,
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(res);
  }

  Future<dynamic> put(String path, [dynamic body]) async {
    final uri = _buildUri(path);
    final res = await http.put(
      uri,
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(res);
  }

  Future<dynamic> delete(String path) async {
    final uri = _buildUri(path);
    final res = await http.delete(uri, headers: _headers());
    return _processResponse(res);
  }
}
