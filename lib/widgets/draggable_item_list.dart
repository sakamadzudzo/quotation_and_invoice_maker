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
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            return Container(
              key: ValueKey('item_$index'),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.drag_handle, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ItemInputWidget(
                      key: ValueKey('item_input_$index'),
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
          onReorder: widget.onReorder,
        ),
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
}