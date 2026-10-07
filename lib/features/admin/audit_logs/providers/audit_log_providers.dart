import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/audit_log_repository.dart';

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepository();
});

/// Current filter + pagination state for the audit logs screen.
final auditLogFilterProvider = StateProvider<AuditLogFilter>((ref) {
  return const AuditLogFilter();
});

/// Fetches audit logs for the current filter. Re-fetches automatically
/// whenever [auditLogFilterProvider] changes.
final auditLogsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final filter = ref.watch(auditLogFilterProvider);
  final repo = ref.watch(auditLogRepositoryProvider);
  return repo.fetchAuditLogs(filter);
});

/// Best-effort "performed by" display name for a given user id, cached per
/// id for the lifetime of the screen.
final performedByNameProvider =
    FutureProvider.family.autoDispose<String, String>((ref, userId) async {
  final repo = ref.watch(auditLogRepositoryProvider);
  return repo.resolvePerformedByName(userId);
});
