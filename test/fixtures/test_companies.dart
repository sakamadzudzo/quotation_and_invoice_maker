import 'package:quotation_invoice_maker/models/company.dart';

/// Test fixtures for Company objects
class TestCompanies {
  static final testCompany1 = Company(
    id: 1,
    name: 'Test Company 1',
    address: '123 Test Street, Test City',
    phone: '+1-555-0123',
    email: 'contact@testcompany1.com',
    bankName: 'Test Bank',
    bankBranch: 'Main Branch',
    accountNumber: '1234567890',
    currency: 'USD',
    terms: 'Payment due within 30 days',
    disclaimer: 'All prices subject to change',
    logoPath: null,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static final testCompany2 = Company(
    id: 2,
    name: 'Test Company 2',
    address: '456 Sample Avenue, Sample City',
    phone: '+1-555-0456',
    email: 'info@testcompany2.com',
    bankName: 'Sample Bank',
    bankBranch: 'Downtown Branch',
    accountNumber: '0987654321',
    currency: 'EUR',
    terms: 'Net 15 days',
    disclaimer: 'Prices valid for 30 days',
    logoPath: '/path/to/logo.png',
    createdAt: DateTime(2024, 1, 2),
    updatedAt: DateTime(2024, 1, 2),
  );

  static final newCompany = Company(
    name: 'New Test Company',
    address: '789 New Street, New City',
    phone: '+1-555-0789',
    email: 'hello@newtestcompany.com',
    bankName: 'New Bank',
    bankBranch: 'Central Branch',
    accountNumber: '1122334455',
    currency: 'GBP',
    terms: 'Payment due within 14 days',
    disclaimer: 'Terms and conditions apply',
    logoPath: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static final companiesList = [testCompany1, testCompany2];
}