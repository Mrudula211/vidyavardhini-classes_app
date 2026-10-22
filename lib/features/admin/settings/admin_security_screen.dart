import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../auth/providers/auth_providers.dart';

/// Admin account security: change the login password and/or the 6-digit
/// access code. Needs the current password and access code as proof.
class AdminSecurityScreen extends ConsumerStatefulWidget {
  const AdminSecurityScreen({super.key});

  @override
  ConsumerState<AdminSecurityScreen> createState() =>
      _AdminSecurityScreenState();
}

class _AdminSecurityScreenState extends ConsumerState<AdminSecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _currentCode = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _newCode = TextEditingController();

  bool _busy = false;
  bool _visible = false;
  String? _error;

  @override
  void dispose() {
    _currentPassword.dispose();
    _currentCode.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _newCode.dispose();
    super.dispose();
  }

  bool get _changingPassword => _newPassword.text.isNotEmpty;
  bool get _changingCode => _newCode.text.isNotEmpty;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_changingPassword && !_changingCode) {
      setState(() => _error = 'Enter a new password and/or a new access code.');
      return;
    }
    if (!guardOnline(context, ref)) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);

      // Prove it is really the admin: current password + current access code.
      final ok = await repo.verifyAdminCredentials(
        _currentCode.text.trim(),
        _currentPassword.text,
      );
      if (!ok) {
        setState(
          () => _error = 'Your current password or access code is not correct.',
        );
        return;
      }

      // Change the access code first (it re-checks the current password on
      // the server), then the password, so the check above still holds.
      if (_changingCode) {
        await repo.changeAdminAccessCode(
          currentPassword: _currentPassword.text,
          newCode: _newCode.text.trim(),
        );
      }
      if (_changingPassword) {
        await repo.setPassword(_newPassword.text);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved. Use the new details the next time you log in.'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(String label, {String? helper, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: icon == null ? null : Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Security')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirm it is you',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currentPassword,
                obscureText: !_visible,
                decoration: _decoration(
                  'Current password',
                  icon: Icons.lock_outline_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    tooltip: _visible ? 'Hide' : 'Show',
                    icon: Icon(
                      _visible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: () => setState(() => _visible = !_visible),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your current password' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currentCode,
                obscureText: !_visible,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: _decoration(
                  'Current access code',
                  icon: Icons.pin_outlined,
                ).copyWith(counterText: ''),
                validator: (v) => (v == null || v.trim().length != 6)
                    ? 'Enter your current 6-digit access code'
                    : null,
              ),
              const Divider(height: 32),
              Text(
                'Choose new details (fill one or both)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPassword,
                obscureText: !_visible,
                onChanged: (_) => setState(() {}),
                decoration: _decoration(
                  'New password',
                  helper: 'At least 8 characters; do not reuse an old password',
                  icon: Icons.key_rounded,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (v.length < 8) return 'Use at least 8 characters';
                  if (v == _currentPassword.text) {
                    return 'The new password must be different';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPassword,
                obscureText: !_visible,
                decoration: _decoration(
                  'Confirm new password',
                  icon: Icons.key_rounded,
                ),
                validator: (v) => _changingPassword && v != _newPassword.text
                    ? 'Passwords do not match'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newCode,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: _decoration(
                  'New access code (6 digits)',
                  icon: Icons.pin_outlined,
                ).copyWith(counterText: ''),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  return RegExp(r'^[0-9]{6}$').hasMatch(v)
                      ? null
                      : 'The access code must be exactly 6 digits';
                },
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
                      : const Text('SAVE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
