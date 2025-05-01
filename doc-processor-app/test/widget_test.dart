// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:doc_processor_app/main.dart';
import 'package:doc_processor_app/providers/auth_provider.dart';
import 'package:doc_processor_app/providers/document_provider.dart';
import 'package:doc_processor_app/services/api_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([ApiService])
import 'widget_test.mocks.dart';

void main() {
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    when(mockApiService.getToken()).thenAnswer((_) async => null);
  });

  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(mockApiService)),
          ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the app renders without errors
    expect(find.byType(MyApp), findsOneWidget);
  });
}
