import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for the `backup_logs` table.
///
/// Inserting a `pending` row fires the `backup_logs_dispatch` trigger, which
/// calls the `backup-trigger` Edge Function; that function writes the dump
/// to the private `backups` bucket and flips the row to success/failed.
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
  /// user id, which starts a backup server-side.
  Future<void> triggerManualBackup(String initiatedBy) async {
    await _client.from('backup_logs').insert({
      'initiated_by': initiatedBy,
      'status': 'pending',
    });
  }
}
