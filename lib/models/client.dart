class Client {
  final int? id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String tinNumber;
  final String vatNumber;
  final Map<String, dynamic> otherInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Client({
    this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.tinNumber,
    required this.vatNumber,
    Map<String, dynamic>? otherInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) :
    otherInfo = otherInfo ?? {},
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'tin_number': tinNumber,
      'vat_number': vatNumber,
      'other_info': otherInfo.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      tinNumber: map['tin_number'] ?? '',
      vatNumber: map['vat_number'] ?? '',
      otherInfo: _parseOtherInfo(map['other_info']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Client copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? tinNumber,
    String? vatNumber,
    Map<String, dynamic>? otherInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      tinNumber: tinNumber ?? this.tinNumber,
      vatNumber: vatNumber ?? this.vatNumber,
      otherInfo: otherInfo ?? this.otherInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Map<String, dynamic> _parseOtherInfo(dynamic otherInfo) {
    if (otherInfo == null) return {};
    if (otherInfo is Map) return Map<String, dynamic>.from(otherInfo);
    if (otherInfo is String) {
      try {
        // For now, just return empty map since we're not using complex JSON
        return {};
      } catch (e) {
        return {};
      }
    }
    return {};
  }
}