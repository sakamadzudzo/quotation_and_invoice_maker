import 'dart:io';
// ignore: unused_import
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../models/company.dart';
import '../models/client.dart';
import '../models/quotation.dart';
import '../models/invoice.dart';
import '../models/payment.dart';
import '../models/quotation_item.dart';
import '../models/tax_name.dart';
import '../providers/settings_provider.dart';

class PdfService {
  static const double margin = 20.0;
  static const double fontSize = 10.0;

  PdfPageFormat _getPageFormat(String paperSize) {
    switch (paperSize) {
      case 'A4':
        return PdfPageFormat.a4;
      case 'Letter':
        return PdfPageFormat.letter;
      case 'A5':
        return PdfPageFormat.a5;
      default:
        return PdfPageFormat.a4;
    }
  }

  Future<String> generateQuotationPdf(
    Quotation quotation,
    Company company,
    Client client,
    List<TaxName> taxNames,
    SettingsProvider settings,
  ) async {
    final pdf = pw.Document();
    final logoBytes = settings.includeLogo ? await _loadLogoBytes(company.logoPath) : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: _getPageFormat(settings.paperSize),
        margin: const pw.EdgeInsets.all(margin),
        build: (context) => [
          _buildHeader(company, 'QUOTATION', logoBytes),
          pw.SizedBox(height: 20),
          _buildQuotationInfo(quotation, client, settings),
          pw.SizedBox(height: 20),
          _buildItemsTable(quotation.items, taxNames, settings),
          pw.SizedBox(height: 20),
          _buildTotalSection(quotation.totalAmount, settings),
          pw.SizedBox(height: 20),
          _buildFooter(company, settings),
        ],
      ),
    );

    return await _savePdf(pdf, 'quotation_${quotation.id}.pdf');
  }

  Future<String> generateInvoicePdf(
    Invoice invoice,
    Company company,
    Client client,
    List<TaxName> taxNames,
    SettingsProvider settings, {
    List<Payment>? payments,
    DateTime? customDate,
  }) async {
    final pdf = pw.Document();
    final logoBytes = settings.includeLogo ? await _loadLogoBytes(company.logoPath) : null;
    final displayDate = customDate ?? invoice.createdAt;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: _getPageFormat(settings.paperSize),
        margin: const pw.EdgeInsets.all(margin),
        build: (context) => [
          _buildHeader(company, 'INVOICE', logoBytes),
          pw.SizedBox(height: 20),
          _buildInvoiceInfo(invoice, client, displayDate, settings),
          pw.SizedBox(height: 20),
          _buildItemsTable(invoice.items, taxNames, settings),
          pw.SizedBox(height: 20),
          _buildTotalSection(invoice.totalAmount, settings),
          if (payments != null && payments.isNotEmpty && settings.includePaymentHistory) ...[
            pw.SizedBox(height: 20),
            _buildPaymentsSection(payments, settings),
          ],
          pw.SizedBox(height: 20),
          _buildFooter(company, settings),
        ],
      ),
    );

    return await _savePdf(pdf, 'invoice_${invoice.id}.pdf');
  }

  Future<List<String>> generatePaymentInvoices(
    Invoice invoice,
    Company company,
    Client client,
    List<TaxName> taxNames,
    List<Payment> payments,
    SettingsProvider settings,
  ) async {
    final pdfPaths = <String>[];
    final logoBytes = settings.includeLogo ? await _loadLogoBytes(company.logoPath) : null;

    for (final payment in payments) {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: _getPageFormat(settings.paperSize),
          margin: const pw.EdgeInsets.all(margin),
          build: (context) => [
            _buildHeader(company, 'INVOICE', logoBytes),
            pw.SizedBox(height: 20),
            _buildInvoiceInfo(invoice, client, payment.paymentDate, settings),
            pw.SizedBox(height: 20),
            _buildItemsTable(invoice.items, taxNames, settings),
            pw.SizedBox(height: 20),
            _buildPaymentSection(payment, settings),
            pw.SizedBox(height: 20),
            _buildFooter(company, settings),
          ],
        ),
      );

      final path = await _savePdf(pdf, 'invoice_${invoice.id}_payment_${payment.id}.pdf');
      pdfPaths.add(path);
    }

    return pdfPaths;
  }

  Future<Uint8List?> _loadLogoBytes(String? logoPath) async {
    if (logoPath == null) return null;
    try {
      final file = File(logoPath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      // Handle error silently or log if needed
    }
    return null;
  }

  pw.Widget _buildHeader(Company company, String documentType, Uint8List? logoBytes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company logo if available
        if (logoBytes != null)
          pw.Container(
            height: 60,
            alignment: pw.Alignment.centerLeft,
            child: pw.Image(pw.MemoryImage(logoBytes), height: 60),
          ),
        pw.SizedBox(height: 10),
        pw.Text(
          company.name,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(company.address),
        pw.Text('Phone: ${company.phone}'),
        pw.Text('Email: ${company.email}'),
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text(
            documentType,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildQuotationInfo(Quotation quotation, Client client, SettingsProvider settings) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Quotation #: ${quotation.id}', style: pw.TextStyle(fontSize: settings.fontSize)),
              pw.Text('Date: ${_formatDate(quotation.createdAt, settings.dateFormat)}', style: pw.TextStyle(fontSize: settings.fontSize)),
              pw.Text('Valid Until: ${_formatDate(quotation.createdAt.add(const Duration(days: 30)), settings.dateFormat)}', style: pw.TextStyle(fontSize: settings.fontSize)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: settings.fontSize)),
              pw.Text(client.name, style: pw.TextStyle(fontSize: settings.fontSize)),
              pw.Text(client.address, style: pw.TextStyle(fontSize: settings.fontSize)),
              pw.Text('Phone: ${client.phone}', style: pw.TextStyle(fontSize: settings.fontSize)),
              pw.Text('Email: ${client.email}', style: pw.TextStyle(fontSize: settings.fontSize)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceInfo(Invoice invoice, Client client, DateTime date, SettingsProvider settings) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Invoice #: ${invoice.id}', style: pw.TextStyle(fontSize: settings.fontSize)),
              pw.Text('Date: ${_formatDate(date, settings.dateFormat)}', style: pw.TextStyle(fontSize: settings.fontSize)),
              pw.Text('Due Date: ${_formatDate(date.add(const Duration(days: 30)), settings.dateFormat)}', style: pw.TextStyle(fontSize: settings.fontSize)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: settings.fontSize)),
              pw.Text(client.name, style: pw.TextStyle(fontSize: settings.fontSize)),
              pw.Text(client.address, style: pw.TextStyle(fontSize: settings.fontSize)),
              pw.Text('Phone: ${client.phone}', style: pw.TextStyle(fontSize: settings.fontSize)),
              pw.Text('Email: ${client.email}', style: pw.TextStyle(fontSize: settings.fontSize)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(List<QuotationItem> items, List<TaxName> taxNames, SettingsProvider settings) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Description', isHeader: true, settings: settings),
            _buildTableCell('Qty', isHeader: true, settings: settings),
            _buildTableCell('Unit Price', isHeader: true, settings: settings),
            _buildTableCell('Tax', isHeader: true, settings: settings),
            _buildTableCell('Total', isHeader: true, settings: settings),
          ],
        ),
        // Items
        ...items.map((item) {
          final taxName = taxNames.where((t) => t.id == item.taxId).firstOrNull;
          return pw.TableRow(
            children: [
              _buildTableCell('${item.productName}\n${item.description}', settings: settings),
              _buildTableCell(item.quantity.toString(), settings: settings),
              _buildTableCell('${settings.currencySymbol}${item.unitPrice.toStringAsFixed(2)}', settings: settings),
              _buildTableCell(taxName?.name ?? 'No Tax', settings: settings),
              _buildTableCell('${settings.currencySymbol}${item.lineTotal.toStringAsFixed(2)}', settings: settings),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTotalSection(double total, SettingsProvider settings) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: settings.fontSize)),
                pw.Text('${settings.currencySymbol}${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: settings.fontSize)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPaymentsSection(List<Payment> payments, SettingsProvider settings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Payment History:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: settings.fontSize)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildTableCell('Date', isHeader: true, settings: settings),
                _buildTableCell('Amount', isHeader: true, settings: settings),
                _buildTableCell('Notes', isHeader: true, settings: settings),
              ],
            ),
            ...payments.map((payment) => pw.TableRow(
              children: [
                _buildTableCell(_formatDate(payment.paymentDate, settings.dateFormat), settings: settings),
                _buildTableCell('${settings.currencySymbol}${payment.amount.toStringAsFixed(2)}', settings: settings),
                _buildTableCell(payment.notes ?? '', settings: settings),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPaymentSection(Payment payment, SettingsProvider settings) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Payment:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: settings.fontSize)),
                pw.Text('${settings.currencySymbol}${payment.amount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: settings.fontSize)),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Text('Payment Date: ${_formatDate(payment.paymentDate, settings.dateFormat)}', style: pw.TextStyle(fontSize: settings.fontSize)),
            if (payment.notes?.isNotEmpty == true) ...[
              pw.SizedBox(height: 5),
              pw.Text('Notes: ${payment.notes}', style: pw.TextStyle(fontSize: settings.fontSize)),
            ],
          ],
        ),
      ),
    );
  }

  pw.Widget _buildFooter(Company company, SettingsProvider settings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (settings.includeTerms && company.terms?.isNotEmpty == true) ...[
          pw.Text('Terms & Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: settings.fontSize)),
          pw.Text(company.terms!, style: pw.TextStyle(fontSize: settings.fontSize)),
          pw.SizedBox(height: 10),
        ],
        if (settings.includeDisclaimer && company.disclaimer?.isNotEmpty == true) ...[
          pw.Text('Disclaimer:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: settings.fontSize)),
          pw.Text(company.disclaimer!, style: pw.TextStyle(fontSize: settings.fontSize)),
        ],
        pw.SizedBox(height: 20),
        pw.Text('Thank you for your business!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: settings.fontSize)),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, required SettingsProvider settings}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: settings.fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  Future<String> _savePdf(pw.Document pdf, String fileName) async {
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<void> sharePdf(String filePath, String title) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: title,
    );
  }

  Future<void> sharePdfFiles(List<String> filePaths, String title) async {
    final xFiles = filePaths.map((path) => XFile(path)).toList();
    await Share.shareXFiles(xFiles, text: title);
  }

  Future<void> printPdf(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  String _formatDate(DateTime date, String dateFormat) {
    switch (dateFormat) {
      case 'DD/MM/YYYY':
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      case 'MM/DD/YYYY':
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      case 'YYYY-MM-DD':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      default:
        return '${date.day}/${date.month}/${date.year}';
    }
  }
}