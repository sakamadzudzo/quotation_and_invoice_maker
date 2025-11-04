import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quotation.dart';
import '../models/company.dart';
import '../models/client.dart';
import '../models/tax_name.dart';
import '../services/pdf_service.dart';
import '../providers/company_provider.dart';
import '../providers/client_provider.dart';
import '../services/database_service.dart';

class QuotationDetailsScreen extends StatefulWidget {
  final Quotation quotation;

  const QuotationDetailsScreen({
    super.key,
    required this.quotation,
  });

  @override
  State<QuotationDetailsScreen> createState() => _QuotationDetailsScreenState();
}

class _QuotationDetailsScreenState extends State<QuotationDetailsScreen> {
  Company? _company;
  Client? _client;
  List<TaxName> _taxNames = [];
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

      _company = companyProvider.getCompanyById(widget.quotation.companyId);
      _client = clientProvider.getClientById(widget.quotation.clientId);
    } catch (e) {
      debugPrint('Error loading quotation details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _printQuotation() async {
    if (_company == null || _client == null) return;

    try {
      final pdfService = PdfService();
      final pdfPath = await pdfService.generateQuotationPdf(
        widget.quotation,
        _company!,
        _client!,
        _taxNames,
      );

      await pdfService.printPdf(pdfPath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  Future<void> _shareQuotation() async {
    if (_company == null || _client == null) return;

    try {
      final pdfService = PdfService();
      final pdfPath = await pdfService.generateQuotationPdf(
        widget.quotation,
        _company!,
        _client!,
        _taxNames,
      );

      await pdfService.sharePdf(pdfPath, 'Quotation #${widget.quotation.id}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_company == null || _client == null) {
      return const Scaffold(
        body: Center(child: Text('Error loading quotation details')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Quotation #${widget.quotation.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printQuotation,
            tooltip: 'Print Quotation',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareQuotation,
            tooltip: 'Share Quotation',
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
            _buildTotal(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quotation #${widget.quotation.id}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Date: ${_formatDate(widget.quotation.createdAt)}'),
            Text('Status: ${widget.quotation.status}'),
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
            Text(_company!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            Text(_client!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            ...widget.quotation.items.map((item) {
              final taxName = _taxNames.where((t) => t.id == item.taxId).firstOrNull;
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
                          Text('${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}'),
                          Text(
                            '\$${item.lineTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (taxName != null)
                        Text(
                          'Tax: ${taxName.name}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildTotal() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Amount:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${widget.quotation.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}