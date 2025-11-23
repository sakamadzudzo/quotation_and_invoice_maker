import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quotation_invoice_maker/core/exceptions/app_exceptions.dart';
import 'package:quotation_invoice_maker/core/logging/i_logger.dart';
import 'package:quotation_invoice_maker/models/client.dart';
import 'package:quotation_invoice_maker/repositories/client_repository.dart';
import 'package:quotation_invoice_maker/services/database_service.dart';

import '../../fixtures/test_clients.dart';
import '../../mocks/mock_database_service.dart';
import '../../mocks/mock_logger.dart';

void main() {
  late ClientRepository repository;
  late MockDatabaseService mockDatabaseService;
  late MockLogger mockLogger;

  setUp(() {
    mockDatabaseService = MockDatabaseService();
    mockLogger = MockLogger();
    repository = ClientRepository(mockDatabaseService);
  });

  group('ClientRepository', () {
    test('should return list of clients when getClients succeeds', () async {
      // Arrange
      when(() => mockDatabaseService.getClients())
          .thenAnswer((_) async => TestClients.clientsList);

      // Act
      final result = await repository.getClients();

      // Assert
      expect(result, equals(TestClients.clientsList));
      verify(() => mockDatabaseService.getClients()).called(1);
    });

    test('should throw RepositoryException when getClients fails', () async {
      // Arrange
      final exception = Exception('Database error');
      when(() => mockDatabaseService.getClients()).thenThrow(exception);

      // Act & Assert
      expect(
        () => repository.getClients(),
        throwsA(isA<RepositoryException>()),
      );
      verify(() => mockDatabaseService.getClients()).called(1);
    });

    test('should return client when getClientById finds existing client', () async {
      // Arrange
      when(() => mockDatabaseService.getClients())
          .thenAnswer((_) async => TestClients.clientsList);

      // Act
      final result = await repository.getClientById(1);

      // Assert
      expect(result, equals(TestClients.testClient1));
      verify(() => mockDatabaseService.getClients()).called(1);
    });

    test('should return null when getClientById does not find client', () async {
      // Arrange
      when(() => mockDatabaseService.getClients())
          .thenAnswer((_) async => TestClients.clientsList);

      // Act
      final result = await repository.getClientById(999);

      // Assert
      expect(result, isNull);
      verify(() => mockDatabaseService.getClients()).called(1);
    });

    test('should throw RepositoryException when getClientById fails', () async {
      // Arrange
      final exception = Exception('Database connection failed');
      when(() => mockDatabaseService.getClients()).thenThrow(exception);

      // Act & Assert
      expect(
        () => repository.getClientById(1),
        throwsA(isA<RepositoryException>()),
      );
      verify(() => mockDatabaseService.getClients()).called(1);
    });

    test('should return inserted client id when insertClient succeeds', () async {
      // Arrange
      const expectedId = 3;
      when(() => mockDatabaseService.insertClient(TestClients.newClient))
          .thenAnswer((_) async => expectedId);

      // Act
      final result = await repository.insertClient(TestClients.newClient);

      // Assert
      expect(result, equals(expectedId));
      verify(() => mockDatabaseService.insertClient(TestClients.newClient)).called(1);
    });

    test('should throw RepositoryException when insertClient fails', () async {
      // Arrange
      final exception = Exception('Insert failed');
      when(() => mockDatabaseService.insertClient(TestClients.newClient))
          .thenThrow(exception);

      // Act & Assert
      expect(
        () => repository.insertClient(TestClients.newClient),
        throwsA(isA<RepositoryException>()),
      );
      verify(() => mockDatabaseService.insertClient(TestClients.newClient)).called(1);
    });

    test('should return affected rows when updateClient succeeds', () async {
      // Arrange
      const expectedRows = 1;
      when(() => mockDatabaseService.updateClient(TestClients.testClient1))
          .thenAnswer((_) async => expectedRows);

      // Act
      final result = await repository.updateClient(TestClients.testClient1);

      // Assert
      expect(result, equals(expectedRows));
      verify(() => mockDatabaseService.updateClient(TestClients.testClient1)).called(1);
    });

    test('should throw RepositoryException when updateClient fails', () async {
      // Arrange
      final exception = Exception('Update failed');
      when(() => mockDatabaseService.updateClient(TestClients.testClient1))
          .thenThrow(exception);

      // Act & Assert
      expect(
        () => repository.updateClient(TestClients.testClient1),
        throwsA(isA<RepositoryException>()),
      );
      verify(() => mockDatabaseService.updateClient(TestClients.testClient1)).called(1);
    });

    test('should return affected rows when deleteClient succeeds', () async {
      // Arrange
      const expectedRows = 1;
      const clientId = 1;
      when(() => mockDatabaseService.deleteClient(clientId))
          .thenAnswer((_) async => expectedRows);

      // Act
      final result = await repository.deleteClient(clientId);

      // Assert
      expect(result, equals(expectedRows));
      verify(() => mockDatabaseService.deleteClient(clientId)).called(1);
    });

    test('should throw RepositoryException when deleteClient fails', () async {
      // Arrange
      final exception = Exception('Delete failed');
      const clientId = 1;
      when(() => mockDatabaseService.deleteClient(clientId)).thenThrow(exception);

      // Act & Assert
      expect(
        () => repository.deleteClient(clientId),
        throwsA(isA<RepositoryException>()),
      );
      verify(() => mockDatabaseService.deleteClient(clientId)).called(1);
    });
  });
}