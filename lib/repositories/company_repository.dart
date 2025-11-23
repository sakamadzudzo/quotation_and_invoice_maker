import '../models/company.dart';
import '../services/database_service.dart';
import '../core/exceptions/app_exceptions.dart';
import 'i_company_repository.dart';

/// Concrete implementation of company data operations.
///
/// This repository handles all company-related database operations,
/// providing a clean abstraction over the data layer.
class CompanyRepository implements ICompanyRepository {
  final DatabaseService _databaseService;

  CompanyRepository(this._databaseService);

  @override
  Future<List<Company>> getCompanies() async {
    try {
      return await _databaseService.getCompanies();
    } catch (e) {
      throw RepositoryException('Failed to fetch companies', e);
    }
  }

  @override
  Future<Company?> getCompanyById(int id) async {
    try {
      final companies = await _databaseService.getCompanies();
      return companies.where((c) => c.id == id).firstOrNull;
    } catch (e) {
      throw RepositoryException('Failed to fetch company with id: $id', e);
    }
  }

  @override
  Future<int> insertCompany(Company company) async {
    try {
      return await _databaseService.insertCompany(company);
    } catch (e) {
      throw RepositoryException('Failed to insert company', e);
    }
  }

  @override
  Future<int> updateCompany(Company company) async {
    try {
      return await _databaseService.updateCompany(company);
    } catch (e) {
      throw RepositoryException('Failed to update company', e);
    }
  }

  @override
  Future<int> deleteCompany(int id) async {
    try {
      return await _databaseService.deleteCompany(id);
    } catch (e) {
      throw RepositoryException('Failed to delete company', e);
    }
  }
}