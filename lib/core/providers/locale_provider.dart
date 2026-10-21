import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Languages the app ships with. Native names are shown unchanged in every
/// language so people can always find their own.
class AppLanguage {
  const AppLanguage(this.code, this.nativeName);

  final String code;
  final String nativeName;

  static const all = [
    AppLanguage('en', 'English'),
    AppLanguage('hi', 'हिन्दी'),
    AppLanguage('mr', 'मराठी'),
  ];
}

/// The user's chosen language, persisted in Hive. `null` follows the phone's
/// language (falling back to English when it is not supported).
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(_load());

  static const boxName = 'settings';
  static const _key = 'locale';

  static Locale? _load() {
    try {
      final code = Hive.box<String>(boxName).get(_key);
      if (code != null && AppLanguage.all.any((l) => l.code == code)) {
        return Locale(code);
      }
    } catch (_) {
      // Box not opened (tests) — follow the system language.
    }
    return null;
  }

  Future<void> setLanguage(String code) async {
    state = Locale(code);
    try {
      await Hive.box<String>(boxName).put(_key, code);
    } catch (_) {
      // Persistence is best-effort; the choice still applies this session.
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(
  (ref) => LocaleNotifier(),
);
