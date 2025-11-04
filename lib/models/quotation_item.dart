class QuotationItem {
  final String productName;
  final String description;
  final int taxId;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  QuotationItem({
    required this.productName,
    required this.description,
    required this.taxId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'product_name': productName,
      'description': description,
      'tax_id': taxId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'line_total': lineTotal,
    };
  }

  factory QuotationItem.fromMap(Map<String, dynamic> map) {
    return QuotationItem(
      productName: map['product_name'],
      description: map['description'],
      taxId: map['tax_id'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'],
      lineTotal: map['line_total'],
    );
  }

  QuotationItem copyWith({
    String? productName,
    String? description,
    int? taxId,
    double? quantity,
    double? unitPrice,
    double? lineTotal,
  }) {
    return QuotationItem(
      productName: productName ?? this.productName,
      description: description ?? this.description,
      taxId: taxId ?? this.taxId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }
}