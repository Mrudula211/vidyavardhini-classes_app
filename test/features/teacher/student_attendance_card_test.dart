import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidyavardhini_classes/features/teacher/attendance/widgets/student_attendance_card.dart';
import 'package:vidyavardhini_classes/shared/models/student_model.dart';

const _student = StudentModel(
  id: 'u1',
  studentId: 'STU0001',
  fullName: 'asha patil',
  gender: 'female',
  dob: '2012-01-01',
  parentName: 'Parent',
  parentPhone: '9999999999',
  whatsappNumber: '9999999999',
  schoolName: 'School',
  board: 'SSC',
  standard: '8th',
  status: 'active',
  createdAt: '2026-01-01',
);

Widget _host({
  required bool isPresent,
  ValueChanged<bool>? onStatus,
  ValueChanged<String>? onReason,
}) {
  return MaterialApp(
    home: Scaffold(
      body: StudentAttendanceCard(
        student: _student,
        isPresent: isPresent,
        reason: 'sick',
        onStatusChanged: onStatus ?? (_) {},
        onReasonChanged: onReason ?? (_) {},
      ),
    ),
  );
}

void main() {
  testWidgets('present: shows PRESENT and hides absence reason', (t) async {
    await t.pumpWidget(_host(isPresent: true));
    expect(find.text('PRESENT'), findsOneWidget);
    expect(find.text('STU0001'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Absence Reason: '), findsNothing);
  });

  testWidgets('absent: shows ABSENT and the reason dropdown', (t) async {
    await t.pumpWidget(_host(isPresent: false));
    expect(find.text('ABSENT'), findsOneWidget);
    expect(find.text('Absence Reason: '), findsOneWidget);
    expect(find.text('Sick / Unwell'), findsOneWidget);
  });

  testWidgets('toggling the switch reports the new status', (t) async {
    bool? received;
    await t.pumpWidget(_host(isPresent: true, onStatus: (v) => received = v));
    await t.tap(find.byType(Switch));
    expect(received, isFalse);
  });
}
