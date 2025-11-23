import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../models/company.dart';
import '../models/client.dart';
import '../models/payment.dart';
import '../models/tax_name.dart';
import '../services/pdf_service.dart';
import '../providers/company_provider.dart';
import '../providers/client_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import 'payment_screen.dart';
import 'pdf_preview_screen.dart';
import 'print_settings_screen.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailsScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  Company? _company;
  Client? _client;
  List<TaxName> _taxNames = [];
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final databaseService = DatabaseService();
      _taxNames = await databaseService.getTaxNames();

      final companyProvider = context.read<CompanyProvider>();
      final clientProvider = context.read<ClientProvider>();
      final invoiceProvider = context.read<InvoiceProvider>();

      _company = companyProvider.getCompanyById(widget.invoice.companyId);
      _client = clientProvider.getClientById(widget.invoice.clientId);
      _payments = await invoiceProvider.getPaymentsByInvoice(
        widget.invoice.id!,
      );
    } catch (e) {
      debugPrint('Error loading invoice details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showPrintOptions() async {
    if (_company == null || _client == null) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Print Invoice'),
              subtitle: const Text('Single invoice with all payments'),
              onTap: () => Navigator.pop(context, 'single'),
            ),
            if (_payments.isNotEmpty) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.call_split),
                title: const Text('Print Separate Invoices'),
                subtitle: Text(
                  'One invoice per payment (${_payments.length} invoices)',
                ),
                onTap: () => Navigator.pop(context, 'separate'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result == 'single') {
      await _printInvoice();
    } else if (result == 'separate') {
      await _printSeparateInvoices();
    }
  }

  Future<void> _printInvoice() async {
    if (_company == null || _client == null) return;

    try {
      final settings = context.read<SettingsProvider>();
      final pdfService = PdfService();
      final pdfPath = await pdfService.generateInvoicePdf(
        widget.invoice,
        _company!,
        _client!,
        _taxNames,
        settings,
        payments: _payments,
      );

      await pdfService.printPdf(pdfPath);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  Future<void> _printSeparateInvoices() async {
    if (_company == null || _client == null || _payments.isEmpty) return;

    try {
      final settings = context.read<SettingsProvider>();
      final pdfService = PdfService();
      final pdfPaths = await pdfService.generatePaymentInvoices(
        widget.invoice,
        _company!,
        _client!,
        _taxNames,
        _payments,
        settings,
      );

      // Print all PDFs
      for (final path in pdfPaths) {
        await pdfService.printPdf(path);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printed ${pdfPaths.length} separate invoices')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDFs: $e')));
    }
  }

  Future<void> _shareInvoice() async {
    if (_company == null || _client == null) return;

    try {
      final settings = context.read<SettingsProvider>();
      final pdfService = PdfService();
      final pdfPath = await pdfService.generateInvoicePdf(
        widget.invoice,
        _company!,
        _client!,
        _taxNames,
        settings,
        payments: _payments,
      );

      await pdfService.sharePdf(pdfPath, 'Invoice #${widget.invoice.id}');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  Future<void> _previewPdf() async {
    if (_company == null || _client == null) return;

    try {
      final settings = context.read<SettingsProvider>();
      final pdfService = PdfService();
      final pdfPath = await pdfService.generateInvoicePdf(
        widget.invoice,
        _company!,
        _client!,
        _taxNames,
        settings,
        payments: _payments,
      );

      final file = File(pdfPath);
      final bytes = await file.readAsBytes();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            bytes: bytes,
            title: 'Invoice #${widget.invoice.id}',
            onPrint: () => pdfService.printPdf(pdfPath),
            onShare: () =>
                pdfService.sharePdf(pdfPath, 'Invoice #${widget.invoice.id}'),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_company == null || _client == null) {
      return const Scaffold(
        body: Center(child: Text('Error loading invoice details')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${widget.invoice.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: _previewPdf,
            tooltip: 'Preview PDF',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'print':
                  _showPrintOptions();
                  break;
                case 'share':
                  _shareInvoice();
                  break;
                case 'settings':
                  _openPrintSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 8),
                    Text('Print'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Print Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildCompanyInfo(),
            const SizedBox(height: 16),
            _buildClientInfo(),
            const SizedBox(height: 24),
            _buildItemsList(),
            const SizedBox(height: 24),
            _buildPaymentsSection(),
            const SizedBox(height: 24),
            _buildTotal(),
          ],
        ),
      ),
      floatingActionButton: _getFAB(),
    );
  }

  Widget _getFAB() {
    final paidAmount = _payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final remainingAmount = widget.invoice.totalAmount - paidAmount;

    if (remainingAmount > 0) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(invoice: widget.invoice),
            ),
          ).then((_) => _loadData()); // Refresh data when returning
        },
        child: const Icon(Icons.payment),
      );
    } else {
      return Container();
    }
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice #${widget.invoice.id}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Date: ${_formatDate(widget.invoice.createdAt)}'),
            Text(
              'Status: ${widget.invoice.status.replaceAll('_', ' ').toUpperCase()}',
            ),
            if (_payments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Payments: ${_payments.length}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'From',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              _company!.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_company!.address),
            Text('Phone: ${_company!.phone}'),
            Text('Email: ${_company!.email}'),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bill To',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              _client!.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_client!.address),
            Text('Phone: ${_client!.phone}'),
            Text('Email: ${_client!.email}'),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...widget.invoice.items.map((item) {
              final taxName = _taxNames
                  .where((t) => t.id == item.taxId)
                  .firstOrNull;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (item.description.isNotEmpty) Text(item.description),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}',
                          ),
                          Text(
                            '\$${item.lineTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (taxName != null)
                        Text(
                          'Tax: ${taxName.name}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_payments.length} payment${_payments.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_payments.isEmpty)
              const Text('No payments recorded yet.')
            else
              ..._payments.map(
                (payment) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${payment.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(_formatDate(payment.paymentDate)),
                          ],
                        ),
                        if (payment.notes?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            payment.notes!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotal() {
    final paidAmount = _payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final remainingAmount = widget.invoice.totalAmount - paidAmount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${widget.invoice.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Paid Amount:'),
                Text('\$${paidAmount.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: remainingAmount > 0 ? Colors.red : Colors.green,
                  ),
                ),
                Text(
                  '\$${remainingAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: remainingAmount > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _openPrintSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrintSettingsScreen()),
    );
  }
}
