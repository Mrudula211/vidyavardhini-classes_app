import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/announcement_model.dart';

class AnnouncementRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createAnnouncement({
    required String title,
    required String content,
    required String priority,
    required String targetType,
    String? targetBoard,
    String? targetStandard,
    required String createdBy,
  }) async {
    await _client.from('announcements').insert({
      'title': title,
      'content': content,
      'priority': priority,
      'target_type': targetType,
      'target_board': targetBoard,
      'target_standard': targetStandard,
      'created_by': createdBy,
    });
  }

  Future<List<AnnouncementModel>> fetchUserAnnouncements({
    required String userId,
    required String role,
  }) async {
    dynamic query = _client.from('announcements').select();

    if (role == 'admin') {
      // Admin sees all announcements
      final data = await query.order('created_at', ascending: false);
      return (data as List).map((j) => AnnouncementModel.fromJson(j)).toList();
    }

    if (role == 'teacher') {
      final data = await query
          .or('target_type.eq.all,target_type.eq.teachers')
          .order('created_at', ascending: false);
      return (data as List).map((j) => AnnouncementModel.fromJson(j)).toList();
    }

    if (role == 'student') {
      final profile = await _client
          .from('student_profiles')
          .select('board, standard')
          .eq('id', userId)
          .single();

      final board = profile['board'] as String?;
      final standard = profile['standard'] as String?;

      final data = await query.or(
        'target_type.eq.all,target_type.eq.students,and(target_type.eq.specific_class,target_board.eq.$board,target_standard.eq.$standard)',
      ).order('created_at', ascending: false);

      return (data as List).map((j) => AnnouncementModel.fromJson(j)).toList();
    }

    final data = await query.eq('target_type', 'all').order('created_at', ascending: false);
    return (data as List).map((j) => AnnouncementModel.fromJson(j)).toList();
  }
}
