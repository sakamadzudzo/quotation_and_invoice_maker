import '../../models/company.dart';
import '../../models/client.dart';
import '../../models/quotation.dart';
import '../../models/invoice.dart';
import '../../models/payment.dart';
import '../../models/tax_name.dart';

class ValidationService {
  // Email validation regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );

  // Phone validation regex (basic international format)
  static final RegExp _phoneRegex = RegExp(
    r'^\+?[\d\s\-\(\)]{10,15}$',
  );

  // File size limits
  static const int maxLogoSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxStorageQuotaBytes = 100 * 1024 * 1024; // 100MB

  // Supported image formats
  static const List<String> supportedImageFormats = ['png', 'jpg', 'jpeg'];

  // Company validation
  static String? validateCompany(Company company) {
    if (company.name.trim().isEmpty) {
      return 'Company name is required';
    }
    if (company.name.trim().length < 2) {
      return 'Company name must be at least 2 characters';
    }
    if (company.address.trim().isEmpty) {
      return 'Company address is required';
    }
    if (company.phone.trim().isEmpty) {
      return 'Company phone is required';
    }
    if (!_phoneRegex.hasMatch(company.phone)) {
      return 'Please enter a valid phone number';
    }
    if (company.email.trim().isEmpty) {
      return 'Company email is required';
    }
    if (!_emailRegex.hasMatch(company.email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Client validation
  static String? validateClient(Client client) {
    if (client.name.trim().isEmpty) {
      return 'Client name is required';
    }
    if (client.name.trim().length < 2) {
      return 'Client name must be at least 2 characters';
    }
    if (client.address.trim().isEmpty) {
      return 'Client address is required';
    }
    if (client.phone.trim().isEmpty) {
      return 'Client phone is required';
    }
    if (!_phoneRegex.hasMatch(client.phone)) {
      return 'Please enter a valid phone number';
    }
    if (client.email.trim().isEmpty) {
      return 'Client email is required';
    }
    if (!_emailRegex.hasMatch(client.email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Quotation validation
  static String? validateQuotation(Quotation quotation) {
    if (quotation.companyId <= 0) {
      return 'Please select a company';
    }
    if (quotation.clientId <= 0) {
      return 'Please select a client';
    }
    if (quotation.items.isEmpty) {
      return 'Quotation must have at least one item';
    }
    if (quotation.totalAmount < 0) {
      return 'Total amount cannot be negative';
    }

    // Validate each item
    for (var item in quotation.items) {
      final itemError = validateQuotationItem(item);
      if (itemError != null) {
        return itemError;
      }
    }

    return null;
  }

  // Quotation item validation
  static String? validateQuotationItem(dynamic item) {
    if (item.productName.trim().isEmpty) {
      return 'Product name is required';
    }
    if (item.quantity <= 0) {
      return 'Quantity must be greater than 0';
    }
    if (item.unitPrice < 0) {
      return 'Unit price cannot be negative';
    }
    if (item.lineTotal < 0) {
      return 'Line total cannot be negative';
    }
    if (item.taxId <= 0) {
      return 'Please select a tax rate';
    }
    return null;
  }

  // Invoice validation
  static String? validateInvoice(Invoice invoice) {
    if (invoice.companyId <= 0) {
      return 'Please select a company';
    }
    if (invoice.clientId <= 0) {
      return 'Please select a client';
    }
    if (invoice.items.isEmpty) {
      return 'Invoice must have at least one item';
    }
    if (invoice.totalAmount < 0) {
      return 'Total amount cannot be negative';
    }

    // Validate each item
    for (var item in invoice.items) {
      final itemError = validateQuotationItem(item);
      if (itemError != null) {
        return itemError;
      }
    }

    return null;
  }

  // Payment validation
  static String? validatePayment(Payment payment, double invoiceTotal, double existingPayments) {
    if (payment.amount <= 0) {
      return 'Payment amount must be greater than 0';
    }
    if (payment.amount > (invoiceTotal - existingPayments)) {
      return 'Payment amount cannot exceed remaining balance';
    }
    if (payment.paymentDate.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return 'Payment date cannot be in the future';
    }
    return null;
  }

  // Tax name validation
  static String? validateTaxName(TaxName taxName, {List<TaxName>? existingTaxes}) {
    if (taxName.name.trim().isEmpty) {
      return 'Tax name is required';
    }
    if (taxName.name.trim().length < 2) {
      return 'Tax name must be at least 2 characters';
    }

    // Check for duplicates
    if (existingTaxes != null) {
      final duplicate = existingTaxes.any(
        (existing) => existing.name.toLowerCase() == taxName.name.toLowerCase() &&
                      existing.id != taxName.id
      );
      if (duplicate) {
        return 'Tax name already exists';
      }
    }

    return null;
  }

  // File validation
  static String? validateLogoFile(String filePath, int fileSize) {
    if (fileSize > maxLogoSizeBytes) {
      return 'Logo file size must be less than 5MB';
    }

    final extension = filePath.split('.').last.toLowerCase();
    if (!supportedImageFormats.contains(extension)) {
      return 'Logo must be a PNG, JPG, or JPEG file';
    }

    return null;
  }

  // Business logic validations
  static String? canEditQuotation(Quotation quotation, {Invoice? relatedInvoice}) {
    if (quotation.status == 'archived') {
      return 'Cannot edit archived quotations';
    }
    if (relatedInvoice != null) {
      return 'Cannot edit quotations that have been converted to invoices';
    }
    return null;
  }

  static String? canDeleteCompany(int companyId, int quotationCount, int invoiceCount) {
    if (quotationCount > 0 || invoiceCount > 0) {
      return 'Cannot delete company with existing quotations or invoices. Please archive or reassign them first.';
    }
    return null;
  }

  static String? canDeleteClient(int clientId, int quotationCount, int invoiceCount) {
    if (quotationCount > 0 || invoiceCount > 0) {
      return 'Cannot delete client with existing quotations or invoices. Please archive or reassign them first.';
    }
    return null;
  }

  static String? canDeleteTaxName(int taxId, int usageCount) {
    if (usageCount > 0) {
      return 'Cannot delete tax rate that is currently used in quotations or invoices';
    }
    return null;
  }

  // Storage validation
  static String? validateStorageQuota(int currentUsage) {
    if (currentUsage > maxStorageQuotaBytes) {
      return 'Storage quota exceeded. Please delete some files or upgrade storage.';
    }
    return null;
  }

  // Date validation
  static String? validateDateNotInFuture(DateTime date, String fieldName) {
    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return '$fieldName cannot be in the future';
    }
    return null;
  }

  // Amount validation
  static String? validatePositiveAmount(double amount, String fieldName) {
    if (amount <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  static String? validateNonNegativeAmount(double amount, String fieldName) {
    if (amount < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }
}