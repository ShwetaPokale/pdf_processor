import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:doc_processor_app/providers/auth_provider.dart';
import 'package:doc_processor_app/services/api_service.dart';

@GenerateMocks([ApiService])
import 'auth_provider_test.mocks.dart';

void main() {
  late AuthProvider authProvider;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    when(mockApiService.getToken()).thenAnswer((_) async => null);
    authProvider = AuthProvider(mockApiService);
  });

  group('AuthProvider Tests', () {
    test('initial state is not authenticated', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.loginMessage, null);
    });

    test('login sets authenticated state and messages', () async {
      // Arrange
      const username = 'test_user';
      const password = 'test_pass';
      
      when(mockApiService.setToken('test_token_123'))
          .thenAnswer((_) async => null);

      // Act
      final result = await authProvider.login(username, password);

      // Assert
      expect(result, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.loginMessage, 'Login successful!');
      verify(mockApiService.setToken('test_token_123')).called(1);
    });

    test('logout resets authenticated state and shows messages', () async {
      // Arrange
      when(mockApiService.removeToken()).thenAnswer((_) async => null);

      // Act
      await authProvider.logout();

      // Assert
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.loginMessage, 'Logged out successfully');
      verify(mockApiService.removeToken()).called(1);
    });

    test('login handles error correctly with message', () async {
      // Arrange
      const username = 'test_user';
      const password = 'test_pass';
      const errorMessage = 'Failed to set token';
      
      when(mockApiService.setToken('test_token_123'))
          .thenThrow(Exception(errorMessage));

      // Act
      final result = await authProvider.login(username, password);

      // Assert
      expect(result, false);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.loginMessage, 'Login failed: Exception: $errorMessage');
    });
  });

  group('Login Tests', () {
    test('login shows loading message', () async {
      // Arrange
      const username = 'test_user';
      const password = 'test_pass';
      
      when(mockApiService.setToken('test_token_123'))
          .thenAnswer((_) async => null);

      // Act
      final future = authProvider.login(username, password);
      
      // Assert
      expect(authProvider.loginMessage, 'Logging in...');
      await future;
    });

    test('login success shows success message', () async {
      // Arrange
      const username = 'test_user';
      const password = 'test_pass';
      
      when(mockApiService.setToken('test_token_123'))
          .thenAnswer((_) async => null);

      // Act
      final result = await authProvider.login(username, password);

      // Assert
      expect(result, true);
      expect(authProvider.loginMessage, 'Login successful!');
      expect(authProvider.isAuthenticated, true);
    });

    test('login failure shows error message', () async {
      // Arrange
      const username = 'test_user';
      const password = 'test_pass';
      const errorMessage = 'Invalid credentials';
      
      when(mockApiService.setToken('test_token_123'))
          .thenThrow(Exception(errorMessage));

      // Act
      final result = await authProvider.login(username, password);

      // Assert
      expect(result, false);
      expect(authProvider.loginMessage, 'Login failed: Exception: $errorMessage');
      expect(authProvider.isAuthenticated, false);
    });
  });
} 