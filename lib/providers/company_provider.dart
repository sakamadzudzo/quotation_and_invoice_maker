import '../../core/providers/base_provider.dart';
import '../../core/cache/cache_manager.dart';
import '../../repositories/i_company_repository.dart';
import '../models/company.dart';

/// Provider for managing company-related state and operations.
///
/// This provider handles all company CRUD operations and maintains
/// the application state for company data with caching support.
class CompanyProvider extends BaseProvider {
  final ICompanyRepository _companyRepository;
  final CacheManager _cacheManager;
  List<Company> _companies = [];

  static const String _companiesCacheKey = 'companies_list';
  static const Duration _cacheDuration = Duration(hours: 1);

  CompanyProvider(this._companyRepository, this._cacheManager);

  /// List of all companies, sorted by creation date (newest first).
  List<Company> get companies => _companies;

  /// Loads all companies from cache or repository.
  ///
  /// Attempts to load from cache first for better performance.
  /// Falls back to repository if cache is empty or expired.
  /// Updates the internal company list and sorts by creation date.
  ///
  /// [forceRefresh] - If true, bypasses cache and loads from repository
  Future<void> loadCompanies({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      // Try to load from cache first
      final cachedCompanies = await _cacheManager.get<List<Company>>(_companiesCacheKey);
      if (cachedCompanies != null) {
        _companies = cachedCompanies;
        notifyListeners();
        return;
      }
    }

    await executeWithLoading(() async {
      _companies = await _companyRepository.getCompanies();
      _companies.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Cache the result for future use
      await _cacheManager.set(_companiesCacheKey, _companies, ttl: _cacheDuration);
    });
  }

  /// Adds a new company to the repository and local state.
  ///
  /// [company] - The company to add
  /// Returns true if successful, false otherwise.
  Future<bool> addCompany(Company company) async {
    final success = await executeOperation(() async {
      final id = await _companyRepository.insertCompany(company);
      final newCompany = company.copyWith(id: id);
      _companies.add(newCompany);
    });

    // Invalidate cache when data changes
    if (success) {
      await _cacheManager.remove(_companiesCacheKey);
    }

    return success;
  }

  /// Updates an existing company in the repository and local state.
  ///
  /// [company] - The company to update (must have a valid ID)
  /// Returns true if successful, false otherwise.
  Future<bool> updateCompany(Company company) async {
    final success = await executeOperation(() async {
      await _companyRepository.updateCompany(company);
      final index = _companies.indexWhere((c) => c.id == company.id);
      if (index != -1) {
        _companies[index] = company;
      }
    });

    // Invalidate cache when data changes
    if (success) {
      await _cacheManager.remove(_companiesCacheKey);
    }

    return success;
  }

  /// Deletes a company from the repository and local state.
  ///
  /// [id] - The ID of the company to delete
  /// Returns true if successful, false otherwise.
  Future<bool> deleteCompany(int id) async {
    final success = await executeOperation(() async {
      await _companyRepository.deleteCompany(id);
      _companies.removeWhere((c) => c.id == id);
    });

    // Invalidate cache when data changes
    if (success) {
      await _cacheManager.remove(_companiesCacheKey);
    }

    return success;
  }

  /// Retrieves a company by its ID from the local state.
  ///
  /// [id] - The ID of the company to retrieve
  /// Returns the company if found, null otherwise.
  Company? getCompanyById(int id) {
    return _companies.where((c) => c.id == id).firstOrNull;
  }
}