import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/attachment_list.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../content/providers/content_providers.dart';
import '../../../../l10n/l10n_context.dart';

class StudentHomeworkListScreen extends ConsumerWidget {
  const StudentHomeworkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.homeworkTitle)),
        body: Center(child: Text(context.l10n.userSessionMissing)),
      );
    }

    final homeworkListAsync = ref.watch(studentHomeworkListProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.homeworkTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(studentHomeworkListProvider(user.id)),
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
                  context.l10n.couldNotLoadHomework,
                  textAlign: TextAlign.center,
                  style: AppTypography.poppins(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(studentHomeworkListProvider(user.id)),
                  child: Text(context.l10n.retry),
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
                      context.l10n.noActiveHomework,
                      textAlign: TextAlign.center,
                      style: AppTypography.poppins(fontSize: 14, color: context.mutedTextColor),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentHomeworkListProvider(user.id)),
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
                              hw.subject.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: context.headingColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              context.l10n.dueDate(hw.dueDate),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hw.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (hw.teacherName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.teacherName(hw.teacherName!),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                      if (hw.description != null && hw.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hw.description!,
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
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
    );
  }
}
