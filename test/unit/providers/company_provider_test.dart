import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quotation_invoice_maker/core/providers/base_provider.dart';
import 'package:quotation_invoice_maker/models/company.dart';
import 'package:quotation_invoice_maker/providers/company_provider.dart';

import '../../fixtures/test_companies.dart';
import '../../mocks/mock_company_repository.dart';
import '../../mocks/mock_cache_manager.dart';

void main() {
  late CompanyProvider provider;
  late MockCompanyRepository mockRepository;
  late MockCacheManager mockCacheManager;

  setUp(() {
    mockRepository = MockCompanyRepository();
    mockCacheManager = MockCacheManager();
    provider = CompanyProvider(mockRepository, mockCacheManager);

    // Setup default mock behaviors
    when(() => mockCacheManager.get<List<Company>>(any()))
        .thenAnswer((_) async => null);
    when(() => mockCacheManager.set(any(), any(), ttl: any(named: 'ttl')))
        .thenAnswer((_) => Future.value());
    when(() => mockCacheManager.remove(any()))
        .thenAnswer((_) => Future.value());
  });

  tearDown(() {
    provider.dispose();
  });

  group('CompanyProvider', () {
    test('should load companies successfully', () async {
      // Arrange
      when(() => mockRepository.getCompanies())
          .thenAnswer((_) async => TestCompanies.companiesList);

      // Act
      await provider.loadCompanies();

      // Assert
      expect(provider.companies, equals(TestCompanies.companiesList));
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      verify(() => mockRepository.getCompanies()).called(1);
      verify(() => mockCacheManager.set('companies_list', TestCompanies.companiesList, ttl: any(named: 'ttl'))).called(1);
    });

    test('should handle load companies error', () async {
      // Arrange
      final exception = Exception('Database error');
      when(() => mockRepository.getCompanies()).thenThrow(exception);

      // Act & Assert
      expect(
        () => provider.loadCompanies(),
        throwsA(isA<Exception>()),
      );
      // Note: error is set but exception is rethrown, so UI layer handles it
    });

    test('should add company successfully', () async {
      // Arrange
      when(() => mockRepository.insertCompany(TestCompanies.newCompany))
          .thenAnswer((_) async => 3);

      // Act
      final result = await provider.addCompany(TestCompanies.newCompany);

      // Assert
      expect(result, isTrue);
      expect(provider.companies.length, equals(1));
      expect(provider.companies.first.id, equals(3));
      expect(provider.companies.first.name, equals(TestCompanies.newCompany.name));
      verify(() => mockRepository.insertCompany(TestCompanies.newCompany)).called(1);
      verify(() => mockCacheManager.remove('companies_list')).called(1);
    });

    test('should handle add company error', () async {
      // Arrange
      final exception = Exception('Insert failed');
      when(() => mockRepository.insertCompany(TestCompanies.newCompany))
          .thenThrow(exception);

      // Act
      final result = await provider.addCompany(TestCompanies.newCompany);

      // Assert
      expect(result, isFalse);
      expect(provider.companies, isEmpty);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Insert failed'));
    });

    test('should update company successfully', () async {
      // Arrange
      final updatedCompany = TestCompanies.testCompany1.copyWith(name: 'Updated Name');
      when(() => mockRepository.updateCompany(updatedCompany))
          .thenAnswer((_) async => 1);

      // First add the company to the provider
      provider.companies.add(TestCompanies.testCompany1);

      // Act
      final result = await provider.updateCompany(updatedCompany);

      // Assert
      expect(result, isTrue);
      expect(provider.companies.length, equals(1));
      expect(provider.companies.first.name, equals('Updated Name'));
      verify(() => mockRepository.updateCompany(updatedCompany)).called(1);
      verify(() => mockCacheManager.remove('companies_list')).called(1);
    });

    test('should handle update company error', () async {
      // Arrange
      final updatedCompany = TestCompanies.testCompany1.copyWith(name: 'Updated Name');
      final exception = Exception('Update failed');
      when(() => mockRepository.updateCompany(updatedCompany)).thenThrow(exception);

      // Act
      final result = await provider.updateCompany(updatedCompany);

      // Assert
      expect(result, isFalse);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Update failed'));
    });

    test('should delete company successfully', () async {
      // Arrange
      const companyId = 1;
      when(() => mockRepository.deleteCompany(companyId))
          .thenAnswer((_) async => 1);
      when(() => mockCacheManager.remove(any()))
          .thenAnswer((_) async => {});

      // Add company to provider first
      provider.companies.add(TestCompanies.testCompany1);

      // Act
      final result = await provider.deleteCompany(companyId);

      // Assert
      expect(result, isTrue);
      expect(provider.companies, isEmpty);
      verify(() => mockRepository.deleteCompany(companyId)).called(1);
      verify(() => mockCacheManager.remove('companies_list')).called(1);
    });

    test('should handle delete company error', () async {
      // Arrange
      const companyId = 1;
      final exception = Exception('Delete failed');
      when(() => mockRepository.deleteCompany(companyId)).thenThrow(exception);

      // Act
      final result = await provider.deleteCompany(companyId);

      // Assert
      expect(result, isFalse);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Delete failed'));
    });

    test('should return company by id when found', () {
      // Arrange
      provider.companies.addAll(TestCompanies.companiesList);

      // Act
      final result = provider.getCompanyById(1);

      // Assert
      expect(result, equals(TestCompanies.testCompany1));
    });

    test('should return null when company by id not found', () {
      // Arrange
      provider.companies.addAll(TestCompanies.companiesList);

      // Act
      final result = provider.getCompanyById(999);

      // Assert
      expect(result, isNull);
    });

    test('should sort companies by creation date descending', () async {
      // Arrange
      final unsortedCompanies = [
        TestCompanies.testCompany2, // created 2024-01-02
        TestCompanies.testCompany1, // created 2024-01-01
      ];
      when(() => mockCacheManager.get<List<Company>>(any()))
          .thenAnswer((_) async => null); // Cache miss
      when(() => mockRepository.getCompanies())
          .thenAnswer((_) async => unsortedCompanies);
      when(() => mockCacheManager.set(any(), any(), ttl: any(named: 'ttl')))
          .thenAnswer((_) async => {});

      // Act
      await provider.loadCompanies();

      // Assert
      expect(provider.companies.length, equals(2));
      expect(provider.companies[0].id, equals(2)); // Newer company first
      expect(provider.companies[1].id, equals(1)); // Older company second
    });
  });
}