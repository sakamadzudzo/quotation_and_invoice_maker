import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'database_service.dart';
import '../models/company.dart';
import '../models/client.dart';
import '../models/quotation.dart';
import '../models/invoice.dart';
import '../models/payment.dart';
import '../models/tax_name.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  static BackupService get instance => _instance;

  BackupService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  drive.DriveApi? _driveApi;
  bool _isSignedIn = false;

  bool get isSignedIn => _isSignedIn;
  String? get userEmail => _googleSignIn.currentUser?.email;

  Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final authHeaders = await _googleSignIn.currentUser!.authHeaders;
        final authenticateClient = GoogleAuthClient(authHeaders);
        _driveApi = drive.DriveApi(authenticateClient);
        _isSignedIn = true;
        return true;
      }
      return false;
    } catch (e) {
      print('Google Sign-In error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _driveApi = null;
    _isSignedIn = false;
  }

  Future<String> createLocalBackup() async {
    try {
      final databaseService = DatabaseService();

      // Get all data
      final companies = await databaseService.getCompanies();
      final clients = await databaseService.getClients();
      final quotations = await databaseService.getQuotations();
      final invoices = await databaseService.getInvoices();
      final taxNames = await databaseService.getTaxNames();

      // Get payments for each invoice
      final invoicesWithPayments = <Map<String, dynamic>>[];
      for (final invoice in invoices) {
        final payments = await databaseService.getPaymentsByInvoice(invoice.id!);
        invoicesWithPayments.add({
          'invoice': invoice.toMap(),
          'payments': payments.map((p) => p.toMap()).toList(),
        });
      }

      // Create backup data structure
      final backupData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'companies': companies.map((c) => c.toMap()).toList(),
        'clients': clients.map((c) => c.toMap()).toList(),
        'quotations': quotations.map((q) => q.toMap()).toList(),
        'invoices': invoicesWithPayments,
        'taxNames': taxNames.map((t) => t.toMap()).toList(),
      };

      // Save to local file
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'backup_$timestamp.json';
      final file = File('${backupDir.path}/$fileName');

      await file.writeAsString(jsonEncode(backupData));
      return file.path;
    } catch (e) {
      throw Exception('Failed to create local backup: $e');
    }
  }

  Future<bool> uploadToGoogleDrive(String localBackupPath) async {
    if (!_isSignedIn || _driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      final file = File(localBackupPath);
      final fileName = file.path.split('/').last;

      // Create file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..parents = ['appDataFolder']; // Use appDataFolder for app-specific data

      // Upload file
      final media = drive.Media(file.openRead(), file.lengthSync());
      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      return uploadedFile.id != null;
    } catch (e) {
      print('Google Drive upload error: $e');
      return false;
    }
  }

  Future<List<drive.File>> listGoogleDriveBackups() async {
    if (!_isSignedIn || _driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      final response = await _driveApi!.files.list(
        q: "name contains 'backup_' and mimeType='application/json'",
        spaces: 'drive',
        orderBy: 'createdTime desc',
      );

      return response.files ?? [];
    } catch (e) {
      print('Error listing Google Drive backups: $e');
      return [];
    }
  }

  Future<String?> downloadFromGoogleDrive(String fileId) async {
    if (!_isSignedIn || _driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      final driveFile = await _driveApi!.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final fileName = 'restored_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${backupDir.path}/$fileName');

      final List<int> dataBytes = [];
      await for (final chunk in driveFile.stream) {
        dataBytes.addAll(chunk);
      }

      await file.writeAsBytes(dataBytes);
      return file.path;
    } catch (e) {
      print('Error downloading from Google Drive: $e');
      return null;
    }
  }

  Future<bool> restoreFromBackup(String backupFilePath) async {
    try {
      final file = File(backupFilePath);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString);

      final databaseService = DatabaseService();

      // Clear existing data (optional - could be made configurable)
      // For safety, we'll add new data without clearing existing

      // Restore companies
      if (backupData['companies'] != null) {
        for (final companyData in backupData['companies']) {
          final company = Company.fromMap(companyData);
          await databaseService.insertCompany(company);
        }
      }

      // Restore clients
      if (backupData['clients'] != null) {
        for (final clientData in backupData['clients']) {
          final client = Client.fromMap(clientData);
          await databaseService.insertClient(client);
        }
      }

      // Restore tax names
      if (backupData['taxNames'] != null) {
        for (final taxData in backupData['taxNames']) {
          final taxName = TaxName.fromMap(taxData);
          await databaseService.insertTaxName(taxName);
        }
      }

      // Restore quotations
      if (backupData['quotations'] != null) {
        for (final quotationData in backupData['quotations']) {
          final quotation = Quotation.fromMap(quotationData);
          await databaseService.insertQuotation(quotation);
        }
      }

      // Restore invoices and payments
      if (backupData['invoices'] != null) {
        for (final invoiceData in backupData['invoices']) {
          final invoice = Invoice.fromMap(invoiceData['invoice']);
          final invoiceId = await databaseService.insertInvoice(invoice);

          // Restore payments
          if (invoiceData['payments'] != null) {
            for (final paymentData in invoiceData['payments']) {
              final payment = Payment.fromMap(paymentData);
              final paymentWithInvoiceId = payment.copyWith(invoiceId: invoiceId);
              await databaseService.insertPayment(paymentWithInvoiceId);
            }
          }
        }
      }

      return true;
    } catch (e) {
      print('Error restoring from backup: $e');
      return false;
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}