/// Abstract interface for logging operations.
///
/// This interface defines the contract for logging functionality,
/// allowing different logging implementations (console, file, remote, etc.).
abstract class ILogger {
  /// Logs a debug message.
  ///
  /// [message] - The debug message to log
  /// [error] - Optional error object associated with the message
  /// [stackTrace] - Optional stack trace for debugging
  void debug(String message, [dynamic error, StackTrace? stackTrace]);

  /// Logs an informational message.
  ///
  /// [message] - The informational message to log
  void info(String message);

  /// Logs a warning message.
  ///
  /// [message] - The warning message to log
  /// [error] - Optional error object associated with the message
  /// [stackTrace] - Optional stack trace for debugging
  void warning(String message, [dynamic error, StackTrace? stackTrace]);

  /// Logs an error message.
  ///
  /// [message] - The error message to log
  /// [error] - Optional error object associated with the message
  /// [stackTrace] - Optional stack trace for debugging
  void error(String message, [dynamic error, StackTrace? stackTrace]);
}