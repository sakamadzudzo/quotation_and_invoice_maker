import 'dart:convert';
import 'quotation_item.dart';

class Quotation {
  final int? id;
  final int companyId;
  final int clientId;
  final List<QuotationItem> items;
  final double totalAmount;
  final String status; // draft, active, archived
  final DateTime createdAt;
  final DateTime updatedAt;

  Quotation({
    this.id,
    required this.companyId,
    required this.clientId,
    required this.items,
    required this.totalAmount,
    this.status = 'draft',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'client_id': clientId,
      'items': jsonEncode(items.map((item) => item.toMap()).toList()),
      'total_amount': totalAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Quotation.fromMap(Map<String, dynamic> map) {
    return Quotation(
      id: map['id'],
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

  Quotation copyWith({
    int? id,
    int? companyId,
    int? clientId,
    List<QuotationItem>? items,
    double? totalAmount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quotation(
      id: id ?? this.id,
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