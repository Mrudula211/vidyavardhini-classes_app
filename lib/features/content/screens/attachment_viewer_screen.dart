import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../shared/models/content_model.dart';
import '../providers/content_providers.dart';

/// Full-screen viewer for image and PDF attachments (private storage, viewed
/// through a short-lived signed URL).
class AttachmentViewerScreen extends ConsumerWidget {
  const AttachmentViewerScreen({super.key, required this.attachment});

  final AttachmentModel attachment;

  static String _key(AttachmentModel a) => '${a.bucket}|${a.fileUrl}';

  static Future<String> resolveUrl(BuildContext context, AttachmentModel a) {
    final container = ProviderScope.containerOf(context);
    return container.read(attachmentUrlProvider(_key(a)).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(attachmentUrlProvider(_key(attachment)));

    return Scaffold(
      appBar: AppBar(
        title: Text(attachment.fileName, overflow: TextOverflow.ellipsis),
      ),
      body: urlAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load file.\n$e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(attachmentUrlProvider(_key(attachment))),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (url) => attachment.fileType == 'pdf'
            ? SfPdfViewer.network(url)
            : InteractiveViewer(
                child: Center(
                  child: Image.network(
                    url,
                    loadingBuilder: (c, child, p) => p == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (c, e, s) =>
                        const Center(child: Text('Could not display image.')),
                  ),
                ),
              ),
      ),
    );
  }
}
