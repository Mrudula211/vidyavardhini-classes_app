import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/teacher_model.dart';
import '../providers/teacher_providers.dart';

class TeacherListScreen extends ConsumerStatefulWidget {
  const TeacherListScreen({super.key});

  @override
  ConsumerState<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends ConsumerState<TeacherListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshTeachers() async {
    setState(() => _isRefreshing = true);
    try {
      ref.invalidate(teacherListProvider);
      await ref.read(teacherListProvider.future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teachers list refreshed from database!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing teachers: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(teacherListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Management'),
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
                  tooltip: 'Refresh Teachers List',
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshTeachers,
                ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search teacher by name or ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                            tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(teacherSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) {
                ref.read(teacherSearchQueryProvider.notifier).state = val;
              },
            ),
          ),

          // Teacher List
          Expanded(
            child: teachersAsync.when(
              data: (teachers) {
                if (teachers.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshTeachers,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_outlined,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No teachers found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search query.',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refreshTeachers,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = teachers[index];
                      return _buildTeacherCard(context, teacher);
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
                      onPressed: _refreshTeachers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Add Teacher',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Teacher'),
        onPressed: () => context.push(Routes.adminTeacherAdd),
      ),
    );
  }

  Widget _buildTeacherCard(BuildContext context, TeacherModel teacher) {
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
          child: Text(
            teacher.fullName.isNotEmpty ? teacher.fullName[0].toUpperCase() : 'T',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                teacher.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (teacher.isActive ? Colors.green : Colors.grey).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: teacher.isActive ? Colors.green : Colors.grey),
              ),
              child: Text(
                teacher.isActive ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  color: teacher.isActive ? Colors.green : Colors.grey,
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
              '${teacher.teacherId} • Monthly Salary: ₹${teacher.monthlySalary.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (teacher.email != null && teacher.email!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                teacher.email!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/admin/teachers/${teacher.id}'),
      ),
    );
  }
}
