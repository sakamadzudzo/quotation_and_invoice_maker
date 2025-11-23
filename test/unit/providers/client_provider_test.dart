import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quotation_invoice_maker/core/providers/base_provider.dart';
import 'package:quotation_invoice_maker/models/client.dart';
import 'package:quotation_invoice_maker/providers/client_provider.dart';

import '../../fixtures/test_clients.dart';
import '../../mocks/mock_client_repository.dart';
import '../../mocks/mock_cache_manager.dart';

void main() {
  late ClientProvider provider;
  late MockClientRepository mockRepository;
  late MockCacheManager mockCacheManager;

  setUp(() {
    mockRepository = MockClientRepository();
    mockCacheManager = MockCacheManager();
    provider = ClientProvider(mockRepository, mockCacheManager);
  });

  tearDown(() {
    provider.dispose();
  });

  group('ClientProvider', () {
    test('should load clients successfully', () async {
      // Arrange
      when(() => mockRepository.getClients())
          .thenAnswer((_) async => TestClients.clientsList);

      // Act
      await provider.loadClients();

      // Assert
      expect(provider.clients, equals(TestClients.clientsList));
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      verify(() => mockRepository.getClients()).called(1);
    });

    test('should handle load clients error', () async {
      // Arrange
      final exception = Exception('Database error');
      when(() => mockRepository.getClients()).thenThrow(exception);

      // Act & Assert
      expect(
        () => provider.loadClients(),
        throwsA(isA<Exception>()),
      );
      // Note: error is set but exception is rethrown, so UI layer handles it
    });

    test('should add client successfully', () async {
      // Arrange
      when(() => mockRepository.insertClient(TestClients.newClient))
          .thenAnswer((_) async => 3);

      // Act
      final result = await provider.addClient(TestClients.newClient);

      // Assert
      expect(result, isTrue);
      expect(provider.clients.length, equals(1));
      expect(provider.clients.first.id, equals(3));
      expect(provider.clients.first.name, equals(TestClients.newClient.name));
      verify(() => mockRepository.insertClient(TestClients.newClient)).called(1);
    });

    test('should handle add client error', () async {
      // Arrange
      final exception = Exception('Insert failed');
      when(() => mockRepository.insertClient(TestClients.newClient))
          .thenThrow(exception);

      // Act
      final result = await provider.addClient(TestClients.newClient);

      // Assert
      expect(result, isFalse);
      expect(provider.clients, isEmpty);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Insert failed'));
    });

    test('should update client successfully', () async {
      // Arrange
      final updatedClient = TestClients.testClient1.copyWith(name: 'Updated Name');
      when(() => mockRepository.updateClient(updatedClient))
          .thenAnswer((_) async => 1);

      // First add the client to the provider
      provider.clients.add(TestClients.testClient1);

      // Act
      final result = await provider.updateClient(updatedClient);

      // Assert
      expect(result, isTrue);
      expect(provider.clients.length, equals(1));
      expect(provider.clients.first.name, equals('Updated Name'));
      verify(() => mockRepository.updateClient(updatedClient)).called(1);
    });

    test('should handle update client error', () async {
      // Arrange
      final updatedClient = TestClients.testClient1.copyWith(name: 'Updated Name');
      final exception = Exception('Update failed');
      when(() => mockRepository.updateClient(updatedClient)).thenThrow(exception);

      // Act
      final result = await provider.updateClient(updatedClient);

      // Assert
      expect(result, isFalse);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Update failed'));
    });

    test('should delete client successfully', () async {
      // Arrange
      const clientId = 1;
      when(() => mockRepository.deleteClient(clientId))
          .thenAnswer((_) async => 1);

      // Add client to provider first
      provider.clients.add(TestClients.testClient1);

      // Act
      final result = await provider.deleteClient(clientId);

      // Assert
      expect(result, isTrue);
      expect(provider.clients, isEmpty);
      verify(() => mockRepository.deleteClient(clientId)).called(1);
    });

    test('should handle delete client error', () async {
      // Arrange
      const clientId = 1;
      final exception = Exception('Delete failed');
      when(() => mockRepository.deleteClient(clientId)).thenThrow(exception);

      // Act
      final result = await provider.deleteClient(clientId);

      // Assert
      expect(result, isFalse);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Delete failed'));
    });

    test('should return client by id when found', () {
      // Arrange
      provider.clients.addAll(TestClients.clientsList);

      // Act
      final result = provider.getClientById(1);

      // Assert
      expect(result, equals(TestClients.testClient1));
    });

    test('should return null when client by id not found', () {
      // Arrange
      provider.clients.addAll(TestClients.clientsList);

      // Act
      final result = provider.getClientById(999);

      // Assert
      expect(result, isNull);
    });

    test('should sort clients by creation date descending', () async {
      // Arrange
      final unsortedClients = [
        TestClients.testClient2, // created 2024-01-02
        TestClients.testClient1, // created 2024-01-01
      ];
      when(() => mockRepository.getClients())
          .thenAnswer((_) async => unsortedClients);

      // Act
      await provider.loadClients();

      // Assert
      expect(provider.clients.length, equals(2));
      expect(provider.clients[0].id, equals(2)); // Newer client first
      expect(provider.clients[1].id, equals(1)); // Older client second
    });
  });
}