import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'i_logger.dart';

/// Default logger implementation using Flutter's debugPrint.
///
/// This logger provides console-based logging with different log levels
/// and includes emojis for better visual distinction in development.
class Logger implements ILogger {
  static const String _tag = 'QuotationApp';
  final AppConfig? _config;

  Logger([this._config]);

  bool get _isLoggingEnabled => _config?.enableLogging ?? true;

  @override
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_isLoggingEnabled && kDebugMode) {
      debugPrint('🐛 $_tag: $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }

  @override
  void info(String message) {
    if (_isLoggingEnabled) {
      debugPrint('ℹ️ $_tag: $message');
    }
  }

  @override
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_isLoggingEnabled) {
      debugPrint('⚠️ $_tag: $message');
      if (error != null) debugPrint('Warning: $error');
    }
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_isLoggingEnabled) {
      debugPrint('❌ $_tag: $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }
}