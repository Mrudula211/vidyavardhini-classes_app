import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/student_model.dart';
import '../providers/student_providers.dart';
import '../widgets/access_code_card.dart';

class StudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;

  const StudentDetailScreen({
    super.key,
    required this.studentId,
  });

  @override
  ConsumerState<StudentDetailScreen> createState() =>
      _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> {
  StudentModel? _student;
  String? _accessCode;
  List<String> _logins = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    final repo = ref.read(studentRepositoryProvider);
    final student = await repo.fetchStudentDetail(widget.studentId);
    String? code;
    var logins = <String>[];
    try {
      code = await repo.fetchAccessCode(widget.studentId);
      logins = await repo.fetchLoginMethods(widget.studentId);
    } catch (_) {
      // The card then shows "Not available".
    }
    if (mounted) {
      setState(() {
        _student = student;
        _accessCode = code;
        _logins = logins;
        _isLoading = false;
      });
    }
  }

  Future<void> _regenerateCode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate a new access code?'),
        content: const Text(
          'The old code stops working immediately. Share the new one with the parent.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Generate')),
        ],
      ),
    );
    if (confirm != true) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final code = await ref
          .read(studentRepositoryProvider)
          .regenerateAccessCode(widget.studentId);
      if (mounted) setState(() => _accessCode = code);
      messenger.showSnackBar(
          const SnackBar(content: Text('New access code created')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not create a new code: $e')));
    }
  }

  Future<void> _banStudent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ban Student'),
        content: Text(
            'Are you sure you want to ban ${_student?.fullName}? They will lose app access immediately.'),
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
            child: const Text('Ban Student'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(studentRepositoryProvider).banStudent(widget.studentId);
      ref.invalidate(studentListProvider);
      await _loadStudent();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student status updated to Banned')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_student == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Profile')),
        body: const Center(child: Text('Student not found')),
      );
    }

    final student = _student!;

    return Scaffold(
      appBar: AppBar(
        title: Text(student.studentId ?? 'Student Detail'),
        actions: [
          if (student.status == 'active')
            IconButton(
              icon: const Icon(Icons.block, color: Colors.red),
              tooltip: 'Ban Student',
              onPressed: _banStudent,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        student.fullName.isNotEmpty
                            ? student.fullName[0].toUpperCase()
                            : 'S',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: context.headingColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      student.fullName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${student.studentId ?? "Pending"}',
                      style: TextStyle(
                          color: context.mutedTextColor,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        student.status.toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      backgroundColor: _getStatusColor(student.status)
                          .withValues(alpha: 0.2),
                      side: BorderSide(color: _getStatusColor(student.status)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (student.status == 'active')
              AccessCodeCard(
                logins: _logins,
                accessCode: _accessCode,
                onRegenerate: _regenerateCode,
              ),
            const SizedBox(height: 8),

            // Academic Info
            _buildSectionHeader('Academic Details'),
            _buildTile('Board', student.board, Icons.school),
            _buildTile(
                'Standard', 'Standard ${student.standard}', Icons.class_),
            _buildTile('School Name', student.schoolName, Icons.location_city),
            const SizedBox(height: 16),

            // Contact Info
            _buildSectionHeader('Contact & Parent Information'),
            _buildTile('Parent Name', student.parentName, Icons.person),
            _buildTile('Parent Phone', student.parentPhone, Icons.phone),
            _buildTile('WhatsApp Number', student.whatsappNumber, Icons.chat),
            if (student.email != null && student.email!.isNotEmpty)
              _buildTile('Email Address', student.email!, Icons.email),
            _buildTile('Gender', student.gender, Icons.wc),
            _buildTile('Date of Birth', student.dob, Icons.cake),

            if (student.rejectionReason != null &&
                student.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader('Rejection Info'),
              _buildTile('Reason', student.rejectionReason!, Icons.error,
                  iconColor: Colors.red),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'banned':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
        child: Text(
          title,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.headingColor),
        ),
      ),
    );
  }

  Widget _buildTile(String label, String value, IconData icon,
      {Color? iconColor}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? context.headingColor),
        title: Text(label,
            style: TextStyle(fontSize: 12, color: context.mutedTextColor)),
        subtitle: Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface)),
      ),
    );
  }
}
