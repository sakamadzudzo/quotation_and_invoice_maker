import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/company_provider.dart';
import '../models/company.dart';
import 'company_form_screen.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  @override
  void initState() {
    super.initState();
    // Load companies when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyProvider>().loadCompanies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Companies'),
      ),
      body: Consumer<CompanyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.companies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No companies yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first company',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.companies.length,
            itemBuilder: (context, index) {
              final company = provider.companies[index];
              return CompanyCard(
                company: company,
                onEdit: () => _editCompany(company),
                onDelete: () => _deleteCompany(company),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCompany,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addCompany() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompanyFormScreen(),
      ),
    );
  }

  void _editCompany(Company company) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyFormScreen(company: company),
      ),
    );
  }

  void _deleteCompany(Company company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text('Are you sure you want to delete ${company.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<CompanyProvider>().deleteCompany(company.id!);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

class CompanyCard extends StatelessWidget {
  final Company company;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CompanyCard({
    super.key,
    required this.company,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            company.name.isNotEmpty ? company.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(company.name),
        subtitle: Text(company.email),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}