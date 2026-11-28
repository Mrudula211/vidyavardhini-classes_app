import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// Shows a student's login (mobile/email) and access code with copy buttons,
/// so the admin can hand them to the parent.
class AccessCodeCard extends StatelessWidget {
  const AccessCodeCard({
    super.key,
    required this.logins,
    required this.accessCode,
    this.onRegenerate,
  });

  /// Everything the student can log in with (mobile and/or email).
  final List<String> logins;
  final String? accessCode;

  /// When set, a "New code" button is shown (for a lost code).
  final VoidCallback? onRegenerate;

  void _copy(BuildContext context, String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$what copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.vpn_key_rounded, color: context.headingColor),
                const SizedBox(width: 8),
                Text(
                  'App login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.headingColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (logins.isEmpty)
              const _Line(label: 'Login', value: 'Not available')
            else
              for (var i = 0; i < logins.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _Line(
                  label: logins[i].contains('@')
                      ? 'Login (email)'
                      : 'Login (mobile number)',
                  value: logins[i],
                  onCopy: () => _copy(context, logins[i], 'Login'),
                ),
              ],
            const SizedBox(height: 8),
            _Line(
              label: 'Access code (use it as the password)',
              value: accessCode ?? 'Not available',
              big: true,
              onCopy: accessCode == null
                  ? null
                  : () => _copy(context, accessCode!, 'Access code'),
            ),
            if (onRegenerate != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onRegenerate,
                  icon: const Icon(Icons.autorenew, size: 18),
                  label: const Text('Generate a new code'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.onCopy,
    this.big = false,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: context.mutedTextColor),
              ),
              SelectableText(
                value,
                style: TextStyle(
                  fontSize: big ? 22 : 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: big ? 2 : 0,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_rounded),
            onPressed: onCopy,
          ),
      ],
    );
  }
}
