import 'dart:io';
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

class PdfService {
  static const double margin = 20.0;
  static const double fontSize = 10.0;

  Future<String> generateQuotationPdf(
    Quotation quotation,
    Company company,
    Client client,
    List<TaxName> taxNames,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(margin),
        build: (context) => [
          _buildHeader(company, 'QUOTATION'),
          pw.SizedBox(height: 20),
          _buildQuotationInfo(quotation, client),
          pw.SizedBox(height: 20),
          _buildItemsTable(quotation.items, taxNames),
          pw.SizedBox(height: 20),
          _buildTotalSection(quotation.totalAmount),
          pw.SizedBox(height: 20),
          _buildFooter(company),
        ],
      ),
    );

    return await _savePdf(pdf, 'quotation_${quotation.id}.pdf');
  }

  Future<String> generateInvoicePdf(
    Invoice invoice,
    Company company,
    Client client,
    List<TaxName> taxNames, {
    List<Payment>? payments,
    DateTime? customDate,
  }) async {
    final pdf = pw.Document();
    final displayDate = customDate ?? invoice.createdAt;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(margin),
        build: (context) => [
          _buildHeader(company, 'INVOICE'),
          pw.SizedBox(height: 20),
          _buildInvoiceInfo(invoice, client, displayDate),
          pw.SizedBox(height: 20),
          _buildItemsTable(invoice.items, taxNames),
          pw.SizedBox(height: 20),
          _buildTotalSection(invoice.totalAmount),
          if (payments != null && payments.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildPaymentsSection(payments),
          ],
          pw.SizedBox(height: 20),
          _buildFooter(company),
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
  ) async {
    final pdfPaths = <String>[];

    for (final payment in payments) {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(margin),
          build: (context) => [
            _buildHeader(company, 'INVOICE'),
            pw.SizedBox(height: 20),
            _buildInvoiceInfo(invoice, client, payment.paymentDate),
            pw.SizedBox(height: 20),
            _buildItemsTable(invoice.items, taxNames),
            pw.SizedBox(height: 20),
            _buildPaymentSection(payment),
            pw.SizedBox(height: 20),
            _buildFooter(company),
          ],
        ),
      );

      final path = await _savePdf(pdf, 'invoice_${invoice.id}_payment_${payment.id}.pdf');
      pdfPaths.add(path);
    }

    return pdfPaths;
  }

  pw.Widget _buildHeader(Company company, String documentType) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company logo if available
        if (company.logoPath != null)
          pw.Container(
            height: 60,
            alignment: pw.Alignment.centerLeft,
            child: pw.Text('LOGO PLACEHOLDER', style: pw.TextStyle(fontSize: 12)),
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

  pw.Widget _buildQuotationInfo(Quotation quotation, Client client) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Quotation #: ${quotation.id}'),
              pw.Text('Date: ${_formatDate(quotation.createdAt)}'),
              pw.Text('Valid Until: ${_formatDate(quotation.createdAt.add(const Duration(days: 30)))}'),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(client.name),
              pw.Text(client.address),
              pw.Text('Phone: ${client.phone}'),
              pw.Text('Email: ${client.email}'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceInfo(Invoice invoice, Client client, DateTime date) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Invoice #: ${invoice.id}'),
              pw.Text('Date: ${_formatDate(date)}'),
              pw.Text('Due Date: ${_formatDate(date.add(const Duration(days: 30)))}'),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(client.name),
              pw.Text(client.address),
              pw.Text('Phone: ${client.phone}'),
              pw.Text('Email: ${client.email}'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(List<QuotationItem> items, List<TaxName> taxNames) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Qty', isHeader: true),
            _buildTableCell('Unit Price', isHeader: true),
            _buildTableCell('Tax', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Items
        ...items.map((item) {
          final taxName = taxNames.where((t) => t.id == item.taxId).firstOrNull;
          return pw.TableRow(
            children: [
              _buildTableCell('${item.productName}\n${item.description}'),
              _buildTableCell(item.quantity.toString()),
              _buildTableCell('\$${item.unitPrice.toStringAsFixed(2)}'),
              _buildTableCell(taxName?.name ?? 'No Tax'),
              _buildTableCell('\$${item.lineTotal.toStringAsFixed(2)}'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTotalSection(double total) {
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
                pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('\$${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPaymentsSection(List<Payment> payments) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Payment History:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Amount', isHeader: true),
                _buildTableCell('Notes', isHeader: true),
              ],
            ),
            ...payments.map((payment) => pw.TableRow(
              children: [
                _buildTableCell(_formatDate(payment.paymentDate)),
                _buildTableCell('\$${payment.amount.toStringAsFixed(2)}'),
                _buildTableCell(payment.notes ?? ''),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPaymentSection(Payment payment) {
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
                pw.Text('Payment:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('\$${payment.amount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Text('Payment Date: ${_formatDate(payment.paymentDate)}'),
            if (payment.notes?.isNotEmpty == true) ...[
              pw.SizedBox(height: 5),
              pw.Text('Notes: ${payment.notes}'),
            ],
          ],
        ),
      ),
    );
  }

  pw.Widget _buildFooter(Company company) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (company.terms?.isNotEmpty == true) ...[
          pw.Text('Terms & Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(company.terms!),
          pw.SizedBox(height: 10),
        ],
        if (company.disclaimer?.isNotEmpty == true) ...[
          pw.Text('Disclaimer:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(company.disclaimer!),
        ],
        pw.SizedBox(height: 20),
        pw.Text('Thank you for your business!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}