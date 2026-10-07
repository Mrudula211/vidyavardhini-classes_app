import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  NotificationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> markAsRead(String id) async {
    await _client.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<int> unreadCount(String userId) async {
    final data = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (data as List).length;
  }

  /// Creates one notification row per recipient. Restricted to admin by the
  /// `notifications: admin insert` RLS policy.
  Future<void> notifyUsers({
    required List<String> userIds,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    if (userIds.isEmpty) return;
    final rows = userIds
        .map((id) => {
              'user_id': id,
              'title': title,
              'body': body,
              'type': type,
              'data': data,
              'sent_at': DateTime.now().toIso8601String(),
            })
        .toList();
    await _client.from('notifications').insert(rows);
  }

  /// Resolves recipient user ids for an announcement's target audience.
  Future<List<String>> resolveAnnouncementRecipients({
    required String targetType,
    String? board,
    String? standard,
  }) async {
    switch (targetType) {
      case 'teachers':
        final data =
            await _client.from('users').select('id').eq('role', 'teacher');
        return (data as List).map((e) => e['id'] as String).toList();
      case 'students':
        final data = await _client
            .from('student_profiles')
            .select('id')
            .eq('status', 'active');
        return (data as List).map((e) => e['id'] as String).toList();
      case 'specific_class':
        if (board == null || standard == null) return [];
        final data = await _client
            .from('student_profiles')
            .select('id')
            .eq('status', 'active')
            .eq('board', board)
            .eq('standard', standard);
        return (data as List).map((e) => e['id'] as String).toList();
      default: // 'all'
        final data =
            await _client.from('users').select('id').eq('is_active', true);
        return (data as List).map((e) => e['id'] as String).toList();
    }
  }
}
