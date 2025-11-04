import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../providers/client_provider.dart';
import '../utils/helpers.dart';

class ClientFormScreen extends StatefulWidget {
  final Client? client;

  const ClientFormScreen({super.key, this.client});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _tinController = TextEditingController();
  final _vatController = TextEditingController();
  final _otherInfoController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.client != null) {
      _nameController.text = widget.client!.name;
      _addressController.text = widget.client!.address;
      _phoneController.text = widget.client!.phone;
      _emailController.text = widget.client!.email;
      _tinController.text = widget.client!.tinNumber;
      _vatController.text = widget.client!.vatNumber;
      _otherInfoController.text = widget.client!.otherInfo.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _tinController.dispose();
    _vatController.dispose();
    _otherInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client == null ? 'Add Client' : 'Edit Client'),
        actions: [
          if (widget.client != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteClient,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Client Name',
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      keyboardType: TextInputType.phone,
                      validator: validatePhone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _tinController,
                      label: 'TIN Number',
                      hint: 'Tax Identification Number',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _vatController,
                      label: 'VAT Number',
                      hint: 'Value Added Tax Number',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: null,
                      decoration: const InputDecoration(
                        labelText: 'Additional Details',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select detail type'),
                      items: const [
                        DropdownMenuItem(value: 'industry', child: Text('Industry')),
                        DropdownMenuItem(value: 'website', child: Text('Website')),
                        DropdownMenuItem(value: 'notes', child: Text('Notes')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        // TODO: Implement additional details logic
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _otherInfoController,
                      label: 'Additional Notes',
                      maxLines: 3,
                      hint: 'Any additional information about the client',
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveClient,
                        child: Text(widget.client == null ? 'Add Client' : 'Update Client'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: [CapitalizeTextFormatter()],
    );
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final otherInfo = _parseOtherInfo(_otherInfoController.text);
      final client = Client(
        id: widget.client?.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        tinNumber: _tinController.text.trim(),
        vatNumber: _vatController.text.trim(),
        otherInfo: otherInfo,
      );

      final success = widget.client == null
          ? await context.read<ClientProvider>().addClient(client)
          : await context.read<ClientProvider>().updateClient(client);

      if (success && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deleteClient() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: const Text('Are you sure you want to delete this client?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await context.read<ClientProvider>().deleteClient(widget.client!.id!);
              if (mounted) Navigator.pop(context); // Close form
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _parseOtherInfo(String text) {
    if (text.trim().isEmpty) return {};
    try {
      // Simple parsing - in production, use json.decode
      return {};
    } catch (e) {
      return {};
    }
  }
}