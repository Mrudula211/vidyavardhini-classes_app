import 'package:flutter/material.dart';

import '../../../../shared/models/student_model.dart';

class StudentAttendanceCard extends StatelessWidget {
  final StudentModel student;
  final bool isPresent;
  final String reason;
  final ValueChanged<bool> onStatusChanged;
  final ValueChanged<String> onReasonChanged;

  const StudentAttendanceCard({
    super.key,
    required this.student,
    required this.isPresent,
    required this.reason,
    required this.onStatusChanged,
    required this.onReasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: (isPresent ? Colors.green : Colors.red)
                      .withValues(alpha: 0.1),
                  child: Text(
                    student.fullName[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPresent ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16,),
                      ),
                      Text(
                        student.studentId ?? 'STU0000',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12,),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      isPresent ? 'PRESENT' : 'ABSENT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPresent ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                    Switch(
                      value: isPresent,
                      activeThumbColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      onChanged: onStatusChanged,
                    ),
                  ],
                ),
              ],
            ),
            // Reason dropdown if absent
            if (!isPresent) ...[
              const Divider(),
              Row(
                children: [
                  const Text('Absence Reason: ',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: reason,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'sick', child: Text('Sick / Unwell'),),
                        DropdownMenuItem(
                            value: 'family_function',
                            child: Text('Family Function'),),
                        DropdownMenuItem(
                            value: 'travel',
                            child: Text('Travel / Out of station'),),
                        DropdownMenuItem(
                            value: 'personal', child: Text('Personal Work'),),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          onReasonChanged(val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
