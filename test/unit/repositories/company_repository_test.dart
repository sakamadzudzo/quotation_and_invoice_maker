import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quotation_invoice_maker/core/exceptions/app_exceptions.dart';
import 'package:quotation_invoice_maker/core/logging/i_logger.dart';
import 'package:quotation_invoice_maker/models/company.dart';
import 'package:quotation_invoice_maker/repositories/company_repository.dart';
import 'package:quotation_invoice_maker/services/database_service.dart';

import '../../fixtures/test_companies.dart';
import '../../mocks/mock_database_service.dart';
import '../../mocks/mock_logger.dart';

void main() {
  late CompanyRepository repository;
  late MockDatabaseService mockDatabaseService;
  late MockLogger mockLogger;

  setUp(() {
    mockDatabaseService = MockDatabaseService();
    mockLogger = MockLogger();
    repository = CompanyRepository(mockDatabaseService);
  });

  group('CompanyRepository', () {
    test('should return list of companies when getCompanies succeeds', () async {
      // Arrange
      when(() => mockDatabaseService.getCompanies())
          .thenAnswer((_) async => TestCompanies.companiesList);

      // Act
      final result = await repository.getCompanies();

      // Assert
      expect(result, equals(TestCompanies.companiesList));
      verify(() => mockDatabaseService.getCompanies()).called(1);
    });

    test('should throw RepositoryException when getCompanies fails', () async {
      // Arrange
      final exception = Exception('Database error');
      when(() => mockDatabaseService.getCompanies()).thenThrow(exception);

      // Act & Assert
      expect(
        () => repository.getCompanies(),
        throwsA(isA<RepositoryException>()),
      );
      verify(() => mockDatabaseService.getCompanies()).called(1);
    });

    test('should return company when getCompanyById finds existing company', () async {
      // Arrange
      when(() => mockDatabaseService.getCompanies())
          .thenAnswer((_) async => TestCompanies.companiesList);

      // Act
      final result = await repository.getCompanyById(1);

      // Assert
      expect(result, equals(TestCompanies.testCompany1));
      verify(() => mockDatabaseService.getCompanies()).called(1);
    });

    test('should return null when getCompanyById does not find company', () async {
      // Arrange
      when(() => mockDatabaseService.getCompanies())
          .thenAnswer((_) async => TestCompanies.companiesList);

      // Act
      final result = await repository.getCompanyById(999);

      // Assert
      expect(result, isNull);
      verify(() => mockDatabaseService.getCompanies()).called(1);
    });

    test('should throw RepositoryException when getCompanyById fails', () async {
      // Arrange
      final exception = Exception('Database connection failed');
      when(() => mockDatabaseService.getCompanies()).thenThrow(exception);

      // Act & Assert
      expect(
        () => repository.getCompanyById(1),
        throwsA(isA<RepositoryException>()),
      );
      verify(() => mockDatabaseService.getCompanies()).called(1);
    });

    test('should return inserted company id when insertCompany succeeds', () async {
      // Arrange
      const expectedId = 3;
      when(() => mockDatabaseService.insertCompany(TestCompanies.newCompany))
          .thenAnswer((_) async => expectedId);

      // Act
      final result = await repository.insertCompany(TestCompanies.newCompany);

      // Assert
      expect(result, equals(expectedId));
      verify(() => mockDatabaseService.insertCompany(TestCompanies.newCompany)).called(1);
    });

    test('should throw RepositoryException when insertCompany fails', () async {
      // Arrange
      final exception = Exception('Insert failed');
      when(() => mockDatabaseService.insertCompany(TestCompanies.newCompany))
          .thenThrow(exception);

      // Act & Assert
      expect(
        () => repository.insertCompany(TestCompanies.newCompany),
        throwsA(isA<RepositoryException>()),
      );
      verify(() => mockDatabaseService.insertCompany(TestCompanies.newCompany)).called(1);
    });

    test('should return affected rows when updateCompany succeeds', () async {
      // Arrange
      const expectedRows = 1;
      when(() => mockDatabaseService.updateCompany(TestCompanies.testCompany1))
          .thenAnswer((_) async => expectedRows);

      // Act
      final result = await repository.updateCompany(TestCompanies.testCompany1);

      // Assert
      expect(result, equals(expectedRows));
      verify(() => mockDatabaseService.updateCompany(TestCompanies.testCompany1)).called(1);
    });

    test('should throw RepositoryException when updateCompany fails', () async {
      // Arrange
      final exception = Exception('Update failed');
      when(() => mockDatabaseService.updateCompany(TestCompanies.testCompany1))
          .thenThrow(exception);

      // Act & Assert
      expect(
        () => repository.updateCompany(TestCompanies.testCompany1),
        throwsA(isA<RepositoryException>()),
      );
      verify(() => mockDatabaseService.updateCompany(TestCompanies.testCompany1)).called(1);
    });

    test('should return affected rows when deleteCompany succeeds', () async {
      // Arrange
      const expectedRows = 1;
      const companyId = 1;
      when(() => mockDatabaseService.deleteCompany(companyId))
          .thenAnswer((_) async => expectedRows);

      // Act
      final result = await repository.deleteCompany(companyId);

      // Assert
      expect(result, equals(expectedRows));
      verify(() => mockDatabaseService.deleteCompany(companyId)).called(1);
    });

    test('should throw RepositoryException when deleteCompany fails', () async {
      // Arrange
      final exception = Exception('Delete failed');
      const companyId = 1;
      when(() => mockDatabaseService.deleteCompany(companyId)).thenThrow(exception);

      // Act & Assert
      expect(
        () => repository.deleteCompany(companyId),
        throwsA(isA<RepositoryException>()),
      );
      verify(() => mockDatabaseService.deleteCompany(companyId)).called(1);
    });
  });
}