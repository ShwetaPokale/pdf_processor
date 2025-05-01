class AppConfig {
  // API Configuration
  static const String apiUrl = 'http://localhost:8080';
  static const String apiKey = '';

  // App Configuration
  static const String appName = 'Doc Processor';
  static const bool isDebug = true;
  static const String logLevel = 'debug';

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;

  // API Endpoints
  static String get loginEndpoint => '$apiUrl/api/auth/login';
  static String get uploadEndpoint => '$apiUrl/api/documents/upload';
  static String get processEndpoint => '$apiUrl/api/documents/process';
  
  // File upload settings
  static const List<String> allowedFileTypes = ['pdf', 'jpg', 'jpeg', 'png'];
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  
  // Authentication settings
  static const String authTokenKey = 'auth_token';
} 