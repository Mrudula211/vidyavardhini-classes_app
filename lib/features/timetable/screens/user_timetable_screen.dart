import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/timetable_providers.dart';

class UserTimetableScreen extends ConsumerWidget {
  const UserTimetableScreen({super.key});

  final List<String> _days = const [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentUserRoleProvider).value;
    final selectedDay = ref.watch(selectedTimetableDayProvider);

    if (user == null || role == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Class Timetable')),
        body: const Center(child: Text('User session missing')),
      );
    }

    final timetableAsync = role == 'teacher'
        ? ref.watch(teacherTimetableProvider(user.id))
        : ref.watch(studentTimetableProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Class Timetable'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (role == 'teacher') {
                ref.invalidate(teacherTimetableProvider(user.id));
              } else {
                ref.invalidate(studentTimetableProvider(user.id));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Day of Week Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: _days.map((day) {
                final isSelected = selectedDay == day;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(day),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(selectedTimetableDayProvider.notifier).state = day;
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Timeline slots list
          Expanded(
            child: timetableAsync.when(
              data: (slots) {
                if (slots.isEmpty) {
                  return const Center(
                    child: Text(
                      'No classes scheduled for this day.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.schedule, color: AppColors.primary),
                        ),
                        title: Text(
                          slot.subject,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          '${slot.startTime} - ${slot.endTime}\nTeacher: ${slot.teacherName ?? "TBD"} • ${slot.roomNumber ?? "Room 101"}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${slot.board} ${slot.standard}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading timetable: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
