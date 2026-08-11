import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Primary URL — auto-selects based on platform
  // Web (Chrome): localhost works directly
  // Android physical device: uses PC's LAN IP
  static const String _primaryUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String _tokenKey    = 'auth_token';

  static late Dio _dio;
  static bool _interceptorAdded = false;
  static bool _dbReady          = false;
  static const String _activeBaseUrl = _primaryUrl;

  static bool   get dbReady      => _dbReady;
  static String get activeUrl    => _activeBaseUrl;

  static Future<void> init() async {
    if (_interceptorAdded) return;
    _interceptorAdded = true;

    _dio = Dio(BaseOptions(
      baseUrl        : _primaryUrl,
      connectTimeout : const Duration(seconds: 8),
      receiveTimeout : const Duration(seconds: 10),
      headers        : {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException e, handler) {
        debugPrint('❌ API [${e.response?.statusCode}] '
            '${e.requestOptions.path}: ${e.response?.data ?? e.message}');
        handler.next(e);
      },
    ));

    await checkHealth();
  }

  static Dio get dio => _dio;

  /// Pings /health and updates _dbReady flag.
  static Future<bool> checkHealth() async {
    try {
      final res = await _dio.get('/health');
      _dbReady = res.data['db_ready'] == true || res.data['db'] == 'connected';
      debugPrint('🏥 Health: db_ready=$_dbReady url=$_activeBaseUrl');
      return _dbReady;
    } catch (_) {
      _dbReady = false;
      return false;
    }
  }

  // ── Token storage ───────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> get hasToken async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  /// Human-readable error from a DioException.
  static String parseError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) return data['error'].toString();
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Request timed out — check your connection.';
        case DioExceptionType.connectionError:
          return 'Cannot reach the server. Is the backend running on port 3000?';
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode;
          if (code == 503) return 'Database not connected — start MySQL / XAMPP.';
          if (code == 401) return 'Session expired — please log in again.';
          return 'Server returned error $code';
        default:
          return e.message ?? 'Network error';
      }
    }
    return e.toString();
  }
}
