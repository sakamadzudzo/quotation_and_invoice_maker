import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FormAutoSave<T> extends StatefulWidget {
  final Widget child;
  final String formKey;
  final T? initialData;
  final Duration autoSaveInterval;
  final Future<bool> Function(T data)? onAutoSave;
  final void Function(T? data)? onRestore;

  const FormAutoSave({
    super.key,
    required this.child,
    required this.formKey,
    this.initialData,
    this.autoSaveInterval = const Duration(seconds: 30),
    this.onAutoSave,
    this.onRestore,
  });

  @override
  State<FormAutoSave<T>> createState() => _FormAutoSaveState<T>();
}

class _FormAutoSaveState<T> extends State<FormAutoSave<T>> {
  Timer? _autoSaveTimer;
  T? _currentData;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _currentData = widget.initialData;
    _loadSavedData();
    _startAutoSaveTimer();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('form_${widget.formKey}');

      if (savedData != null) {
        // In a real implementation, you'd deserialize based on T
        // For now, we'll assume T is a simple type or has fromJson
        widget.onRestore?.call(_currentData);
        setState(() => _hasUnsavedChanges = true);
      }
    } catch (e) {
      debugPrint('Error loading saved form data: $e');
    }
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(widget.autoSaveInterval, (timer) {
      if (_hasUnsavedChanges && _currentData != null) {
        _performAutoSave();
      }
    });
  }

  Future<void> _performAutoSave() async {
    if (_currentData == null) return;

    try {
      final shouldSave = await widget.onAutoSave?.call(_currentData!) ?? true;
      if (shouldSave) {
        final prefs = await SharedPreferences.getInstance();
        // In a real implementation, you'd serialize based on T
        // For now, we'll use a simple approach
        await prefs.setString('form_${widget.formKey}', _currentData.toString());
        setState(() => _hasUnsavedChanges = false);
      }
    } catch (e) {
      debugPrint('Error auto-saving form data: $e');
    }
  }

  void updateData(T data) {
    setState(() {
      _currentData = data;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> saveNow() async {
    await _performAutoSave();
  }

  Future<void> clearSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('form_${widget.formKey}');
      setState(() => _hasUnsavedChanges = false);
    } catch (e) {
      debugPrint('Error clearing saved form data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_hasUnsavedChanges)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.save,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Unsaved changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class AutoSaveTextController extends TextEditingController {
  final String fieldKey;
  final Duration saveDelay;

  Timer? _saveTimer;

  AutoSaveTextController({
    super.text,
    required this.fieldKey,
    this.saveDelay = const Duration(seconds: 2),
  });

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  @override
  TextEditingValue get value => super.value;

  @override
  set value(TextEditingValue newValue) {
    super.value = newValue;
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDelay, () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('field_${fieldKey}', text);
      } catch (e) {
        debugPrint('Error saving field: $e');
      }
    });
  }

  Future<String?> loadSavedValue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('field_${fieldKey}');
    } catch (e) {
      debugPrint('Error loading saved field: $e');
      return null;
    }
  }

  Future<void> clearSavedValue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('field_${fieldKey}');
    } catch (e) {
      debugPrint('Error clearing saved field: $e');
    }
  }
}

class FormAutoSaveManager {
  static const String _autoSavePrefix = 'form_autosave_';

  static Future<void> saveFormData(String formId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data);
      await prefs.setString('$_autoSavePrefix$formId', jsonData);
      await prefs.setInt('${_autoSavePrefix}timestamp_$formId', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving form data: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadFormData(String formId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('$_autoSavePrefix$formId');

      if (jsonData != null) {
        return jsonDecode(jsonData) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading form data: $e');
    }
    return null;
  }

  static Future<void> clearFormData(String formId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_autoSavePrefix$formId');
      await prefs.remove('${_autoSavePrefix}timestamp_$formId');
    } catch (e) {
      debugPrint('Error clearing form data: $e');
    }
  }

  static Future<DateTime?> getLastSavedTime(String formId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('${_autoSavePrefix}timestamp_$formId');

      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      debugPrint('Error getting last saved time: $e');
    }
    return null;
  }

  static Future<void> cleanupOldAutoSaves(Duration maxAge) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cutoffTime = DateTime.now().subtract(maxAge);

      for (final key in keys) {
        if (key.startsWith('${_autoSavePrefix}timestamp_')) {
          final timestamp = prefs.getInt(key);
          if (timestamp != null) {
            final saveTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            if (saveTime.isBefore(cutoffTime)) {
              final formId = key.replaceFirst('${_autoSavePrefix}timestamp_', '');
              await clearFormData(formId);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old auto-saves: $e');
    }
  }
}