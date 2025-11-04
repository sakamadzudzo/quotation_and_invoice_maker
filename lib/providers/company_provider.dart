import 'package:flutter/foundation.dart';
import '../models/company.dart';
import '../services/database_service.dart';

class CompanyProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Company> _companies = [];
  bool _isLoading = false;

  List<Company> get companies => _companies;
  bool get isLoading => _isLoading;

  Future<void> loadCompanies() async {
    _isLoading = true;
    notifyListeners();

    try {
      _companies = await _databaseService.getCompanies();
      // Sort by creation date, newest first
      _companies.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error loading companies: $e');
      // Error handling is done at the UI layer
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCompany(Company company) async {
    try {
      final id = await _databaseService.insertCompany(company);
      final newCompany = company.copyWith(id: id);
      _companies.add(newCompany);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding company: $e');
      return false;
    }
  }

  Future<bool> updateCompany(Company company) async {
    try {
      await _databaseService.updateCompany(company);
      final index = _companies.indexWhere((c) => c.id == company.id);
      if (index != -1) {
        _companies[index] = company;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating company: $e');
      return false;
    }
  }

  Future<bool> deleteCompany(int id) async {
    try {
      await _databaseService.deleteCompany(id);
      _companies.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting company: $e');
      return false;
    }
  }

  Company? getCompanyById(int id) {
    return _companies.where((c) => c.id == id).firstOrNull;
  }
}