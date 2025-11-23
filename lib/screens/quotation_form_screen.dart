import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/company.dart';
import '../models/client.dart';
import '../models/quotation.dart';
import '../models/quotation_item.dart';
import '../models/tax_name.dart';
import '../providers/company_provider.dart';
import '../providers/client_provider.dart';
import '../providers/quotation_provider.dart';
import '../services/database_service.dart';
import '../widgets/draggable_item_list.dart';

class QuotationFormScreen extends StatefulWidget {
  final Quotation? quotation; // For editing existing quotation

  const QuotationFormScreen({super.key, this.quotation});

  @override
  State<QuotationFormScreen> createState() => _QuotationFormScreenState();
}

class _QuotationFormScreenState extends State<QuotationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();

  Company? _selectedCompany;
  Client? _selectedClient;
  List<QuotationItem> _items = [];
  List<TaxName> _availableTaxes = [];
  bool _isLoading = false;

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.lineTotal);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _availableTaxes = await _databaseService.getTaxNames();

      if (widget.quotation != null) {
        // Editing existing quotation - load its data
        // Ensure providers have data loaded
        final companyProvider = context.read<CompanyProvider>();
        final clientProvider = context.read<ClientProvider>();

        // Load data if not already loaded
        if (companyProvider.companies.isEmpty) {
          await companyProvider.loadCompanies();
        }
        if (clientProvider.clients.isEmpty) {
          await clientProvider.loadClients();
        }

        // Now find the company and client
        _selectedCompany = companyProvider.companies
            .where((c) => c.id == widget.quotation!.companyId)
            .firstOrNull;
        _selectedClient = clientProvider.clients
            .where((c) => c.id == widget.quotation!.clientId)
            .firstOrNull;
        _items = List.from(widget.quotation!.items);
      } else {
        // New quotation - add a default item
        _addNewItem();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  Future<void> _saveQuotation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a company')),
      );
      return;
    }
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }
    if (_items.isEmpty || _items.any((item) => item.productName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item with a product name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quotation = widget.quotation != null
          ? widget.quotation!.copyWith(
              companyId: _selectedCompany!.id!,
              clientId: _selectedClient!.id!,
              items: _items,
              totalAmount: _totalAmount,
              updatedAt: DateTime.now(),
            )
          : Quotation(
              companyId: _selectedCompany!.id!,
              clientId: _selectedClient!.id!,
              items: _items,
              totalAmount: _totalAmount,
              status: 'draft',
            );

      final success = widget.quotation != null
          ? await context.read<QuotationProvider>().updateQuotation(quotation)
          : await context.read<QuotationProvider>().addQuotation(quotation);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.quotation != null ? 'Quotation updated successfully' : 'Quotation saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving quotation: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.quotation != null ? 'Edit Quotation' : 'Create Quotation'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading quotation data...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quotation != null ? 'Edit Quotation' : 'Create Quotation'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveQuotation,
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
              _buildCompanySelection(),
              const SizedBox(height: 16),
              _buildClientSelection(),
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