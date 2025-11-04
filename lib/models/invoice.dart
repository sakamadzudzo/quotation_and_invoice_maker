import 'dart:convert';
import 'quotation_item.dart';

class Invoice {
  final int? id;
  final int? quotationId;
  final int companyId;
  final int clientId;
  final List<QuotationItem> items;
  final double totalAmount;
  final String status; // unpaid, partially_paid, paid
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    this.id,
    this.quotationId,
    required this.companyId,
    required this.clientId,
    required this.items,
    required this.totalAmount,
    this.status = 'unpaid',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quotation_id': quotationId,
      'company_id': companyId,
      'client_id': clientId,
      'items': jsonEncode(items.map((item) => item.toMap()).toList()),
      'total_amount': totalAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      quotationId: map['quotation_id'],
      companyId: map['company_id'],
      clientId: map['client_id'],
      items: _parseItems(map['items']),
      totalAmount: map['total_amount'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  static List<QuotationItem> _parseItems(dynamic items) {
    if (items == null) return [];
    if (items is List) return items.map((item) => QuotationItem.fromMap(item)).toList();
    if (items is String) {
      try {
        final List<dynamic> decoded = jsonDecode(items);
        return decoded.map((item) => QuotationItem.fromMap(item)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  Invoice copyWith({
    int? id,
    int? quotationId,
    int? companyId,
    int? clientId,
    List<QuotationItem>? items,
    double? totalAmount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      quotationId: quotationId ?? this.quotationId,
      companyId: companyId ?? this.companyId,
      clientId: clientId ?? this.clientId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}