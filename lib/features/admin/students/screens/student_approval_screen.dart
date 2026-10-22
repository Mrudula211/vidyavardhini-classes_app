import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/student_model.dart';
import '../../../auth/providers/auth_providers.dart';
import '../providers/student_providers.dart';

class StudentApprovalScreen extends ConsumerStatefulWidget {
  final String studentId;

  const StudentApprovalScreen({
    super.key,
    required this.studentId,
  });

  @override
  ConsumerState<StudentApprovalScreen> createState() =>
      _StudentApprovalScreenState();
}

class _StudentApprovalScreenState extends ConsumerState<StudentApprovalScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _monthlyFeeController =
      TextEditingController(text: '2000');

  StudentModel? _student;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _monthlyFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    final repo = ref.read(studentRepositoryProvider);
    final student = await repo.fetchStudentDetail(widget.studentId);
    final nextId = await ref.read(nextStudentIdProvider.future);

    if (mounted) {
      setState(() {
        _student = student;
        _studentIdController.text = nextId;
        _isLoading = false;
      });
    }
  }

  Future<void> _approveStudent() async {
    if (!_formKey.currentState!.validate() || _student == null) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final monthlyFee =
          double.tryParse(_monthlyFeeController.text.trim()) ?? 0.0;
      await ref.read(studentRepositoryProvider).approveStudent(
            studentId: widget.studentId,
            assignedStudentId: _studentIdController.text.trim(),
            monthlyFee: monthlyFee,
            adminId: currentUser.id,
          );

      ref.invalidate(studentListProvider);
      ref.invalidate(pendingStudentsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Student ${_student!.fullName} approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve student: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _rejectStudent() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Student Registration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please state the reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'e.g. Incomplete information, Wrong board',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      setState(() => _isSubmitting = true);
      try {
        await ref.read(studentRepositoryProvider).rejectStudent(
              studentId: widget.studentId,
              reason: reasonController.text.trim(),
            );

        ref.invalidate(studentListProvider);
        ref.invalidate(pendingStudentsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student registration rejected')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error rejecting student: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Approve Student')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_student == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Approve Student')),
        body: const Center(child: Text('Student profile not found')),
      );
    }

    final student = _student!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration Approval'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          student.fullName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: context.headingColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${student.board} • Standard ${student.standard}',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            Text(
                              'School: ${student.schoolName}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Detail Section
              const Text(
                'Registration Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Parent Name', student.parentName),
              _buildInfoRow('Parent Phone', student.parentPhone),
              _buildInfoRow('WhatsApp', student.whatsappNumber),
              _buildInfoRow('Gender', student.gender),
              _buildInfoRow('Date of Birth', student.dob),
              if (student.email != null && student.email!.isNotEmpty)
                _buildInfoRow('Email', student.email!),
              const SizedBox(height: 24),

              // Approval Form Section
              const Text(
                'Approval Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Assigned Student ID',
                  hintText: 'e.g. STU0001',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                  helperText:
                      'Auto-suggested permanent Student ID (never reused)',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Student ID is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _monthlyFeeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Fee (₹)',
                  hintText: 'e.g. 2000',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                  helperText: 'Sets fee structure for monthly fee triggers',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Monthly fee is required';
                  }
                  if (double.tryParse(val.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Buttons
              if (_isSubmitting)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _approveStudent,
                        child: const Text(
                          'APPROVE STUDENT',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _rejectStudent,
                        child: const Text(
                          'REJECT REGISTRATION',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
