import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/attachment_picker_field.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../attendance/providers/attendance_providers.dart';
import '../../../content/providers/content_providers.dart';

class ClassworkCreateScreen extends ConsumerStatefulWidget {
  const ClassworkCreateScreen({super.key});

  @override
  ConsumerState<ClassworkCreateScreen> createState() => _ClassworkCreateScreenState();
}

class _ClassworkCreateScreenState extends ConsumerState<ClassworkCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController(text: 'Science');

  String _selectedBoard = 'SSC';
  String _selectedStandard = '10th';
  bool _isSubmitting = false;
  List<PickedAttachment> _attachments = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _submitClasswork() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(contentRepositoryProvider).createClasswork(
            teacherId: currentUser.id,
            board: _selectedBoard,
            standard: _selectedStandard,
            subject: _subjectController.text.trim(),
            title: _titleController.text.trim(),
            description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
            attachments: _attachments,
          );

      ref.invalidate(teacherClassworkListProvider(currentUser.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classwork notes published successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish classwork: $e')),
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
        title: const Text('Create Classwork Notes'),
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
                  hintText: 'e.g. Science, Mathematics, Geography',
                  prefixIcon: Icon(Icons.book),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Subject is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Classwork Title *',
                  hintText: 'e.g. Chapter 2 Periodic Classification Notes',
                  prefixIcon: Icon(Icons.folder_special),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Board Summary / Class Notes',
                  hintText: 'e.g. Key definitions, formulas, and board summaries discussed in class today.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              AttachmentPickerField(
                files: _attachments,
                enabled: !_isSubmitting,
                onChanged: (v) => setState(() => _attachments = v),
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
                  onPressed: _isSubmitting ? null : _submitClasswork,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'PUBLISH CLASSWORK NOTES',
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
