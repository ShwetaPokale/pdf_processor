import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/app_config.dart';

class ApiService {
  final Dio _dio;
  SharedPreferences? _prefs;
  final String baseUrl;

  ApiService({Dio? dio, SharedPreferences? prefs})
      : baseUrl = AppConfig.apiUrl,
        _dio = dio ?? Dio(BaseOptions(
          baseUrl: kIsWeb ? AppConfig.apiUrl : AppConfig.apiUrl.replaceAll('localhost', '10.0.2.2'),
          connectTimeout: const Duration(milliseconds: 30000),
          receiveTimeout: const Duration(milliseconds: 30000),
        )),
        _prefs = prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> getToken() async {
    await _initPrefs();
    return _prefs?.getString('token');
  }

  Future<void> setToken(String token) async {
    await _initPrefs();
    await _prefs?.setString('token', token);
  }

  Future<void> removeToken() async {
    await _initPrefs();
    await _prefs?.remove('token');
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
      print('Making login request to /api/login');
      final response = await _dio.post('/api/login', data: {
        'username': username,
        'password': password,
      });
      
      print('Login response status code: ${response.statusCode}');
      print('Login response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['token'] == null) {
          print('Token is null in response data');
          throw Exception('Login response missing token');
        }
        print("Login success, token received");
        return data;
      } else {
        print("Login failed with status code: ${response.statusCode}");
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      print('Login error caught: $e');
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