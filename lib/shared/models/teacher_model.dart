class TeacherModel {
  final String id;
  final String teacherId;
  final String fullName;
  final String? gender;
  final String? dob;
  final String? email;
  final String? joiningDate;
  final String? profilePhotoUrl;
  final double monthlySalary;
  final bool isActive;
  final String createdAt;

  const TeacherModel({
    required this.id,
    required this.teacherId,
    required this.fullName,
    this.gender,
    this.dob,
    this.email,
    this.joiningDate,
    this.profilePhotoUrl,
    required this.monthlySalary,
    required this.isActive,
    required this.createdAt,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      gender: json['gender'] as String?,
      dob: json['dob'] as String?,
      email: json['email'] as String?,
      joiningDate: json['joining_date'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      monthlySalary: (json['monthly_salary'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  String get teacherIdCode => teacherId;
  String? get qualification => 'B.Ed / M.Sc';
  List<String> get subjects => const ['Mathematics', 'Science'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'full_name': fullName,
      'gender': gender,
      'dob': dob,
      'email': email,
      'joining_date': joiningDate,
      'profile_photo_url': profilePhotoUrl,
      'monthly_salary': monthlySalary,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}

class TeacherAssignmentModel {
  final String id;
  final String teacherId;
  final String academicYearId;
  final String board;
  final String standard;
  final String subject;
  final String createdAt;

  const TeacherAssignmentModel({
    required this.id,
    required this.teacherId,
    required this.academicYearId,
    required this.board,
    required this.standard,
    required this.subject,
    required this.createdAt,
  });

  factory TeacherAssignmentModel.fromJson(Map<String, dynamic> json) {
    return TeacherAssignmentModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String? ?? '',
      academicYearId: json['academic_year_id'] as String? ?? '',
      board: json['board'] as String? ?? '',
      standard: json['standard'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'academic_year_id': academicYearId,
      'board': board,
      'standard': standard,
      'subject': subject,
      'created_at': createdAt,
    };
  }
}
