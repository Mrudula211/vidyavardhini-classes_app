import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for the `backup_logs` table.
///
/// Note: There is currently no backend job (e.g. an Edge Function on a
/// cron) that actually performs database backups. [triggerManualBackup]
/// only records a `pending` request row for audit/visibility purposes.
/// Restore functionality is intentionally out of scope for v1.
class BackupRepository {
  BackupRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetches all backup log entries, most recent first.
  Future<List<Map<String, dynamic>>> fetchBackupLogs() async {
    final data = await _client
        .from('backup_logs')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Inserts a new `pending` backup_logs row initiated by the given admin
  /// user id. This does not trigger any actual backup process yet.
  Future<void> triggerManualBackup(String initiatedBy) async {
    await _client.from('backup_logs').insert({
      'initiated_by': initiatedBy,
      'status': 'pending',
    });
  }
}
