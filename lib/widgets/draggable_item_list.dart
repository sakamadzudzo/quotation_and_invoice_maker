import 'package:flutter/material.dart';
import 'item_input_widget.dart';
import '../models/quotation_item.dart';
import '../models/tax_name.dart';

class DraggableItemList extends StatefulWidget {
  final List<QuotationItem> items;
  final List<TaxName> availableTaxes;
  final Function(int, QuotationItem) onItemChanged;
  final Function(int) onItemRemoved;
  final Function() onAddItem;
  final Function(int, int) onReorder;

  const DraggableItemList({
    super.key,
    required this.items,
    required this.availableTaxes,
    required this.onItemChanged,
    required this.onItemRemoved,
    required this.onAddItem,
    required this.onReorder,
  });

  @override
  State<DraggableItemList> createState() => _DraggableItemListState();
}

class _DraggableItemListState extends State<DraggableItemList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildDraggableItem(index, item);
        }),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: widget.onAddItem,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableItem(int index, QuotationItem item) {
    return LongPressDraggable<int>(
      data: index,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: MediaQuery.of(context).size.width - 32,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Text(
            item.productName.isNotEmpty ? item.productName : 'Unnamed Item',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.drag_handle, color: Colors.grey),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  item.productName.isNotEmpty ? item.productName : 'Unnamed Item',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
      child: DragTarget<int>(
        onWillAccept: (data) => data != null && data != index,
        onAccept: (draggedIndex) {
          widget.onReorder(draggedIndex, index);
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              border: candidateData.isNotEmpty
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.drag_handle, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ItemInputWidget(
                    key: ValueKey('item_${index}_${item.productName}_${item.quantity}'),
                    initialItem: item,
                    availableTaxes: widget.availableTaxes,
                    onItemChanged: (updatedItem) => widget.onItemChanged(index, updatedItem),
                    onRemove: () => widget.onItemRemoved(index),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}