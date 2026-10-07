import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';

/// Filter criteria for querying `audit_logs`.
class AuditLogFilter {
  const AuditLogFilter({
    this.action,
    this.entityType,
    this.from,
    this.to,
    this.page = 0,
  });

  /// Matched with `ilike` against the `action` column (contains).
  final String? action;
  final String? entityType;
  final DateTime? from;
  final DateTime? to;
  final int page;

  AuditLogFilter copyWith({
    String? action,
    bool clearAction = false,
    String? entityType,
    bool clearEntityType = false,
    DateTime? from,
    bool clearFrom = false,
    DateTime? to,
    bool clearTo = false,
    int? page,
  }) {
    return AuditLogFilter(
      action: clearAction ? null : (action ?? this.action),
      entityType: clearEntityType ? null : (entityType ?? this.entityType),
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
      page: page ?? this.page,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuditLogFilter &&
        other.action == action &&
        other.entityType == entityType &&
        other.from == from &&
        other.to == to &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(action, entityType, from, to, page);
}

class AuditLogRepository {
  AuditLogRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetches audit log rows ordered by `created_at` descending, paginated
  /// via `.range()` using [AppConstants.pageSize], with optional filters.
  Future<List<Map<String, dynamic>>> fetchAuditLogs(
    AuditLogFilter filter,
  ) async {
    var query = _client.from('audit_logs').select();

    if (filter.action != null && filter.action!.trim().isNotEmpty) {
      query = query.ilike('action', '%${filter.action!.trim()}%');
    }
    if (filter.entityType != null && filter.entityType!.trim().isNotEmpty) {
      query = query.eq('entity_type', filter.entityType!.trim());
    }
    if (filter.from != null) {
      query = query.gte('created_at', filter.from!.toIso8601String());
    }
    if (filter.to != null) {
      query = query.lte('created_at', filter.to!.toIso8601String());
    }

    final start = filter.page * AppConstants.pageSize;
    final end = start + AppConstants.pageSize - 1;

    final data =
        await query.order('created_at', ascending: false).range(start, end);
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Best-effort lookup of a human-readable display name for the user who
  /// performed an action. Tries admin, teacher, then student profiles (by
  /// `full_name`), falling back to the phone number on `users`.
  Future<String> resolvePerformedByName(String userId) async {
    try {
      final admin = await _client
          .from('admin_profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      if (admin != null && admin['full_name'] != null) {
        return admin['full_name'].toString();
      }

      final teacher = await _client
          .from('teacher_profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      if (teacher != null && teacher['full_name'] != null) {
        return teacher['full_name'].toString();
      }

      final student = await _client
          .from('student_profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      if (student != null && student['full_name'] != null) {
        return student['full_name'].toString();
      }

      final user = await _client
          .from('users')
          .select('phone')
          .eq('id', userId)
          .maybeSingle();
      if (user != null && user['phone'] != null) {
        return user['phone'].toString();
      }
    } catch (_) {
      // Best-effort only; fall through to the raw id below.
    }
    return userId;
  }
}
