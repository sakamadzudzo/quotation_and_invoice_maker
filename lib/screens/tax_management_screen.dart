import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tax_name.dart';
import '../providers/tax_provider.dart';

class TaxManagementScreen extends StatefulWidget {
  const TaxManagementScreen({super.key});

  @override
  State<TaxManagementScreen> createState() => _TaxManagementScreenState();
}

class _TaxManagementScreenState extends State<TaxManagementScreen> {
  late TaxProvider _taxProvider;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _taxProvider = Provider.of<TaxProvider>(context, listen: false);
    _loadTaxNames();
  }

  Future<void> _loadTaxNames() async {
    setState(() => _isLoading = true);
    try {
      await _taxProvider.loadTaxNames();
    } catch (e) {
      debugPrint('Error loading tax names: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addTaxName() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tax Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tax Name (e.g., VAT 15%, GST 10%)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final success = await _taxProvider.addTaxName(TaxName(name: result, isCustom: true));
        if (success) {
          await _loadTaxNames();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tax name "$result" added')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tax name already exists')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding tax name: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteTaxName(TaxName taxName) async {
    if (!taxName.isCustom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete default tax names')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tax Name'),
        content: Text('Are you sure you want to delete "${taxName.name}"?'),
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
      try {
        final success = await _taxProvider.deleteTaxName(taxName.id!);
        if (success) {
          await _loadTaxNames();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tax name "${taxName.name}" removed')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot delete tax name that is in use')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting tax name: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaxProvider>(
      builder: (context, taxProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tax Management'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addTaxName,
                tooltip: 'Add Tax Name',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : taxProvider.taxNames.isEmpty
                  ? const Center(
                      child: Text('No tax names available'),
                    )
                  : ListView.builder(
                      itemCount: taxProvider.taxNames.length,
                      itemBuilder: (context, index) {
                        final taxName = taxProvider.taxNames[index];
                        return ListTile(
                          title: Text(taxName.name),
                          subtitle: taxName.isCustom
                              ? const Text('Custom')
                              : const Text('Default'),
                          trailing: taxName.isCustom
                              ? IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteTaxName(taxName),
                                  tooltip: 'Delete',
                                )
                              : const Icon(Icons.lock, color: Colors.grey),
                          leading: CircleAvatar(
                            backgroundColor: taxName.isCustom
                                ? Colors.blue
                                : Colors.green,
                            child: Icon(
                              taxName.isCustom ? Icons.person : Icons.business,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addTaxName,
            tooltip: 'Add Tax Name',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}