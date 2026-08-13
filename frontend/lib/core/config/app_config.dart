import 'package:flutter/foundation.dart';

enum Environment { development, production }

class AppConfig {
  // Default to production so the app connects to the live Render backend immediately.
  // Can be overridden at compile time: --dart-define=ENV=development
  static const String _envString = String.fromEnvironment('ENV', defaultValue: 'production');

  static Environment get environment {
    if (_envString.toLowerCase() == 'development' || _envString.toLowerCase() == 'dev') {
      return Environment.development;
    }
    return Environment.production;
  }

  static bool get isProduction => environment == Environment.production;
  static bool get isDevelopment => environment == Environment.development;

  /// Production Backend Hosted on Render
  static const String productionBaseUrl = 'https://smartkrishi-kbyr.onrender.com/api';

  /// Local Development URLs
  static const String localWebBaseUrl = 'http://localhost:8080/api';
  static const String localAndroidBaseUrl = 'http://10.0.2.2:8080/api';

  /// Centralized API Base URL getter
  static String get apiBaseUrl {
    if (isProduction) {
      return productionBaseUrl;
    }

    if (kIsWeb) {
      return localWebBaseUrl;
    }
    return localAndroidBaseUrl;
  }

  /// App name & version metadata
  static const String appName = 'SmartKrishi';
  static const String appVersion = '1.0.0';
}
