import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../utils/logger.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _result = 'Нажмите кнопку для тестирования';
  bool _isLoading = false;

  Future<void> _testAchievements() async {
    setState(() {
      _isLoading = true;
      _result = 'Загрузка...';
    });

    try {
      Logger.info('Testing achievements API');
      final response = await ApiService.get(ApiConfig.allAchievements, needsAuth: true);
      Logger.info('Achievements loaded', '${response.length} items');
      setState(() {
        _result = 'Успех! Получено ${response.length} достижений\n\n${response.toString()}';
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Test failed', e);
      setState(() {
        _result = 'Ошибка: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testProfile() async {
    setState(() {
      _isLoading = true;
      _result = 'Загрузка...';
    });

    try {
      Logger.info('Testing profile API');
      final response = await ApiService.get(ApiConfig.profile, needsAuth: true);
      Logger.info('Profile loaded', response);
      setState(() {
        _result = 'Успех! Профиль:\n\n${response.toString()}';
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Test failed', e);
      setState(() {
        _result = 'Ошибка: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testProfile,
              child: const Text('Тест Profile API'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAchievements,
              child: const Text('Тест Achievements API'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_result),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
