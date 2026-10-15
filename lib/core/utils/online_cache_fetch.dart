import 'dart:convert';

import '../services/cache_service.dart';

/// Deep-converts Supabase row maps into JSON-safe `Map<String, dynamic>`.
List<Map<String, dynamic>> normalizeCacheRows(List<dynamic> data) {
  return data
      .map((e) => jsonDecode(jsonEncode(e)) as Map<String, dynamic>)
      .toList();
}

/// Fetches [load], caches the raw rows, and falls back to Hive on failure.
Future<List<T>> fetchWithCacheFallback<T>({
  required String cacheKey,
  required int ttlMinutes,
  required Future<List<Map<String, dynamic>>> Function() load,
  required T Function(Map<String, dynamic>) fromJson,
}) async {
  try {
    final rows = await load();
    await CacheService.instance.putList(
      cacheKey,
      rows,
      ttlMinutes: ttlMinutes,
    );
    return rows.map(fromJson).toList();
  } catch (_) {
    final cached = CacheService.instance.getList(cacheKey);
    if (cached != null) {
      return cached.map(fromJson).toList();
    }
    rethrow;
  }
}
