class TeacherSalaryModel {
  final String id;
  final String teacherId;
  final int month;
  final int year;
  final double monthlySalary;
  final int workingDays;
  final int presentDays;
  final int absentDays;
  final double dailySalary;
  final double earnedSalary;
  final String status;
  final String? paymentDate;
  final String? paymentMethod;
  final String? notes;
  final String createdAt;

  const TeacherSalaryModel({
    required this.id,
    required this.teacherId,
    required this.month,
    required this.year,
    required this.monthlySalary,
    required this.workingDays,
    required this.presentDays,
    required this.absentDays,
    required this.dailySalary,
    required this.earnedSalary,
    required this.status,
    this.paymentDate,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
  });

  bool get isPaid => status == 'paid';

  factory TeacherSalaryModel.fromJson(Map<String, dynamic> json) {
    return TeacherSalaryModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String? ?? '',
      month: json['month'] as int? ?? 1,
      year: json['year'] as int? ?? 2026,
      monthlySalary: (json['monthly_salary'] as num?)?.toDouble() ?? 0.0,
      workingDays: json['working_days'] as int? ?? 0,
      presentDays: json['present_days'] as int? ?? 0,
      absentDays: json['absent_days'] as int? ?? 0,
      dailySalary: (json['daily_salary'] as num?)?.toDouble() ?? 0.0,
      earnedSalary: (json['earned_salary'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      paymentDate: json['payment_date'] as String?,
      paymentMethod: json['payment_method'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
