/// Input validation and sanitization utilities.
///
/// This file provides comprehensive validation and sanitization functions
/// for user input across the application. It includes text formatters,
/// validation functions, and sanitization utilities to ensure data integrity
/// and security.
///
/// Key Features:
/// - Text input formatters for consistent data entry
/// - Email and phone validation
/// - Numeric and currency validation
/// - Input sanitization to prevent malicious input
/// - Business-specific validation rules
///
/// Usage:
/// ```dart
/// // Validate email
/// String? error = validateEmail('user@example.com');
///
/// // Sanitize input
/// String clean = sanitizeInput(dirtyInput);
///
/// // Use formatters
/// TextField(
///   inputFormatters: [CapitalizeTextFormatter()],
/// )
/// ```
library;

import 'package:flutter/services.dart';

class CapitalizeTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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

    return newValue.copyWith(text: newText, selection: newValue.selection);
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Capitalize first letter
    String newText = newValue.text.toUpperCase();

    return newValue.copyWith(text: newText, selection: newValue.selection);
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

/// Validates a required text field
String? validateRequired(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

/// Validates text length
String? validateLength(String? value, int minLength, int maxLength, String fieldName) {
  if (value == null || value.isEmpty) return null;

  if (value.length < minLength) {
    return '$fieldName must be at least $minLength characters';
  }
  if (value.length > maxLength) {
    return '$fieldName must be no more than $maxLength characters';
  }
  return null;
}

/// Validates numeric input
String? validateNumeric(String? value, String fieldName) {
  if (value == null || value.isEmpty) return null;

  final number = double.tryParse(value);
  if (number == null) {
    return '$fieldName must be a valid number';
  }
  return null;
}

/// Validates positive numbers
String? validatePositiveNumber(String? value, String fieldName) {
  if (value == null || value.isEmpty) return null;

  final number = double.tryParse(value);
  if (number == null) {
    return '$fieldName must be a valid number';
  }
  if (number <= 0) {
    return '$fieldName must be greater than 0';
  }
  return null;
}

/// Validates currency format
String? validateCurrency(String? value) {
  if (value == null || value.isEmpty) return null;

  // Remove currency symbols and spaces for validation
  final cleanValue = value.replaceAll(RegExp(r'[^\d.,]'), '');
  final number = double.tryParse(cleanValue.replaceAll(',', '.'));
  if (number == null) {
    return 'Invalid currency format';
  }
  return null;
}

/// Validates company name (no special characters that could cause issues)
String? validateCompanyName(String? value) {
  if (value == null || value.isEmpty) return null;

  // Allow letters, numbers, spaces, hyphens, apostrophes, and periods
  final companyRegex = RegExp(r"^[a-zA-Z0-9\s\-'.&]+$");
  if (!companyRegex.hasMatch(value)) {
    return 'Company name contains invalid characters';
  }
  return null;
}

/// Validates address format
String? validateAddress(String? value) {
  if (value == null || value.isEmpty) return null;

  if (value.length < 5) {
    return 'Address is too short';
  }
  if (value.length > 200) {
    return 'Address is too long';
  }
  return null;
}

/// Sanitizes input by removing potentially dangerous characters
String sanitizeInput(String input) {
  if (input.isEmpty) return input;

  // Remove null bytes and other control characters
  var sanitized = input.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '');

  // Trim whitespace
  sanitized = sanitized.trim();

  // Remove excessive whitespace
  sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

  return sanitized;
}

/// Sanitizes HTML by removing tags (basic protection)
String sanitizeHtml(String input) {
  if (input.isEmpty) return input;

  // Remove HTML tags
  return input.replaceAll(RegExp(r'<[^>]*>'), '');
}

/// Validates and sanitizes user input for database storage
String? validateAndSanitizeInput(String? input, {
  bool required = false,
  int? minLength,
  int? maxLength,
  String? fieldName = 'Field',
  bool allowHtml = false,
}) {
  if (input == null || input.isEmpty) {
    return required ? '$fieldName is required' : null;
  }

  // Sanitize input
  var sanitized = allowHtml ? input : sanitizeHtml(input);
  sanitized = sanitizeInput(sanitized);

  // Validate length
  if (minLength != null && sanitized.length < minLength) {
    return '$fieldName must be at least $minLength characters';
  }
  if (maxLength != null && sanitized.length > maxLength) {
    return '$fieldName must be no more than $maxLength characters';
  }

  return null;
}

/// Text formatter that only allows numeric input
class NumericTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Allow only numbers and decimal point
    final numericRegex = RegExp(r'^[0-9]*\.?[0-9]*$');
    if (numericRegex.hasMatch(newValue.text)) {
      return newValue;
    }

    return oldValue;
  }
}

/// Text formatter that limits length
class LengthLimitingFormatter extends TextInputFormatter {
  final int maxLength;

  LengthLimitingFormatter(this.maxLength);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length <= maxLength) {
      return newValue;
    }
    return oldValue;
  }
}
