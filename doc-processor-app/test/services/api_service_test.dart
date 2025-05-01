import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doc_processor_app/services/api_service.dart';

void main() {
  late ApiService apiService;
  late Dio dio;

  setUp(() {
    dio = Dio();
    apiService = ApiService(dio: dio);
  });

  group('Login Tests', () {
    test('Successful login returns user data and prints success message', () async {
      // Arrange
      final mockResponse = {
        'token': 'test_token',
        'user': {'id': 1, 'username': 'test_user'}
      };
      
      // Create a mock interceptor
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            data: mockResponse,
            statusCode: 200,
            requestOptions: options,
          ));
        },
      ));

      // Act
      final result = await apiService.login('test_user', 'password123');
      
      // Assert
      expect(result, mockResponse);
      expect(() => print("login success"), prints("login success\n"));
    });

    test('Login with invalid credentials throws exception', () async {
      // Arrange
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(DioException(
            requestOptions: options,
            response: Response(
              data: {'error': 'Invalid credentials'},
              statusCode: 401,
              requestOptions: options,
            ),
          ));
        },
      ));

      // Act & Assert
      expect(
        () => apiService.login('wrong_user', 'wrong_pass'),
        throwsA(isA<Exception>()),
      );
    });

    test('Network error during login throws exception', () async {
      // Arrange
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(DioException(
            requestOptions: options,
            error: 'Network error',
          ));
        },
      ));

      // Act & Assert
      expect(
        () => apiService.login('test_user', 'password123'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
