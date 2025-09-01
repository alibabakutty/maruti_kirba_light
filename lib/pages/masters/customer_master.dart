import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maruti_kirba_lighting_solutions/models/customer_master_data.dart';
import 'package:maruti_kirba_lighting_solutions/pages/masters/utils/compact_form_field.dart';
import 'package:maruti_kirba_lighting_solutions/service/api_service.dart'; // Import the API service

class CustomerMaster extends StatefulWidget {
  final String? customerName;
  final bool isDisplayMode;
  const CustomerMaster({
    super.key,
    this.customerName,
    this.isDisplayMode = false,
  });

  @override
  State<CustomerMaster> createState() => _CustomerMasterState();
}

class _CustomerMasterState extends State<CustomerMaster> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerCodeController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isSubmitting = false;
  bool _isEditing = false;
  bool _isLoading = false;

  CustomerMasterData? _customerMasterData;
  String? customerNameFromArgs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        setState(() {
          customerNameFromArgs = args;
          _isEditing = !widget.isDisplayMode;
        });
        _fetchCustomerData(widget.customerName!);
      } else if (widget.customerName != null) {
        setState(() {
          _isEditing = !widget.isDisplayMode;
        });
        _fetchCustomerData(widget.customerName!);
      }
    });
  }

  Future<void> _fetchCustomerData(String customerName) async {
    setState(() => _isLoading = true);
    try {
      print('Fetching data for customer: $customerName');
      // Use ApiService instead of MysqlService
      final data = await ApiService.getCustomerByCustomerName(customerName);
      print('API Response for $customerName: $data');
      if (data != null) {
        if (data is Map<String, dynamic>) {
          // Convert API response to CustomerMasterData
          // Convert API response to CustomerMasterData
          setState(() {
            _customerMasterData = CustomerMasterData.fromJson({
              'id': data['id'],
              'customer_code': data['customerCode'] ?? data['customer_code'],
              'customer_name': data['customerName'] ?? data['customer_name'],
              'mobile_number': data['mobileNumber'] ?? data['mobile_number'],
              'email': data['email'],
              'created_at': data['createdAt'] ?? data['created_at'],
              'updated_at': data['updatedAt'] ?? data['updated_at'],
            });
            _customerCodeController.text = _customerMasterData!.customerCode;
            _customerNameController.text = _customerMasterData!.customerName;
            _mobileNumberController.text =
                _customerMasterData!.mobileNumber ?? '';
            _emailController.text = _customerMasterData!.email ?? '';
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Customer not found')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final customerData = CustomerMasterData(
        id: _isEditing ? _customerMasterData!.id : null,
        customerCode: _customerCodeController.text,
        customerName: _customerNameController.text,
        mobileNumber: _mobileNumberController.text,
        email: _emailController.text,
        createdAt: _customerMasterData?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing && _customerMasterData != null) {
        // Update existing customer
        await ApiService.updateCustomerByCustomerName(
          _customerMasterData!.customerName,
          customerData.toJson(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Customer updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/cda_page', extra: 'customer');
        }
      } else {
        // Check if customer already exists for new customer
        final existingCustomer = await ApiService.getCustomerByCustomerName(
          customerData.customerName,
        );

        if (existingCustomer != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Customer name ${customerData.customerName} already exists',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Create new customer
        await ApiService.createCustomer(customerData.toJson());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Customer created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _resetForm();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetForm() {
    _customerCodeController.clear();
    _customerNameController.clear();
    _mobileNumberController.clear();
    _emailController.clear();
    setState(() {
      _customerMasterData = null;
      _isEditing = false;
    });
    _formKey.currentState?.reset();
  }

  void _toggleEditMode() {
    setState(() => _isEditing = !_isEditing);
  }

  @override
  void dispose() {
    _customerCodeController.dispose();
    _customerNameController.dispose();
    _mobileNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isDisplayMode
              ? 'CUSTOMER DETAILS: ${widget.customerName ?? ''}'
              : _isEditing
              ? 'EDIT CUSTOMER: ${widget.customerName ?? ''}'
              : 'CREATE NEW CUSTOMER',
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0), // Royal Blue
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cda_page', extra: 'customer'),
        ),
        actions: widget.isDisplayMode
            ? [
                IconButton(
                  icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
                  onPressed: _toggleEditMode,
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Customer Code Field
                      CompactFormField(
                        controller: _customerCodeController,
                        label: 'Customer Code',
                        icon: Icons.code,
                        hint: 'Enter Customer Code',
                        isReadOnly: widget.isDisplayMode || _isEditing,
                        fieldWidth: 0.53,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter customer code';
                          }
                          return null;
                        },
                      ),

                      // Customer Name Field
                      CompactFormField(
                        controller: _customerNameController,
                        label: 'Customer Name',
                        icon: Icons.person,
                        hint: 'Enter Customer Name',
                        isReadOnly: widget.isDisplayMode,
                        fieldWidth: 0.53,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter customer name';
                          }
                          return null;
                        },
                      ),

                      // Mobile Number Field
                      CompactFormField(
                        controller: _mobileNumberController,
                        label: 'Mobile Number',
                        icon: Icons.phone,
                        hint: 'Enter Mobile Number',
                        keyboardType: TextInputType.phone,
                        isReadOnly: widget.isDisplayMode,
                        fieldWidth: 0.53,
                      ),

                      // Email Field
                      CompactFormField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        hint: 'Enter Email',
                        keyboardType: TextInputType.emailAddress,
                        isReadOnly: widget.isDisplayMode,
                        fieldWidth: 0.53,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      // Action Buttons
                      if (!widget.isDisplayMode) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF1565C0,
                              ), // Royal Blue
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isSubmitting ? null : _submitForm,
                            child: _isSubmitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    _isEditing
                                        ? 'UPDATE CUSTOMER'
                                        : 'SAVE CUSTOMER',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
