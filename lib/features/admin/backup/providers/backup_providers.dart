import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/backup_repository.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepository();
});

final backupLogsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(backupRepositoryProvider).fetchBackupLogs();
});
