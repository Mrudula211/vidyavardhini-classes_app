import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../announcements/providers/announcement_providers.dart';

class AnnouncementCreateScreen extends ConsumerStatefulWidget {
  const AnnouncementCreateScreen({super.key});

  @override
  ConsumerState<AnnouncementCreateScreen> createState() => _AnnouncementCreateScreenState();
}

class _AnnouncementCreateScreenState extends ConsumerState<AnnouncementCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String _priority = 'general';
  String _targetType = 'all';
  String _targetBoard = 'SSC';
  String _targetStandard = '10th';
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _publishAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;
    if (!guardOnline(context, ref)) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isPublishing = true);

    try {
      await ref.read(announcementRepositoryProvider).createAnnouncement(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            priority: _priority,
            targetType: _targetType,
            targetBoard: _targetType == 'specific_class' ? _targetBoard : null,
            targetStandard: _targetType == 'specific_class' ? _targetStandard : null,
            createdBy: currentUser.id,
          );

      ref.invalidate(userAnnouncementsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement published broadcast successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish announcement: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Announcement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Announcement Title *',
                  hintText: 'e.g. Mid-Term Examination Timetable',
                  prefixIcon: Icon(Icons.campaign),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority Level *',
                  prefixIcon: Icon(Icons.priority_high),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General Notice')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent Notice')),
                  DropdownMenuItem(value: 'emergency', child: Text('Emergency Alert')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _priority = val);
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _targetType,
                decoration: const InputDecoration(
                  labelText: 'Target Audience *',
                  prefixIcon: Icon(Icons.group),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Users (Everyone)')),
                  DropdownMenuItem(value: 'students', child: Text('All Students')),
                  DropdownMenuItem(value: 'teachers', child: Text('All Teachers')),
                  DropdownMenuItem(value: 'specific_class', child: Text('Specific Class')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _targetType = val);
                },
              ),
              const SizedBox(height: 16),

              if (_targetType == 'specific_class') ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _targetBoard,
                        decoration: const InputDecoration(labelText: 'Board'),
                        items: const [
                          DropdownMenuItem(value: 'SSC', child: Text('SSC')),
                          DropdownMenuItem(value: 'CBSE', child: Text('CBSE')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _targetBoard = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _targetStandard,
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
                          if (val != null) setState(() => _targetStandard = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Announcement Message Content *',
                  hintText: 'Write the complete details of the announcement here...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Message content is required' : null,
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
                  onPressed: _isPublishing ? null : _publishAnnouncement,
                  child: _isPublishing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'PUBLISH BROADCAST ANNOUNCEMENT',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
