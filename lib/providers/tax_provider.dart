import 'package:flutter/foundation.dart';
import '../models/tax_name.dart';
import '../services/database_service.dart';

class TaxProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<TaxName> _taxNames = [];
  bool _isLoading = false;

  List<TaxName> get taxNames => _taxNames;
  bool get isLoading => _isLoading;

  Future<void> loadTaxNames() async {
    _isLoading = true;
    notifyListeners();

    try {
      _taxNames = await _databaseService.getTaxNames();
    } catch (e) {
      debugPrint('Error loading tax names: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTaxName(TaxName taxName) async {
    // Check for duplicate names
    if (_taxNames.any((t) => t.name.toLowerCase() == taxName.name.toLowerCase())) {
      debugPrint('Tax name already exists');
      return false;
    }

    try {
      final id = await _databaseService.insertTaxName(taxName);
      final newTaxName = taxName.copyWith(id: id);
      _taxNames.add(newTaxName);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding tax name: $e');
      return false;
    }
  }

  Future<bool> deleteTaxName(int id) async {
    // Check if tax name is being used
    final taxName = _taxNames.where((t) => t.id == id).firstOrNull;
    if (taxName != null && await _isTaxNameInUse(taxName.name)) {
      debugPrint('Cannot delete tax name that is in use');
      return false;
    }

    try {
      await _databaseService.deleteTaxName(id);
      _taxNames.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting tax name: $e');
      return false;
    }
  }

  Future<bool> _isTaxNameInUse(String taxName) async {
    // This would need to be implemented to check quotations and invoices
    // For now, return false - in a real implementation, you'd query the database
    return false;
  }

  TaxName? getTaxNameById(int id) {
    return _taxNames.where((t) => t.id == id).firstOrNull;
  }

  TaxName? getTaxNameByName(String name) {
    return _taxNames.where((t) => t.name == name).firstOrNull;
  }
}