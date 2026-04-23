import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/support_ticket.dart';
import '../config/api_config.dart';

class SupportProvider with ChangeNotifier {
  List<SupportTicket> _tickets = [];
  SupportTicket? _currentTicket;
  bool _isLoading = false;
  String? _error;

  List<SupportTicket> get tickets => _tickets;
  SupportTicket? get currentTicket => _currentTicket;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTickets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse(ApiConfig.supportMy),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _tickets = data.map((json) => SupportTicket.fromJson(json)).toList();
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTicket(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.support}/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Сервер возвращает {ticket: ..., messages: [...]}
        if (data['ticket'] != null) {
          var ticket = SupportTicket.fromJson(data['ticket']);
          // Обновляем сообщения из ответа
          if (data['messages'] != null) {
            ticket = SupportTicket(
              id: ticket.id,
              userId: ticket.userId,
              userName: ticket.userName,
              subject: ticket.subject,
              status: ticket.status,
              lastMessage: ticket.lastMessage,
              messages: (data['messages'] as List)
                  .map((m) => SupportMessage.fromJson(m))
                  .toList(),
              createdAt: ticket.createdAt,
              updatedAt: ticket.updatedAt,
            );
          }
          _currentTicket = ticket;
        } else {
          _currentTicket = SupportTicket.fromJson(data);
        }
      } else if (response.statusCode == 403) {
        _error = 'Нет доступа к этому обращению';
      } else if (response.statusCode == 404) {
        _error = 'Обращение не найдено';
      }
    } catch (e) {
      _error = e.toString();
      print('loadTicket error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createTicket(String subject, String message) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.post(
        Uri.parse(ApiConfig.support),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'subject': subject, 'message': message}),
      );

      if (response.statusCode == 201) {
        await loadTickets();
        return true;
      }
      throw Exception('Ошибка: ${response.statusCode}');
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendMessage(int ticketId, String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.support}/$ticketId/messages'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        await loadTicket(ticketId);
        return true;
      }
      throw Exception('Ошибка: ${response.statusCode}');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> closeTicket(int ticketId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.patch(
        Uri.parse('${ApiConfig.support}/$ticketId/close'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await loadTickets();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearCurrentTicket() {
    _currentTicket = null;
  }
}