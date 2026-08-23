import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/student_model.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../attendance/providers/attendance_providers.dart';
import '../widgets/student_attendance_card.dart';

class AttendanceMarkScreen extends ConsumerStatefulWidget {
  const AttendanceMarkScreen({super.key});

  @override
  ConsumerState<AttendanceMarkScreen> createState() =>
      _AttendanceMarkScreenState();
}

class _AttendanceMarkScreenState extends ConsumerState<AttendanceMarkScreen> {
  List<Map<String, dynamic>> _localStudentList = [];
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final selectedDate = ref.watch(selectedAttendanceDateProvider);
    final selectedBoard = ref.watch(selectedAttendanceBoardProvider);
    final selectedStandard = ref.watch(selectedAttendanceStandardProvider);
    final studentsAsync = ref.watch(studentsForAttendanceProvider);

    final assignedClassesAsync = currentUser != null
        ? ref.watch(teacherAssignedClassesProvider(currentUser.id))
        : const AsyncValue.data([]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
      ),
      body: Column(
        children: [
          // Class & Date Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // Class Selector
                assignedClassesAsync.when(
                  data: (classes) {
                    if (classes.isEmpty) {
                      return const Text(
                        'No classes assigned to you.',
                        style: TextStyle(color: Colors.red),
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: '${selectedBoard}_$selectedStandard',
                            decoration: const InputDecoration(
                              labelText: 'Select Class',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: classes.map((c) {
                              final val = '${c['board']}_${c['standard']}';
                              return DropdownMenuItem(
                                value: val,
                                child: Text(
                                  '${c['board']} • Standard ${c['standard']}',
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final parts = val.split('_');
                                ref
                                    .read(
                                      selectedAttendanceBoardProvider.notifier,
                                    )
                                    .state = parts[0];
                                ref
                                    .read(
                                      selectedAttendanceStandardProvider
                                          .notifier,
                                    )
                                    .state = parts[1];
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) =>
                      const Text('Error loading assigned classes'),
                ),
                const SizedBox(height: 12),

                // Date Picker
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text('Date: $selectedDate'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.parse(selectedDate),
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            ref
                                    .read(selectedAttendanceDateProvider.notifier)
                                    .state =
                                picked.toIso8601String().split('T').first;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Student List with Toggle & Reason
          Expanded(
            child: studentsAsync.when(
              data: (remoteList) {
                if (_localStudentList.isEmpty ||
                    _hasParamsChanged(remoteList)) {
                  _localStudentList = List.from(
                    remoteList.map(Map<String, dynamic>.from),
                  );
                }

                if (_localStudentList.isEmpty) {
                  return const Center(
                    child: Text('No active students found in this class.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _localStudentList.length,
                  itemBuilder: (context, index) {
                    final item = _localStudentList[index];
                    final student = item['student'] as StudentModel;
                    final isPresent = item['status'] == 'present';
                    final reason = item['reason'] as String? ?? 'sick';

                    return StudentAttendanceCard(
                      student: student,
                      isPresent: isPresent,
                      reason: reason,
                      onStatusChanged: (val) {
                        setState(() {
                          item['status'] = val ? 'present' : 'absent';
                        });
                      },
                      onReasonChanged: (val) {
                        setState(() {
                          item['reason'] = val;
                        });
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error loading students: $err')),
            ),
          ),

          // Submit Button
          if (_localStudentList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (currentUser == null) return;
                          setState(() => _isSubmitting = true);
                          try {
                            await ref
                                .read(attendanceRepositoryProvider)
                                .submitBatchAttendance(
                                  date: selectedDate,
                                  markedBy: currentUser.id,
                                  records: _localStudentList,
                                );

                            ref.invalidate(studentsForAttendanceProvider);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Attendance submitted successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to submit attendance: $e',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isSubmitting = false);
                          }
                        },
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SUBMIT ATTENDANCE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasParamsChanged(List<Map<String, dynamic>> remoteList) {
    if (remoteList.length != _localStudentList.length) return true;
    for (int i = 0; i < remoteList.length; i++) {
      final rStudent = remoteList[i]['student'] as StudentModel;
      final lStudent = _localStudentList[i]['student'] as StudentModel;
      if (rStudent.id != lStudent.id) return true;
    }
    return false;
  }
}
