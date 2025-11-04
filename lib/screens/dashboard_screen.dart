import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quotation_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/company_provider.dart';
import '../providers/client_provider.dart';
import '../models/company.dart';
import '../models/client.dart';
import 'quotation_form_screen.dart';
import 'invoice_form_screen.dart';
import 'payment_screen.dart';
import 'quotation_details_screen.dart';
import 'invoice_details_screen.dart';

enum SortOption {
  dateCreated,
  dateModified,
  clientName,
  companyName,
  totalValue,
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SortOption _currentSort = SortOption.dateCreated;
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuotationProvider>().loadQuotations();
      context.read<InvoiceProvider>().loadInvoices();
      context.read<CompanyProvider>().loadCompanies();
      context.read<ClientProvider>().loadClients();
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
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: SortOption.dateCreated,
                  child: Text('Sort by Date Created'),
                ),
                const PopupMenuItem(
                  value: SortOption.dateModified,
                  child: Text('Sort by Date Modified'),
                ),
                const PopupMenuItem(
                  value: SortOption.clientName,
                  child: Text('Sort by Client Name'),
                ),
                const PopupMenuItem(
                  value: SortOption.companyName,
                  child: Text('Sort by Company Name'),
                ),
                const PopupMenuItem(
                  value: SortOption.totalValue,
                  child: Text('Sort by Total Value'),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            QuotationsTab(sortOption: _currentSort, ascending: _ascending),
            InvoicesTab(sortOption: _currentSort, ascending: _ascending),
          ],
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

  const QuotationsTab({
    super.key,
    required this.sortOption,
    required this.ascending,
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
    return Consumer2<QuotationProvider, ClientProvider>(
      builder: (context, quotationProvider, clientProvider, child) {
        if (quotationProvider.isLoading || clientProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (quotationProvider.quotations.isEmpty) {
          return Center(
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
                  'No quotations yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to create your first quotation',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final sortedQuotations = _sortQuotations(
          quotationProvider.quotations,
          clientProvider.clients,
          sortOption,
          ascending,
        );

        return ListView.builder(
          itemCount: sortedQuotations.length,
          itemBuilder: (context, index) {
            final quotation = sortedQuotations[index];
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
                    Text('Created: ${_formatDate(quotation.createdAt)}'),
                  ],
                ),
                trailing: Chip(
                  label: Text(quotation.status),
                  backgroundColor: _getStatusColor(quotation.status),
                ),
                onTap: () => _convertToInvoice(context, quotation),
                onLongPress: () => _showQuotationActions(context, quotation),
              ),
            );
          },
        );
      },
    );
  }

  List<dynamic> _sortQuotations(
    List quotations,
    List<Client> clients,
    SortOption option,
    bool ascending,
  ) {
    final sorted = [...quotations];
    sorted.sort((a, b) {
      dynamic aValue, bValue;

      switch (option) {
        case SortOption.dateCreated:
          aValue = a.createdAt;
          bValue = b.createdAt;
          break;
        case SortOption.dateModified:
          aValue = a.updatedAt;
          bValue = b.updatedAt;
          break;
        case SortOption.clientName:
          final aClient = clients.where((c) => c.id == a.clientId).firstOrNull;
          final bClient = clients.where((c) => c.id == b.clientId).firstOrNull;
          aValue = aClient?.name ?? '';
          bValue = bClient?.name ?? '';
          break;
        case SortOption.totalValue:
          aValue = a.totalAmount;
          bValue = b.totalAmount;
          break;
        case SortOption.companyName:
          // For now, sort by ID as company info not directly available
          aValue = a.id ?? 0;
          bValue = b.id ?? 0;
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

class InvoicesTab extends StatelessWidget {
  final SortOption sortOption;
  final bool ascending;

  const InvoicesTab({
    super.key,
    required this.sortOption,
    required this.ascending,
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
                          'Date: ${_formatDate(payment.paymentDate)}\n'
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
    return Consumer2<InvoiceProvider, ClientProvider>(
      builder: (context, invoiceProvider, clientProvider, child) {
        if (invoiceProvider.isLoading || clientProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (invoiceProvider.invoices.isEmpty) {
          return Center(
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
                  'No invoices yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Convert quotations to invoices or create directly',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final sortedInvoices = _sortInvoices(
          invoiceProvider.invoices,
          clientProvider.clients,
          sortOption,
          ascending,
        );

        return ListView.builder(
          itemCount: sortedInvoices.length,
          itemBuilder: (context, index) {
            final invoice = sortedInvoices[index];
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
                    Text('Created: ${_formatDate(invoice.createdAt)}'),
                  ],
                ),
                trailing: Chip(
                  label: Text(invoice.status),
                  backgroundColor: _getStatusColor(invoice.status),
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
    );
  }

  List<dynamic> _sortInvoices(
    List invoices,
    List<Client> clients,
    SortOption option,
    bool ascending,
  ) {
    final sorted = [...invoices];
    sorted.sort((a, b) {
      dynamic aValue, bValue;

      switch (option) {
        case SortOption.dateCreated:
          aValue = a.createdAt;
          bValue = b.createdAt;
          break;
        case SortOption.dateModified:
          aValue = a.updatedAt;
          bValue = b.updatedAt;
          break;
        case SortOption.clientName:
          final aClient = clients.where((c) => c.id == a.clientId).firstOrNull;
          final bClient = clients.where((c) => c.id == b.clientId).firstOrNull;
          aValue = aClient?.name ?? '';
          bValue = bClient?.name ?? '';
          break;
        case SortOption.totalValue:
          aValue = a.totalAmount;
          bValue = b.totalAmount;
          break;
        case SortOption.companyName:
          // For now, sort by ID as company info not directly available
          aValue = a.id ?? 0;
          bValue = b.id ?? 0;
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

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

Color _getStatusColor(String status) {
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