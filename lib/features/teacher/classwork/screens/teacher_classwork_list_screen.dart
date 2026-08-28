import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../content/providers/content_providers.dart';

class TeacherClassworkListScreen extends ConsumerWidget {
  const TeacherClassworkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Classwork Notes')),
        body: const Center(child: Text('User session missing')),
      );
    }

    final classworkListAsync = ref.watch(teacherClassworkListProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classwork Notes'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(teacherClassworkListProvider(user.id)),
          ),
        ],
      ),
      body: classworkListAsync.when(
        data: (classworkList) {
          if (classworkList.isEmpty) {
            return const Center(
              child: Text('No classwork published yet.\nTap "+ Add Classwork" to publish class notes.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: classworkList.length,
            itemBuilder: (context, index) {
              final cw = classworkList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${cw.board} • Standard ${cw.standard} • ${cw.subject}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cw.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (cw.description != null && cw.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          cw.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading classwork: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Add new classwork',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Classwork'),
        onPressed: () => context.push(Routes.teacherClassworkCreate),
      ),
    );
  }
}
