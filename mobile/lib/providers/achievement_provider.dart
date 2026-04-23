import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';

class AchievementProvider with ChangeNotifier {
  List<Achievement> _achievements = [];
  bool _isLoading = false;
  String? _error;

  List<Achievement> get achievements => _achievements;
  List<Achievement> get earnedAchievements =>
      _achievements.where((a) => a.isEarned).toList();
  List<Achievement> get lockedAchievements =>
      _achievements.where((a) => !a.isEarned).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get earnedCount => earnedAchievements.length;
  int get totalCount => _achievements.isEmpty ? 10 : _achievements.length;

  Future<void> loadAchievements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Logger.info('Loading achievements');
      final response = await ApiService.get(ApiConfig.allAchievements, needsAuth: true);
      Logger.debug('Achievements response', response);

      if (response == null || response is! List || (response as List).isEmpty) {
        // Если API вернул null или пустой массив - используем дефолтные достижения
        Logger.debug('Using default achievements');
        _achievements = _getDefaultAchievements();
      } else {
        _achievements = (response as List)
            .map((json) => Achievement.fromJson(json))
            .toList();
      }

      Logger.info('Loaded achievements', '${_achievements.length} total, ${earnedCount} earned');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading achievements', e);
      // При ошибке используем дефолтные достижения
      _achievements = _getDefaultAchievements();
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Дефолтные достижения если API недоступен
  List<Achievement> _getDefaultAchievements() {
    return [
      Achievement(id: 1, code: 'first_donation', title: 'Первый шаг', description: 'Совершите первое пожертвование', icon: '🌱', category: 'donor', requirementType: 'donation_count', requirementValue: 1, isEarned: false),
      Achievement(id: 2, code: 'generous_heart', title: 'Щедрое сердце', description: 'Помогите 5 людям', icon: '❤️', category: 'donor', requirementType: 'people_helped', requirementValue: 5, isEarned: false),
      Achievement(id: 3, code: 'philanthropist', title: 'Филантроп', description: 'Помогите 20 людям', icon: '🌟', category: 'donor', requirementType: 'people_helped', requirementValue: 20, isEarned: false),
      Achievement(id: 4, code: 'hero', title: 'Герой добра', description: 'Помогите 50 людям', icon: '🦸', category: 'donor', requirementType: 'people_helped', requirementValue: 50, isEarned: false),
      Achievement(id: 5, code: 'small_donor', title: 'Начинающий благотворитель', description: 'Пожертвуйте 1000 рублей', icon: '💰', category: 'donor', requirementType: 'donation_amount', requirementValue: 1000, isEarned: false),
      Achievement(id: 6, code: 'big_donor', title: 'Большое сердце', description: 'Пожертвуйте 10000 рублей', icon: '💎', category: 'donor', requirementType: 'donation_amount', requirementValue: 10000, isEarned: false),
      Achievement(id: 7, code: 'mega_donor', title: 'Меценат', description: 'Пожертвуйте 50000 рублей', icon: '👑', category: 'donor', requirementType: 'donation_amount', requirementValue: 50000, isEarned: false),
      Achievement(id: 8, code: 'first_fundraiser', title: 'Первый сбор', description: 'Создайте свой первый сбор', icon: '🎯', category: 'fundraiser', requirementType: 'fundraiser_count', requirementValue: 1, isEarned: false),
      Achievement(id: 9, code: 'successful_fundraiser', title: 'Успешный сбор', description: 'Закройте сбор на 100%', icon: '🏆', category: 'fundraiser', requirementType: 'fundraiser_completed', requirementValue: 1, isEarned: false),
      Achievement(id: 10, code: 'community_star', title: 'Звезда сообщества', description: 'Получите 100 пожертвований', icon: '⭐', category: 'community', requirementType: 'donations_received', requirementValue: 100, isEarned: false),
    ];
  }

  List<Achievement> getAchievementsByCategory(String category) {
    return _achievements.where((a) => a.category == category).toList();
  }
}
