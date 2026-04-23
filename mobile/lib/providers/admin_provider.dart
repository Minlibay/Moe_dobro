import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/fundraiser.dart';
import '../models/donation.dart';
import '../models/admin_stats.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class AdminProvider with ChangeNotifier {
  List<User> _users = [];
  List<Fundraiser> _fundraisers = [];
  List<Fundraiser> _pendingFundraisers = [];
  List<Donation> _donations = [];
  AdminStats? _stats;
  bool _isLoading = false;
  String? _error;

  List<User> get users => _users;
  List<Fundraiser> get fundraisers => _fundraisers;
  List<Fundraiser> get pendingFundraisers => _pendingFundraisers;
  List<Donation> get donations => _donations;
  AdminStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Загрузить пользователей
  Future<void> loadUsers({String? search, bool? isVerified}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = '${ApiConfig.baseUrl}/admin/users?limit=100';
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }
      if (isVerified != null) {
        url += '&is_verified=$isVerified';
      }

      final response = await ApiService.get(url, needsAuth: true);
      _users = (response['users'] as List)
          .map((json) => User.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Загрузить сборы
  Future<void> loadFundraisers({String? status, String? category, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = '${ApiConfig.baseUrl}/admin/fundraisers?limit=100';
      if (status != null) url += '&status=$status';
      if (category != null) url += '&category=$category';
      if (search != null && search.isNotEmpty) url += '&search=$search';

      final response = await ApiService.get(url, needsAuth: true);
      _fundraisers = (response['fundraisers'] as List)
          .map((json) => Fundraiser.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Загрузить донаты
  Future<void> loadDonations({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = '${ApiConfig.baseUrl}/admin/donations?limit=100';
      if (status != null) url += '&status=$status';

      final response = await ApiService.get(url, needsAuth: true);
      _donations = (response['donations'] as List)
          .map((json) => Donation.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Загрузить статистику
  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('${ApiConfig.baseUrl}/admin/stats', needsAuth: true);
      _stats = AdminStats.fromJson(response);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Верифицировать пользователя
  Future<bool> verifyUser(int userId, bool isVerified) async {
    try {
      await ApiService.patch(
        '${ApiConfig.baseUrl}/admin/users/$userId/verify',
        needsAuth: true,
      );
      await loadUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Закрыть сбор
  Future<bool> closeFundraiser(int fundraiserId) async {
    try {
      await ApiService.patch(
        '${ApiConfig.baseUrl}/admin/fundraisers/$fundraiserId/close',
        needsAuth: true,
      );
      await loadFundraisers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Сделать сбор избранным
  Future<bool> featureFundraiser(int fundraiserId, bool isFeatured) async {
    try {
      await ApiService.patch(
        '${ApiConfig.baseUrl}/admin/fundraisers/$fundraiserId/feature',
        needsAuth: true,
      );
      await loadFundraisers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Удалить сбор
  Future<bool> deleteFundraiser(int fundraiserId) async {
    try {
      await ApiService.delete(
        '${ApiConfig.baseUrl}/admin/fundraisers/$fundraiserId',
        needsAuth: true,
      );
      await loadFundraisers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Загрузить сборы на модерацию
  Future<void> loadPendingFundraisers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('[AdminProvider] Loading pending fundraisers...');
      final response = await ApiService.get(
        '${ApiConfig.baseUrl}/admin/fundraisers/pending',
        needsAuth: true,
      );
      print('[AdminProvider] Pending response: $response');
      
      if (response == null) {
        _pendingFundraisers = [];
      } else if (response is Map && response.containsKey('fundraisers')) {
        // API returns {"fundraisers": [...]}
        final list = response['fundraisers'] as List;
        _pendingFundraisers = list
            .map((json) => Fundraiser.fromJson(json))
            .toList();
      } else if (response is List) {
        _pendingFundraisers = (response as List)
            .map((json) => Fundraiser.fromJson(json))
            .toList();
      } else {
        _pendingFundraisers = [];
      }
      
      print('[AdminProvider] Loaded ${_pendingFundraisers.length} pending fundraisers');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('[AdminProvider] Error loading pending: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Одобрить сбор (опубликовать)
  Future<bool> approveFundraiser(int fundraiserId) async {
    try {
      await ApiService.patch(
        '${ApiConfig.baseUrl}/admin/fundraisers/$fundraiserId/approve',
        needsAuth: true,
      );
      await loadPendingFundraisers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Отклонить сбор
  Future<bool> rejectFundraiser(int fundraiserId, String reason) async {
    try {
      await ApiService.patchWithBody(
        '${ApiConfig.baseUrl}/admin/fundraisers/$fundraiserId/reject',
        {'reason': reason},
        needsAuth: true,
      );
      await loadPendingFundraisers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
