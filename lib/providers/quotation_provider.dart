import 'package:flutter/foundation.dart';
import '../models/quotation.dart';
import '../services/database_service.dart';

class QuotationProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Quotation> _quotations = [];
  bool _isLoading = false;

  List<Quotation> get quotations => _quotations;
  bool get isLoading => _isLoading;

  Future<void> loadQuotations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _quotations = await _databaseService.getQuotations();
      // Sort by creation date, newest first
      _quotations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error loading quotations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addQuotation(Quotation quotation) async {
    try {
      final id = await _databaseService.insertQuotation(quotation);
      final newQuotation = quotation.copyWith(id: id);
      _quotations.add(newQuotation);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding quotation: $e');
      return false;
    }
  }

  Future<bool> updateQuotation(Quotation quotation) async {
    // Prevent editing archived quotations
    if (quotation.status == 'archived') {
      debugPrint('Cannot edit archived quotation');
      return false;
    }

    try {
      await _databaseService.updateQuotation(quotation);
      final index = _quotations.indexWhere((q) => q.id == quotation.id);
      if (index != -1) {
        _quotations[index] = quotation;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating quotation: $e');
      return false;
    }
  }

  Quotation? getQuotationById(int id) {
    return _quotations.where((q) => q.id == id).firstOrNull;
  }

  List<Quotation> getQuotationsByCompany(int companyId) {
    return _quotations.where((q) => q.companyId == companyId).toList();
  }

  List<Quotation> getQuotationsByClient(int clientId) {
    return _quotations.where((q) => q.clientId == clientId).toList();
  }

  Future<bool> deleteQuotation(int id) async {
    try {
      await _databaseService.deleteQuotation(id);
      _quotations.removeWhere((q) => q.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting quotation: $e');
      return false;
    }
  }
}