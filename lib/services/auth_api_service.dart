import 'package:dio/dio.dart';
import 'api_service.dart';

/// Handles all /api/auth/* calls.
class AuthApiService {
  static final Dio _dio = ApiService.dio;

  /// Register a new user. Returns {token, user{id,name,email}} on success.
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/api/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Login. Returns {token, user{id,name,email}} on success.
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Fetch current user profile (requires valid JWT in interceptor).
  static Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/api/auth/me');
    return Map<String, dynamic>.from(res.data['user'] as Map);
  }

  /// Update display name.
  static Future<String> updateProfile({required String name}) async {
    final res = await _dio.put('/api/auth/profile', data: {'name': name});
    return res.data['name'] as String;
  }

  /// Reset password by email (no auth required).
  static Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    await _dio.put('/api/auth/reset-password', data: {
      'email'       : email,
      'new_password': newPassword,
    });
  }
}
