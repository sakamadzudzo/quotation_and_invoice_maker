import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quotation_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/company_provider.dart';
import '../providers/client_provider.dart';
import '../utils/dashboard_utils.dart';
import '../widgets/advanced_search_filter.dart';
import '../services/search_service.dart';
import '../core/di/service_locator.dart';
import 'quotation_form_screen.dart';
import 'invoice_form_screen.dart';
import 'payment_screen.dart';
import 'quotation_details_screen.dart';
import 'invoice_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SortOption _currentSort = SortOption.dateCreated;
  bool _ascending = false;
  SearchFilters _quotationFilters = const SearchFilters();
  SearchFilters _invoiceFilters = const SearchFilters();
  SearchStatistics? _searchStatistics;
  final SearchService _searchService = ServiceLocator.searchService;

  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuotationProvider>().loadQuotations();
      context.read<InvoiceProvider>().loadInvoices();
      context.read<CompanyProvider>().loadCompanies();
      context.read<ClientProvider>().loadClients();
      _loadSearchStatistics();
    });
  }

  Future<void> _loadSearchStatistics() async {
    final quotationProvider = context.read<QuotationProvider>();
    final invoiceProvider = context.read<InvoiceProvider>();
    final clientProvider = context.read<ClientProvider>();
    final companyProvider = context.read<CompanyProvider>();

    final statistics = await _searchService.getFilterStatistics(
      quotations: quotationProvider.quotations,
      invoices: invoiceProvider.invoices,
      clients: clientProvider.clients,
      companies: companyProvider.companies,
    );

    if (mounted) {
      setState(() {
        _searchStatistics = statistics;
      });
    }
  }

  void _onQuotationFiltersChanged(SearchFilters filters) {
    setState(() {
      _quotationFilters = filters;
    });
  }

  void _onInvoiceFiltersChanged(SearchFilters filters) {
    setState(() {
      _invoiceFilters = filters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quotation & Invoice Maker'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Quotations'),
              Tab(text: 'Invoices'),
            ],
          ),
          actions: [
            PopupMenuButton<SortOption>(
              icon: const Icon(Icons.sort),
              onSelected: (SortOption option) {
                setState(() {
                  if (_currentSort == option) {
                    _ascending = !_ascending;
                  } else {
                    _currentSort = option;
                    _ascending = false;
                  }
                });
              },
              itemBuilder: (BuildContext context) => SortOption.values
                  .map((option) => PopupMenuItem(
                        value: option,
                        child: Text(option.displayName),
                      ))
                  .toList(),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: [
                    QuotationsTab(
                      sortOption: _currentSort,
                      ascending: _ascending,
                      filters: _quotationFilters,
                      onFiltersChanged: _onQuotationFiltersChanged,
                      searchStatistics: _searchStatistics,
                    ),
                    InvoicesTab(
                      sortOption: _currentSort,
                      ascending: _ascending,
                      filters: _invoiceFilters,
                      onFiltersChanged: _onInvoiceFiltersChanged,
                      searchStatistics: _searchStatistics,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateOptions(context),
          icon: const Icon(Icons.add),
          label: const Text('Create'),
        ),
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Create Quotation'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuotationFormScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Create Invoice'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InvoiceFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  void _showQuotationActions(BuildContext context, quotation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('View Details'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to quotation details
            },
          ),
          if (quotation.status == 'draft')
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Advance to Active'),
              onTap: () {
                Navigator.pop(context);
                _advanceQuotationToActive(context, quotation);
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to edit quotation
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(context);
              _deleteQuotation(context, quotation);
            },
          ),
        ],
      ),
    );
  }

  void _advanceQuotationToActive(BuildContext context, quotation) async {
    final updatedQuotation = quotation.copyWith(status: 'active');
    final success = await context.read<QuotationProvider>().updateQuotation(updatedQuotation);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation advanced to active status')),
      );
    }
  }

  void _deleteQuotation(BuildContext context, quotation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quotation'),
        content: const Text('Are you sure you want to delete this quotation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<QuotationProvider>().deleteQuotation(quotation.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation deleted')),
        );
      }
    }
  }
}

