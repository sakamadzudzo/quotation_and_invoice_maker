import '../models/company.dart';

/// Abstract interface for company data operations.
///
/// This interface defines the contract for company-related data access operations,
/// separating business logic from data persistence concerns.
abstract class ICompanyRepository {
  /// Retrieves all companies from the data source.
  ///
  /// Returns a list of companies sorted by creation date (newest first).
  /// Throws [RepositoryException] if the operation fails.
  Future<List<Company>> getCompanies();

  /// Retrieves a specific company by its ID.
  ///
  /// [id] - The unique identifier of the company
  /// Returns the company if found, null otherwise.
  /// Throws [RepositoryException] if the operation fails.
  Future<Company?> getCompanyById(int id);

  /// Inserts a new company into the data source.
  ///
  /// [company] - The company to insert
  /// Returns the ID of the newly inserted company.
  /// Throws [RepositoryException] if the operation fails.
  Future<int> insertCompany(Company company);

  /// Updates an existing company in the data source.
  ///
  /// [company] - The company to update (must have a valid ID)
  /// Returns the number of rows affected.
  /// Throws [RepositoryException] if the operation fails.
  Future<int> updateCompany(Company company);

  /// Deletes a company from the data source.
  ///
  /// [id] - The unique identifier of the company to delete
  /// Returns the number of rows affected.
  /// Throws [RepositoryException] if the operation fails.
  Future<int> deleteCompany(int id);
}