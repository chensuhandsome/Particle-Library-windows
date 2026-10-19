import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/app/full_backup.dart';
import 'package:pdgapp/notes/notes.dart';
import 'package:pdgapp/user/user_store.dart';

void main() {
  test('full backup round-trips settings, favorites and notes', () async {
    final dir = await Directory.systemTemp.createTemp('particle-backup-');
    addTearDown(() => dir.delete(recursive: true));
    final source = await UserStore.open(
      overridePath: '${dir.path}/source-user.json',
    );
    await source.setSettings(source.settings.copyWith(textScale: 1.2));
    await source.addRecent('X(3872)', 'all');
    final sourceNotes = await NotesStore.open(
      overridePath: '${dir.path}/source-notes.db',
    );
    await sourceNotes.create(
      title: 'Backup note',
      bodyMarkdown: 'A note with **markdown**.',
      tags: const ['backup'],
    );

    final archive = '${dir.path}/backup.zip';
    final exported = await FullBackup.export(
      user: source,
      notes: sourceNotes,
      destinationPath: archive,
    );
    expect(exported.notes, 1);
    expect(File(archive).existsSync(), isTrue);

    final target = await UserStore.open(
      overridePath: '${dir.path}/target-user.json',
    );
    final targetNotes = await NotesStore.open(
      overridePath: '${dir.path}/target-notes.db',
    );
    final imported = await FullBackup.import(
      user: target,
      notes: targetNotes,
      sourcePath: archive,
    );
    expect(imported.full, isTrue);
    expect(imported.notes, 1);
    final restored = await targetNotes.allForExport();
    expect(restored.single.title, 'Backup note');
    expect(target.settings.textScale, 1.2);
    await sourceNotes.close();
    await targetNotes.close();
  });
}
