import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/timetable_model.dart';
import '../../../timetable/providers/timetable_providers.dart';
import '../widgets/add_timetable_slot_sheet.dart';

class AdminTimetableScreen extends ConsumerStatefulWidget {
  const AdminTimetableScreen({super.key});

  @override
  ConsumerState<AdminTimetableScreen> createState() => _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends ConsumerState<AdminTimetableScreen> {
  final List<String> _days = const [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final selectedBoard = ref.watch(selectedTimetableBoardProvider);
    final selectedStandard = ref.watch(selectedTimetableStandardProvider);
    final selectedDay = ref.watch(selectedTimetableDayProvider);
    final timetableAsync = ref.watch(adminClassTimetableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Class Timetable'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminClassTimetableProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Class Filter Dropdowns
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedBoard,
                    decoration: const InputDecoration(labelText: 'Board'),
                    items: const [
                      DropdownMenuItem(value: 'SSC', child: Text('SSC')),
                      DropdownMenuItem(value: 'CBSE', child: Text('CBSE')),
                    ],
                    onChanged: (val) {
                      if (val != null) ref.read(selectedTimetableBoardProvider.notifier).state = val;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
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
                      if (val != null) ref.read(selectedTimetableStandardProvider.notifier).state = val;
                    },
                  ),
                ),
              ],
            ),
          ),

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
          const SizedBox(height: 12),

          // Timetable Slots List
          Expanded(
            child: timetableAsync.when(
              data: (slots) {
                if (slots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No schedule slots for this day.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _openAddSlotSheet(context, selectedBoard, selectedStandard, selectedDay),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Schedule Slot'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    return _buildSlotTile(context, slot);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading timetable: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Add Timetable Slot',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm),
        label: const Text('Add Slot'),
        onPressed: () => _openAddSlotSheet(context, selectedBoard, selectedStandard, selectedDay),
      ),
    );
  }

  void _openAddSlotSheet(BuildContext context, String board, String standard, String day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => AddTimetableSlotSheet(
        board: board,
        standard: standard,
        initialDay: day,
      ),
    );
  }

  Widget _buildSlotTile(BuildContext context, TimetableSlotModel slot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            slotsIndex(slot.startTime),
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
          ),
        ),
        title: Text(
          slot.subject,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '${slot.startTime} - ${slot.endTime}\nTeacher: ${slot.teacherName ?? "Unassigned"} • ${slot.roomNumber ?? "No Room"}',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
        trailing: IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Slot?'),
                content: Text('Remove ${slot.subject} slot from ${slot.dayOfWeek}?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            );

            if (confirm == true) {
              await ref.read(timetableRepositoryProvider).deleteTimetableSlot(slot.id);
              ref.invalidate(adminClassTimetableProvider);
            }
          },
        ),
      ),
    );
  }

  String slotsIndex(String time) {
    if (time.length >= 2) return time.substring(0, 2);
    return 'CL';
  }
}
