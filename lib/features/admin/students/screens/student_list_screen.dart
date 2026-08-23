import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/student_model.dart';
import '../providers/student_providers.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshStudents() async {
    setState(() => _isRefreshing = true);
    try {
      ref.invalidate(studentListProvider);
      await ref.read(studentListProvider.future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student list refreshed from database!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing students: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentListProvider);
    final selectedBoard = ref.watch(studentFilterBoardProvider);
    final selectedStandard = ref.watch(studentFilterStandardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        actions: [
          _isRefreshing
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: 'Refresh Students List',
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshStudents,
                ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, or STU ID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(studentSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(studentSearchQueryProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: 12),
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All'),
                      _buildFilterChip('pending', 'Pending'),
                      _buildFilterChip('active', 'Active'),
                      _buildFilterChip('inactive', 'Inactive'),
                      _buildFilterChip('banned', 'Banned'),
                      _buildFilterChip('rejected', 'Rejected'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Board and Standard Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedBoard,
                        decoration: const InputDecoration(
                          labelText: 'Board',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Boards')),
                          DropdownMenuItem(value: 'SSC', child: Text('SSC')),
                          DropdownMenuItem(value: 'CBSE', child: Text('CBSE')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(studentFilterBoardProvider.notifier).state = val;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedStandard,
                        decoration: const InputDecoration(
                          labelText: 'Standard',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Standards')),
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
                          if (val != null) {
                            ref.read(studentFilterStandardProvider.notifier).state = val;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshStudents,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('No students found')),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refreshStudents,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return _buildStudentCard(context, student);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $err'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshStudents,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selectedStatus = ref.watch(studentFilterStatusProvider);
    final isSelected = selectedStatus == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        onSelected: (selected) {
          ref.read(studentFilterStatusProvider.notifier).state = value;
        },
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentModel student) {
    Color statusColor;
    switch (student.status) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'banned':
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          foregroundColor: AppColors.primary,
          radius: 26,
          backgroundImage: student.profilePhotoUrl != null
              ? NetworkImage(student.profilePhotoUrl!)
              : null,
          child: student.profilePhotoUrl == null
              ? Text(
                  student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                student.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                student.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${student.studentId ?? "No ID"} • ${student.board} Standard ${student.standard}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 2),
            Text(
              'Parent: ${student.parentName} (${student.parentPhone})',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (student.status == 'pending') {
            context.push('/admin/students/${student.id}/approve');
          } else {
            context.push('/admin/students/${student.id}');
          }
        },
      ),
    );
  }
}
