import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../models/quotation.dart';
import '../models/quotation_item.dart';
import '../models/tax_name.dart';
import '../models/company.dart';
import '../models/client.dart';
import '../providers/invoice_provider.dart';
// ignore: unused_import
import '../providers/quotation_provider.dart';
import '../providers/company_provider.dart';
import '../providers/client_provider.dart';
import '../services/database_service.dart';
import '../widgets/draggable_item_list.dart';

class InvoiceFormScreen extends StatefulWidget {
  final Quotation? quotation; // If converting from quotation
  final Invoice? invoice; // If editing existing invoice

  const InvoiceFormScreen({super.key, this.quotation, this.invoice});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();

  Company? _selectedCompany;
  Client? _selectedClient;
  List<QuotationItem> _items = [];
  List<TaxName> _availableTaxes = [];
  bool _isLoading = false;
  // ignore: unused_field
  bool _isEditing = false;

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.lineTotal);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _availableTaxes = await _databaseService.getTaxNames();

      if (widget.invoice != null) {
        // Editing existing invoice
        _isEditing = true;
        final companies = context.read<CompanyProvider>().companies;
        final clients = context.read<ClientProvider>().clients;

        _selectedCompany = companies.where((c) => c.id == widget.invoice!.companyId).firstOrNull;
        _selectedClient = clients.where((c) => c.id == widget.invoice!.clientId).firstOrNull;
        _items = List.from(widget.invoice!.items);
      } else if (widget.quotation != null) {
        // Converting from quotation
        _selectedCompany = context.read<CompanyProvider>().companies
            .where((c) => c.id == widget.quotation!.companyId).firstOrNull;
        _selectedClient = context.read<ClientProvider>().clients
            .where((c) => c.id == widget.quotation!.clientId).firstOrNull;
        _items = List.from(widget.quotation!.items);
      } else {
        // New invoice from scratch
        _addNewItem();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  void _addNewItem() {
    setState(() {
      _items.add(QuotationItem(
        productName: '',
        description: '',
        taxId: _availableTaxes.isNotEmpty ? _availableTaxes.first.id! : 0,
        quantity: 0,
        unitPrice: 0,
        lineTotal: 0,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, QuotationItem item) {
    setState(() {
      _items[index] = item;
    });
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty || _items.any((item) => item.productName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item with a product name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final invoice = widget.invoice != null
          ? widget.invoice!.copyWith(
              quotationId: widget.quotation?.id,
              companyId: _selectedCompany!.id!,
              clientId: _selectedClient!.id!,
              items: _items,
              totalAmount: _totalAmount,
              updatedAt: DateTime.now(),
            )
          : Invoice(
              quotationId: widget.quotation?.id,
              companyId: _selectedCompany?.id ?? widget.quotation?.companyId ?? 0,
              clientId: _selectedClient?.id ?? widget.quotation?.clientId ?? 0,
              items: _items,
              totalAmount: _totalAmount,
              status: 'unpaid',
            );

      final success = widget.invoice != null
          ? await context.read<InvoiceProvider>().updateInvoice(invoice)
          : await context.read<InvoiceProvider>().addInvoice(invoice);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.invoice != null ? 'Invoice updated successfully' : 'Invoice created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating invoice: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.invoice != null
              ? 'Edit Invoice'
              : widget.quotation != null
                  ? 'Convert to Invoice'
                  : 'Create Invoice'
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveInvoice,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.invoice != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Editing invoice #${widget.invoice!.id}',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                )
              else if (widget.quotation != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Converting quotation #${widget.quotation!.id} to invoice',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.quotation == null && widget.invoice == null) ...[
                const SizedBox(height: 24),
                _buildCompanySelection(),
                const SizedBox(height: 16),
                _buildClientSelection(),
              ],
              const SizedBox(height: 24),
              const Text(
                'Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DraggableItemList(
                items: _items,
                availableTaxes: _availableTaxes,
                onItemChanged: _updateItem,
                onItemRemoved: _removeItem,
                onAddItem: _addNewItem,
                onReorder: _reorderItems,
              ),
              const SizedBox(height: 24),
              _buildTotalSummary(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanySelection() {
    return Consumer<CompanyProvider>(
      builder: (context, provider, child) {
        return DropdownButtonFormField<Company>(
          value: _selectedCompany,
          decoration: const InputDecoration(
            labelText: 'Select Company',
            border: OutlineInputBorder(),
          ),
          items: provider.companies.map((company) {
            return DropdownMenuItem<Company>(
              value: company,
              child: Text(company.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCompany = value;
            });
          },
          validator: (value) => value == null ? 'Please select a company' : null,
        );
      },
    );
  }

  Widget _buildClientSelection() {
    return Consumer<ClientProvider>(
      builder: (context, provider, child) {
        return DropdownButtonFormField<Client>(
          value: _selectedClient,
          decoration: const InputDecoration(
            labelText: 'Select Client',
            border: OutlineInputBorder(),
          ),
          items: provider.clients.map((client) {
            return DropdownMenuItem<Client>(
              value: client,
              child: Text(client.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedClient = value;
            });
          },
          validator: (value) => value == null ? 'Please select a client' : null,
        );
      },
    );
  }

  Widget _buildTotalSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
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
                '\$${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_items.length} item${_items.length == 1 ? '' : 's'}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}