/// Advanced search and filtering widget for quotations and invoices.
///
/// This widget provides a comprehensive search interface with multiple filter
/// options including text search, date ranges, status filters, and sorting.
/// It integrates with the SearchService to provide real-time filtering.
///
/// Features:
/// - Text search with autocomplete suggestions
/// - Date range picker
/// - Status filtering
/// - Amount range filtering
/// - Client/company filtering
/// - Sorting options
/// - Filter statistics display
///
/// Example usage:
/// ```dart
/// AdvancedSearchFilter(
///   onFiltersChanged: (filters) => applyFilters(filters),
///   searchStatistics: statistics,
///   availableClients: clients,
///   availableCompanies: companies,
/// )
/// ```
library;

import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/company.dart';
import '../services/search_service.dart';

/// Filter configuration for search operations.
class SearchFilters {
  final String? query;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? status;
  final int? clientId;
  final int? companyId;
  final double? minAmount;
  final double? maxAmount;
  final String sortBy;
  final String sortOrder;

  const SearchFilters({
    this.query,
    this.dateFrom,
    this.dateTo,
    this.status,
    this.clientId,
    this.companyId,
    this.minAmount,
    this.maxAmount,
    this.sortBy = 'date',
    this.sortOrder = 'desc',
  });

  SearchFilters copyWith({
    String? query,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
    int? clientId,
    int? companyId,
    double? minAmount,
    double? maxAmount,
    String? sortBy,
    String? sortOrder,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      status: status ?? this.status,
      clientId: clientId ?? this.clientId,
      companyId: companyId ?? this.companyId,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  bool get hasActiveFilters =>
      query != null && query!.isNotEmpty ||
      dateFrom != null ||
      dateTo != null ||
      status != null ||
      clientId != null ||
      companyId != null ||
      minAmount != null ||
      maxAmount != null;

  void clear() {
    // This method would be used to reset filters
  }
}

class AdvancedSearchFilter extends StatefulWidget {
  final Function(SearchFilters) onFiltersChanged;
  final SearchStatistics? searchStatistics;
  final List<Client> availableClients;
  final List<Company> availableCompanies;
  final bool showDocumentTypeToggle;
  final String initialDocumentType;

  const AdvancedSearchFilter({
    super.key,
    required this.onFiltersChanged,
    this.searchStatistics,
    this.availableClients = const [],
    this.availableCompanies = const [],
    this.showDocumentTypeToggle = true,
    this.initialDocumentType = 'quotations',
  });

  @override
  State<AdvancedSearchFilter> createState() => _AdvancedSearchFilterState();
}

class _AdvancedSearchFilterState extends State<AdvancedSearchFilter> {
  late SearchFilters _filters;
  late String _documentType;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _showAdvancedFilters = false;
  List<String> _searchSuggestions = [];

  @override
  void initState() {
    super.initState();
    _filters = const SearchFilters();
    _documentType = widget.initialDocumentType;
    _loadSearchSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSearchSuggestions() async {
    // This would typically load from SearchService
    // For now, we'll create basic suggestions
    final suggestions = <String>{};

    for (final client in widget.availableClients) {
      if (client.name.length > 2) {
        suggestions.add(client.name);
      }
    }

    for (final company in widget.availableCompanies) {
      if (company.name.length > 2) {
        suggestions.add(company.name);
      }
    }

    setState(() {
      _searchSuggestions = suggestions.toList()..sort();
    });
  }

  void _updateFilters(SearchFilters newFilters) {
    setState(() {
      _filters = newFilters;
    });
    widget.onFiltersChanged(newFilters);
  }

  void _clearFilters() {
    final clearedFilters = const SearchFilters();
    _searchController.clear();
    _updateFilters(clearedFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            if (_showAdvancedFilters) ...[
              const SizedBox(height: 16),
              _buildAdvancedFilters(),
            ],
            if (widget.searchStatistics != null) ...[
              const SizedBox(height: 16),
              _buildStatistics(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'Search & Filter',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (widget.showDocumentTypeToggle) ...[
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'quotations', label: Text('Quotations')),
              ButtonSegment(value: 'invoices', label: Text('Invoices')),
            ],
            selected: {_documentType},
            onSelectionChanged: (selection) {
              setState(() {
                _documentType = selection.first;
              });
              // Trigger filter update with document type change
              widget.onFiltersChanged(_filters);
            },
          ),
          const SizedBox(width: 16),
        ],
        TextButton.icon(
          onPressed: () => setState(() => _showAdvancedFilters = !_showAdvancedFilters),
          icon: Icon(_showAdvancedFilters ? Icons.expand_less : Icons.expand_more),
          label: Text(_showAdvancedFilters ? 'Less Filters' : 'More Filters'),
        ),
        if (_filters.hasActiveFilters) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _searchSuggestions.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        _searchController.text = selection;
        _updateFilters(_filters.copyWith(query: selection));
      },
      fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
        return TextField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            hintText: 'Search by client, company, or product name...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _updateFilters(_filters.copyWith(query: null));
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            _updateFilters(_filters.copyWith(query: value.isEmpty ? null : value));
          },
        );
      },
    );
  }

  Widget _buildAdvancedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Advanced Filters',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDateRangePicker(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatusDropdown(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildClientDropdown(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCompanyDropdown(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAmountRange(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSortingOptions(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _filters.dateFrom ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    _updateFilters(_filters.copyWith(dateFrom: date));
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'From',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _filters.dateFrom != null
                        ? '${_filters.dateFrom!.day}/${_filters.dateFrom!.month}/${_filters.dateFrom!.year}'
                        : 'Select date',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _filters.dateTo ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    _updateFilters(_filters.copyWith(dateTo: date));
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'To',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _filters.dateTo != null
                        ? '${_filters.dateTo!.day}/${_filters.dateTo!.month}/${_filters.dateTo!.year}'
                        : 'Select date',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    final statusOptions = _documentType == 'quotations'
        ? ['draft', 'active', 'archived']
        : ['unpaid', 'partially_paid', 'paid'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          value: _filters.status,
          hint: const Text('All statuses'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All statuses')),
            ...statusOptions.map((status) => DropdownMenuItem(
              value: status,
              child: Text(status.replaceAll('_', ' ').toUpperCase()),
            )),
          ],
          onChanged: (value) => _updateFilters(_filters.copyWith(status: value)),
        ),
      ],
    );
  }

  Widget _buildClientDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Client', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          value: _filters.clientId,
          hint: const Text('All clients'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All clients')),
            ...widget.availableClients.map((client) => DropdownMenuItem(
              value: client.id,
              child: Text(client.name),
            )),
          ],
          onChanged: (value) => _updateFilters(_filters.copyWith(clientId: value)),
        ),
      ],
    );
  }

  Widget _buildCompanyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Company', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          value: _filters.companyId,
          hint: const Text('All companies'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All companies')),
            ...widget.availableCompanies.map((company) => DropdownMenuItem(
              value: company.id,
              child: Text(company.name),
            )),
          ],
          onChanged: (value) => _updateFilters(_filters.copyWith(companyId: value)),
        ),
      ],
    );
  }

  Widget _buildAmountRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Amount Range', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _filters.minAmount?.toString(),
                decoration: const InputDecoration(
                  labelText: 'Min',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  _updateFilters(_filters.copyWith(minAmount: amount));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: _filters.maxAmount?.toString(),
                decoration: const InputDecoration(
                  labelText: 'Max',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  _updateFilters(_filters.copyWith(maxAmount: amount));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                value: _filters.sortBy,
                items: const [
                  DropdownMenuItem(value: 'date', child: Text('Date')),
                  DropdownMenuItem(value: 'amount', child: Text('Amount')),
                  DropdownMenuItem(value: 'client', child: Text('Client')),
                  DropdownMenuItem(value: 'status', child: Text('Status')),
                ],
                onChanged: (value) => _updateFilters(_filters.copyWith(sortBy: value)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                final newOrder = _filters.sortOrder == 'asc' ? 'desc' : 'asc';
                _updateFilters(_filters.copyWith(sortOrder: newOrder));
              },
              icon: Icon(
                _filters.sortOrder == 'asc'
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
              ),
              tooltip: _filters.sortOrder == 'asc' ? 'Sort Descending' : 'Sort Ascending',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    final stats = widget.searchStatistics;
    if (stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatChip('Total', '${stats.totalDocuments}'),
              const SizedBox(width: 8),
              if (_documentType == 'quotations')
                ...stats.quotationStatusCounts.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildStatChip(
                      entry.key.replaceAll('_', ' ').toUpperCase(),
                      '${entry.value}',
                    ),
                  ),
                )
              else
                ...stats.invoiceStatusCounts.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildStatChip(
                      entry.key.replaceAll('_', ' ').toUpperCase(),
                      '${entry.value}',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.blue.withOpacity(0.2),
      labelStyle: const TextStyle(fontSize: 12),
    );
  }
}