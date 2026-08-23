class HomeworkModel {
  final String id;
  final String teacherId;
  final String academicYearId;
  final String board;
  final String standard;
  final String subject;
  final String title;
  final String? description;
  final String dueDate;
  final bool isActive;
  final String createdAt;
  final String? teacherName;
  final List<AttachmentModel> attachments;

  const HomeworkModel({
    required this.id,
    required this.teacherId,
    required this.academicYearId,
    required this.board,
    required this.standard,
    required this.subject,
    required this.title,
    this.description,
    required this.dueDate,
    required this.isActive,
    required this.createdAt,
    this.teacherName,
    this.attachments = const [],
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    final tProfile = json['teacher_profiles'] as Map<String, dynamic>?;
    final attsList = json['homework_attachments'] as List?;

    return HomeworkModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String? ?? '',
      academicYearId: json['academic_year_id'] as String? ?? '',
      board: json['board'] as String? ?? '',
      standard: json['standard'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      dueDate: json['due_date'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String? ?? '',
      teacherName: tProfile != null ? tProfile['full_name'] as String? : null,
      attachments: attsList != null
          ? attsList.map((a) => AttachmentModel.fromJson(a)).toList()
          : const [],
    );
  }
}

class ClassworkModel {
  final String id;
  final String teacherId;
  final String academicYearId;
  final String board;
  final String standard;
  final String subject;
  final String title;
  final String? description;
  final bool isActive;
  final String createdAt;
  final String? teacherName;
  final List<AttachmentModel> attachments;

  const ClassworkModel({
    required this.id,
    required this.teacherId,
    required this.academicYearId,
    required this.board,
    required this.standard,
    required this.subject,
    required this.title,
    this.description,
    required this.isActive,
    required this.createdAt,
    this.teacherName,
    this.attachments = const [],
  });

  factory ClassworkModel.fromJson(Map<String, dynamic> json) {
    final tProfile = json['teacher_profiles'] as Map<String, dynamic>?;
    final attsList = json['classwork_attachments'] as List?;

    return ClassworkModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String? ?? '',
      academicYearId: json['academic_year_id'] as String? ?? '',
      board: json['board'] as String? ?? '',
      standard: json['standard'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String? ?? '',
      teacherName: tProfile != null ? tProfile['full_name'] as String? : null,
      attachments: attsList != null
          ? attsList.map((a) => AttachmentModel.fromJson(a)).toList()
          : const [],
    );
  }
}

class AttachmentModel {
  final String id;
  final String fileUrl;
  final String fileType;
  final String fileName;
  final int? fileSize;

  const AttachmentModel({
    required this.id,
    required this.fileUrl,
    required this.fileType,
    required this.fileName,
    this.fileSize,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] as String,
      fileUrl: json['file_url'] as String? ?? '',
      fileType: json['file_type'] as String? ?? 'text',
      fileName: json['file_name'] as String? ?? '',
      fileSize: json['file_size'] as int?,
    );
  }
}
