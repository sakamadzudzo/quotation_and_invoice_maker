import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/company.dart';
import '../providers/company_provider.dart';
import '../utils/helpers.dart';

class CompanyFormScreen extends StatefulWidget {
  final Company? company;

  const CompanyFormScreen({super.key, this.company});

  @override
  State<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends State<CompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankBranchController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _currencyController = TextEditingController();
  final _termsController = TextEditingController();
  final _disclaimerController = TextEditingController();

  File? _logoFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.company != null) {
      _nameController.text = widget.company!.name;
      _addressController.text = widget.company!.address;
      _phoneController.text = widget.company!.phone;
      _emailController.text = widget.company!.email;
      _bankNameController.text = widget.company!.bankName;
      _bankBranchController.text = widget.company!.bankBranch;
      _accountNumberController.text = widget.company!.accountNumber;
      _currencyController.text = widget.company!.currency;
      _termsController.text = widget.company!.terms;
      _disclaimerController.text = widget.company!.disclaimer;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bankNameController.dispose();
    _bankBranchController.dispose();
    _accountNumberController.dispose();
    _currencyController.dispose();
    _termsController.dispose();
    _disclaimerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.company == null ? 'Add Company' : 'Edit Company'),
        actions: [
          if (widget.company != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteCompany,
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
                    _buildLogoSection(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Company Name',
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                      inputFormatters: [CapitalizeTextFormatter()],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                      inputFormatters: [CapitalizeTextFormatter()],
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
                      controller: _bankNameController,
                      label: 'Bank Name',
                      inputFormatters: [CapitalizeTextFormatter()],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _bankBranchController,
                      label: 'Bank Branch',
                      inputFormatters: [CapitalizeTextFormatter()],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _accountNumberController,
                      label: 'Account Number',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _currencyController,
                      label: 'Currency',
                      hint: 'USD, EUR, ZAR, etc.',
                      inputFormatters: [UpperCaseTextFormatter()],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _termsController,
                      label: 'Terms & Conditions',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _disclaimerController,
                      label: 'Disclaimer',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveCompany,
                        child: Text(
                          widget.company == null
                              ? 'Add Company'
                              : 'Update Company',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        const Text(
          'Company Logo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickLogo,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _logoFile != null
                ? Image.file(_logoFile!, fit: BoxFit.cover)
                : widget.company?.logoPath != null &&
                      widget.company!.logoPath!.isNotEmpty
                ? FutureBuilder<bool>(
                    future: File(widget.company!.logoPath!).exists(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.data == true) {
                        return Image.file(
                          File(widget.company!.logoPath!),
                          fit: BoxFit.cover,
                        );
                      }
                      return const Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: Colors.grey,
                      );
                    },
                  )
                : const Icon(
                    Icons.add_photo_alternate,
                    size: 40,
                    color: Colors.grey,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: _pickLogo, child: const Text('Select Logo')),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
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
      inputFormatters: inputFormatters,
    );
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final company = Company(
        id: widget.company?.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        bankName: _bankNameController.text.trim(),
        bankBranch: _bankBranchController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        currency: _currencyController.text.trim(),
        terms: _termsController.text.trim(),
        disclaimer: _disclaimerController.text.trim(),
        logoPath: _logoFile?.path ?? widget.company?.logoPath,
      );

      final success = widget.company == null
          ? await context.read<CompanyProvider>().addCompany(company)
          : await context.read<CompanyProvider>().updateCompany(company);

      if (success && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deleteCompany() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: const Text('Are you sure you want to delete this company?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await context.read<CompanyProvider>().deleteCompany(
                widget.company!.id!,
              );
              if (mounted) Navigator.pop(context); // Close form
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
