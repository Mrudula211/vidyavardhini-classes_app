import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/login_identifier.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../providers/student_providers.dart';
import '../widgets/access_code_card.dart';

/// Admin adds a student. The app creates the student's login and a generated
/// access code, which is shown afterwards so it can be shared with the parent.
class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _parentName = TextEditingController();
  final _parentPhone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _school = TextEditingController();
  final _fee = TextEditingController();
  final _loginId = TextEditingController();

  String _gender = 'male';
  String _board = AppConstants.boards.first;
  String _standard = AppConstants.standards.first;
  DateTime? _dob;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _name,
      _parentName,
      _parentPhone,
      _whatsapp,
      _school,
      _fee,
      _loginId,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 12),
      firstDate: DateTime(now.year - 25),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      setState(() => _error = 'Choose the date of birth.');
      return;
    }
    if (!guardOnline(context, ref)) return;

    final login = LoginIdentifier.parse(_loginId.text)!;
    final parent = LoginIdentifier.parse(_parentPhone.text)!;
    final whatsapp = _whatsapp.text.trim().isEmpty
        ? null
        : LoginIdentifier.parse(_whatsapp.text)?.phone;

    setState(() => _busy = true);
    try {
      final result = await ref.read(studentRepositoryProvider).createStudent(
            fullName: _name.text,
            gender: _gender,
            dob: _dob!,
            parentName: _parentName.text,
            parentPhone: parent.phone!,
            schoolName: _school.text,
            board: _board,
            standard: _standard,
            monthlyFee: double.parse(_fee.text.trim()),
            loginPhone: login.phone,
            loginEmail: login.email,
            whatsappNumber: whatsapp,
          );
      ref.invalidate(studentListProvider);
      ref.invalidate(pendingStudentsProvider);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Student added'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_name.text.trim()}  •  ${result['student_id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                AccessCodeCard(
                  logins: [
                    if (result['login'] != null) result['login'] as String
                  ],
                  accessCode: result['access_code'] as String?,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Give the parent this login and access code. They log in '
                  'with the mobile number or email and use the access code as '
                  'the password. You can see it again on the student\'s page.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not add the student: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String label, IconData icon, {String? helper}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  String? _required(String? v, String message) =>
      (v == null || v.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _name,
                decoration: _dec('Student full name *', Icons.person),
                validator: (v) => _required(v, 'Enter the student name'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: _dec('Gender *', Icons.wc),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? _gender),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDob,
                child: InputDecorator(
                  decoration: _dec('Date of birth *', Icons.cake),
                  child: Text(
                    _dob == null
                        ? 'Tap to choose'
                        : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _board,
                      decoration: _dec('Board *', Icons.menu_book),
                      items: [
                        for (final b in AppConstants.boards)
                          DropdownMenuItem(value: b, child: Text(b)),
                      ],
                      onChanged: (v) => setState(() => _board = v ?? _board),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _standard,
                      decoration: _dec('Standard *', Icons.class_),
                      items: [
                        for (final s in AppConstants.standards)
                          DropdownMenuItem(value: s, child: Text(s)),
                      ],
                      onChanged: (v) =>
                          setState(() => _standard = v ?? _standard),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _school,
                decoration: _dec('School name *', Icons.school),
                validator: (v) => _required(v, 'Enter the school name'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _parentName,
                decoration:
                    _dec('Parent / guardian name *', Icons.family_restroom),
                validator: (v) => _required(v, 'Enter the parent name'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _parentPhone,
                keyboardType: TextInputType.phone,
                decoration: _dec('Parent mobile number *', Icons.phone),
                validator: (v) {
                  final id = LoginIdentifier.parse(v ?? '');
                  return (id == null || !id.isPhone)
                      ? 'Enter a 10-digit mobile number'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _whatsapp,
                keyboardType: TextInputType.phone,
                decoration: _dec(
                  'WhatsApp number (optional)',
                  Icons.chat,
                  helper: 'Leave empty to use the parent mobile number',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final id = LoginIdentifier.parse(v);
                  return (id == null || !id.isPhone)
                      ? 'Enter a 10-digit mobile number'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _fee,
                keyboardType: TextInputType.number,
                decoration: _dec('Monthly fee (₹) *', Icons.currency_rupee),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  return (n == null || n < 0) ? 'Enter the monthly fee' : null;
                },
              ),
              const Divider(height: 32),
              Text(
                'App login for this student',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'The student logs in with this mobile number or email and the '
                'access code shown after saving.',
                style: TextStyle(fontSize: 12, color: context.mutedTextColor),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _loginId,
                keyboardType: TextInputType.emailAddress,
                decoration: _dec('Login mobile number or email *', Icons.login),
                validator: (v) => LoginIdentifier.parse(v ?? '') == null
                    ? 'Enter a 10-digit mobile number or a valid email'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.maroon.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.maroon.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(_error!),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('ADD STUDENT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
