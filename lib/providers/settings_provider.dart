import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _backupEnabledKey = 'backup_enabled';

  ThemeMode _themeMode = ThemeMode.system;
  bool _backupEnabled = false;
  bool _isLoading = true;

  ThemeMode get themeMode => _themeMode;
  bool get backupEnabled => _backupEnabled;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme mode
      final themeIndex = prefs.getInt(_themeKey) ?? 0; // 0 = system, 1 = light, 2 = dark
      _themeMode = ThemeMode.values[themeIndex];

      // Load backup setting
      _backupEnabled = prefs.getBool(_backupEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeMode.index);
      _themeMode = themeMode;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  Future<void> setBackupEnabled(bool enabled) async {
    if (_backupEnabled == enabled) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_backupEnabledKey, enabled);
      _backupEnabled = enabled;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving backup setting: $e');
    }
  }
}