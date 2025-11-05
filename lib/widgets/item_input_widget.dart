import 'package:flutter/material.dart';
import '../models/quotation_item.dart';
import '../models/tax_name.dart';
import '../utils/helpers.dart';

class ItemInputWidget extends StatefulWidget {
  final QuotationItem? initialItem;
  final List<TaxName> availableTaxes;
  final Function(QuotationItem) onItemChanged;
  final VoidCallback onRemove;

  const ItemInputWidget({
    super.key,
    this.initialItem,
    required this.availableTaxes,
    required this.onItemChanged,
    required this.onRemove,
  });

  @override
  State<ItemInputWidget> createState() => _ItemInputWidgetState();
}

class _ItemInputWidgetState extends State<ItemInputWidget> {
  late TextEditingController _productNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;

  late int _selectedTaxId;
  late double _quantity;
  late double _unitPrice;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(
      text: widget.initialItem?.productName ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialItem?.description ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.initialItem?.quantity.toString() ?? '',
    );
    _unitPriceController = TextEditingController(
      text: widget.initialItem?.unitPrice.toString() ?? '',
    );

    _selectedTaxId =
        widget.initialItem?.taxId ?? widget.availableTaxes.first.id ?? 0;
    _quantity = widget.initialItem?.quantity ?? 0.0;
    _unitPrice = widget.initialItem?.unitPrice ?? 0.0;
  }

  @override
  void didUpdateWidget(ItemInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.availableTaxes != oldWidget.availableTaxes &&
        widget.availableTaxes.isNotEmpty) {
      _selectedTaxId =
          widget.initialItem?.taxId ?? widget.availableTaxes.first.id ?? 0;
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _updateItem() {
    final lineTotal = _quantity * _unitPrice;
    final item = QuotationItem(
      productName: _productNameController.text,
      description: _descriptionController.text,
      taxId: _selectedTaxId,
      quantity: _quantity,
      unitPrice: _unitPrice,
      lineTotal: lineTotal,
    );
    widget.onItemChanged(item);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _productNameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _updateItem(),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    inputFormatters: [CapitalizeTextFormatter()],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (_) => _updateItem(),
              inputFormatters: null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _quantity = double.tryParse(value) ?? 0.0;
                      _updateItem();
                    },
                    validator: (value) {
                      final qty = double.tryParse(value ?? '');
                      if (qty == null || qty <= 0) {
                        return 'Must be > 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _unitPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _unitPrice = double.tryParse(value) ?? 0.0;
                      _updateItem();
                    },
                    validator: (value) {
                      final price = double.tryParse(value ?? '');
                      if (price == null || price < 0) {
                        return 'Must be >= 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedTaxId,
              decoration: const InputDecoration(
                labelText: 'Tax',
                border: OutlineInputBorder(),
              ),
              items: widget.availableTaxes.map((tax) {
                return DropdownMenuItem<int>(
                  value: tax.id,
                  child: Text(tax.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTaxId = value;
                  });
                  _updateItem();
                }
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Line Total:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${_quantity * _unitPrice}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
