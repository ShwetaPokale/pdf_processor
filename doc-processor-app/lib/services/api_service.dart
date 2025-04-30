import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  final Dio _dio;
  final String baseUrl;

  ApiService() : baseUrl = kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080',
        _dio = Dio(BaseOptions(
          baseUrl: kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080',
          connectTimeout: const Duration(milliseconds: 30000),
          receiveTimeout: const Duration(milliseconds: 30000),
        ));

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<Response> processFile(File file) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });

    return await _dio.post(
      '/api/process',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/api/login', data: {
        'username': username,
        'password': password,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> processDocument(File file, String command) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'command': command,
      });

      final response = await _dio.post(
        '/api/process',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        return Exception(error.response?.data['error'] ?? 'An error occurred');
      }
      return Exception(error.message ?? 'Network error occurred');
    }
    return Exception('An unexpected error occurred');
  }
} 