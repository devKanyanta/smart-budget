import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'api_exception.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  ApiException? _lastError;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  ApiException? get error => _lastError;
  ApiService get api => _api;

  AuthService() {
    _loadSavedAuth();
  }

  Future<void> _loadSavedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');

    if (accessToken != null && refreshToken != null) {
      _api.setTokens(accessToken: accessToken, refreshToken: refreshToken);
      try {
        await _fetchProfile();
        _isAuthenticated = true;
      } catch (_) {
        _isAuthenticated = false;
        _api.clearTokens();
      }
      notifyListeners();
    }
  }

  Future<void> _fetchProfile() async {
    final response = await _api.getProfile();
    _user = response['data'];
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.login(email: email, password: password);
      if (response['success']) {
        final data = response['data'];
        _api.setTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['accessToken']);
        await prefs.setString('refresh_token', data['refreshToken']);

        _user = data['user'];
        _isAuthenticated = true;
        _lastError = null;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _lastError = ApiException.from(e);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String email,
    required String fullName,
    String? phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.register(
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        password: password,
        confirmPassword: confirmPassword,
      );
      if (response['success']) {
        final data = response['data'];
        _api.setTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['accessToken']);
        await prefs.setString('refresh_token', data['refreshToken']);

        _user = data['user'];
        _isAuthenticated = true;
        _lastError = null;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _lastError = ApiException.from(e);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _api.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');

    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
