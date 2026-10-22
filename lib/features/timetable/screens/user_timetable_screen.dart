import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/timetable_providers.dart';
import '../../../l10n/l10n_context.dart';

class UserTimetableScreen extends ConsumerWidget {
  const UserTimetableScreen({super.key});

  final List<String> _days = const [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  String _dayLabel(BuildContext context, String day) {
    final l10n = context.l10n;
    switch (day) {
      case 'Monday':
        return l10n.dayMonday;
      case 'Tuesday':
        return l10n.dayTuesday;
      case 'Wednesday':
        return l10n.dayWednesday;
      case 'Thursday':
        return l10n.dayThursday;
      case 'Friday':
        return l10n.dayFriday;
      case 'Saturday':
        return l10n.daySaturday;
      default:
        return l10n.daySunday;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentUserRoleProvider).value;
    final selectedDay = ref.watch(selectedTimetableDayProvider);

    if (user == null || role == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.timetableTitle)),
        body: Center(child: Text(context.l10n.userSessionMissing)),
      );
    }

    final timetableAsync = role == 'teacher'
        ? ref.watch(teacherTimetableProvider(user.id))
        : ref.watch(studentTimetableProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.timetableTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.refresh,
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
                    label: Text(_dayLabel(context, day)),
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
                  return Center(
                    child: Text(
                      context.l10n.noClassesToday,
                      style: const TextStyle(color: Colors.grey),
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
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.schedule, color: AppColors.primary),
                        ),
                        title: Text(
                          slot.subject,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          (slot.roomNumber == null || slot.roomNumber!.isEmpty)
                            ? context.l10n.slotDetailsNoRoom(
                                slot.startTime,
                                slot.endTime,
                                slot.teacherName ?? context.l10n.tbd,
                              )
                            : context.l10n.slotDetails(
                                slot.startTime,
                                slot.endTime,
                                slot.teacherName ?? context.l10n.tbd,
                                slot.roomNumber!,
                              ),
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${slot.board} ${slot.standard}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: context.headingColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text(context.l10n.couldNotLoadTimetable)),
            ),
          ),
        ],
      ),
    );
  }
}
