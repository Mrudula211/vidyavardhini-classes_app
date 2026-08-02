import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/teachers/providers/teacher_providers.dart';
import '../../../auth/providers/auth_providers.dart';
import '../providers/chat_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentUserRoleProvider).value;
    final chatRoomsAsync = ref.watch(userChatRoomsProvider);

    if (user == null || role == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Doubt Clearing Chat')),
        body: const Center(child: Text('User session missing')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doubt Clearing Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(userChatRoomsProvider),
          ),
        ],
      ),
      body: chatRoomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    role == 'student'
                        ? 'No active doubt conversations.\nTap "+ Ask Doubt" to start chatting with your teacher.'
                        : 'No doubt chat requests yet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final recipientName = role == 'student'
                  ? (room.teacherName ?? 'Teacher')
                  : (room.studentName ?? 'Student');

              final dateStr = room.lastMessageAt != null && room.lastMessageAt!.contains('T')
                  ? room.lastMessageAt!.split('T').first
                  : '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      recipientName.isNotEmpty ? recipientName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  title: Text(
                    recipientName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    room.lastMessage ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: Text(
                    dateStr,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  onTap: () => context.push('/chat/${room.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading chats: $err')),
      ),
      floatingActionButton: role == 'student'
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.question_answer),
              label: const Text('Ask Doubt'),
              onPressed: () => _showStartChatDialog(context, ref, user.id),
            )
          : null,
    );
  }

  void _showStartChatDialog(BuildContext context, WidgetRef ref, String studentId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final teachersAsync = ref.watch(teacherListProvider);

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Teacher to Ask Doubt',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  teachersAsync.when(
                    data: (teachers) {
                      if (teachers.isEmpty) {
                        return const Text('No active teachers found.');
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: teachers.length,
                        itemBuilder: (context, index) {
                          final teacher = teachers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(teacher.fullName[0].toUpperCase()),
                            ),
                            title: Text(teacher.fullName),
                            subtitle: Text('Subjects: ${teacher.subjects.join(", ")}'),
                            onTap: () async {
                              Navigator.pop(ctx);
                              final roomId = await ref.read(chatRepositoryProvider).getOrCreateChatRoom(
                                    studentId: studentId,
                                    teacherId: teacher.id,
                                  );
                              ref.invalidate(userChatRoomsProvider);
                              if (context.mounted) {
                                context.push('/chat/$roomId');
                              }
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error: $err'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
