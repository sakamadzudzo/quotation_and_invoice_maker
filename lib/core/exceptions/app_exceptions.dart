/// Base class for all application-specific exceptions.
///
/// This abstract class provides a consistent structure for custom exceptions
/// throughout the application, including message, original error, and error codes.
abstract class AppException implements Exception {
  final String message;
  final dynamic originalError;
  final String? code;

  AppException(this.message, [this.originalError, this.code]);

  @override
  String toString() => '$runtimeType${code != null ? '[$code]' : ''}: $message';
}

/// Exception thrown when repository operations fail.
///
/// This exception is used by repository classes to wrap data access errors
/// and provide consistent error handling for database operations.
class RepositoryException extends AppException {
  RepositoryException(String message, [dynamic error, String? code])
      : super(message, error, code);
}

/// Exception thrown when validation operations fail.
///
/// This exception is used when business rules or data validation fails,
/// providing detailed information about what validation rule was violated.
class ValidationException extends AppException {
  ValidationException(String message, [String? code])
      : super(message, null, code);
}

/// Exception thrown when network operations fail.
///
/// This exception is used for API calls and network-related operations
/// that fail due to connectivity or server issues.
class NetworkException extends AppException {
  NetworkException(String message, [dynamic error])
      : super(message, error, 'NETWORK_ERROR');
}

/// Exception thrown when database operations fail.
///
/// This exception is specifically for SQLite database operations
/// and provides detailed information about database-related errors.
class DatabaseException extends AppException {
  DatabaseException(String message, [dynamic error])
      : super(message, error, 'DATABASE_ERROR');
}

/// Exception thrown when PDF generation operations fail.
///
/// This exception is used by PDF services to indicate document generation
/// failures, which could be due to missing data, invalid formats, or
/// file system issues.
class PdfGenerationException extends AppException {
  PdfGenerationException(String message, [dynamic error])
      : super(message, error, 'PDF_GENERATION_ERROR');
}