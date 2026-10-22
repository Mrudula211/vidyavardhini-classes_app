import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../auth/providers/auth_providers.dart';
import '../providers/promotion_providers.dart';
import '../repository/promotion_repository.dart';

/// Admin Settings -> Academic Year -> Promote Students.
/// Flow (PRD 15.2): warning -> type CONFIRM -> password -> SMS OTP -> execute.
class PromotionScreen extends ConsumerStatefulWidget {
  const PromotionScreen({super.key});

  @override
  ConsumerState<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends ConsumerState<PromotionScreen> {
  final _label = TextEditingController();
  final _confirm = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();

  DateTime? _start;
  DateTime? _end;
  bool _prefilled = false;
  bool _otpSent = false;
  bool _busy = false;
  String? _error;
  PromotionResult? _result;

  @override
  void dispose() {
    _label.dispose();
    _confirm.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  /// Suggest the next year from the current one, e.g. 2026-2027 -> 2027-2028.
  void _prefill(AcademicYearInfo current) {
    if (_prefilled) return;
    _prefilled = true;
    _start = current.endDate.add(const Duration(days: 1));
    _end = DateTime(_start!.year + 1, _start!.month, _start!.day)
        .subtract(const Duration(days: 1));
    _label.text = '${_start!.year}-${_start!.year + 1}';
  }

  bool get _inputsValid =>
      _label.text.trim().isNotEmpty &&
      _start != null &&
      _end != null &&
      _confirm.text == 'CONFIRM' &&
      _password.text.isNotEmpty;

  String _clean(Object e) {
    final text = e.toString();
    final m = RegExp(r'message: ([^,)]+)').firstMatch(text);
    return m?.group(1) ?? text;
  }

  Future<void> _sendOtp(String email) async {
    if (!guardOnline(context, ref)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(promotionRepositoryProvider).sendOtp(email);
      if (mounted) setState(() => _otpSent = true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not send the code: ${_clean(e)}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _promote(String email) async {
    if (!guardOnline(context, ref)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result =
          await ref.read(promotionRepositoryProvider).verifyOtpAndPromote(
                email: email,
                otp: _otp.text.trim(),
                confirmText: _confirm.text,
                password: _password.text,
                yearLabel: _label.text.trim(),
                startDate: _start!,
                endDate: _end!,
              );
      ref.invalidate(currentAcademicYearProvider);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = _clean(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = (isStart ? _start : _end) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => isStart ? _start = picked : _end = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final yearAsync = ref.watch(currentAcademicYearProvider);
    final fmt = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Promote Students')),
      body: yearAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Could not load academic year.\n$e')),
        data: (current) {
          if (current == null) {
            return const Center(child: Text('No current academic year found.'));
          }
          if (_result != null) return _buildDone(current);
          _prefill(current);
          final email = user?.email;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: AppColors.maroon.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'This closes ${current.label} and starts the new year.\n\n'
                    '• Standards 1st-9th move up one standard\n'
                    '• 10th standard students and inactive students are archived\n'
                    '• Fee structures and teacher assignments carry over\n\n'
                    'This cannot be undone. Take a backup first.',
                  ),
                ),
              ),
              if (user == null || email == null || email.isEmpty) ...[
                const SizedBox(height: 12),
                const _ErrorNote(
                  'Sign in with your admin email and password (not only the '
                  'access code) to promote students. Promotion needs a verified '
                  'admin session with an email address.',
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _label,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'New academic year (e.g. 2027-2028)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _pickDate(true),
                      child: Text(
                          'Start: ${_start == null ? '--' : fmt.format(_start!)}',),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _pickDate(false),
                      child: Text(
                          'End: ${_end == null ? '--' : fmt.format(_end!)}',),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirm,
                onChanged: (_) => setState(() {}),
                enabled: !_otpSent,
                decoration: const InputDecoration(
                  labelText: 'Type CONFIRM',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                onChanged: (_) => setState(() {}),
                enabled: !_otpSent,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Admin password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (!_otpSent)
                ElevatedButton.icon(
                  onPressed:
                      (_busy || !_inputsValid || email == null || email.isEmpty)
                          ? null
                          : () => _sendOtp(email),
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('Email me a code'),
                )
              else ...[
                TextField(
                  controller: _otp,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Enter the 6-digit code from your email',
                    border: OutlineInputBorder(),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.maroon,
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      (_busy || _otp.text.trim().length < 6 || email == null)
                          ? null
                          : () => _promote(email),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upgrade),
                  label: const Text('Verify OTP & Promote'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _sendOtp(email!),
                  child: const Text('Resend code'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorNote(_error!),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildDone(AcademicYearInfo previous) {
    final r = _result!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Promotion complete',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${r.promoted} students promoted\n${r.archived} students archived',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.maroon.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.maroon.withValues(alpha: 0.4)),
      ),
      child: Text(text),
    );
  }
}
