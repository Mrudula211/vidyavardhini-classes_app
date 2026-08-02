class StudentAttendanceModel {
  final String id;
  final String studentId;
  final String academicYearId;
  final String date;
  final String status;
  final String markedBy;
  final String createdAt;
  final String? studentName;
  final String? studentIdCode;
  final AbsenceReasonModel? absenceReason;

  const StudentAttendanceModel({
    required this.id,
    required this.studentId,
    required this.academicYearId,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.createdAt,
    this.studentName,
    this.studentIdCode,
    this.absenceReason,
  });

  factory StudentAttendanceModel.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String? ?? '',
      academicYearId: json['academic_year_id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'absent',
      markedBy: json['marked_by'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      studentName: json['student_profiles'] != null ? json['student_profiles']['full_name'] as String? : null,
      studentIdCode: json['student_profiles'] != null ? json['student_profiles']['student_id'] as String? : null,
      absenceReason: json['absence_reasons'] != null && (json['absence_reasons'] as List).isNotEmpty
          ? AbsenceReasonModel.fromJson((json['absence_reasons'] as List).first)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'academic_year_id': academicYearId,
      'date': date,
      'status': status,
      'marked_by': markedBy,
      'created_at': createdAt,
    };
  }
}

class AbsenceReasonModel {
  final String id;
  final String attendanceId;
  final String reason;
  final String? description;

  const AbsenceReasonModel({
    required this.id,
    required this.attendanceId,
    required this.reason,
    this.description,
  });

  factory AbsenceReasonModel.fromJson(Map<String, dynamic> json) {
    return AbsenceReasonModel(
      id: json['id'] as String,
      attendanceId: json['attendance_id'] as String? ?? '',
      reason: json['reason'] as String? ?? 'other',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attendance_id': attendanceId,
      'reason': reason,
      'description': description,
    };
  }
}

class TeacherAttendanceModel {
  final String id;
  final String teacherId;
  final String date;
  final String status;
  final String? checkInTime;
  final double? latitude;
  final double? longitude;
  final bool isManualCorrection;
  final String? correctionReason;
  final String? teacherName;

  const TeacherAttendanceModel({
    required this.id,
    required this.teacherId,
    required this.date,
    required this.status,
    this.checkInTime,
    this.latitude,
    this.longitude,
    required this.isManualCorrection,
    this.correctionReason,
    this.teacherName,
  });

  factory TeacherAttendanceModel.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'absent',
      checkInTime: json['check_in_time'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isManualCorrection: json['is_manual_correction'] as bool? ?? false,
      correctionReason: json['correction_reason'] as String?,
      teacherName: json['teacher_profiles'] != null ? json['teacher_profiles']['full_name'] as String? : null,
    );
  }
}

class GeofenceSettingsModel {
  final String id;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final String? updatedAt;

  const GeofenceSettingsModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.updatedAt,
  });

  factory GeofenceSettingsModel.fromJson(Map<String, dynamic> json) {
    return GeofenceSettingsModel(
      id: json['id'] as String,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 19.3833,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 72.8333,
      radiusMeters: json['radius_meters'] as int? ?? 100,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
