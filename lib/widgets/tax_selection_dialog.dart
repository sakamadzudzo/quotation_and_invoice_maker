import 'package:flutter/material.dart';
import '../models/tax_name.dart';

class TaxSelectionDialog extends StatefulWidget {
  final List<TaxName> availableTaxes;
  final int? selectedTaxId;
  final Function(TaxName) onTaxSelected;

  const TaxSelectionDialog({
    super.key,
    required this.availableTaxes,
    this.selectedTaxId,
    required this.onTaxSelected,
  });

  @override
  State<TaxSelectionDialog> createState() => _TaxSelectionDialogState();
}

class _TaxSelectionDialogState extends State<TaxSelectionDialog> {
  late TextEditingController _customTaxController;
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _customTaxController = TextEditingController();
  }

  @override
  void dispose() {
    _customTaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Tax'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...widget.availableTaxes.map((tax) => RadioListTile<int>(
              title: Text(tax.name),
              value: tax.id!,
              groupValue: widget.selectedTaxId,
              onChanged: (value) {
                if (value != null) {
                  final selectedTax = widget.availableTaxes.firstWhere((t) => t.id == value);
                  widget.onTaxSelected(selectedTax);
                  Navigator.pop(context);
                }
              },
            )),
            const Divider(),
            ListTile(
              title: const Text('Add Custom Tax'),
              leading: const Icon(Icons.add),
              onTap: () {
                setState(() {
                  _showCustomInput = !_showCustomInput;
                });
              },
            ),
            if (_showCustomInput) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customTaxController,
                decoration: const InputDecoration(
                  labelText: 'Custom Tax Name',
                  hintText: 'e.g., VAT 15%, GST 10%',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    final customTax = TaxName(
                      name: value.trim(),
                      isCustom: true,
                    );
                    widget.onTaxSelected(customTax);
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_customTaxController.text.trim().isNotEmpty) {
                    final customTax = TaxName(
                      name: _customTaxController.text.trim(),
                      isCustom: true,
                    );
                    widget.onTaxSelected(customTax);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Custom Tax'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}