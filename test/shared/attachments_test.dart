import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidyavardhini_classes/core/services/storage_service.dart';
import 'package:vidyavardhini_classes/l10n/app_localizations.dart';
import 'package:vidyavardhini_classes/shared/models/attendance_model.dart';
import 'package:vidyavardhini_classes/shared/models/content_model.dart';
import 'package:vidyavardhini_classes/shared/widgets/attachment_list.dart';
import 'package:vidyavardhini_classes/shared/widgets/attachment_picker_field.dart';

void main() {
  group('StorageService.fileTypeFor', () {
    test('maps extensions to file_type enum values', () {
      expect(StorageService.fileTypeFor('a.JPG'), 'image');
      expect(StorageService.fileTypeFor('a.png'), 'image');
      expect(StorageService.fileTypeFor('notes.pdf'), 'pdf');
      expect(StorageService.fileTypeFor('clip.mp4'), 'video');
      expect(StorageService.fileTypeFor('readme.txt'), 'text');
      expect(StorageService.fileTypeFor('noextension'), 'text');
    });
  });

  group('formatFileSize', () {
    test('formats units and hides unknown sizes', () {
      expect(formatFileSize(null), '');
      expect(formatFileSize(0), '');
      expect(formatFileSize(512), '512 B');
      expect(formatFileSize(2048), '2 KB');
      expect(formatFileSize(5 * 1024 * 1024), '5.0 MB');
    });
  });

  group('content models', () {
    test('homework attachments get the homework bucket', () {
      final hw = HomeworkModel.fromJson({
        'id': 'h1',
        'homework_attachments': [
          {
            'id': 'a1',
            'file_url': 't/1_x.pdf',
            'file_type': 'pdf',
            'file_name': 'x.pdf',
            'file_size': 10,
          },
        ],
      });
      expect(hw.attachments.single.bucket, 'homework-attachments');
      expect(hw.attachments.single.fileUrl, 't/1_x.pdf');
    });

    test('classwork attachments get the classwork bucket', () {
      final cw = ClassworkModel.fromJson({
        'id': 'c1',
        'classwork_attachments': [
          {
            'id': 'a1',
            'file_url': 'p',
            'file_type': 'image',
            'file_name': 'i.png',
          },
        ],
      });
      expect(cw.attachments.single.bucket, 'classwork-attachments');
    });
  });

  test('TeacherCheckInResult parses RPC payload', () {
    final r = TeacherCheckInResult.fromJson(
      {
        'in_range': false,
        'distance_m': 123.4,
        'radius_m': 100,
        'status': 'absent',
      },
    );
    expect(r.inRange, isFalse);
    expect(r.distanceMeters, 123.4);
    expect(r.radiusMeters, 100);
    expect(r.status, 'absent');
  });

  testWidgets('AttachmentList renders names and is empty-safe', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AttachmentList(attachments: [])),
      ),
    );
    expect(find.textContaining('Attachments'), findsNothing);

    await t.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AttachmentList(
            attachments: [
              AttachmentModel(
                id: '1',
                bucket: 'homework-attachments',
                fileUrl: 'p',
                fileType: 'pdf',
                fileName: 'chapter4.pdf',
                fileSize: 2048,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Attachments (1)'), findsOneWidget);
    expect(find.text('chapter4.pdf'), findsOneWidget);
    expect(find.text('2 KB'), findsOneWidget);
  });

  testWidgets('AttachmentPickerField lists picked files and removes them',
      (t) async {
    var files = <PickedAttachment>[
      PickedAttachment(
        name: 'board.png',
        size: 1024,
        fileType: 'image',
        readBytes: () async => Uint8List(0),
      ),
    ];
    await t.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => AttachmentPickerField(
                files: files,
                onChanged: (v) => setState(() => files = v),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('board.png'), findsOneWidget);
    await t.tap(find.byTooltip('Remove board.png'));
    await t.pump();
    expect(find.text('board.png'), findsNothing);
    expect(files, isEmpty);
  });
}
