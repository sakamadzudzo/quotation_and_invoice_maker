/// Advanced search and filtering service for quotations and invoices.
///
/// This service provides comprehensive search capabilities across all business
/// documents, supporting text search, date filtering, status filtering, and
/// multi-criteria queries.
///
/// Features:
/// - Full-text search across document content
/// - Date range filtering
/// - Status-based filtering
/// - Client and company filtering
/// - Amount range filtering
/// - Sorting and pagination
///
/// Example usage:
/// ```dart
/// final searchService = SearchService();
/// final results = await searchService.searchQuotations(
///   query: 'laptop',
///   dateFrom: DateTime(2024, 1, 1),
///   status: QuotationStatus.sent,
/// );
/// ```
library;

import '../models/quotation.dart';
import '../models/invoice.dart';
import '../models/client.dart';
import '../models/company.dart';
import '../core/logging/i_logger.dart';

class SearchService {
  final ILogger _logger;

  SearchService(this._logger);

  /// Search quotations with advanced filtering options.
  ///
  /// [query] - Text to search in quotation content (product names, descriptions, client names)
  /// [dateFrom] - Start date for filtering
  /// [dateTo] - End date for filtering
  /// [status] - Filter by quotation status
  /// [clientId] - Filter by specific client
  /// [companyId] - Filter by specific company
  /// [minAmount] - Minimum total amount
  /// [maxAmount] - Maximum total amount
  /// [sortBy] - Sort field ('date', 'amount', 'client', 'status')
  /// [sortOrder] - Sort order ('asc', 'desc')
  Future<List<Quotation>> searchQuotations({
    String? query,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
    int? clientId,
    int? companyId,
    double? minAmount,
    double? maxAmount,
    String sortBy = 'date',
    String sortOrder = 'desc',
    List<Quotation> quotations = const [],
    List<Client> clients = const [],
    List<Company> companies = const [],
  }) async {
    try {
      _logger.info('Searching quotations with filters: query=$query, status=$status');

      var filteredQuotations = quotations;

      // Apply text search
      if (query != null && query.isNotEmpty) {
        final searchTerm = query.toLowerCase();
        filteredQuotations = filteredQuotations.where((quotation) {
          // Search in quotation items
          final itemMatch = quotation.items.any((item) =>
            item.productName.toLowerCase().contains(searchTerm) ||
            item.description.toLowerCase().contains(searchTerm)
          );

          // Search in client name
          final client = clients.where((c) => c.id == quotation.clientId).firstOrNull;
          final clientMatch = client?.name.toLowerCase().contains(searchTerm) ?? false;

          // Search in company name
          final company = companies.where((c) => c.id == quotation.companyId).firstOrNull;
          final companyMatch = company?.name.toLowerCase().contains(searchTerm) ?? false;

          return itemMatch || clientMatch || companyMatch;
        }).toList();
      }

      // Apply date filtering
      if (dateFrom != null) {
        filteredQuotations = filteredQuotations
            .where((q) => q.createdAt.isAfter(dateFrom.subtract(const Duration(days: 1))))
            .toList();
      }
      if (dateTo != null) {
        filteredQuotations = filteredQuotations
            .where((q) => q.createdAt.isBefore(dateTo.add(const Duration(days: 1))))
            .toList();
      }

      // Apply status filtering
      if (status != null) {
        filteredQuotations = filteredQuotations
            .where((q) => q.status == status)
            .toList();
      }

      // Apply client filtering
      if (clientId != null) {
        filteredQuotations = filteredQuotations
            .where((q) => q.clientId == clientId)
            .toList();
      }

      // Apply company filtering
      if (companyId != null) {
        filteredQuotations = filteredQuotations
            .where((q) => q.companyId == companyId)
            .toList();
      }

      // Apply amount filtering
      if (minAmount != null) {
        filteredQuotations = filteredQuotations
            .where((q) => q.totalAmount >= minAmount)
            .toList();
      }
      if (maxAmount != null) {
        filteredQuotations = filteredQuotations
            .where((q) => q.totalAmount <= maxAmount)
            .toList();
      }

      // Apply sorting
      filteredQuotations.sort((a, b) {
        int comparison = 0;

        switch (sortBy) {
          case 'date':
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
          case 'amount':
            comparison = a.totalAmount.compareTo(b.totalAmount);
            break;
          case 'client':
            final clientA = clients.where((c) => c.id == a.clientId).firstOrNull?.name ?? '';
            final clientB = clients.where((c) => c.id == b.clientId).firstOrNull?.name ?? '';
            comparison = clientA.compareTo(clientB);
            break;
          case 'status':
            comparison = a.status.toString().compareTo(b.status.toString());
            break;
          default:
            comparison = a.createdAt.compareTo(b.createdAt);
        }

        return sortOrder == 'asc' ? comparison : -comparison;
      });

      _logger.info('Found ${filteredQuotations.length} quotations matching search criteria');
      return filteredQuotations;
    } catch (e, stackTrace) {
      _logger.error('Error searching quotations', e, stackTrace);
      rethrow;
    }
  }

