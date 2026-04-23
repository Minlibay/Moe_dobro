import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> register(String phone, String fullName, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        ApiConfig.register,
        {'phone': phone, 'full_name': fullName, 'password': password},
      );

      await _saveToken(response['token']);
      _user = User.fromJson(response['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        ApiConfig.login,
        {'phone': phone, 'password': password},
      );

      await _saveToken(response['token']);
      _user = User.fromJson(response['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Проверяем, является ли ошибка блокировкой
      if (e.toString().contains('blocked') || e.toString().contains('заблокирован')) {
        _error = 'BLOCKED:${e.toString()}';
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Logger.info('Loading profile');
      final response = await ApiService.get(ApiConfig.profile, needsAuth: true);
      Logger.debug('Profile response', response);

      _user = User.fromJson(response);
      Logger.info('Profile loaded', 'totalDonated: ${_user?.totalDonated}, totalReceived: ${_user?.totalReceived}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading profile', e);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({String? fullName, String? bio, String? avatarPath}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (avatarPath != null) {
        final response = await ApiService.uploadFile(
          ApiConfig.profile,
          avatarPath,
          'avatar',
          fields: {
            if (fullName != null) 'full_name': fullName,
            if (bio != null) 'bio': bio,
          },
          needsAuth: true,
          method: 'PUT',
        );
        _user = User.fromJson(response['user']);
      } else {
        final response = await ApiService.put(
          ApiConfig.profile,
          {
            if (fullName != null) 'full_name': fullName,
            if (bio != null) 'bio': bio,
          },
          needsAuth: true,
        );
        _user = User.fromJson(response['user']);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _user = null;
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<bool> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      try {
        await loadProfile();
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }
}
