import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Thin Hive wrapper for read-only JSON list caches with TTL expiry.
class CacheService {
  CacheService._();

  static final CacheService instance = CacheService._();

  static const String boxName = 'app_cache';

  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);
  }

  Box<String> get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError('CacheService.init() must be called before use');
    }
    return box;
  }

  /// Persists [rows] under [key]. Expired on next read after [ttlMinutes].
  Future<void> putList(
    String key,
    List<Map<String, dynamic>> rows, {
    required int ttlMinutes,
  }) async {
    try {
      final payload = jsonEncode({
        'cachedAt': DateTime.now().toIso8601String(),
        'ttlMinutes': ttlMinutes,
        'data': rows,
      });
      await _requireBox.put(key, payload);
    } catch (e) {
      debugPrint('Cache put failed for $key: $e');
    }
  }

  /// Returns cached rows if present and within TTL; otherwise null.
  List<Map<String, dynamic>>? getList(String key) {
    try {
      final raw = _requireBox.get(key);
      if (raw == null) return null;

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(decoded['cachedAt']?.toString() ?? '');
      final ttlMinutes = (decoded['ttlMinutes'] as num?)?.toInt() ?? 0;
      if (cachedAt == null) return null;

      final age = DateTime.now().difference(cachedAt);
      if (age.inMinutes > ttlMinutes) {
        _requireBox.delete(key);
        return null;
      }

      final data = decoded['data'];
      if (data is! List) return null;
      return data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      debugPrint('Cache get failed for $key: $e');
      return null;
    }
  }

  Future<void> invalidate(String key) async {
    await _requireBox.delete(key);
  }

  Future<void> clear() async {
    await _requireBox.clear();
  }
}
