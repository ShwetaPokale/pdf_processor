class AppConfig {
  static const String apiBaseUrl = 'http://localhost:8080';
  
  // API Endpoints
  static const String loginEndpoint = '$apiBaseUrl/api/auth/login';
  static const String uploadEndpoint = '$apiBaseUrl/api/documents/upload';
  static const String processEndpoint = '$apiBaseUrl/api/documents/process';
  
  // File upload settings
  static const List<String> allowedFileTypes = ['pdf', 'jpg', 'jpeg', 'png'];
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  
  // Authentication settings
  static const String authTokenKey = 'auth_token';
} 