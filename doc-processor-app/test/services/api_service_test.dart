import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doc_processor_app/services/api_service.dart';

@GenerateMocks([Dio, File])
import 'api_service_test.mocks.dart';

void main() {
  late ApiService apiService;
  late MockDio mockDio;
  late MockFile mockFile;
  late SharedPreferences prefs;

  setUp(() async {
    mockDio = MockDio();
    mockFile = MockFile();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    
    // Create ApiService with SharedPreferences
    apiService = ApiService(prefs);
    // Set the mock Dio instance
    apiService.setDioForTesting(mockDio);
  });

  group('processDocument', () {
    test('should successfully process document and return response data', () async {
      // Arrange
      const String command = 'extract_text';
      const String fileName = 'test.pdf';
      final Map<String, dynamic> expectedResponse = {'status': 'success', 'data': 'processed content'};
      
      when(mockFile.path).thenReturn('/path/to/$fileName');
      when(mockDio.post(
        '/api/process',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
        data: expectedResponse,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/process'),
      ));

      // Act
      final result = await apiService.processDocument(mockFile, command);

      // Assert
      expect(result, equals(expectedResponse));
      verify(mockDio.post(
        '/api/process',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).called(1);
    });

    test('should throw exception when API call fails', () async {
      // Arrange
      const String command = 'extract_text';
      const String fileName = 'test.pdf';
      
      when(mockFile.path).thenReturn('/path/to/$fileName');
      when(mockDio.post(
        '/api/process',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/api/process'),
        response: Response(
          data: {'error': 'Processing failed'},
          statusCode: 500,
          requestOptions: RequestOptions(path: '/api/process'),
        ),
      ));

      // Act & Assert
      expect(
        () => apiService.processDocument(mockFile, command),
        throwsA(isA<Exception>()),
      );
    });
  });
}

