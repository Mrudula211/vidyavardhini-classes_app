import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/teacher_model.dart';
import '../providers/teacher_providers.dart';

class TeacherDetailScreen extends ConsumerStatefulWidget {
  final String teacherId;

  const TeacherDetailScreen({
    super.key,
    required this.teacherId,
  });

  @override
  ConsumerState<TeacherDetailScreen> createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends ConsumerState<TeacherDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _salaryController = TextEditingController();

  List<Map<String, String>> _localAssignments = [];
  bool _isSavingSalary = false;
  bool _isSavingAssignments = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _updateSalary() async {
    final newSalary = double.tryParse(_salaryController.text.trim());
    if (newSalary == null) return;

    setState(() => _isSavingSalary = true);
    try {
      await ref.read(teacherRepositoryProvider).updateTeacherSalary(
            teacherId: widget.teacherId,
            monthlySalary: newSalary,
          );
      ref.invalidate(teacherDetailProvider(widget.teacherId));
      ref.invalidate(teacherListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Monthly salary updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating salary: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingSalary = false);
    }
  }

  Future<void> _toggleStatus(bool currentStatus) async {
    try {
      await ref.read(teacherRepositoryProvider).toggleTeacherStatus(
            teacherId: widget.teacherId,
            isActive: !currentStatus,
          );
      ref.invalidate(teacherDetailProvider(widget.teacherId));
      ref.invalidate(teacherListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Teacher status updated to ${!currentStatus ? "Active" : "Inactive"}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  void _showAddAssignmentDialog() {
    String selectedBoard = 'SSC';
    String selectedStandard = '10th';
    final subjectController = TextEditingController(text: 'Mathematics');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Class Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedBoard,
              decoration: const InputDecoration(labelText: 'Board'),
              items: const [
                DropdownMenuItem(value: 'SSC', child: Text('SSC')),
                DropdownMenuItem(value: 'CBSE', child: Text('CBSE')),
              ],
              onChanged: (val) {
                if (val != null) selectedBoard = val;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedStandard,
              decoration: const InputDecoration(labelText: 'Standard'),
              items: const [
                DropdownMenuItem(value: '1st', child: Text('1st Std')),
                DropdownMenuItem(value: '2nd', child: Text('2nd Std')),
                DropdownMenuItem(value: '3rd', child: Text('3rd Std')),
                DropdownMenuItem(value: '4th', child: Text('4th Std')),
                DropdownMenuItem(value: '5th', child: Text('5th Std')),
                DropdownMenuItem(value: '6th', child: Text('6th Std')),
                DropdownMenuItem(value: '7th', child: Text('7th Std')),
                DropdownMenuItem(value: '8th', child: Text('8th Std')),
                DropdownMenuItem(value: '9th', child: Text('9th Std')),
                DropdownMenuItem(value: '10th', child: Text('10th Std')),
              ],
              onChanged: (val) {
                if (val != null) selectedStandard = val;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                hintText: 'e.g. Science, Algebra, English',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (subjectController.text.trim().isNotEmpty) {
                setState(() {
                  _localAssignments.add({
                    'board': selectedBoard,
                    'standard': selectedStandard,
                    'subject': subjectController.text.trim(),
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAssignments() async {
    setState(() => _isSavingAssignments = true);
    try {
      await ref.read(teacherRepositoryProvider).saveTeacherAssignments(
            teacherId: widget.teacherId,
            assignments: _localAssignments,
          );
      ref.invalidate(teacherAssignmentsProvider(widget.teacherId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class assignments saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving assignments: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingAssignments = false);
    }
  }

  Future<void> _deleteTeacher() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Teacher Profile'),
        content: const Text(
          'Are you sure you want to permanently delete this teacher account from the database? This action cannot be undone.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(teacherRepositoryProvider).deleteTeacher(widget.teacherId);
        ref.invalidate(teacherListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teacher deleted from database successfully')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete teacher: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherAsync = ref.watch(teacherDetailProvider(widget.teacherId));
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider(widget.teacherId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Profile'),
        actions: [
          IconButton(
            tooltip: 'Delete Teacher',
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            onPressed: _deleteTeacher,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.class_), text: 'Assigned Classes'),
          ],
        ),
      ),
      body: teacherAsync.when(
        data: (teacher) {
          if (teacher == null) {
            return const Center(child: Text('Teacher profile not found'));
          }

          if (_salaryController.text.isEmpty) {
            _salaryController.text = teacher.monthlySalary.toStringAsFixed(0);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Profile & Salary
              _buildProfileTab(context, teacher),

              // Tab 2: Class Assignments
              _buildAssignmentsTab(context, assignmentsAsync),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, TeacherModel teacher) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      teacher.fullName.isNotEmpty ? teacher.fullName[0].toUpperCase() : 'T',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    teacher.fullName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Teacher ID: ${teacher.teacherId}',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Account Status: ',
                        style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                      ),
                      Switch(
                        value: teacher.isActive,
                        activeThumbColor: Colors.green,
                        onChanged: (val) => _toggleStatus(teacher.isActive),
                      ),
                      Text(
                        teacher.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: teacher.isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Details Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal & Employment Info',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const Divider(),
                  if (teacher.email != null) _buildDetailRow('Email', teacher.email!),
                  if (teacher.gender != null) _buildDetailRow('Gender', teacher.gender!),
                  if (teacher.joiningDate != null) _buildDetailRow('Joining Date', teacher.joiningDate!),
                  _buildDetailRow('Created At', teacher.createdAt.split('T').first),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Salary Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Salary Structure',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _salaryController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Monthly Salary (₹)',
                            prefixIcon: Icon(Icons.currency_rupee),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onPressed: _isSavingSalary ? null : _updateSalary,
                        child: _isSavingSalary
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Update'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab(
    BuildContext context,
    AsyncValue<List<TeacherAssignmentModel>> assignmentsAsync,
  ) {
    return assignmentsAsync.when(
      data: (remoteAssignments) {
        if (_localAssignments.isEmpty && remoteAssignments.isNotEmpty) {
          _localAssignments = remoteAssignments
              .map((a) => {
                    'board': a.board,
                    'standard': a.standard,
                    'subject': a.subject,
                  },)
              .toList();
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assigned Classes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddAssignmentDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Class'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Expanded(
                child: _localAssignments.isEmpty
                    ? const Center(
                        child: Text(
                          'No classes assigned yet.\nTap "+ Add Class" to assign board/standard/subjects.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _localAssignments.length,
                        itemBuilder: (ctx, idx) {
                          final a = _localAssignments[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(a['board'] ?? 'S', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                              title: Text('${a['board']} • Standard ${a['standard']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Subject: ${a['subject']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _localAssignments.removeAt(idx);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSavingAssignments ? null : _saveAssignments,
                  child: _isSavingAssignments
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SAVE CLASS ASSIGNMENTS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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
