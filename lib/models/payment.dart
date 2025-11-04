class Payment {
  final int? id;
  final int invoiceId;
  final double amount;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;

  Payment({
    this.id,
    required this.invoiceId,
    required this.amount,
    required this.paymentDate,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      invoiceId: map['invoice_id'],
      amount: map['amount'],
      paymentDate: DateTime.parse(map['payment_date']),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Payment copyWith({
    int? id,
    int? invoiceId,
    double? amount,
    DateTime? paymentDate,
    String? notes,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}