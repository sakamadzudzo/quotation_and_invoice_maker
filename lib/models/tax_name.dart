class TaxName {
  final int? id;
  final String name;
  final bool isCustom;
  final DateTime createdAt;

  TaxName({
    this.id,
    required this.name,
    this.isCustom = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_custom': isCustom ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TaxName.fromMap(Map<String, dynamic> map) {
    return TaxName(
      id: map['id'],
      name: map['name'],
      isCustom: map['is_custom'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  TaxName copyWith({
    int? id,
    String? name,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return TaxName(
      id: id ?? this.id,
      name: name ?? this.name,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}