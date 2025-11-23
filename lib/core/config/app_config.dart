/// Application configuration management system.
///
/// This file provides centralized configuration management for the Quotation & Invoice Maker app.
/// It supports multiple environments (development, staging, production) and feature flags
/// to control app behavior based on build variants or runtime conditions.
///
/// Key Features:
/// - Environment-specific configuration (dev/staging/prod)
/// - Feature flags for controlling functionality
/// - Centralized settings management
/// - Type-safe configuration access
///
/// Usage:
/// ```dart
/// final config = AppConfig.fromEnvironment();
/// if (config.isDevelopment) {
///   // Development-specific code
/// }
/// ```
library;

import 'package:flutter/foundation.dart';

/// Application configuration management.
///
/// Provides environment-specific settings and feature flags.
/// Supports development, staging, and production environments.
class AppConfig {
  static const String _envKey = 'ENVIRONMENT';
  static const String _apiBaseUrlKey = 'API_BASE_URL';
  static const String _enableLoggingKey = 'ENABLE_LOGGING';
  static const String _enableAnalyticsKey = 'ENABLE_ANALYTICS';

  // Default configuration values
  static const String _defaultEnvironment = 'development';
  static const String _defaultApiBaseUrl = 'https://api.example.com';
  static const bool _defaultEnableLogging = true;
  static const bool _defaultEnableAnalytics = false;

  /// Current environment (development, staging, production)
  final String environment;

  /// API base URL for network requests
  final String apiBaseUrl;

  /// Whether logging is enabled
  final bool enableLogging;

  /// Whether analytics is enabled
  final bool enableAnalytics;

  /// Whether the app is running in development mode
  bool get isDevelopment => environment == 'development';

  /// Whether the app is running in staging mode
  bool get isStaging => environment == 'staging';

  /// Whether the app is running in production mode
  bool get isProduction => environment == 'production';

  /// Whether the app is running in debug mode
  bool get isDebug => kDebugMode;

  const AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableLogging,
    required this.enableAnalytics,
  });

  /// Creates a configuration for development environment.
  factory AppConfig.development() => const AppConfig._(
        environment: 'development',
        apiBaseUrl: 'https://dev-api.example.com',
        enableLogging: true,
        enableAnalytics: false,
      );

  /// Creates a configuration for staging environment.
  factory AppConfig.staging() => const AppConfig._(
        environment: 'staging',
        apiBaseUrl: 'https://staging-api.example.com',
        enableLogging: true,
        enableAnalytics: true,
      );

  /// Creates a configuration for production environment.
  factory AppConfig.production() => const AppConfig._(
        environment: 'production',
        apiBaseUrl: 'https://api.example.com',
        enableLogging: false,
        enableAnalytics: true,
      );

  /// Creates a configuration from environment variables or platform channels.
  ///
  /// This method can be extended to read from:
  /// - Environment variables
  /// - Platform channels (for native configuration)
  /// - Remote configuration services
  /// - Local configuration files
  factory AppConfig.fromEnvironment() {
    // In a real app, you would read from environment variables,
    // platform channels, or configuration files
    final environment = const String.fromEnvironment(
      _envKey,
      defaultValue: _defaultEnvironment,
    );

    switch (environment.toLowerCase()) {
      case 'production':
      case 'prod':
        return AppConfig.production();
      case 'staging':
      case 'stage':
        return AppConfig.staging();
      case 'development':
      case 'dev':
      default:
        return AppConfig.development();
    }
  }

  /// Creates a custom configuration with specific values.
  factory AppConfig.custom({
    String? environment,
    String? apiBaseUrl,
    bool? enableLogging,
    bool? enableAnalytics,
  }) => AppConfig._(
        environment: environment ?? _defaultEnvironment,
        apiBaseUrl: apiBaseUrl ?? _defaultApiBaseUrl,
        enableLogging: enableLogging ?? _defaultEnableLogging,
        enableAnalytics: enableAnalytics ?? _defaultEnableAnalytics,
      );

  @override
  String toString() {
    return 'AppConfig('
        'environment: $environment, '
        'apiBaseUrl: $apiBaseUrl, '
        'enableLogging: $enableLogging, '
        'enableAnalytics: $enableAnalytics'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppConfig &&
        other.environment == environment &&
        other.apiBaseUrl == apiBaseUrl &&
        other.enableLogging == enableLogging &&
        other.enableAnalytics == enableAnalytics;
  }

  @override
  int get hashCode {
    return Object.hash(
      environment,
      apiBaseUrl,
      enableLogging,
      enableAnalytics,
    );
  }
}

/// Feature flags for controlling app behavior.
///
/// Add new features here and control their availability
/// based on environment or user segments.
class FeatureFlags {
  /// Whether the new PDF customization feature is enabled
  static const bool pdfCustomization = true;

  /// Whether cloud backup is enabled
  static const bool cloudBackup = false;

  /// Whether advanced analytics is enabled
  static const bool advancedAnalytics = false;

  /// Whether experimental features are enabled
  static const bool experimentalFeatures = false;

  /// Whether to show debug information
  static bool get showDebugInfo => AppConfig.fromEnvironment().isDevelopment;
}

/// Configuration keys for environment variables and platform channels.
class ConfigKeys {
  static const String environment = 'ENVIRONMENT';
  static const String apiBaseUrl = 'API_BASE_URL';
  static const String enableLogging = 'ENABLE_LOGGING';
  static const String enableAnalytics = 'ENABLE_ANALYTICS';
  static const String databasePath = 'DATABASE_PATH';
  static const String logLevel = 'LOG_LEVEL';
}