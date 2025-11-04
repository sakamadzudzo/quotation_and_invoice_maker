class Company {
  final int? id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String bankName;
  final String bankBranch;
  final String accountNumber;
  final String currency;
  final String terms;
  final String disclaimer;
  final String? logoPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.bankName,
    required this.bankBranch,
    required this.accountNumber,
    required this.currency,
    required this.terms,
    required this.disclaimer,
    this.logoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) :
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'bank_name': bankName,
      'bank_branch': bankBranch,
      'account_number': accountNumber,
      'currency': currency,
      'terms': terms,
      'disclaimer': disclaimer,
      'logo_path': logoPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      bankName: map['bank_name'] ?? '',
      bankBranch: map['bank_branch'] ?? '',
      accountNumber: map['account_number'] ?? '',
      currency: map['currency'] ?? 'USD',
      terms: map['terms'],
      disclaimer: map['disclaimer'],
      logoPath: map['logo_path'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Company copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? bankName,
    String? bankBranch,
    String? accountNumber,
    String? currency,
    String? terms,
    String? disclaimer,
    String? logoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bankName: bankName ?? this.bankName,
      bankBranch: bankBranch ?? this.bankBranch,
      accountNumber: accountNumber ?? this.accountNumber,
      currency: currency ?? this.currency,
      terms: terms ?? this.terms,
      disclaimer: disclaimer ?? this.disclaimer,
      logoPath: logoPath ?? this.logoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}