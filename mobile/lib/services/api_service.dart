import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/logger.dart';

class ApiService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _getHeaders({bool needsAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (needsAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        Logger.warning('No token found for authenticated request');
      }
    }

    return headers;
  }

  static Future<dynamic> get(String url, {bool needsAuth = false}) async {
    try {
      Logger.info('GET Request', url);
      final headers = await _getHeaders(needsAuth: needsAuth);
      Logger.debug('Headers', headers);
      final response = await http.get(Uri.parse(url), headers: headers);
      Logger.debug('Response status', response.statusCode);
      return _handleResponse(response);
    } catch (e) {
      Logger.error('GET Request failed', e);
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<dynamic> post(String url, dynamic body, {bool needsAuth = false}) async {
    try {
      final headers = await _getHeaders(needsAuth: needsAuth);
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<dynamic> put(String url, dynamic body, {bool needsAuth = false}) async {
    try {
      final headers = await _getHeaders(needsAuth: needsAuth);
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<dynamic> patch(String url, {bool needsAuth = false}) async {
    try {
      final headers = await _getHeaders(needsAuth: needsAuth);
      final response = await http.patch(Uri.parse(url), headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<dynamic> patchWithBody(String url, Map<String, dynamic> body, {bool needsAuth = false}) async {
    try {
      final headers = await _getHeaders(needsAuth: needsAuth);
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<dynamic> delete(String url, {bool needsAuth = false}) async {
    try {
      final headers = await _getHeaders(needsAuth: needsAuth);
      final response = await http.delete(Uri.parse(url), headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    Logger.debug('Response body', response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      Logger.error('API Error', error);
      throw Exception(error['error'] ?? 'Неизвестная ошибка');
    }
  }

  static Future<dynamic> uploadFile(
    String url,
    String filePath,
    String fieldName, {
    Map<String, String>? fields,
    bool needsAuth = false,
    String method = 'POST',
  }) async {
    try {
      final request = http.MultipartRequest(method, Uri.parse(url));

      if (needsAuth) {
        final token = await _getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      // Determine MIME type
      String contentType = _getContentType(filePath);

      if (kIsWeb) {
        final bytes = await File(filePath).readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.${contentType.split('/')[1]}',
          contentType: http.MediaType.parse(contentType),
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          fieldName,
          filePath,
          contentType: http.MediaType.parse(contentType),
        ));
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Ошибка загрузки файла: $e');
    }
  }

  static String _getContentType(String filePath) {
    if (filePath.toLowerCase().endsWith('.png')) {
      return 'image/png';
    } else if (filePath.toLowerCase().endsWith('.webp')) {
      return 'image/webp';
    } else {
      return 'image/jpeg';
    }
  }

  // Загрузка нескольких файлов
  static Future<dynamic> uploadFiles(
    String url,
    List<String> filePaths,
    String fieldName, {
    Map<String, String>? fields,
    bool needsAuth = false,
  }) async {
    try {
      Logger.info('uploadFiles: URL = $url');
      Logger.info('uploadFiles: fieldName = $fieldName, filePaths = $filePaths');
      
      final request = http.MultipartRequest('POST', Uri.parse(url));
      Logger.info('Created MultipartRequest');

      if (needsAuth) {
        final token = await _getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
          Logger.info('[DEBUG] Added auth token');
        }
      }

      // Add all files
      for (int i = 0; i < filePaths.length; i++) {
        final filePath = filePaths[i];
        String contentType = _getContentType(filePath);
        Logger.info('[DEBUG] Processing file $i: $filePath, contentType: $contentType');
        
        if (kIsWeb) {
          final bytes = await File(filePath).readAsBytes();
          Logger.info('[DEBUG] Web file size: ${bytes.length}');
          request.files.add(http.MultipartFile.fromBytes(
            '${fieldName}[$i]',
            bytes,
            filename: 'upload_${i}_${DateTime.now().millisecondsSinceEpoch}',
            contentType: http.MediaType.parse(contentType),
          ));
        } else {
          final file = await http.MultipartFile.fromPath(
            '${fieldName}[$i]',
            filePath,
            contentType: http.MediaType.parse(contentType),
          );
          Logger.info('[DEBUG] Added file from path, size: ${file.length}');
          request.files.add(file);
        }
      }

      if (fields != null) {
        Logger.info('[DEBUG] Adding fields: $fields');
        request.fields.addAll(fields);
      }

      Logger.info('[DEBUG] Sending request with ${request.files.length} files');
      final streamedResponse = await request.send();
      Logger.info('[DEBUG] Response status: ${streamedResponse.statusCode}');
      
      final response = await http.Response.fromStream(streamedResponse);
      Logger.info('[DEBUG] Response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      Logger.info('[DEBUG] uploadFiles ERROR: $e');
      throw Exception('Ошибка загрузки файлов: $e');
    }
  }
}
