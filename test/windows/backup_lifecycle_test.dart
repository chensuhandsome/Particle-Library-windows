import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/app/full_backup.dart';
import 'package:pdgapp/notes/notes.dart';
import 'package:pdgapp/user/user_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory sandbox;
  late Directory files;
  late UserStore user;
  late NotesStore notes;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('particle-windows-backup-');
    files = await Directory('${sandbox.path}/\u5907\u4efd with spaces [1]')
        .create();
    user = await UserStore.open(overridePath: '${files.path}/user.json');
    notes = await NotesStore.open(overridePath: '${files.path}/notes.db');
  });

  tearDown(() async {
    await notes.close();
    expect(sandbox.parent.absolute.path, Directory.systemTemp.absolute.path);
    await sandbox.delete(recursive: true);
  });

  Future<File> archive(Map<String, List<int>> members) async {
    final zip = Archive();
    for (final entry in members.entries) {
      zip.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }
    final file = File('${files.path}/\u5907\u4efd [old].zip');
    await file.writeAsBytes(ZipEncoder().encode(zip), flush: true);
    return file;
  }

  Future<FullBackupImport> restore(File source) => FullBackup.import(
    user: user,
    notes: notes,
    sourcePath: source.path,
    reviewCacheDirectory: Directory('${files.path}/reviews'),
    reviewRegionsDirectory: Directory('${files.path}/regions'),
  );

  Future<void> renameAndDelete(File source) async {
    final moved = await source.rename('${source.path}.renamed');
    await moved.delete();
    expect(await moved.exists(), isFalse);
  }

  test('v0.1.3 backup restores and immediately releases its archive', () async {
    // This is the formatVersion 1 envelope written by the v0.1.3 exporter.
    final payload = {
      'format': FullBackup.format,
      'formatVersion': 1,
      'exportedAt': '2026-10-20T10:00:00Z',
      'user': user.exportData(),
      'notes': {
        'schema': 'particle-library.notes.v1',
        'notes': [
          {
            'uuid': 'windows-legacy-note',
            'title': '\u65e7\u7b14\u8bb0',
            'bodyMarkdown': 'A note from 0.1.3 with [D0](pdgid:S032).',
            'createdAt': '2026-10-20T10:00:00Z',
            'updatedAt': '2026-10-20T10:00:00Z',
          },
        ],
      },
    };
    final source = await archive({
      'backup.json': utf8.encode(jsonEncode(payload)),
      'reviews/rpp2026-rev-test.pdf': ascii.encode('%PDF-1.4\n%%EOF'),
    });
    final result = await restore(source);
    expect(result.full, isTrue);
    expect(result.notes, 1);
    expect(result.pdfs, 1);
    expect(
      (await notes.noteByUuid('windows-legacy-note'))?.title,
      '\u65e7\u7b14\u8bb0',
    );
    await renameAndDelete(source);
    final dbPath = notes.storagePath;
    await notes.close();
    notes = await NotesStore.open(overridePath: dbPath);
    expect(
      (await notes.noteByUuid('windows-legacy-note'))?.bodyMarkdown,
      contains('0.1.3'),
    );
  });

  test('a rejected ZIP also releases the source handle', () async {
    final source = await archive({'not-a-backup.txt': utf8.encode('invalid')});
    await expectLater(restore(source), throwsFormatException);
    await renameAndDelete(source);
  });
}
