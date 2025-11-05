import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../utils/constants.dart';
import 'validation_service.dart';

class FileService {
  static const String logosDirectory = AppConstants.logosDirectory;
  static const String backupsDirectory = AppConstants.backupsDirectory;
  static const int maxStorageQuotaBytes = 200 * 1024 * 1024; // 200MB

  // Get app documents directory
  static Future<Directory> getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  // Get logos directory
  static Future<Directory> getLogosDirectory() async {
    final appDir = await getAppDocumentsDirectory();
    final logosDir = Directory(path.join(appDir.path, logosDirectory));
    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
    }
    return logosDir;
  }

  // Get backups directory
  static Future<Directory> getBackupsDirectory() async {
    final appDir = await getAppDocumentsDirectory();
    final backupsDir = Directory(path.join(appDir.path, backupsDirectory));
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    return backupsDir;
  }

  // Save logo file with validation
  static Future<String?> saveLogoFile(String sourcePath, String fileName) async {
    try {
      final sourceFile = File(sourcePath);
      final fileSize = await sourceFile.length();

      // Validate file
      final validationError = ValidationService.validateLogoFile(sourcePath, fileSize);
      if (validationError != null) {
        throw Exception(validationError);
      }

      final logosDir = await getLogosDirectory();
      final extension = path.extension(sourcePath);
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName$extension';
      final destinationPath = path.join(logosDir.path, uniqueFileName);

      // Copy file
      await sourceFile.copy(destinationPath);

      return uniqueFileName;
    } catch (e) {
      throw Exception('Failed to save logo: $e');
    }
  }

  // Delete logo file
  static Future<void> deleteLogoFile(String fileName) async {
    try {
      final logosDir = await getLogosDirectory();
      final filePath = path.join(logosDir.path, fileName);
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Log error but don't throw - cleanup is not critical
      print('Warning: Failed to delete logo file $fileName: $e');
    }
  }

  // Get logo file path
  static Future<String?> getLogoFilePath(String fileName) async {
    try {
      final logosDir = await getLogosDirectory();
      final filePath = path.join(logosDir.path, fileName);
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get storage usage
  static Future<int> getStorageUsage() async {
    try {
      final appDir = await getAppDocumentsDirectory();
      return await _calculateDirectorySize(appDir);
    } catch (e) {
      return 0;
    }
  }

  // Calculate directory size recursively
  static Future<int> _calculateDirectorySize(Directory directory) async {
    int totalSize = 0;

    try {
      final files = directory.list(recursive: true);
      await for (final entity in files) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      // Continue with partial calculation
    }

    return totalSize;
  }

  // Check storage quota
  static Future<String?> checkStorageQuota() async {
    final usage = await getStorageUsage();
    return ValidationService.validateStorageQuota(usage);
  }

  // Clean up orphaned logo files
  static Future<void> cleanupOrphanedLogos(List<String> activeLogoFiles) async {
    try {
      final logosDir = await getLogosDirectory();
      final files = logosDir.list();

      await for (final entity in files) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          if (!activeLogoFiles.contains(fileName)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      print('Warning: Failed to cleanup orphaned logos: $e');
    }
  }

  // Create backup file
  static Future<String> createBackup(Map<String, dynamic> data) async {
    try {
      final backupsDir = await getBackupsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'backup_$timestamp.json';
      final filePath = path.join(backupsDir.path, fileName);

      final jsonData = data.toString(); // Convert to JSON string
      final file = File(filePath);
      await file.writeAsString(jsonData);

      return fileName;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  // List backup files
  static Future<List<FileSystemEntity>> listBackupFiles() async {
    try {
      final backupsDir = await getBackupsDirectory();
      final files = await backupsDir.list().toList();
      return files.whereType<File>().toList();
    } catch (e) {
      return [];
    }
  }

  // Validate backup file integrity
  static Future<bool> validateBackupFile(String fileName) async {
    try {
      final backupsDir = await getBackupsDirectory();
      final filePath = path.join(backupsDir.path, fileName);
      final file = File(filePath);

      if (!await file.exists()) {
        return false;
      }

      // Try to read and parse the file
      final content = await file.readAsString();
      if (content.isEmpty) {
        return false;
      }

      // Basic JSON structure validation
      if (!content.startsWith('{') || !content.endsWith('}')) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get available storage space
  static Future<int?> getAvailableStorageSpace() async {
    try {
      final appDir = await getAppDocumentsDirectory();
      // ignore: unused_local_variable
      final stat = await FileStat.stat(appDir.path);
      // This is a simplified approach - in a real app you'd use platform-specific APIs
      return null; // Not implemented for cross-platform compatibility
    } catch (e) {
      return null;
    }
  }
}