import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool    _isLoggedIn       = false;
  String  _currentUserEmail = '';
  String  _currentUserName  = '';
  String  _currentUserPhone = '';
  String  _profileImagePath = '';   // local file path
  int?    _userId;
  bool    _isLoading        = false;
  String? _errorMessage;
  bool    _isServerReachable= false;
  bool    _isDbReady        = false;

  bool    get isLoggedIn          => _isLoggedIn;
  String  get currentUserEmail    => _currentUserEmail;
  String  get currentUserName     => _currentUserName;
  String  get currentUserPhone    => _currentUserPhone;
  String  get profileImagePath    => _profileImagePath;
  int?    get userId              => _userId;
  bool    get isLoading           => _isLoading;
  String? get errorMessage        => _errorMessage;
  bool    get isServerReachable   => _isServerReachable;
  bool    get isDbReady           => _isDbReady;

  static const _nameKey       = 'user_name';
  static const _emailKey      = 'user_email';
  static const _pwdKey        = 'user_password';
  static const _phoneKey      = 'user_phone';
  static const _imageKey      = 'user_image_path';
  static const _userIdKey     = 'user_id';
  static const _isLoggedInKey = 'is_logged_in';

  AuthProvider() { _init(); }

  Future<void> _init() async {
    await ApiService.init();
    await _restoreSession();
    // Only check server if already logged in — don't show errors on login page
    if (_isLoggedIn) unawaited(checkServerStatus());
  }

  Future<void> checkServerStatus() async {
    try {
      final healthy      = await ApiService.checkHealth();
      _isServerReachable = true;
      _isDbReady         = healthy;
    } catch (_) {
      _isServerReachable = false;
      _isDbReady         = false;
    }
    notifyListeners();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    if (_isLoggedIn) {
      _currentUserEmail = prefs.getString(_emailKey) ?? '';
      _currentUserName  = prefs.getString(_nameKey)  ?? '';
      _currentUserPhone = prefs.getString(_phoneKey) ?? '';
      _profileImagePath = prefs.getString(_imageKey) ?? '';
      _userId           = prefs.getInt(_userIdKey);
    }
    notifyListeners();
  }

  // ── Register ────────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true; _errorMessage = null; notifyListeners();

    // Try cloud register
    try {
      final data = await AuthApiService.register(
          name: name, email: email, password: password);
      await _persistCloudSession(data, password: password);
      _isLoading = false; notifyListeners();
      return true;
    } catch (e) {
      final msg = ApiService.parseError(e);
      final offline = _isOfflineError(msg);

      if (offline) {
        // Save locally so user can log in offline
        await _saveLocalCredentials(
            name: name, email: email, password: password, userId: null);
        _isLoading = false; notifyListeners();
        return true;
      }

      _errorMessage = msg;
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  // ── Login ────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true; _errorMessage = null; notifyListeners();

    // Try cloud login
    try {
      final data = await AuthApiService.login(email: email, password: password);
      await _persistCloudSession(data, password: password);
      _isLoading = false; notifyListeners();
      return true;
    } catch (e) {
      final msg    = ApiService.parseError(e);
      final offline = _isOfflineError(msg);

      if (offline) {
        // Fallback: check locally stored credentials
        final ok = await _localLogin(email: email, password: password);
        if (ok) {
          _isLoading = false; notifyListeners();
          return true;
        }
        _errorMessage =
            'Server / database offline. Register first while online to enable offline login.';
      } else {
        _errorMessage = msg;
      }
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  // ── Logout ───────────────────────────────────────────────────
  Future<void> logout() async {
    await ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    _isLoggedIn = false; _currentUserEmail = '';
    _currentUserName = ''; _userId = null;
    _isServerReachable = false; _isDbReady = false;
    notifyListeners();
  }

  // ── Update profile ────────────────────────────────────────────
  Future<void> updateProfile({required String name}) async {
    try {
      final updated = await AuthApiService.updateProfile(name: name);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, updated);
      _currentUserName = updated;
      notifyListeners();
    } catch (_) {
      // Offline: update locally only
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, name.trim());
      _currentUserName = name.trim();
      notifyListeners();
    }
  }

  /// Update full profile — name, phone, and optional image path.
  Future<void> updateFullProfile({
    required String name,
    required String phone,
    String? imagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final updated = await AuthApiService.updateProfile(name: name);
      await prefs.setString(_nameKey, updated);
      _currentUserName = updated;
    } catch (_) {
      await prefs.setString(_nameKey, name.trim());
      _currentUserName = name.trim();
    }
    await prefs.setString(_phoneKey, phone.trim());
    _currentUserPhone = phone.trim();
    if (imagePath != null && imagePath.isNotEmpty) {
      await prefs.setString(_imageKey, imagePath);
      _profileImagePath = imagePath;
    }
    notifyListeners();
  }
  void clearError() { _errorMessage = null; notifyListeners(); }

  /// Updates the locally cached password (called after a successful reset).
  Future<void> updateLocalPassword({
    required String email,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString(_emailKey) ?? '';
    if (storedEmail == email.toLowerCase().trim()) {
      await prefs.setString(_pwdKey, newPassword);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────

  /// True when the error means the server/DB is simply unreachable.
  bool _isOfflineError(String msg) =>
      msg.contains('Cannot reach') ||
      msg.contains('timed out') ||
      msg.contains('port 3000') ||
      msg.contains('database not connected') ||
      msg.contains('Database not connected') ||
      msg.contains('503') ||
      msg.contains('SocketException') ||
      msg.contains('Network error');

  Future<bool> _localLogin({
    required String email,
    required String password,
  }) async {
    final prefs         = await SharedPreferences.getInstance();
    final storedEmail   = prefs.getString(_emailKey)  ?? '';
    final storedPwd     = prefs.getString(_pwdKey)    ?? '';
    final storedName    = prefs.getString(_nameKey)   ?? '';
    final storedUserId  = prefs.getInt(_userIdKey);

    if (storedEmail.isEmpty) return false;
    if (email.toLowerCase().trim() != storedEmail) return false;
    if (password != storedPwd) return false;

    _isLoggedIn       = true;
    _currentUserEmail = storedEmail;
    _currentUserName  = storedName;
    _userId           = storedUserId;
    await prefs.setBool(_isLoggedInKey, true);
    return true;
  }

  Future<void> _saveLocalCredentials({
    required String name,
    required String email,
    required String password,
    required int?   userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_nameKey,  name.trim());
    await prefs.setString(_emailKey, email.toLowerCase().trim());
    await prefs.setString(_pwdKey,   password);
    if (userId != null) await prefs.setInt(_userIdKey, userId);
    _isLoggedIn       = true;
    _currentUserName  = name.trim();
    _currentUserEmail = email.toLowerCase().trim();
    _userId           = userId;
    // Restore phone and image if already saved
    final prefs2 = await SharedPreferences.getInstance();
    _currentUserPhone = prefs2.getString(_phoneKey) ?? '';
    _profileImagePath = prefs2.getString(_imageKey) ?? '';
  }

  Future<void> _persistCloudSession(
      Map<String, dynamic> data, {required String password}) async {
    final token = data['token'] as String;
    final user  = data['user']  as Map<String, dynamic>;
    await ApiService.saveToken(token);
    // id from Supabase is a UUID string, not int
    final userId = user['id']?.toString() ?? '';
    await _saveLocalCredentials(
      name    : user['name']  as String,
      email   : user['email'] as String,
      password: password,
      userId  : null,   // stored as string below
    );
    // Store UUID string separately
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_uuid', userId);
    _isServerReachable = true;
    _isDbReady         = true;
    unawaited(checkServerStatus());
  }
}

// ignore: avoid_void_async
void unawaited(Future<void> f) {}
