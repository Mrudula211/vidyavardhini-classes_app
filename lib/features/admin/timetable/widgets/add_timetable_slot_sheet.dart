import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../teachers/providers/teacher_providers.dart';
import '../../../timetable/providers/timetable_providers.dart';

class AddTimetableSlotSheet extends ConsumerStatefulWidget {
  final String board;
  final String standard;
  final String initialDay;

  const AddTimetableSlotSheet({
    super.key,
    required this.board,
    required this.standard,
    required this.initialDay,
  });

  @override
  ConsumerState<AddTimetableSlotSheet> createState() => _AddTimetableSlotSheetState();
}

class _AddTimetableSlotSheetState extends ConsumerState<AddTimetableSlotSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController(text: '08:00 AM');
  final TextEditingController _endTimeController = TextEditingController(text: '08:45 AM');
  final TextEditingController _roomController = TextEditingController(text: 'Room 101');

  late String _selectedDay;
  String? _selectedTeacherId;
  bool _isSubmitting = false;

  final List<String> _days = const [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _saveSlot() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(timetableRepositoryProvider).createTimetableSlot(
            board: widget.board,
            standard: widget.standard,
            subject: _subjectController.text.trim(),
            teacherId: _selectedTeacherId,
            dayOfWeek: _selectedDay,
            startTime: _startTimeController.text.trim(),
            endTime: _endTimeController.text.trim(),
            roomNumber: _roomController.text.trim().isNotEmpty ? _roomController.text.trim() : null,
          );

      ref.invalidate(adminClassTimetableProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Timetable slot added for $_selectedDay!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save slot: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(teacherListProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Class Schedule Slot (${widget.board} • ${widget.standard})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Day of Week *',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDay = val);
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Start Time *',
                        hintText: 'e.g. 08:00 AM',
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Start time required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      decoration: const InputDecoration(
                        labelText: 'End Time *',
                        hintText: 'e.g. 08:45 AM',
                        prefixIcon: Icon(Icons.access_time_filled),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'End time required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name *',
                  hintText: 'e.g. Mathematics, Science, English',
                  prefixIcon: Icon(Icons.menu_book),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Subject required' : null,
              ),
              const SizedBox(height: 12),

              teachersAsync.when(
                data: (teachers) {
                  return DropdownButtonFormField<String>(
                    value: _selectedTeacherId,
                    decoration: const InputDecoration(
                      labelText: 'Assign Teacher (Optional)',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None (Unassigned)')),
                      ...teachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName))),
                    ],
                    onChanged: (val) => setState(() => _selectedTeacherId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room Number / Lab (Optional)',
                  hintText: 'e.g. Room 101, Lab 2',
                  prefixIcon: Icon(Icons.meeting_room),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSubmitting ? null : _saveSlot,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SAVE TIMETABLE SLOT',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
