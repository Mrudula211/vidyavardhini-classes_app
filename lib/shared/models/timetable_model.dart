class TimetableSlotModel {
  final String id;
  final String academicYearId;
  final String board;
  final String standard;
  final String subject;
  final String? teacherId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? roomNumber;
  final String? teacherName;

  const TimetableSlotModel({
    required this.id,
    required this.academicYearId,
    required this.board,
    required this.standard,
    required this.subject,
    this.teacherId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.roomNumber,
    this.teacherName,
  });

  factory TimetableSlotModel.fromJson(Map<String, dynamic> json) {
    final tProfile = json['teacher_profiles'] as Map<String, dynamic>?;

    return TimetableSlotModel(
      id: json['id'] as String,
      academicYearId: json['academic_year_id'] as String? ?? '',
      board: json['board'] as String? ?? '',
      standard: json['standard'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      teacherId: json['teacher_id'] as String?,
      dayOfWeek: json['day_of_week'] as String? ?? 'Monday',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      roomNumber: json['room_number'] as String?,
      teacherName: tProfile != null ? tProfile['full_name'] as String? : null,
    );
  }
}
