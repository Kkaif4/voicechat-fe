class AppConstants {
  static const String appName = 'VoiceChat';
  static const String appVersion = '1.0.0';

  // Network
  static const String baseUrl =
      'http://localhost:5000/api/v1'; // Update with real IP usually
  static const String socketUrl = 'http://localhost:5000';

  // Storage Keys
  static const String tokenKey = 'auth_token';

  // Timeouts
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 10000;
}
