class AppConstants {
  // Database
  static const String databaseName = 'quotation_invoice.db';
  static const int databaseVersion = 3;

  // Table names
  static const String tableCompanies = 'companies';
  static const String tableClients = 'clients';
  static const String tableTaxNames = 'tax_names';
  static const String tableQuotations = 'quotations';
  static const String tableInvoices = 'invoices';
  static const String tablePayments = 'payments';

  // Status values
  static const String statusDraft = 'draft';
  static const String statusActive = 'active';
  static const String statusArchived = 'archived';
  static const String statusUnpaid = 'unpaid';
  static const String statusPartiallyPaid = 'partially_paid';
  static const String statusPaid = 'paid';

  // File paths
  static const String logosDirectory = 'logos';
  static const String backupsDirectory = 'backups';

  // Default tax names
  static const List<String> defaultTaxNames = [
    'VAT 15%',
    'GST 10%',
    'No Tax',
  ];
}