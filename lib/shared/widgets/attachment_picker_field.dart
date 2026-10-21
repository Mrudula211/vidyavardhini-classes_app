import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../features/content/providers/content_providers.dart';
import 'attachment_list.dart';

/// "Attach files" control for create screens. The parent owns the list.
class AttachmentPickerField extends ConsumerWidget {
  const AttachmentPickerField({
    super.key,
    required this.files,
    required this.onChanged,
    this.enabled = true,
  });

  final List<PickedAttachment> files;
  final ValueChanged<List<PickedAttachment>> onChanged;
  final bool enabled;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    try {
      final picked = await ref.read(storageServiceProvider).pickAttachments();
      if (picked.isEmpty) return;
      onChanged([...files, ...picked]);
    } on AttachmentTooLargeException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not pick files: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: enabled ? () => _pick(context, ref) : null,
          icon: const Icon(Icons.attach_file),
          label: const Text('Attach files (images, PDF, text, video)'),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Max ${AppConstants.maxUploadMb} MB per file.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.lightOutline),
          ),
        ),
        for (var i = 0; i < files.length; i++)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(attachmentIcon(files[i].fileType)),
            title: Text(files[i].name, overflow: TextOverflow.ellipsis),
            subtitle: Text(formatFileSize(files[i].size)),
            trailing: IconButton(
              tooltip: 'Remove ${files[i].name}',
              icon: const Icon(Icons.close),
              onPressed:
                  enabled ? () => onChanged([...files]..removeAt(i)) : null,
            ),
          ),
      ],
    );
  }
}
