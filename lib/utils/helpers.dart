import 'package:flutter/services.dart';

class CapitalizeTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Capitalize first letter
    String newText = newValue.text;
    if (newText.length == 1) {
      newText = newText.toUpperCase();
    } else {
      // Capitalize after whitespace (space, newline, comma, period, slash)
      final regex = RegExp(r'(\s|^|,|\.|/)([a-z])');
      newText = newText.replaceAllMapped(regex, (match) {
        return '${match.group(1)}${match.group(2)?.toUpperCase()}';
      });
    }

    return newValue.copyWith(
      text: newText,
      selection: newValue.selection,
    );
  }
}

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return null;
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  return emailRegex.hasMatch(value) ? null : 'Invalid email address';
}

String? validatePhone(String? value) {
  if (value == null || value.isEmpty) return null;
  final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{7,}$');
  return phoneRegex.hasMatch(value) ? null : 'Invalid phone number';
}