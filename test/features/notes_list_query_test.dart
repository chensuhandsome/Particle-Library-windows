import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/features/notes/notes_list_query.dart';
import 'package:pdgapp/notes/notes.dart';

void main() {
  late Directory tempDir;
  late NotesStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pdgapp-notes-list-');
    store = await NotesStore.open(overridePath: '${tempDir.path}/notes.db');
  });

  tearDown(() async {
    await store.close();
    try {
      await tempDir.delete(recursive: true);
    } on FileSystemException {
      // Disposable temp dir.
    }
  });

  test('a tag plus a query finds a note beyond the first page', () async {
    // The oldest note is the only one that matches the query; 80 newer notes
    // carry the same tag, more than one page of 50.
    await store.create(
      title: 'rare resonance',
      bodyMarkdown: 'the rare one',
      tags: const ['kaon'],
    );
    for (var i = 0; i < 80; i++) {
      await store.create(
        title: 'common $i',
        bodyMarkdown: 'ordinary text',
        tags: const ['kaon'],
      );
    }

    final notes = await loadNoteList(
      store,
      pageSize: 50,
      tags: const ['kaon'],
      query: 'rare',
    );
    expect(notes.map((note) => note.title), ['rare resonance']);
  });

  test('unfiled notes are found behind a page of filed ones', () async {
    final collection = await store.createCollection('Filed');
    await store.create(title: 'needle unfiled', bodyMarkdown: 'needle');
    for (var i = 0; i < 70; i++) {
      await store.create(
        title: 'needle filed $i',
        bodyMarkdown: 'needle',
        collectionIds: [collection.id],
      );
    }

    final notes = await loadNoteList(
      store,
      pageSize: 50,
      query: 'needle',
      unfiledScope: true,
    );
    expect(notes.map((note) => note.title), ['needle unfiled']);
  });

  test('a full page is returned so that load more stays available', () async {
    for (var i = 0; i < 120; i++) {
      await store.create(
        title: 'item $i',
        bodyMarkdown: 'shared words',
        tags: const ['bulk'],
      );
    }
    final first = await loadNoteList(
      store,
      pageSize: 50,
      tags: const ['bulk'],
      query: 'shared',
    );
    expect(first, hasLength(50));
    final more = await loadNoteList(
      store,
      pageSize: 100,
      tags: const ['bulk'],
      query: 'shared',
    );
    expect(more, hasLength(100));
    final all = await loadNoteList(
      store,
      pageSize: 150,
      tags: const ['bulk'],
      query: 'shared',
    );
    expect(all, hasLength(120));
  });

  test('without extra filters it is the plain store query', () async {
    final collection = await store.createCollection('C');
    await store.create(title: 'in collection', collectionIds: [collection.id]);
    await store.create(title: 'loose');

    final recent = await loadNoteList(store, pageSize: 50);
    expect(recent, hasLength(2));
    final inCollection = await loadNoteList(
      store,
      pageSize: 50,
      collectionId: collection.id,
    );
    expect(inCollection.single.title, 'in collection');
    final unfiled = await loadNoteList(store, pageSize: 50, unfiledScope: true);
    expect(unfiled.single.title, 'loose');
  });
}
