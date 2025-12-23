enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment _environment = Environment.development;

  static Environment get environment => _environment;

  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;

  /// Initialize environment from --dart-define
  static void initialize() {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');

    switch (env.toLowerCase()) {
      case 'production':
      case 'prod':
        _environment = Environment.production;
        break;
      case 'staging':
      case 'stg':
        _environment = Environment.staging;
        break;
      case 'development':
      case 'dev':
      default:
        _environment = Environment.development;
        break;
    }
  }

  /// Get API base URL based on environment
  static String get apiBaseUrl {
    const customBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (customBaseUrl.isNotEmpty) {
      return customBaseUrl;
    }

    switch (_environment) {
      case Environment.production:
        return 'https://api.nguhanhson.vn/api/v1';
      case Environment.staging:
        return 'https://staging-api.nguhanhson.vn/api/v1';
      case Environment.development:
        return 'http://localhost:3000/api/v1';
    }
  }

  /// Get environment display name
  static String get environmentName {
    switch (_environment) {
      case Environment.production:
        return 'Production';
      case Environment.staging:
        return 'Staging';
      case Environment.development:
        return 'Development';
    }
  }

  /// Enable debug features
  static bool get enableDebugFeatures {
    return isDevelopment || isStaging;
  }

  /// Enable analytics
  static bool get enableAnalytics {
    return isProduction || isStaging;
  }

  /// Enable crash reporting
  static bool get enableCrashReporting {
    return isProduction;
  }

  /// Get timeout duration
  static Duration get connectionTimeout {
    return isDevelopment
        ? const Duration(seconds: 60)
        : const Duration(seconds: 30);
  }

  /// Get receive timeout
  static Duration get receiveTimeout {
    return isDevelopment
        ? const Duration(seconds: 60)
        : const Duration(seconds: 30);
  }

  /// Print environment info
  static void printInfo() {
    print('╔════════════════════════════════════════╗');
    print('║  Environment Configuration            ║');
    print('╠════════════════════════════════════════╣');
    print('║  Environment: $_environment');
    print('║  API Base URL: $apiBaseUrl');
    print('║  Debug Features: $enableDebugFeatures');
    print('║  Analytics: $enableAnalytics');
    print('║  Crash Reporting: $enableCrashReporting');
    print('╚════════════════════════════════════════╝');
  }
}
