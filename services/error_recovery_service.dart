import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../utils/constants.dart';
import 'database_service.dart';
import 'file_service.dart';

class ErrorRecoveryService {
  static const int maxRecoveryAttempts = 3;

  // Database corruption recovery
  static Future<bool> recoverDatabaseCorruption() async {
    try {
      final dbService = DatabaseService();
      final dbPath = await _getDatabasePath();

      // Check if database file exists and is corrupted
      if (!await File(dbPath).exists()) {
        // Database doesn't exist, create new one
        await dbService.database;
        return true;
      }

      // Try to open database to check for corruption
      Database? testDb;
      try {
        testDb = await openDatabase(dbPath, readOnly: true);
        // Try a simple query to test database integrity
        await testDb.rawQuery('SELECT COUNT(*) FROM sqlite_master');
        await testDb.close();
        return true; // Database is fine
      } catch (e) {
        // Database is corrupted, attempt recovery
        if (testDb != null) {
          await testDb.close();
        }

        return await _attemptDatabaseRecovery(dbPath);
      }
    } catch (e) {
      print('Database recovery failed: $e');
      return false;
    }
  }

  static Future<String> _getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return path.join(databasesPath, AppConstants.databaseName);
  }

  static Future<bool> _attemptDatabaseRecovery(String dbPath) async {
    try {
      // Create backup of corrupted database
      final backupPath = '${dbPath}.corrupted.${DateTime.now().millisecondsSinceEpoch}';
      await File(dbPath).copy(backupPath);

      // Delete corrupted database
      await File(dbPath).delete();

      // Create new database
      final dbService = DatabaseService();
      await dbService.database;

      print('Database recovery successful. Corrupted backup saved at: $backupPath');
      return true;
    } catch (e) {
      print('Database recovery attempt failed: $e');
      return false;
    }
  }

  // Storage space validation
  static Future<String?> validateStorageSpace(int requiredBytes) async {
    try {
      // Get available storage space (simplified - platform dependent)
      final availableSpace = await FileService.getAvailableStorageSpace();

      if (availableSpace != null && availableSpace < requiredBytes) {
        return 'Insufficient storage space. Required: ${requiredBytes ~/ 1024}KB, Available: ${availableSpace ~/ 1024}KB';
      }

      // Check current app storage usage
      final currentUsage = await FileService.getStorageUsage();
      const maxQuota = 100 * 1024 * 1024; // 100MB

      if (currentUsage + requiredBytes > maxQuota) {
        return 'Storage quota exceeded. Current usage: ${(currentUsage / 1024 / 1024).toStringAsFixed(1)}MB, Limit: ${maxQuota ~/ 1024 ~/ 1024}MB';
      }

      return null;
    } catch (e) {
      return 'Unable to validate storage space: $e';
    }
  }

  // File permission validation
  static Future<String?> validateFilePermissions(String filePath) async {
    try {
      final file = File(filePath);

      // Check if we can read the file
      if (await file.exists()) {
        await file.readAsBytes();
      }

      // Check if we can write to the directory
      final directory = Directory(path.dirname(filePath));
      final testFile = File(path.join(directory.path, '.permission_test'));

      await testFile.writeAsString('test');
      await testFile.delete();

      return null;
    } catch (e) {
      return 'File permission error: $e';
    }
  }

  // Network timeout handling for Google Drive
  static Future<T> withNetworkTimeout<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      attempts++;

      try {
        return await operation().timeout(timeout);
      } catch (e) {
        if (attempts >= maxRetries) {
          throw Exception('Network operation failed after $maxRetries attempts: $e');
        }

        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }

    throw Exception('Network timeout after $maxRetries attempts');
  }

  // Concurrent access conflict resolution
  static Future<T> withConflictResolution<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 100),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      attempts++;

      try {
        return await operation();
      } catch (e) {
        final errorMessage = e.toString().toLowerCase();

        // Check if it's a database lock or conflict error
        if (errorMessage.contains('database is locked') ||
            errorMessage.contains('constraint failed') ||
            errorMessage.contains('busy')) {

          if (attempts >= maxRetries) {
            throw Exception('Database conflict could not be resolved after $maxRetries attempts: $e');
          }

          // Wait and retry
          await Future.delayed(retryDelay * attempts);
          continue;
        }

        // Not a conflict error, rethrow immediately
        rethrow;
      }
    }

    throw Exception('Operation failed after $maxRetries attempts');
  }

  // Crash recovery for critical operations
  static Future<T> withCrashRecovery<T>(
    Future<T> Function() operation,
    String operationName, {
    Future<void> Function()? cleanup,
  }) async {
    try {
      return await operation();
    } catch (e) {
      print('Critical operation "$operationName" failed: $e');

      // Attempt cleanup if provided
      if (cleanup != null) {
        try {
          await cleanup();
        } catch (cleanupError) {
          print('Cleanup also failed: $cleanupError');
        }
      }

      // Log crash details for debugging
      await _logCrash(operationName, e);

      // Re-throw with more context
      throw Exception('Operation "$operationName" failed and could not be recovered: $e');
    }
  }

  static Future<void> _logCrash(String operationName, dynamic error) async {
    try {
      final crashLog = {
        'timestamp': DateTime.now().toIso8601String(),
        'operation': operationName,
        'error': error.toString(),
        'stackTrace': error is Error ? error.stackTrace.toString() : 'No stack trace',
      };

      // In a real app, this would be saved to a crash log file or sent to analytics
      print('CRASH LOG: $crashLog');
    } catch (e) {
      // Don't let crash logging itself crash
      print('Failed to log crash: $e');
    }
  }

  // Memory management for large datasets
  static Future<List<T>> processLargeDataset<T>(
    Future<List<T>> Function() dataLoader,
    int batchSize, {
    void Function(int processed, int total)? onProgress,
  }) async {
    try {
      final allData = await dataLoader();
      final result = <T>[];

      for (int i = 0; i < allData.length; i += batchSize) {
        final end = (i + batchSize < allData.length) ? i + batchSize : allData.length;
        final batch = allData.sublist(i, end);

        // Process batch (in real implementation, this might involve database operations)
        result.addAll(batch);

        // Report progress
        onProgress?.call(result.length, allData.length);

        // Allow UI to remain responsive
        await Future.delayed(Duration.zero);
      }

      return result;
    } catch (e) {
      throw Exception('Failed to process large dataset: $e');
    }
  }

  // Background processing wrapper
  static Future<T> runInBackground<T>(
    Future<T> Function() operation, {
    String? taskName,
    void Function(double progress)? onProgress,
  }) async {
    // In Flutter, we can use compute() for CPU-intensive tasks
    // or just run in a separate isolate for I/O operations
    try {
      if (taskName != null) {
        print('Starting background task: $taskName');
      }

      final result = await operation();

      if (taskName != null) {
        print('Completed background task: $taskName');
      }

      return result;
    } catch (e) {
      throw Exception('Background task failed: $e');
    }
  }
}