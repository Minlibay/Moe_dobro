import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(ApiConfig.notifications, needsAuth: true);
      _notifications = (response['notifications'] as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
      _unreadCount = response['unread_count'] ?? 0;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await ApiService.patch(ApiConfig.markAsRead(id), needsAuth: true);

      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !_notifications[index].isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
      }

      await loadNotifications();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiService.patch(ApiConfig.markAllAsRead, needsAuth: true);
      _unreadCount = 0;
      await loadNotifications();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
