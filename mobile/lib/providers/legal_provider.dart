import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/legal_document.dart';
import '../config/api_config.dart';

class LegalProvider with ChangeNotifier {
  LegalDocument? _privacyPolicy;
  LegalDocument? _termsOfService;
  LegalDocument? _offer;
  bool _isLoading = false;
  String? _error;

  LegalDocument? get privacyPolicy => _privacyPolicy;
  LegalDocument? get termsOfService => _termsOfService;
  LegalDocument? get offer => _offer;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDocument(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.legal}/$type'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final doc = LegalDocument.fromJson(data);
        
        if (type == 'privacy') {
          _privacyPolicy = doc;
        } else if (type == 'terms') {
          _termsOfService = doc;
        } else if (type == 'offer') {
          _offer = doc;
        }
      }
    } catch (e) {
      _error = e.toString();
    }
    
    notifyListeners();
  }

  Future<void> loadAllDocuments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.wait([
      loadDocument('privacy'),
      loadDocument('terms'),
      loadDocument('offer'),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateDocument(String type, String title, String content) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.legal}/$type'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'title': title, 'content': content}),
      );

      if (response.statusCode == 200) {
        await loadDocument(type);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _error = 'Ошибка: ${response.statusCode}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}