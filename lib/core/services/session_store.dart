import 'package:hive_flutter/hive_flutter.dart';

/// Small local memory that lets people stay logged in across app restarts and
/// patchy connections. Everything is best-effort: if the box is unavailable
/// (tests, first run) reads return null and writes are skipped.
class SessionStore {
  SessionStore._();

  static const _boxName = 'settings';
  static const _teacherKey = 'teacher_verified_uid';

  static Box<String>? get _box {
    try {
      return Hive.box<String>(_boxName);
    } catch (_) {
      return null;
    }
  }

  static String? _read(String key) => _box?.get(key);

  static Future<void> _write(String key, String value) async {
    try {
      await _box?.put(key, value);
    } catch (_) {}
  }

  static Future<void> _delete(String key) async {
    try {
      await _box?.delete(key);
    } catch (_) {}
  }

  // Teacher access-code step: remembered for the same account until logout.
  static bool isTeacherVerified(String userId) => _read(_teacherKey) == userId;
  static Future<void> saveTeacherVerified(String userId) =>
      _write(_teacherKey, userId);
  static Future<void> clearTeacherVerified() => _delete(_teacherKey);

  // Last known role / student status, used when the network lookup fails.
  static String? cachedRole(String userId) => _read('role:$userId');
  static Future<void> cacheRole(String userId, String role) =>
      _write('role:$userId', role);
  static String? cachedStatus(String userId) => _read('status:$userId');
  static Future<void> cacheStatus(String userId, String status) =>
      _write('status:$userId', status);

  /// Forget everything about a person (on logout).
  static Future<void> forget(String userId) async {
    await _delete('role:$userId');
    await _delete('status:$userId');
    await _delete(_teacherKey);
  }
}
