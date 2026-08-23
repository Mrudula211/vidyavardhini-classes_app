class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String priority;
  final String targetType;
  final String? targetBoard;
  final String? targetStandard;
  final String createdBy;
  final String createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.priority,
    required this.targetType,
    this.targetBoard,
    this.targetStandard,
    required this.createdBy,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      priority: json['priority'] as String? ?? 'general',
      targetType: json['target_type'] as String? ?? 'all',
      targetBoard: json['target_board'] as String?,
      targetStandard: json['target_standard'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