  /// Search invoices with advanced filtering options.
  ///
  /// Similar to searchQuotations but for invoices, with additional payment status filtering.
  Future<List<Invoice>> searchInvoices({
    String? query,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
    int? clientId,
    int? companyId,
    double? minAmount,
    double? maxAmount,
    PaymentStatus? paymentStatus,
    String sortBy = 'date',
    String sortOrder = 'desc',
    List<Invoice> invoices = const [],
    List<Client> clients = const [],
    List<Company> companies = const [],
  }) async {
    try {
      _logger.info('Searching invoices with filters: query=$query, status=$status, paymentStatus=$paymentStatus');

      var filteredInvoices = invoices;

      // Apply text search
      if (query != null && query.isNotEmpty) {
        final searchTerm = query.toLowerCase();
        filteredInvoices = filteredInvoices.where((invoice) {
          // Search in invoice items
          final itemMatch = invoice.items.any((item) =>
            item.productName.toLowerCase().contains(searchTerm) ||
            item.description.toLowerCase().contains(searchTerm)
          );

          // Search in client name
          final client = clients.where((c) => c.id == invoice.clientId).firstOrNull;
          final clientMatch = client?.name.toLowerCase().contains(searchTerm) ?? false;

          // Search in company name
          final company = companies.where((c) => c.id == invoice.companyId).firstOrNull;
          final companyMatch = company?.name.toLowerCase().contains(searchTerm) ?? false;

          return itemMatch || clientMatch || companyMatch;
        }).toList();
      }

      // Apply date filtering
      if (dateFrom != null) {
        filteredInvoices = filteredInvoices
            .where((i) => i.createdAt.isAfter(dateFrom.subtract(const Duration(days: 1))))
            .toList();
      }
      if (dateTo != null) {
        filteredInvoices = filteredInvoices
            .where((i) => i.createdAt.isBefore(dateTo.add(const Duration(days: 1))))
            .toList();
      }

      // Apply status filtering
      if (status != null) {
        filteredInvoices = filteredInvoices
            .where((i) => i.status == status)
            .toList();
      }

      // Apply client filtering
      if (clientId != null) {
        filteredInvoices = filteredInvoices
            .where((i) => i.clientId == clientId)
            .toList();
      }

      // Apply company filtering
      if (companyId != null) {
        filteredInvoices = filteredInvoices
            .where((i) => i.companyId == companyId)
            .toList();
      }

      // Apply amount filtering
      if (minAmount != null) {
        filteredInvoices = filteredInvoices
            .where((i) => i.totalAmount >= minAmount)
            .toList();
      }
      if (maxAmount != null) {
        filteredInvoices = filteredInvoices
            .where((i) => i.totalAmount <= maxAmount)
            .toList();
      }

      // Apply payment status filtering
      if (paymentStatus != null) {
        filteredInvoices = filteredInvoices.where((invoice) {
          // This would need to be calculated based on payments
          // For now, return all invoices (implement payment status logic)
          return true;
        }).toList();
      }

      // Apply sorting
      filteredInvoices.sort((a, b) {
        int comparison = 0;

        switch (sortBy) {
          case 'date':
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
          case 'amount':
            comparison = a.totalAmount.compareTo(b.totalAmount);
            break;
          case 'client':
            final clientA = clients.where((c) => c.id == a.clientId).firstOrNull?.name ?? '';
            final clientB = clients.where((c) => c.id == b.clientId).firstOrNull?.name ?? '';
            comparison = clientA.compareTo(clientB);
            break;
          case 'status':
            comparison = a.status.toString().compareTo(b.status.toString());
            break;
          default:
            comparison = a.createdAt.compareTo(b.createdAt);
        }

        return sortOrder == 'asc' ? comparison : -comparison;
      });

      _logger.info('Found ${filteredInvoices.length} invoices matching search criteria');
      return filteredInvoices;
    } catch (e, stackTrace) {
      _logger.error('Error searching invoices', e, stackTrace);
      rethrow;
    }
  }

