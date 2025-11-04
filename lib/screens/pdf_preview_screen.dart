import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List bytes;
  final String title;
  final VoidCallback? onPrint;
  final VoidCallback? onShare;

  const PdfPreviewScreen({
    super.key,
    required this.bytes,
    required this.title,
    this.onPrint,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview: $title'),
        actions: [
          if (onShare != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: onShare,
              tooltip: 'Share PDF',
            ),
          if (onPrint != null)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: onPrint,
              tooltip: 'Print PDF',
            ),
        ],
      ),
      body: PdfPreview(
        build: (format) => bytes,
        allowPrinting: false, // We handle printing separately
        allowSharing: false, // We handle sharing separately
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}