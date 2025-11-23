import 'package:flutter/foundation.dart';

/// Base class for all providers in the application.
///
/// This abstract class provides common functionality for state management,
/// loading states, error handling, and consistent behavior across all providers.
abstract class BaseProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  /// Whether the provider is currently performing an operation.
  bool get isLoading => _isLoading;

  /// The current error message, if any.
  String? get error => _error;

  /// Sets the loading state and notifies listeners.
  ///
  /// [loading] - Whether the provider should be in a loading state
  @protected
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Sets the error message and notifies listeners.
  ///
  /// [error] - The error message to display, or null to clear the error
  @protected
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clears the current error message and notifies listeners.
  @protected
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Executes an operation with automatic loading state management.
  ///
  /// [operation] - The async operation to execute
  /// Returns the result of the operation.
  /// Automatically handles loading states and error propagation.
  @protected
  Future<T> executeWithLoading<T>(Future<T> Function() operation) async {
    try {
      setLoading(true);
      clearError();
      final result = await operation();
      return result;
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  /// Executes an operation and returns a boolean success indicator.
  ///
  /// [operation] - The async operation to execute
  /// Returns true if the operation completed successfully, false otherwise.
  /// Errors are handled internally and do not propagate.
  @protected
  Future<bool> executeOperation(Future<void> Function() operation) async {
    try {
      await executeWithLoading(operation);
      return true;
    } catch (e) {
      return false;
    }
  }
}