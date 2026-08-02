class StudentModel {
  final String id;
  final String? studentId;
  final String fullName;
  final String gender;
  final String dob;
  final String parentName;
  final String parentPhone;
  final String whatsappNumber;
  final String? email;
  final String schoolName;
  final String board;
  final String standard;
  final String? profilePhotoUrl;
  final String status;
  final String? rejectionReason;
  final String? approvedBy;
  final String? approvedAt;
  final String createdAt;

  const StudentModel({
    required this.id,
    this.studentId,
    required this.fullName,
    required this.gender,
    required this.dob,
    required this.parentName,
    required this.parentPhone,
    required this.whatsappNumber,
    this.email,
    required this.schoolName,
    required this.board,
    required this.standard,
    this.profilePhotoUrl,
    required this.status,
    this.rejectionReason,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String?,
      fullName: json['full_name'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      dob: json['dob'] as String? ?? '',
      parentName: json['parent_name'] as String? ?? '',
      parentPhone: json['parent_phone'] as String? ?? '',
      whatsappNumber: json['whatsapp_number'] as String? ?? '',
      email: json['email'] as String?,
      schoolName: json['school_name'] as String? ?? '',
      board: json['board'] as String? ?? '',
      standard: json['standard'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'full_name': fullName,
      'gender': gender,
      'dob': dob,
      'parent_name': parentName,
      'parent_phone': parentPhone,
      'whatsapp_number': whatsappNumber,
      'email': email,
      'school_name': schoolName,
      'board': board,
      'standard': standard,
      'profile_photo_url': profilePhotoUrl,
      'status': status,
      'rejection_reason': rejectionReason,
      'approved_by': approvedBy,
      'approved_at': approvedAt,
      'created_at': createdAt,
    };
  }
}
