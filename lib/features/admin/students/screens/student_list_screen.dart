import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/student_model.dart';
import '../providers/student_providers.dart';
import '../../../../core/constants/routes.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isRefreshing = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
          IconButton(
            tooltip: 'Add Student',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => context.push(Routes.adminStudentAdd),
          ),
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
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(studentSearchQueryProvider.notifier).state =
                                  '';
                              ref.read(studentListPageProvider.notifier).state =
                                  0;
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(
                      const Duration(milliseconds: 350),
                      () {
                        ref.read(studentSearchQueryProvider.notifier).state =
                            value;
                        ref.read(studentListPageProvider.notifier).state = 0;
                      },
                    );
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
                            ref.read(studentFilterBoardProvider.notifier).state =
                                val;
                            ref.read(studentListPageProvider.notifier).state = 0;
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
                            ref
                                .read(studentFilterStandardProvider.notifier)
                                .state = val;
                            ref.read(studentListPageProvider.notifier).state = 0;
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
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_outline_rounded,
                                    size: 48, color: AppColors.lightOutline,),
                                const SizedBox(height: 12),
                                Text(
                                  'No students found.',
                                  style: AppTypography.poppins(
                                    fontSize: 14,
                                    color: context.mutedTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: 6,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.lightSurfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 40, color: AppColors.maroon,),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load students.\n$err',
                        textAlign: TextAlign.center,
                        style: AppTypography.poppins(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _refreshStudents,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _StudentListPager(studentsAsync: studentsAsync),
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
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
        onSelected: (selected) {
          ref.read(studentFilterStatusProvider.notifier).state = value;
          ref.read(studentListPageProvider.notifier).state = 0;
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
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          foregroundColor: AppColors.primary,
          radius: 26,
          child: student.profilePhotoUrl != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: student.profilePhotoUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Text(
                      student.fullName.isNotEmpty
                          ? student.fullName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    errorWidget: (context, url, error) => Text(
                      student.fullName.isNotEmpty
                          ? student.fullName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                )
              : Text(
                  student.fullName.isNotEmpty
                      ? student.fullName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
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
                color: statusColor.withValues(alpha: 0.1),
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

class _StudentListPager extends ConsumerWidget {
  const _StudentListPager({required this.studentsAsync});

  final AsyncValue<List<StudentModel>> studentsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(studentListPageProvider);
    final length = studentsAsync.value?.length ?? 0;
    if (page == 0 && length < AppConstants.pageSize) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Previous'),
            onPressed: page > 0
                ? () =>
                    ref.read(studentListPageProvider.notifier).state = page - 1
                : null,
          ),
          Text(
            'Page ${page + 1}',
            style: AppTypography.poppins(fontSize: 12),
          ),
          TextButton.icon(
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Next'),
            onPressed: length >= AppConstants.pageSize
                ? () =>
                    ref.read(studentListPageProvider.notifier).state = page + 1
                : null,
          ),
        ],
      ),
    );
  }
}
