import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';

/// Compact English / हिन्दी / मराठी selector. [onDark] styles it for the
/// maroon welcome screen.
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = Localizations.localeOf(context).languageCode;
    final fg = onDark ? AppColors.parchment : context.bodyTextColor;

    return Wrap(
      spacing: 8,
      children: [
        for (final lang in AppLanguage.all)
          Semantics(
            button: true,
            selected: lang.code == selected,
            label: lang.nativeName,
            child: ChoiceChip(
              label: Text(lang.nativeName),
              selected: lang.code == selected,
              showCheckmark: false,
              selectedColor: AppColors.gold,
              backgroundColor:
                  onDark ? AppColors.parchment.withValues(alpha: 0.1) : null,
              side: BorderSide(
                color: lang.code == selected
                    ? AppColors.gold
                    : fg.withValues(alpha: 0.35),
              ),
              labelStyle: TextStyle(
                color: lang.code == selected ? AppColors.brown : fg,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) =>
                  ref.read(localeProvider.notifier).setLanguage(lang.code),
            ),
          ),
      ],
    );
  }
}