  /// Get search suggestions based on existing data.
  ///
  /// Returns a list of suggested search terms based on common patterns
  /// in the existing quotations and invoices.
  Future<List<String>> getSearchSuggestions({
    List<Quotation> quotations = const [],
    List<Invoice> invoices = const [],
    List<Client> clients = const [],
    List<Company> companies = const [],
  }) async {
    try {
      final suggestions = <String>{};

      // Add client names
      for (final client in clients) {
        if (client.name.length > 2) {
          suggestions.add(client.name);
        }
      }

      // Add company names
      for (final company in companies) {
        if (company.name.length > 2) {
          suggestions.add(company.name);
        }
      }

      // Add product names from quotations
      for (final quotation in quotations) {
        for (final item in quotation.items) {
          if (item.productName.length > 2) {
            suggestions.add(item.productName);
          }
        }
      }

      // Add product names from invoices
      for (final invoice in invoices) {
        for (final item in invoice.items) {
          if (item.productName.length > 2) {
            suggestions.add(item.productName);
          }
        }
      }

      return suggestions.toList()..sort();
    } catch (e, stackTrace) {
      _logger.error('Error getting search suggestions', e, stackTrace);
      return [];
    }
  }

  /// Get filter statistics for the current dataset.
  ///
  /// Returns statistics that can be used to populate filter dropdowns
  /// and show counts for different filter options.
  Future<SearchStatistics> getFilterStatistics({
    List<Quotation> quotations = const [],
    List<Invoice> invoices = const [],
    List<Client> clients = const [],
    List<Company> companies = const [],
  }) async {
    try {
      final quotationStats = <String, int>{};
      final invoiceStats = <String, int>{};
      final clientStats = <int, int>{};
      final companyStats = <int, int>{};

      // Calculate quotation statistics
      for (final quotation in quotations) {
        quotationStats[quotation.status] = (quotationStats[quotation.status] ?? 0) + 1;
        if (quotation.clientId != null) {
          clientStats[quotation.clientId!] = (clientStats[quotation.clientId!] ?? 0) + 1;
        }
        if (quotation.companyId != null) {
          companyStats[quotation.companyId!] = (companyStats[quotation.companyId!] ?? 0) + 1;
        }
      }

      // Calculate invoice statistics
      for (final invoice in invoices) {
        invoiceStats[invoice.status] = (invoiceStats[invoice.status] ?? 0) + 1;
        if (invoice.clientId != null) {
          clientStats[invoice.clientId!] = (clientStats[invoice.clientId!] ?? 0) + 1;
        }
        if (invoice.companyId != null) {
          companyStats[invoice.companyId!] = (companyStats[invoice.companyId!] ?? 0) + 1;
        }
      }

      return SearchStatistics(
        quotationStatusCounts: quotationStats,
        invoiceStatusCounts: invoiceStats,
        clientDocumentCounts: clientStats,
        companyDocumentCounts: companyStats,
        totalQuotations: quotations.length,
        totalInvoices: invoices.length,
      );
    } catch (e, stackTrace) {
      _logger.error('Error calculating filter statistics', e, stackTrace);
      return SearchStatistics.empty();
    }
  }
}

/// Statistics for search filters and data insights.
class SearchStatistics {
  final Map<String, int> quotationStatusCounts;
  final Map<String, int> invoiceStatusCounts;
  final Map<int, int> clientDocumentCounts; // clientId -> count
  final Map<int, int> companyDocumentCounts; // companyId -> count
  final int totalQuotations;
  final int totalInvoices;

  SearchStatistics({
    required this.quotationStatusCounts,
    required this.invoiceStatusCounts,
    required this.clientDocumentCounts,
    required this.companyDocumentCounts,
    required this.totalQuotations,
    required this.totalInvoices,
  });

  factory SearchStatistics.empty() => SearchStatistics(
    quotationStatusCounts: {},
    invoiceStatusCounts: {},
    clientDocumentCounts: {},
    companyDocumentCounts: {},
    totalQuotations: 0,
    totalInvoices: 0,
  );

  int get totalDocuments => totalQuotations + totalInvoices;
}

/// Payment status for filtering invoices.
enum PaymentStatus {
  unpaid,
  partiallyPaid,
  fullyPaid,
  overdue,
}