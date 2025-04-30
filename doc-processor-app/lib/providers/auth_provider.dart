import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  bool _isAuthenticated = false;

  AuthProvider(this._apiService) {
    _checkAuthStatus();
  }

  bool get isAuthenticated => _isAuthenticated;

  Future<void> _checkAuthStatus() async {
    final token = await _apiService.getToken();
    _isAuthenticated = token != null;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      // For now, we'll use a simple token for testing
      const token = 'test_token_123';
      await _apiService.setToken(token);
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.removeToken();
    _isAuthenticated = false;
    notifyListeners();
  }
} 