class QuotationsTab extends StatelessWidget {
  final SortOption sortOption;
  final bool ascending;
  final SearchFilters filters;
  final Function(SearchFilters) onFiltersChanged;
  final SearchStatistics? searchStatistics;

  const QuotationsTab({
    super.key,
    required this.sortOption,
    required this.ascending,
    required this.filters,
    required this.onFiltersChanged,
    this.searchStatistics,
  });

  void _showQuotationActions(BuildContext context, quotation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('View Details'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuotationDetailsScreen(quotation: quotation),
                ),
              );
            },
          ),
          if (quotation.status == 'draft')
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Advance to Active'),
              onTap: () {
                Navigator.pop(context);
                _advanceQuotationToActive(context, quotation);
              },
            ),
          if (quotation.status == 'active')
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Convert to Invoice'),
              onTap: () {
                Navigator.pop(context);
                _convertToInvoice(context, quotation);
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuotationFormScreen(quotation: quotation),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(context);
              _deleteQuotation(context, quotation);
            },
          ),
        ],
      ),
    );
  }

  void _advanceQuotationToActive(BuildContext context, quotation) async {
    final updatedQuotation = quotation.copyWith(status: 'active');
    final success = await context.read<QuotationProvider>().updateQuotation(updatedQuotation);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation advanced to active status')),
      );
    }
  }

  void _deleteQuotation(BuildContext context, quotation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quotation'),
        content: const Text('Are you sure you want to delete this quotation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<QuotationProvider>().deleteQuotation(quotation.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation deleted')),
        );
      }
    }
  }

  void _convertToInvoice(BuildContext context, quotation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceFormScreen(quotation: quotation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<QuotationProvider, ClientProvider, CompanyProvider, InvoiceProvider>(
      builder: (context, quotationProvider, clientProvider, companyProvider, invoiceProvider, child) {
        if (quotationProvider.isLoading || clientProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          child: Column(
            children: [
              AdvancedSearchFilter(
                onFiltersChanged: onFiltersChanged,
                searchStatistics: searchStatistics,
                availableClients: clientProvider.clients,
                availableCompanies: companyProvider.companies,
                showDocumentTypeToggle: false,
                initialDocumentType: 'quotations',
              ),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: ServiceLocator.searchService.searchQuotations(
                    query: filters.query,
                    dateFrom: filters.dateFrom,
                    dateTo: filters.dateTo,
                    status: filters.status,
                    clientId: filters.clientId,
                    companyId: filters.companyId,
                    minAmount: filters.minAmount,
                    maxAmount: filters.maxAmount,
                    sortBy: filters.sortBy,
                    sortOrder: filters.sortOrder,
                    quotations: quotationProvider.quotations,
                    clients: clientProvider.clients,
                    companies: companyProvider.companies,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final filteredQuotations = snapshot.data ?? [];

                    if (filteredQuotations.isEmpty) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              filters.hasActiveFilters ? 'No quotations match your filters' : 'No quotations yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              filters.hasActiveFilters
                                  ? 'Try adjusting your search criteria'
                                  : 'Tap the + button to create your first quotation',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredQuotations.length,
                      itemBuilder: (context, index) {
                        final quotation = filteredQuotations[index];
                        final client = clientProvider.getClientById(quotation.clientId);
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text('Quotation #${quotation.id}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Client: ${client?.name ?? 'Unknown'}'),
                                Text('Total: \$${quotation.totalAmount.toStringAsFixed(2)}'),
                                Text('Created: ${DashboardUtils.formatDate(quotation.createdAt)}'),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(quotation.status.replaceAll('_', ' ').toUpperCase()),
                              backgroundColor: DashboardUtils.getStatusColor(quotation.status),
                            ),
                            onTap: () => _convertToInvoice(context, quotation),
                            onLongPress: () => _showQuotationActions(context, quotation),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

class InvoicesTab extends StatelessWidget {
  final SortOption sortOption;
  final bool ascending;
  final SearchFilters filters;
  final Function(SearchFilters) onFiltersChanged;
  final SearchStatistics? searchStatistics;

  const InvoicesTab({
    super.key,
    required this.sortOption,
    required this.ascending,
    required this.filters,
    required this.onFiltersChanged,
    this.searchStatistics,
  });

  void _showInvoiceActions(BuildContext context, invoice) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('View Details'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InvoiceDetailsScreen(invoice: invoice),
                ),
              );
            },
          ),
          if (invoice.status != 'paid')
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Add Payment'),
              onTap: () {
                Navigator.pop(context);
                _addPayment(context, invoice);
              },
            ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('View Payments'),
            onTap: () {
              Navigator.pop(context);
              _viewPayments(context, invoice);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Invoice'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InvoiceFormScreen(invoice: invoice),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _addPayment(BuildContext context, invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(invoice: invoice),
      ),
    );
  }

  void _viewPayments(BuildContext context, invoice) async {
    final payments = await context.read<InvoiceProvider>().getPaymentsByInvoice(invoice.id);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Payments for Invoice #${invoice.id}'),
          content: SizedBox(
            width: double.maxFinite,
            child: payments.isEmpty
                ? const Text('No payments recorded yet.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return ListTile(
                        title: Text('\$${payment.amount.toStringAsFixed(2)}'),
                        subtitle: Text(
                          'Date: ${DashboardUtils.formatDate(payment.paymentDate)}\n'
                          '${payment.notes?.isNotEmpty == true ? 'Notes: ${payment.notes}' : ''}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePayment(context, payment, invoice.id),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _deletePayment(BuildContext context, payment, int invoiceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<InvoiceProvider>().deletePayment(payment.id, invoiceId);
      if (success && context.mounted) {
        Navigator.pop(context); // Close payments dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<InvoiceProvider, ClientProvider, CompanyProvider, QuotationProvider>(
      builder: (context, invoiceProvider, clientProvider, companyProvider, quotationProvider, child) {
        if (invoiceProvider.isLoading || clientProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          child: Column(
            children: [
              AdvancedSearchFilter(
                onFiltersChanged: onFiltersChanged,
                searchStatistics: searchStatistics,
                availableClients: clientProvider.clients,
                availableCompanies: companyProvider.companies,
                showDocumentTypeToggle: false,
                initialDocumentType: 'invoices',
              ),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: ServiceLocator.searchService.searchInvoices(
                    query: filters.query,
                    dateFrom: filters.dateFrom,
                    dateTo: filters.dateTo,
                    status: filters.status,
                    clientId: filters.clientId,
                    companyId: filters.companyId,
                    minAmount: filters.minAmount,
                    maxAmount: filters.maxAmount,
                    sortBy: filters.sortBy,
                    sortOrder: filters.sortOrder,
                    invoices: invoiceProvider.invoices,
                    clients: clientProvider.clients,
                    companies: companyProvider.companies,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final filteredInvoices = snapshot.data ?? [];

                    if (filteredInvoices.isEmpty) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              filters.hasActiveFilters ? 'No invoices match your filters' : 'No invoices yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              filters.hasActiveFilters
                                  ? 'Try adjusting your search criteria'
                                  : 'Convert quotations to invoices or create directly',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredInvoices.length,
                      itemBuilder: (context, index) {
                        final invoice = filteredInvoices[index];
                        final client = clientProvider.getClientById(invoice.clientId);
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text('Invoice #${invoice.id}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Client: ${client?.name ?? 'Unknown'}'),
                                Text('Total: \$${invoice.totalAmount.toStringAsFixed(2)}'),
                                Text('Created: ${DashboardUtils.formatDate(invoice.createdAt)}'),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(invoice.status.replaceAll('_', ' ').toUpperCase()),
                              backgroundColor: DashboardUtils.getStatusColor(invoice.status),
                            ),
                            onTap: () {
                              if (invoice.status == 'paid') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invoice is fully paid')),
                                );
                              } else {
                                _addPayment(context, invoice);
                              }
                            },
                            onLongPress: () => _showInvoiceActions(context, invoice),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
