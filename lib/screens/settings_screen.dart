import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import 'backup_screen.dart';
import 'tax_management_screen.dart';
import 'print_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBackupLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              _buildSectionHeader('Appearance'),
              _buildThemeSelector(settings),
              const SizedBox(height: 24),
              _buildSectionHeader('Business Settings'),
              _buildBusinessSettingsSection(),
              const SizedBox(height: 24),
              _buildSectionHeader('Print & PDF Settings'),
              _buildPrintSettingsSection(),
              const SizedBox(height: 24),
              _buildSectionHeader('Backup & Sync'),
              _buildBackupSection(settings),
              const SizedBox(height: 24),
              _buildSectionHeader('About'),
              _buildAboutSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(SettingsProvider settings) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('Choose your preferred theme'),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (value) {
                if (value != null) {
                  settings.setThemeMode(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessSettingsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            title: const Text('Tax Management'),
            subtitle: const Text('Manage tax rates and names'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TaxManagementScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrintSettingsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            title: const Text('Print & PDF Settings'),
            subtitle: const Text('Customize document appearance and formatting'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrintSettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection(SettingsProvider settings) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Enable Cloud Backup'),
            subtitle: const Text('Automatically backup data to Google Drive'),
            value: settings.backupEnabled,
            onChanged: (value) {
              settings.setBackupEnabled(value);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Backup & Restore'),
            subtitle: const Text('Manage your data backups'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BackupScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Create Local Backup'),
            subtitle: const Text('Save a backup to your device'),
            trailing: _isBackupLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.backup),
            onTap: _createLocalBackup,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(title: const Text('Version'), subtitle: const Text('1.0.0')),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Quotation & Invoice Maker'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Quotation & Invoice Maker',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 All rights reserved',
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          const TextSpan(
                            text: 'Quotation & Invoice Maker\n',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(
                            text: 'A simple, offline invoicing app for individuals, freelancers, SMEs, and tuckshops.\n\n',
                          ),
                          const TextSpan(
                            text: 'Key Features\n',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(
                            text: '• Create & manage companies and clients\n'
                                  '• Build quotations and convert them to invoices\n'
                                  '• Track payments and balances\n'
                                  '• Print clean PDF quotations and invoices\n'
                                  '• Local storage (no sign-ups, no cloud)\n'
                                  '• Works 100% offline\n\n',
                          ),
                          const TextSpan(
                            text: 'Why You\'ll Love It\n',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(
                            text: '• Fast and easy to use\n'
                                  '• No subscriptions\n'
                                  '• Minimal interface with only essential features\n'
                                  '• Private: all data stays on your device\n\n'
                                  'Perfect for anyone who needs quick, clean quotations and invoices without complicated accounting software.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createLocalBackup() async {
    setState(() => _isBackupLoading = true);

    try {
      final backupPath = await BackupService.instance.createLocalBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup created successfully: ${backupPath.split('/').last}',
            ),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Could open file manager or show backup location
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create backup: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isBackupLoading = false);
      }
    }
  }
}
