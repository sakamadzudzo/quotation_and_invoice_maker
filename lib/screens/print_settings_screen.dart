import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class PrintSettingsScreen extends StatefulWidget {
  const PrintSettingsScreen({super.key});

  @override
  State<PrintSettingsScreen> createState() => _PrintSettingsScreenState();
}

class _PrintSettingsScreenState extends State<PrintSettingsScreen> {
  final List<String> _dateFormats = ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'];
  final List<String> _paperSizes = ['A4', 'Letter', 'A5'];
  final List<String> _currencySymbols = ['\$', '€', '£', 'R', '¥'];

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Print Settings'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Document Content'),
                _buildSwitchTile(
                  'Include Company Logo',
                  'Show company logo in document header',
                  settings.includeLogo,
                  (value) => settings.setIncludeLogo(value),
                ),
                _buildSwitchTile(
                  'Include Terms & Conditions',
                  'Show terms and conditions in footer',
                  settings.includeTerms,
                  (value) => settings.setIncludeTerms(value),
                ),
                _buildSwitchTile(
                  'Include Disclaimer',
                  'Show disclaimer in footer',
                  settings.includeDisclaimer,
                  (value) => settings.setIncludeDisclaimer(value),
                ),
                _buildSwitchTile(
                  'Include Payment History',
                  'Show payment history in invoices',
                  settings.includePaymentHistory,
                  (value) => settings.setIncludePaymentHistory(value),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Formatting'),
                _buildDropdownTile(
                  'Date Format',
                  'Choose how dates are displayed',
                  settings.dateFormat,
                  _dateFormats,
                  (value) => settings.setDateFormat(value!),
                ),
                _buildDropdownTile(
                  'Currency Symbol',
                  'Choose currency symbol for amounts',
                  settings.currencySymbol,
                  _currencySymbols,
                  (value) => settings.setCurrencySymbol(value!),
                ),
                _buildDropdownTile(
                  'Paper Size',
                  'Choose paper size for printing',
                  settings.paperSize,
                  _paperSizes,
                  (value) => settings.setPaperSize(value!),
                ),
                _buildSliderTile(
                  'Font Size',
                  'Adjust text size in documents',
                  settings.fontSize,
                  8.0,
                  14.0,
                  (value) => settings.setFontSize(value),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Preview'),
                _buildPreviewCard(settings),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: DropdownButton<String>(
          value: value,
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('${value.toStringAsFixed(1)}pt'),
                Expanded(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: ((max - min) * 2).toInt(),
                    label: '${value.toStringAsFixed(1)}pt',
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(SettingsProvider settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (settings.includeLogo)
                    Container(
                      height: 40,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Text('Company Logo', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Sample Company',
                    style: TextStyle(fontSize: settings.fontSize + 4, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'QUOTATION',
                    style: TextStyle(fontSize: settings.fontSize + 6, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${_getFormattedDate(DateTime.now(), settings.dateFormat)}',
                    style: TextStyle(fontSize: settings.fontSize),
                  ),
                  Text(
                    'Amount: ${settings.currencySymbol}1,250.00',
                    style: TextStyle(fontSize: settings.fontSize),
                  ),
                  if (settings.includeTerms) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Terms: Payment due within 30 days',
                      style: TextStyle(fontSize: settings.fontSize - 1, fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (settings.includeDisclaimer) ...[
                    Text(
                      'Disclaimer: All prices subject to change',
                      style: TextStyle(fontSize: settings.fontSize - 1, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedDate(DateTime date, String dateFormat) {
    switch (dateFormat) {
      case 'DD/MM/YYYY':
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      case 'MM/DD/YYYY':
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      case 'YYYY-MM-DD':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      default:
        return date.toString().split(' ')[0];
    }
  }

}