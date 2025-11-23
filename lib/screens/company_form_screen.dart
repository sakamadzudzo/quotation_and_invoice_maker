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
                    CompanyFormFields(
                      nameController: _nameController,
                      addressController: _addressController,
                      phoneController: _phoneController,
                      emailController: _emailController,
                      bankNameController: _bankNameController,
                      bankBranchController: _bankBranchController,
                      accountNumberController: _accountNumberController,
                      currencyController: _currencyController,
                      termsController: _termsController,
                      disclaimerController: _disclaimerController,
                      onSave: _saveCompany,
                      isEditing: widget.company != null,
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
                : _buildExistingLogo(),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: _pickLogo, child: const Text('Select Logo')),
      ],
    );
  }

  Widget _buildExistingLogo() {
    if (widget.company?.logoPath != null && widget.company!.logoPath!.isNotEmpty) {
      // Use a more efficient approach - check file existence synchronously if possible
      try {
        final file = File(widget.company!.logoPath!);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        }
      } catch (e) {
        // File doesn't exist or can't be accessed
      }
    }
    return const Icon(
      Icons.add_photo_alternate,
      size: 40,
      color: Colors.grey,
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
        name: sanitizeInput(_nameController.text.trim()),
        address: sanitizeInput(_addressController.text.trim()),
        phone: sanitizeInput(_phoneController.text.trim()),
        email: sanitizeInput(_emailController.text.trim()),
        bankName: sanitizeInput(_bankNameController.text.trim()),
        bankBranch: sanitizeInput(_bankBranchController.text.trim()),
        accountNumber: sanitizeInput(_accountNumberController.text.trim()),
        currency: sanitizeInput(_currencyController.text.trim()),
        terms: sanitizeInput(_termsController.text.trim()),
        disclaimer: sanitizeInput(_disclaimerController.text.trim()),
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

/// Optimized form fields widget to reduce rebuilds and improve performance.
class CompanyFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController bankNameController;
  final TextEditingController bankBranchController;
  final TextEditingController accountNumberController;
  final TextEditingController currencyController;
  final TextEditingController termsController;
  final TextEditingController disclaimerController;
  final VoidCallback onSave;
  final bool isEditing;

  const CompanyFormFields({
    super.key,
    required this.nameController,
    required this.addressController,
    required this.phoneController,
    required this.emailController,
    required this.bankNameController,
    required this.bankBranchController,
    required this.accountNumberController,
    required this.currencyController,
    required this.termsController,
    required this.disclaimerController,
    required this.onSave,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: nameController,
          label: 'Company Name',
          validator: (value) {
            final requiredError = validateRequired(value, 'Company name');
            if (requiredError != null) return requiredError;
            final lengthError = validateLength(value, 2, 100, 'Company name');
            if (lengthError != null) return lengthError;
            return validateCompanyName(value);
          },
          inputFormatters: [
            CapitalizeTextFormatter(),
            LengthLimitingFormatter(100),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: addressController,
          label: 'Address',
          maxLines: 3,
          validator: (value) {
            final requiredError = validateRequired(value, 'Address');
            if (requiredError != null) return requiredError;
            return validateAddress(value);
          },
          inputFormatters: [
            CapitalizeTextFormatter(),
            LengthLimitingFormatter(200),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: phoneController,
          label: 'Phone',
          keyboardType: TextInputType.phone,
          validator: validatePhone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: emailController,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          validator: validateEmail,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: bankNameController,
          label: 'Bank Name',
          inputFormatters: [CapitalizeTextFormatter()],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: bankBranchController,
          label: 'Bank Branch',
          inputFormatters: [CapitalizeTextFormatter()],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: accountNumberController,
          label: 'Account Number',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: currencyController,
          label: 'Currency',
          hint: 'USD, EUR, ZAR, etc.',
          inputFormatters: [UpperCaseTextFormatter()],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: termsController,
          label: 'Terms & Conditions',
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: disclaimerController,
          label: 'Disclaimer',
          maxLines: 4,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSave,
            child: Text(isEditing ? 'Update Company' : 'Add Company'),
          ),
        ),
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
}
