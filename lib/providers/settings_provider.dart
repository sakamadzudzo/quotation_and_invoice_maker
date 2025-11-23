import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _backupEnabledKey = 'backup_enabled';

  // PDF Settings
  static const String _includeLogoKey = 'pdf_include_logo';
  static const String _includeTermsKey = 'pdf_include_terms';
  static const String _includeDisclaimerKey = 'pdf_include_disclaimer';
  static const String _includePaymentHistoryKey = 'pdf_include_payment_history';
  static const String _dateFormatKey = 'pdf_date_format';
  static const String _currencySymbolKey = 'pdf_currency_symbol';
  static const String _fontSizeKey = 'pdf_font_size';
  static const String _paperSizeKey = 'pdf_paper_size';

  ThemeMode _themeMode = ThemeMode.system;
  bool _backupEnabled = false;
  bool _isLoading = true;

  // PDF Settings
  bool _includeLogo = true;
  bool _includeTerms = true;
  bool _includeDisclaimer = true;
  bool _includePaymentHistory = true;
  String _dateFormat = 'DD/MM/YYYY';
  String _currencySymbol = '\$';
  double _fontSize = 10.0;
  String _paperSize = 'A4';

  ThemeMode get themeMode => _themeMode;
  bool get backupEnabled => _backupEnabled;
  bool get isLoading => _isLoading;

  // PDF Settings getters
  bool get includeLogo => _includeLogo;
  bool get includeTerms => _includeTerms;
  bool get includeDisclaimer => _includeDisclaimer;
  bool get includePaymentHistory => _includePaymentHistory;
  String get dateFormat => _dateFormat;
  String get currencySymbol => _currencySymbol;
  double get fontSize => _fontSize;
  String get paperSize => _paperSize;

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

      // Load PDF settings
      _includeLogo = prefs.getBool(_includeLogoKey) ?? true;
      _includeTerms = prefs.getBool(_includeTermsKey) ?? true;
      _includeDisclaimer = prefs.getBool(_includeDisclaimerKey) ?? true;
      _includePaymentHistory = prefs.getBool(_includePaymentHistoryKey) ?? true;
      _dateFormat = prefs.getString(_dateFormatKey) ?? 'DD/MM/YYYY';
      _currencySymbol = prefs.getString(_currencySymbolKey) ?? '\$';
      _fontSize = prefs.getDouble(_fontSizeKey) ?? 10.0;
      _paperSize = prefs.getString(_paperSizeKey) ?? 'A4';
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

  // PDF Settings setters
  Future<void> setIncludeLogo(bool value) async {
    if (_includeLogo == value) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_includeLogoKey, value);
      _includeLogo = value;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving include logo setting: $e');
    }
  }

  Future<void> setIncludeTerms(bool value) async {
    if (_includeTerms == value) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_includeTermsKey, value);
      _includeTerms = value;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving include terms setting: $e');
    }
  }

  Future<void> setIncludeDisclaimer(bool value) async {
    if (_includeDisclaimer == value) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_includeDisclaimerKey, value);
      _includeDisclaimer = value;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving include disclaimer setting: $e');
    }
  }

  Future<void> setIncludePaymentHistory(bool value) async {
    if (_includePaymentHistory == value) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_includePaymentHistoryKey, value);
      _includePaymentHistory = value;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving include payment history setting: $e');
    }
  }

  Future<void> setDateFormat(String value) async {
    if (_dateFormat == value) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dateFormatKey, value);
      _dateFormat = value;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving date format setting: $e');
    }
  }

  Future<void> setCurrencySymbol(String value) async {
    if (_currencySymbol == value) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencySymbolKey, value);
      _currencySymbol = value;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving currency symbol setting: $e');
    }
  }

  Future<void> setFontSize(double value) async {
    if (_fontSize == value) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, value);
      _fontSize = value;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving font size setting: $e');
    }
  }

  Future<void> setPaperSize(String value) async {
    if (_paperSize == value) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_paperSizeKey, value);
      _paperSize = value;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving paper size setting: $e');
    }
  }
}