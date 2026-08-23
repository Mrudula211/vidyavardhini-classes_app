import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/chat_model.dart';

class ChatRepository {
  final SupabaseClient _client;

  ChatRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<List<ChatRoomModel>> fetchUserChatRooms({
    required String userId,
    required String role,
  }) async {
    dynamic query = _client.from('chat_rooms').select('*, student_profiles(*), teacher_profiles(*)');

    if (role == 'student') {
      query = query.eq('student_id', userId);
    } else if (role == 'teacher') {
      query = query.eq('teacher_id', userId);
    }

    final data = await query.order('last_message_at', ascending: false);
    return (data as List).map((j) => ChatRoomModel.fromJson(j)).toList();
  }

  Future<String> getOrCreateChatRoom({
    required String studentId,
    required String teacherId,
  }) async {
    final existing = await _client
        .from('chat_rooms')
        .select('id')
        .eq('student_id', studentId)
        .eq('teacher_id', teacherId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final inserted = await _client
        .from('chat_rooms')
        .insert({
          'student_id': studentId,
          'teacher_id': teacherId,
          'last_message_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }

  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    String messageType = 'text',
    String? fileUrl,
  }) async {
    final now = DateTime.now().toIso8601String();

    await _client.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'file_url': fileUrl,
      'is_read': false,
    });

    await _client.from('chat_rooms').update({
      'last_message': content,
      'last_message_at': now,
    }).eq('id', roomId);
  }

  Stream<List<ChatMessageModel>> streamMessages(String roomId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((data) => data.map(ChatMessageModel.fromJson).toList());
  }

  Future<ChatRoomModel?> fetchChatRoomById(String roomId) async {
    final res = await _client
        .from('chat_rooms')
        .select('*, student_profiles(*), teacher_profiles(*)')
        .eq('id', roomId)
        .maybeSingle();

    if (res == null) return null;
    return ChatRoomModel.fromJson(res);
  }
}
