class FeeStructureModel {
  final String id;
  final String studentId;
  final String academicYearId;
  final double monthlyFee;

  const FeeStructureModel({
    required this.id,
    required this.studentId,
    required this.academicYearId,
    required this.monthlyFee,
  });

  factory FeeStructureModel.fromJson(Map<String, dynamic> json) {
    return FeeStructureModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String? ?? '',
      academicYearId: json['academic_year_id'] as String? ?? '',
      monthlyFee: (json['monthly_fee'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MonthlyFeeModel {
  final String id;
  final String studentId;
  final String academicYearId;
  final int month;
  final int year;
  final double expectedAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status;
  final String createdAt;
  final String? studentName;
  final String? studentIdCode;
  final String? parentPhone;
  final String? board;
  final String? standard;

  const MonthlyFeeModel({
    required this.id,
    required this.studentId,
    required this.academicYearId,
    required this.month,
    required this.year,
    required this.expectedAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    required this.createdAt,
    this.studentName,
    this.studentIdCode,
    this.parentPhone,
    this.board,
    this.standard,
  });

  factory MonthlyFeeModel.fromJson(Map<String, dynamic> json) {
    final profile = json['student_profiles'] as Map<String, dynamic>?;

    return MonthlyFeeModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String? ?? '',
      academicYearId: json['academic_year_id'] as String? ?? '',
      month: json['month'] as int? ?? 1,
      year: json['year'] as int? ?? 2026,
      expectedAmount: (json['expected_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String? ?? '',
      studentName: profile != null ? profile['full_name'] as String? : null,
      studentIdCode: profile != null ? profile['student_id'] as String? : null,
      parentPhone: profile != null ? profile['parent_phone'] as String? : null,
      board: profile != null ? profile['board'] as String? : null,
      standard: profile != null ? profile['standard'] as String? : null,
    );
  }
}

class FeePaymentModel {
  final String id;
  final String monthlyFeeId;
  final double amount;
  final String paymentMethod;
  final String paymentDate;
  final String? referenceNumber;
  final String? notes;
  final String createdAt;

  const FeePaymentModel({
    required this.id,
    required this.monthlyFeeId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.referenceNumber,
    this.notes,
    required this.createdAt,
  });

  factory FeePaymentModel.fromJson(Map<String, dynamic> json) {
    return FeePaymentModel(
      id: json['id'] as String,
      monthlyFeeId: json['monthly_fee_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      paymentDate: json['payment_date'] as String? ?? '',
      referenceNumber: json['reference_number'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
