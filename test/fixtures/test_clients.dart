import 'package:quotation_invoice_maker/models/client.dart';

/// Test fixtures for Client objects
class TestClients {
  static final testClient1 = Client(
    id: 1,
    name: 'John Doe',
    address: '123 Main Street, Springfield',
    phone: '+1-555-0123',
    email: 'john.doe@example.com',
    tinNumber: 'TIN123456',
    vatNumber: 'VAT789012',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static final testClient2 = Client(
    id: 2,
    name: 'Jane Smith',
    address: '456 Oak Avenue, Rivertown',
    phone: '+1-555-0456',
    email: 'jane.smith@example.com',
    tinNumber: 'TIN654321',
    vatNumber: 'VAT210987',
    createdAt: DateTime(2024, 1, 2),
    updatedAt: DateTime(2024, 1, 2),
  );

  static final newClient = Client(
    name: 'Bob Johnson',
    address: '789 Pine Road, Lakeview',
    phone: '+1-555-0789',
    email: 'bob.johnson@example.com',
    tinNumber: 'TIN111222',
    vatNumber: 'VAT333444',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static final clientsList = [testClient1, testClient2];
}