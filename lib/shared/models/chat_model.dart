class ChatRoomModel {
  final String id;
  final String studentId;
  final String teacherId;
  final String? lastMessage;
  final String? lastMessageAt;
  final String createdAt;
  final String? studentName;
  final String? teacherName;

  const ChatRoomModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.studentName,
    this.teacherName,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    final sProfile = json['student_profiles'] as Map<String, dynamic>?;
    final tProfile = json['teacher_profiles'] as Map<String, dynamic>?;

    return ChatRoomModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String? ?? '',
      teacherId: json['teacher_id'] as String? ?? '',
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      studentName: sProfile != null ? sProfile['full_name'] as String? : null,
      teacherName: tProfile != null ? tProfile['full_name'] as String? : null,
    );
  }
}

class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final String messageType;
  final String? fileUrl;
  final bool isRead;
  final String createdAt;

  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.messageType,
    this.fileUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      messageType: json['message_type'] as String? ?? 'text',
      fileUrl: json['file_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
