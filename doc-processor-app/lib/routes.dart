import 'package:flutter/material.dart';
import 'package:doc_processor_app/screens/login_screen.dart';
import 'package:doc_processor_app/screens/home_screen.dart';
import 'package:doc_processor_app/screens/upload_screen.dart';
import 'package:doc_processor_app/screens/results_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/upload':
        return MaterialPageRoute(builder: (_) => const UploadScreen());
      case '/results':
        return MaterialPageRoute(builder: (_) => const ResultsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
} 