/// Dashboard utility functions and helpers.
///
/// This file contains shared utilities used across dashboard-related screens
/// and widgets. It provides common functionality for formatting, sorting,
/// and displaying dashboard data.
///
/// Key Features:
/// - Date formatting utilities
/// - Status color mapping
/// - Generic sorting functionality
/// - Extension methods for enums
///
/// Usage:
/// ```dart
/// // Format a date
/// String formatted = DashboardUtils.formatDate(DateTime.now());
///
/// // Get status color
/// Color color = DashboardUtils.getStatusColor('paid');
///
/// // Sort items
/// List<Item> sorted = DashboardUtils.sortItems(...);
/// ```
library;

import 'package:flutter/material.dart';
import '../models/client.dart';

/// Utility functions for dashboard operations
class DashboardUtils {
  /// Formats a DateTime to a readable string
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Returns the appropriate color for a given status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'partially_paid':
        return Colors.orange;
      case 'unpaid':
        return Colors.red;
      case 'active':
        return Colors.blue;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// Sorts a list of items based on the given criteria
  static List<T> sortItems<T extends dynamic>({
    required List<T> items,
    required List<Client> clients,
    required SortOption option,
    required bool ascending,
    required dynamic Function(T) getDateCreated,
    required dynamic Function(T) getDateModified,
    required dynamic Function(T) getClientId,
    required dynamic Function(T) getTotalAmount,
    required dynamic Function(T) getId,
  }) {
    final sorted = [...items];
    sorted.sort((a, b) {
      dynamic aValue, bValue;

      switch (option) {
        case SortOption.dateCreated:
          aValue = getDateCreated(a);
          bValue = getDateCreated(b);
          break;
        case SortOption.dateModified:
          aValue = getDateModified(a);
          bValue = getDateModified(b);
          break;
        case SortOption.clientName:
          final aClient = clients.where((c) => c.id == getClientId(a)).firstOrNull;
          final bClient = clients.where((c) => c.id == getClientId(b)).firstOrNull;
          aValue = aClient?.name ?? '';
          bValue = bClient?.name ?? '';
          break;
        case SortOption.totalValue:
          aValue = getTotalAmount(a);
          bValue = getTotalAmount(b);
          break;
        case SortOption.companyName:
          // For now, sort by ID as company info not directly available
          aValue = getId(a) ?? 0;
          bValue = getId(b) ?? 0;
          break;
      }

      if (ascending) {
        return aValue.compareTo(bValue);
      } else {
        return bValue.compareTo(aValue);
      }
    });
    return sorted;
  }
}

/// Enum for sorting options
enum SortOption {
  dateCreated,
  dateModified,
  clientName,
  companyName,
  totalValue,
}

/// Extension methods for SortOption
extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.dateCreated:
        return 'Sort by Date Created';
      case SortOption.dateModified:
        return 'Sort by Date Modified';
      case SortOption.clientName:
        return 'Sort by Client Name';
      case SortOption.companyName:
        return 'Sort by Company Name';
      case SortOption.totalValue:
        return 'Sort by Total Value';
    }
  }
}