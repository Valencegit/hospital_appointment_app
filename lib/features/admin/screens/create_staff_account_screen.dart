import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../models/department_model.dart';
import '../../../services/user_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../providers/department_provider.dart';
import 'package:provider/provider.dart';

class CreateStaffAccountScreen extends StatefulWidget {
  const CreateStaffAccountScreen({super.key});

  @override
  State<CreateStaffAccountScreen> createState() =>
      _CreateStaffAccountScreenState();
}

class _CreateStaffAccountScreenState extends State<CreateStaffAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _specializationController = TextEditingController();
  final _userService = UserService();

  String _role = AppConstants.roleReceptionist;
  String? _departmentId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    final departmentId = _departmentId;
    if (departmentId == null) return;

    setState(() => _isSubmitting = true);
    try {
      await _userService.createStaffAccount(
        fullName: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        employeeId: _employeeIdController.text,
        departmentId: departmentId,
        role: _role,
        specialization: _role == AppConstants.roleDoctor
            ? _specializationController.text
            : null,
      );

      String invitationMessage;
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );
        invitationMessage =
            'A password setup email was sent to ${_emailController.text.trim()}.';
      } catch (error) {
        invitationMessage =
            'The account was created, but the password setup email could not '
            'be sent ($error). Ask the staff member to use Forgot Password '
            'on the login screen.';
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Staff account created'),
          content: Text(invitationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create staff account: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final departments =
        context.read<DepartmentProvider>().activeDepartmentsStream();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Staff Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Provision a hospital staff account',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Staff roles are assigned securely by the server. '
                        'The staff member will receive a password setup email.',
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        initialValue: _role,
                        decoration: const InputDecoration(
                          labelText: 'Staff role',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: AppConstants.roleReceptionist,
                            child: Text('Receptionist'),
                          ),
                          DropdownMenuItem(
                            value: AppConstants.roleDoctor,
                            child: Text('Doctor'),
                          ),
                          DropdownMenuItem(
                            value: AppConstants.roleSchedulingOfficer,
                            child: Text('Scheduling Officer'),
                          ),
                        ],
                        onChanged: _isSubmitting
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _role = value);
                                }
                              },
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hintText: 'Enter the staff member’s full name',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: Validators.validateName,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Official Email',
                        hintText: 'name@hospital.org',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hintText: 'Enter the staff member’s phone number',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: Validators.validatePhone,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _employeeIdController,
                        label: 'Staff ID',
                        hintText: 'Enter the hospital staff ID',
                        prefixIcon: Icons.numbers_rounded,
                        validator: (value) => Validators.validateRequired(
                          value,
                          'Staff ID',
                        ),
                      ),
                      if (_role == AppConstants.roleDoctor) ...[
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: _specializationController,
                          label: 'Specialization',
                          hintText: 'e.g. Cardiology',
                          prefixIcon: Icons.medical_services_outlined,
                          validator: (value) => Validators.validateRequired(
                            value,
                            'Specialization',
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      StreamBuilder<List<DepartmentModel>>(
                        stream: departments,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(
                              'Could not load departments: ${snapshot.error}',
                              style: TextStyle(color: Colors.red.shade700),
                            );
                          }
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const LinearProgressIndicator();
                          }

                          final activeDepartments = snapshot.data ?? const [];
                          final selectedId = activeDepartments.any(
                            (department) => department.id == _departmentId,
                          )
                              ? _departmentId
                              : null;
                          if (activeDepartments.isEmpty) {
                            return const InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Department',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                'Create an active department before adding staff.',
                              ),
                            );
                          }

                          return DropdownButtonFormField<String>(
                            initialValue: selectedId,
                            decoration: const InputDecoration(
                              labelText: 'Assigned Department',
                              prefixIcon: Icon(Icons.local_hospital_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: activeDepartments
                                .map(
                                  (department) => DropdownMenuItem(
                                    value: department.id,
                                    child: Text(department.name),
                                  ),
                                )
                                .toList(),
                            validator: (value) =>
                                value == null ? 'Choose a department' : null,
                            onChanged: _isSubmitting
                                ? null
                                : (value) {
                                    setState(() => _departmentId = value);
                                  },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        text: 'Create Staff Account',
                        icon: Icons.person_add_alt_1_rounded,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting || _departmentId == null
                            ? null
                            : _createAccount,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
