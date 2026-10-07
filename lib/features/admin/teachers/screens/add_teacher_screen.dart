import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/teacher_providers.dart';

class AddTeacherScreen extends ConsumerStatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  ConsumerState<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends ConsumerState<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController(text: '20000');
  final TextEditingController _accessCodeController = TextEditingController();

  String _gender = 'male';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _generateAccessCode();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  void _generateAccessCode() {
    final random = Random();
    final pin = (100000 + random.nextInt(900000)).toString();
    setState(() {
      _accessCodeController.text = pin;
    });
  }

  Future<void> _submitTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(teacherRepositoryProvider);
      final res = await repo.createTeacher(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        gender: _gender,
        monthlySalary: double.tryParse(_salaryController.text.trim()) ?? 0.0,
        accessCode: _accessCodeController.text.trim(),
      );

      final assignedId = res['teacher_id'] as String? ?? 'TCHXXXX';

      ref.invalidate(teacherListProvider);

      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Teacher Created Successfully'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Teacher Name: ${_fullNameController.text.trim()}'),
                const SizedBox(height: 8),
                Text('Assigned ID: $assignedId', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Access Code: ${_accessCodeController.text.trim()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 12),
                const Text('Please share this Teacher ID and Access Code with the teacher for logging into the app.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        ref.invalidate(teacherListProvider);
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create teacher: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Teacher'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'e.g. Rajesh Sharma',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Full name is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: 'e.g. +919876543211',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'e.g. rajesh@gmail.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _gender = val);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Salary (₹) *',
                  hintText: 'e.g. 20000',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Monthly salary is required';
                  if (double.tryParse(val.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _accessCodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Teacher Access Code (6-digit PIN) *',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length != 6) {
                          return 'Enter a 6-digit access code';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    onPressed: _generateAccessCode,
                    icon: const Icon(Icons.autorenew),
                    label: const Text('Generate PIN'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              if (_isSubmitting)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _submitTeacher,
                    child: const Text(
                      'CREATE TEACHER ACCOUNT',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
