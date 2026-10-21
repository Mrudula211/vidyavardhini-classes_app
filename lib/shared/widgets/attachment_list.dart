import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/content/screens/attachment_viewer_screen.dart';
import '../models/content_model.dart';

IconData attachmentIcon(String fileType) {
  switch (fileType) {
    case 'image':
      return Icons.image_outlined;
    case 'pdf':
      return Icons.picture_as_pdf_outlined;
    case 'video':
      return Icons.videocam_outlined;
    default:
      return Icons.description_outlined;
  }
}

String formatFileSize(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Tappable list of a homework/classwork item's attachments.
/// Images and PDFs open in the in-app viewer; other types open externally.
class AttachmentList extends StatelessWidget {
  const AttachmentList({super.key, required this.attachments});

  final List<AttachmentModel> attachments;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attachments (${attachments.length})',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          for (final a in attachments)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(attachmentIcon(a.fileType)),
              title: Text(a.fileName, overflow: TextOverflow.ellipsis),
              subtitle: Text(formatFileSize(a.fileSize)),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => openAttachment(context, a),
            ),
        ],
      ),
    );
  }
}

Future<void> openAttachment(BuildContext context, AttachmentModel a) async {
  if (a.fileType == 'image' || a.fileType == 'pdf') {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AttachmentViewerScreen(attachment: a),
      ),
    );
    return;
  }
  // Video / text: hand the signed URL to the system.
  final messenger = ScaffoldMessenger.of(context);
  try {
    final url = await AttachmentViewerScreen.resolveUrl(context, a);
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No app found to open this file.')),
      );
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Could not open file: $e')));
  }
}
