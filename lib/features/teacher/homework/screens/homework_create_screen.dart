import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../attendance/providers/attendance_providers.dart';
import '../../../content/providers/content_providers.dart';

class HomeworkCreateScreen extends ConsumerStatefulWidget {
  const HomeworkCreateScreen({super.key});

  @override
  ConsumerState<HomeworkCreateScreen> createState() => _HomeworkCreateScreenState();
}

class _HomeworkCreateScreenState extends ConsumerState<HomeworkCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController(text: 'Mathematics');
  final TextEditingController _dueDateController = TextEditingController();

  String _selectedBoard = 'SSC';
  String _selectedStandard = '10th';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _dueDateController.text = tomorrow.toIso8601String().split('T').first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subjectController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _submitHomework() async {
    if (!_formKey.currentState!.validate()) return;
    if (!guardOnline(context, ref)) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(contentRepositoryProvider).createHomework(
            teacherId: currentUser.id,
            board: _selectedBoard,
            standard: _selectedStandard,
            subject: _subjectController.text.trim(),
            title: _titleController.text.trim(),
            description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
            dueDate: _dueDateController.text.trim(),
          );

      ref.invalidate(teacherHomeworkListProvider(currentUser.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Homework published successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish homework: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final assignedClassesAsync = currentUser != null
        ? ref.watch(teacherAssignedClassesProvider(currentUser.id))
        : const AsyncValue.data([]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Homework'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              assignedClassesAsync.when(
                data: (classes) {
                  if (classes.isEmpty) {
                    return const Text('No classes assigned to you.', style: TextStyle(color: Colors.red));
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: '${_selectedBoard}_$_selectedStandard',
                    decoration: const InputDecoration(
                      labelText: 'Select Target Class *',
                      prefixIcon: Icon(Icons.class_),
                      border: OutlineInputBorder(),
                    ),
                    items: classes.map((c) {
                      final val = '${c['board']}_${c['standard']}';
                      return DropdownMenuItem(
                        value: val,
                        child: Text('${c['board']} • Standard ${c['standard']}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final parts = val.split('_');
                        setState(() {
                          _selectedBoard = parts[0];
                          _selectedStandard = parts[1];
                        });
                      }
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading assigned classes'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                  hintText: 'e.g. Mathematics, Science, History',
                  prefixIcon: Icon(Icons.book),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Subject is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Homework Title *',
                  hintText: 'e.g. Chapter 4 Ex 4.2 Problem Set',
                  prefixIcon: Icon(Icons.assignment),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Submission Due Date *',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: 'Select date',
                    icon: const Icon(Icons.edit_calendar),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(_dueDateController.text),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _dueDateController.text = picked.toIso8601String().split('T').first;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Detailed Instructions / Description',
                  hintText: 'e.g. Solve Questions 1 to 10 in your homework notebook.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSubmitting ? null : _submitHomework,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'PUBLISH HOMEWORK',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
