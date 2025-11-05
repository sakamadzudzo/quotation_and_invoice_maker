import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/constants.dart';
import '../models/company.dart';
import '../models/client.dart';
import '../models/tax_name.dart';
import '../models/quotation.dart';
import '../models/invoice.dart';
import '../models/payment.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.databaseName);
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    // For now, we'll drop and recreate tables to ensure clean schema
    if (oldVersion < newVersion) {
      await _recreateTables(db);
    }
  }

  Future<void> _recreateTables(Database db) async {
    // Drop existing tables
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.tablePayments}');
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.tableInvoices}');
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.tableQuotations}');
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.tableTaxNames}');
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.tableClients}');
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.tableCompanies}');

    // Recreate tables with current schema
    await _createTables(db);
    await _insertDefaultData(db);
  }

  Future<void> _createTables(Database db) async {
    // Companies table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCompanies} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        bank_name TEXT,
        bank_branch TEXT,
        account_number TEXT,
        currency TEXT DEFAULT 'USD',
        terms TEXT,
        disclaimer TEXT,
        logo_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Clients table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableClients} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        tin_number TEXT,
        vat_number TEXT,
        other_info TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tax names table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableTaxNames} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Quotations table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableQuotations} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER NOT NULL,
        client_id INTEGER NOT NULL,
        items TEXT NOT NULL,
        total_amount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'draft',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (company_id) REFERENCES ${AppConstants.tableCompanies} (id),
        FOREIGN KEY (client_id) REFERENCES ${AppConstants.tableClients} (id)
      )
    ''');

    // Invoices table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableInvoices} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quotation_id INTEGER,
        company_id INTEGER NOT NULL,
        client_id INTEGER NOT NULL,
        items TEXT NOT NULL,
        total_amount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'unpaid',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (quotation_id) REFERENCES ${AppConstants.tableQuotations} (id),
        FOREIGN KEY (company_id) REFERENCES ${AppConstants.tableCompanies} (id),
        FOREIGN KEY (client_id) REFERENCES ${AppConstants.tableClients} (id)
      )
    ''');

    // Payments table
    await db.execute('''
      CREATE TABLE ${AppConstants.tablePayments} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES ${AppConstants.tableInvoices} (id)
      )
    ''');
  }

  Future<void> _insertDefaultData(Database db) async {
    // Insert default tax names
    for (String taxName in AppConstants.defaultTaxNames) {
      await db.insert(AppConstants.tableTaxNames, {
        'name': taxName,
        'is_custom': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Company CRUD operations
  Future<int> insertCompany(Company company) async {
    final db = await database;
    return await db.insert(AppConstants.tableCompanies, company.toMap());
  }

  Future<List<Company>> getCompanies() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.tableCompanies);
    return List.generate(maps.length, (i) => Company.fromMap(maps[i]));
  }

  Future<int> updateCompany(Company company) async {
    final db = await database;
    return await db.update(
      AppConstants.tableCompanies,
      company.toMap(),
      where: 'id = ?',
      whereArgs: [company.id],
    );
  }

  Future<int> deleteCompany(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableCompanies,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Client CRUD operations
  Future<int> insertClient(Client client) async {
    final db = await database;
    return await db.insert(AppConstants.tableClients, client.toMap());
  }

  Future<List<Client>> getClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.tableClients);
    return List.generate(maps.length, (i) => Client.fromMap(maps[i]));
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    return await db.update(
      AppConstants.tableClients,
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableClients,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteQuotation(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableQuotations,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Tax name operations
  Future<List<TaxName>> getTaxNames() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.tableTaxNames);
    return List.generate(maps.length, (i) => TaxName.fromMap(maps[i]));
  }

  Future<int> insertTaxName(TaxName taxName) async {
    final db = await database;
    return await db.insert(AppConstants.tableTaxNames, taxName.toMap());
  }

  // Quotation operations
  Future<int> insertQuotation(Quotation quotation) async {
    final db = await database;
    return await db.insert(AppConstants.tableQuotations, quotation.toMap());
  }

  Future<List<Quotation>> getQuotations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.tableQuotations);
    return List.generate(maps.length, (i) => Quotation.fromMap(maps[i]));
  }

  Future<int> updateQuotation(Quotation quotation) async {
    final db = await database;
    return await db.update(
      AppConstants.tableQuotations,
      quotation.toMap(),
      where: 'id = ?',
      whereArgs: [quotation.id],
    );
  }

  // Invoice operations
  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;
    return await db.insert(AppConstants.tableInvoices, invoice.toMap());
  }

  Future<List<Invoice>> getInvoices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.tableInvoices);
    return List.generate(maps.length, (i) => Invoice.fromMap(maps[i]));
  }

  Future<int> updateInvoice(Invoice invoice) async {
    final db = await database;
    return await db.update(
      AppConstants.tableInvoices,
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

  // Payment operations
  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return await db.insert(AppConstants.tablePayments, payment.toMap());
  }

  Future<List<Payment>> getPaymentsByInvoice(int invoiceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tablePayments,
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await database;
    return await db.update(
      AppConstants.tablePayments,
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deletePayment(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tablePayments,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTaxName(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableTaxNames,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}