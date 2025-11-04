import 'package:flutter/foundation.dart';
import '../models/invoice.dart';
import '../models/payment.dart';
import '../services/database_service.dart';

class InvoiceProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Invoice> _invoices = [];
  bool _isLoading = false;

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;

  Future<void> loadInvoices() async {
    _isLoading = true;
    notifyListeners();

    try {
      _invoices = await _databaseService.getInvoices();
      // Sort by creation date, newest first
      _invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error loading invoices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addInvoice(Invoice invoice) async {
    try {
      final id = await _databaseService.insertInvoice(invoice);
      final newInvoice = invoice.copyWith(id: id);
      _invoices.add(newInvoice);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding invoice: $e');
      return false;
    }
  }

  Future<bool> updateInvoice(Invoice invoice) async {
    try {
      await _databaseService.updateInvoice(invoice);
      final index = _invoices.indexWhere((i) => i.id == invoice.id);
      if (index != -1) {
        _invoices[index] = invoice;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating invoice: $e');
      return false;
    }
  }

  Invoice? getInvoiceById(int id) {
    return _invoices.where((i) => i.id == id).firstOrNull;
  }

  List<Invoice> getInvoicesByCompany(int companyId) {
    return _invoices.where((i) => i.companyId == companyId).toList();
  }

  List<Invoice> getInvoicesByClient(int clientId) {
    return _invoices.where((i) => i.clientId == clientId).toList();
  }

  Invoice? getInvoiceByQuotationId(int quotationId) {
    return _invoices.where((i) => i.quotationId == quotationId).firstOrNull;
  }

  // Payment operations
  Future<List<Payment>> getPaymentsByInvoice(int invoiceId) async {
    try {
      return await _databaseService.getPaymentsByInvoice(invoiceId);
    } catch (e) {
      debugPrint('Error loading payments: $e');
      return [];
    }
  }

  Future<bool> addPayment(Payment payment) async {
    try {
      await _databaseService.insertPayment(payment);
      // Update invoice status if needed
      await _updateInvoiceStatus(payment.invoiceId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding payment: $e');
      return false;
    }
  }

  Future<bool> updatePayment(Payment payment) async {
    try {
      await _databaseService.updatePayment(payment);
      await _updateInvoiceStatus(payment.invoiceId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating payment: $e');
      return false;
    }
  }

  Future<bool> deletePayment(int id, int invoiceId) async {
    try {
      await _databaseService.deletePayment(id);
      await _updateInvoiceStatus(invoiceId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting payment: $e');
      return false;
    }
  }

  Future<void> _updateInvoiceStatus(int invoiceId) async {
    final payments = await getPaymentsByInvoice(invoiceId);
    final invoice = getInvoiceById(invoiceId);
    
    if (invoice != null) {
      final totalPaid = payments.fold<double>(0, (sum, payment) => sum + payment.amount);
      String newStatus;
      
      if (totalPaid == 0) {
        newStatus = 'unpaid';
      } else if (totalPaid >= invoice.totalAmount) {
        newStatus = 'paid';
      } else {
        newStatus = 'partially_paid';
      }
      
      if (newStatus != invoice.status) {
        final updatedInvoice = invoice.copyWith(status: newStatus);
        await updateInvoice(updatedInvoice);
      }
    }
  }
}