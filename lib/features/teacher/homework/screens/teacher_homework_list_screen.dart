import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../shared/widgets/attachment_list.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../content/providers/content_providers.dart';

class TeacherHomeworkListScreen extends ConsumerWidget {
  const TeacherHomeworkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Uploaded Homework')),
        body: const Center(child: Text('User session missing')),
      );
    }

    final homeworkListAsync = ref.watch(teacherHomeworkListProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Uploaded Homework'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(teacherHomeworkListProvider(user.id)),
          ),
        ],
      ),
      body: homeworkListAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 96,
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
                const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.maroon),
                const SizedBox(height: 12),
                Text(
                  'Could not load homework.\n$err',
                  textAlign: TextAlign.center,
                  style: AppTypography.poppins(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(teacherHomeworkListProvider(user.id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (homeworkList) {
          if (homeworkList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.assignment_outlined, size: 48, color: AppColors.lightOutline),
                    const SizedBox(height: 12),
                    Text(
                      'No homework created yet.\nTap "+ Create Homework" to publish an assignment.',
                      textAlign: TextAlign.center,
                      style: AppTypography.poppins(fontSize: 14, color: context.mutedTextColor),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(teacherHomeworkListProvider(user.id)),
            child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: homeworkList.length,
            itemBuilder: (context, index) {
              final hw = homeworkList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${hw.board} • Standard ${hw.standard} • ${hw.subject}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: context.headingColor,
                              ),
                            ),
                          ),
                          Text(
                            'Due: ${hw.dueDate}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hw.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (hw.description != null && hw.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          hw.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ],
                      AttachmentList(attachments: hw.attachments),
                    ],
                  ),
                ),
              );
            },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Create Homework',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Homework'),
        onPressed: () => context.push(Routes.teacherHomeworkCreate),
      ),
    );
  }
}
