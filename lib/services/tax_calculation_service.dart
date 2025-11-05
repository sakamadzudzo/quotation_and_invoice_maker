import '../../models/quotation_item.dart';
import '../../models/tax_name.dart';

class TaxCalculationService {
  // Parse tax percentage from tax name (e.g., "VAT 15%" -> 15.0)
  static double parseTaxPercentage(String taxName) {
    final RegExp regex = RegExp(r'(\d+(?:\.\d+)?)%');
    final match = regex.firstMatch(taxName);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }
    return 0.0;
  }

  // Calculate tax amount for a single item
  static double calculateItemTax(QuotationItem item, String taxName) {
    final taxPercentage = parseTaxPercentage(taxName);
    final subtotal = item.quantity * item.unitPrice;
    return subtotal * (taxPercentage / 100);
  }

  // Calculate line total including tax
  static double calculateLineTotal(QuotationItem item, String taxName) {
    final subtotal = item.quantity * item.unitPrice;
    final taxAmount = calculateItemTax(item, taxName);
    return subtotal + taxAmount;
  }

  // Calculate total tax for a list of items
  static double calculateTotalTax(List<QuotationItem> items, List<TaxName> taxNames) {
    double totalTax = 0.0;

    for (final item in items) {
      final taxName = taxNames.where((tax) => tax.id == item.taxId).firstOrNull;
      if (taxName != null) {
        totalTax += calculateItemTax(item, taxName.name);
      }
    }

    return totalTax;
  }

  // Calculate subtotal (before tax) for a list of items
  static double calculateSubtotal(List<QuotationItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
  }

  // Calculate grand total (including tax) for a list of items
  static double calculateGrandTotal(List<QuotationItem> items, List<TaxName> taxNames) {
    final subtotal = calculateSubtotal(items);
    final totalTax = calculateTotalTax(items, taxNames);
    return subtotal + totalTax;
  }

  // Update line totals for all items in a quotation/invoice
  static List<QuotationItem> updateLineTotals(List<QuotationItem> items, List<TaxName> taxNames) {
    return items.map((item) {
      final taxName = taxNames.where((tax) => tax.id == item.taxId).firstOrNull;
      if (taxName != null) {
        final newLineTotal = calculateLineTotal(item, taxName.name);
        return item.copyWith(lineTotal: newLineTotal);
      }
      return item;
    }).toList();
  }

  // Get tax breakdown for display
  static Map<String, double> getTaxBreakdown(List<QuotationItem> items, List<TaxName> taxNames) {
    final breakdown = <String, double>{};

    for (final item in items) {
      final taxName = taxNames.where((tax) => tax.id == item.taxId).firstOrNull;
      if (taxName != null) {
        final taxAmount = calculateItemTax(item, taxName.name);
        breakdown[taxName.name] = (breakdown[taxName.name] ?? 0.0) + taxAmount;
      }
    }

    return breakdown;
  }

  // Validate tax calculation consistency
  static bool validateTaxCalculations(List<QuotationItem> items, List<TaxName> taxNames, double expectedTotal) {
    final calculatedTotal = calculateGrandTotal(items, taxNames);
    const tolerance = 0.01; // Allow for small floating point differences
    return (calculatedTotal - expectedTotal).abs() < tolerance;
  }
}