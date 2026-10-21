import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

/// A file chosen by the user, not yet uploaded.
class PickedAttachment {
  const PickedAttachment({
    required this.name,
    required this.size,
    required this.fileType,
    required this.readBytes,
  });

  final String name;
  final int size;

  /// One of the `file_type` enum values: image, pdf, text, video.
  final String fileType;
  final Future<Uint8List> Function() readBytes;
}

/// Result of a successful upload: the storage object path and its metadata.
class UploadedAttachment {
  const UploadedAttachment({
    required this.path,
    required this.name,
    required this.size,
    required this.fileType,
  });

  final String path;
  final String name;
  final int size;
  final String fileType;
}

class AttachmentTooLargeException implements Exception {
  AttachmentTooLargeException(this.name);
  final String name;

  @override
  String toString() => '"$name" is larger than ${AppConstants.maxUploadMb} MB.';
}

/// Picks files and moves them to/from private Supabase Storage buckets.
class StorageService {
  StorageService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const allowedExtensions = [
    'jpg', 'jpeg', 'png', 'webp', 'pdf', 'txt', 'mp4', //
  ];

  static String fileTypeFor(String fileName) {
    final ext =
        fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
        return 'image';
      case 'pdf':
        return 'pdf';
      case 'mp4':
      case 'mov':
      case 'mkv':
        return 'video';
      default:
        return 'text';
    }
  }

  static String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  /// Opens the system file picker. Returns an empty list if cancelled.
  /// Throws [AttachmentTooLargeException] for any file over the size limit.
  Future<List<PickedAttachment>> pickAttachments() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (result == null) return const [];

    const maxBytes = AppConstants.maxUploadMb * 1024 * 1024;
    final picked = <PickedAttachment>[];
    for (final f in result.files) {
      if (f.size > maxBytes) throw AttachmentTooLargeException(f.name);
      picked.add(
        PickedAttachment(
          name: f.name,
          size: f.size,
          fileType: fileTypeFor(f.name),
          readBytes: f.readAsBytes,
        ),
      );
    }
    return picked;
  }

  /// Uploads files to `<bucket>/<ownerId>/<timestamp>_<name>`. If any upload
  /// fails, already-uploaded files are removed and the error is rethrown.
  Future<List<UploadedAttachment>> uploadAll({
    required String bucket,
    required String ownerId,
    required List<PickedAttachment> files,
  }) async {
    final uploaded = <UploadedAttachment>[];
    try {
      for (final f in files) {
        final path =
            '$ownerId/${DateTime.now().microsecondsSinceEpoch}_${_sanitize(f.name)}';
        await _client.storage.from(bucket).uploadBinary(
              path,
              await f.readBytes(),
              fileOptions: FileOptions(contentType: _contentType(f)),
            );
        uploaded.add(
          UploadedAttachment(
            path: path,
            name: f.name,
            size: f.size,
            fileType: f.fileType,
          ),
        );
      }
    } catch (_) {
      await removeAll(bucket, uploaded.map((u) => u.path).toList());
      rethrow;
    }
    return uploaded;
  }

  Future<void> removeAll(String bucket, List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(bucket).remove(paths);
    } catch (_) {
      // Best-effort cleanup; orphaned objects are harmless (private bucket).
    }
  }

  /// Short-lived URL for viewing a private object.
  Future<String> signedUrl(String bucket, String path) {
    return _client.storage.from(bucket).createSignedUrl(path, 3600);
  }

  String _contentType(PickedAttachment f) {
    switch (f.fileType) {
      case 'image':
        final ext = f.name.split('.').last.toLowerCase();
        return ext == 'png'
            ? 'image/png'
            : ext == 'webp'
                ? 'image/webp'
                : 'image/jpeg';
      case 'pdf':
        return 'application/pdf';
      case 'video':
        return 'video/mp4';
      default:
        return 'text/plain';
    }
  }
}
