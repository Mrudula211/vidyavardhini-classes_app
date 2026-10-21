import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  /// Short access to the generated translations: `context.l10n.retry`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
