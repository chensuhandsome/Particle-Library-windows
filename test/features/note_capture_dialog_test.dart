import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/app/app_scope.dart';
import 'package:pdgapp/app/app_theme.dart';
import 'package:pdgapp/app/settings_controller.dart';
import 'package:pdgapp/core/contract.dart';
import 'package:pdgapp/data/pdg_database.dart';
import 'package:pdgapp/data/pdg_repository.dart';
import 'package:pdgapp/data/sql_executor.dart';
import 'package:pdgapp/features/notes/note_capture.dart';
import 'package:pdgapp/notes/notes.dart';
import 'package:pdgapp/search/search_service.dart';
import 'package:pdgapp/user/user_store.dart';

void main() {
  late DirectSqlExecutor executor;
  late PdgDatabase db;
  late UserStore userStore;
  late NotesStore notes;
  late Directory tempDir;
  late AppServices services;

  setUpAll(() async {
    final snapshot = File('assets/pdgall-2026.0.sqlite');
    if (!snapshot.existsSync()) {
      fail(
        'Snapshot asset missing; this suite must run against the real pdgall file.',
      );
    }
    executor = await DirectSqlExecutor.open(snapshot.path);
    db = await PdgDatabase.open(
      executor,
      snapshotHash: SnapshotContract.expectedSha256,
    );
    tempDir = await Directory.systemTemp.createTemp('pdgapp-note-capture-');
    userStore = await UserStore.open(overridePath: '${tempDir.path}/user.json');
    notes = await NotesStore.open(overridePath: '${tempDir.path}/notes.db');
    services = AppServices(
      database: db,
      repository: PdgRepository(db),
      search: SearchService(db),
      userStore: userStore,
      settings: SettingsController(userStore, systemLocale: const Locale('en')),
      snapshotHash: SnapshotContract.expectedSha256,
      snapshotPath: snapshot.path,
      copiedFromBundle: true,
      notes: notes,
    );
  });

  tearDownAll(() async {
    await notes.close();
    await executor.dispose();
    await tempDir.delete(recursive: true);
  });

  Future<NoteRecord> makeNote(String title, String body) =>
      notes.create(title: title, bodyMarkdown: body);

  Future<void> openCapture(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => captureTextToNote(
                    context,
                    text: '1870.0 ± 0.5 MeV',
                    anchors: [NoteAnchorInput.pdgid('S031M')],
                    label: 'D+- MASS',
                  ),
                  child: const Text('capture'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('capture'));
    await tester.pumpAndSettle();
    expect(find.text('Add to note'), findsOneWidget);
  }

  Future<List<NoteRecord>> everything() =>
      notes.allForExport(includeDeleted: false);

  Future<void> clearNotes() async {
    for (final note in await everything()) {
      await notes.delete(note.id);
    }
  }

  setUp(clearNotes);

  testWidgets('tapping a note selects it and keeps the dialog open', (
    tester,
  ) async {
    await makeNote('First note', 'first body');
    await makeNote('Second note', 'second body');
    await openCapture(tester);

    await tester.tap(find.text('Second note'));
    await tester.pumpAndSettle();

    // The dialog is still there with both actions available.
    expect(find.text('Add to note'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Save & open'), findsOneWidget);
    expect(find.text('Appending to: Second note'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    // Nothing has been written yet.
    expect((await everything()).length, 2);
    for (final note in await everything()) {
      expect(note.bodyMarkdown, isNot(contains('1870.0')));
    }
  });

  testWidgets('Save appends to the selected note only', (tester) async {
    final first = await makeNote('First note', 'first body');
    final second = await makeNote('Second note', 'second body');
    await openCapture(tester);

    await tester.tap(find.text('Second note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Add to note'), findsNothing);
    final all = await everything();
    expect(all, hasLength(2));
    expect(
      (await notes.noteById(second.id))!.bodyMarkdown,
      allOf(contains('second body'), contains('1870.0')),
    );
    expect((await notes.noteById(first.id))!.bodyMarkdown, 'first body');
  });

  testWidgets('tapping the selected note again clears the selection', (
    tester,
  ) async {
    await makeNote('First note', 'first body');
    await openCapture(tester);

    await tester.tap(find.text('First note'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.text('First note'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsNothing);

    // With nothing selected, Save creates a new note.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final all = await everything();
    expect(all, hasLength(2));
    expect(
      all.where((note) => note.bodyMarkdown.contains('1870.0')),
      hasLength(1),
    );
    expect(
      all.firstWhere((note) => note.title == 'First note').bodyMarkdown,
      'first body',
    );
  });

  testWidgets('Save & open appends to the selected note and opens it', (
    tester,
  ) async {
    final target = await makeNote('Target note', 'target body');
    await openCapture(tester);

    await tester.tap(find.text('Target note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save & open'));
    await tester.pumpAndSettle();

    expect(find.text('Add to note'), findsNothing);
    expect((await notes.noteById(target.id))!.bodyMarkdown, contains('1870.0'));
    expect((await everything()), hasLength(1));
    // The editor for that note is now on screen.
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('Target note'), findsWidgets);
  });

  testWidgets('a selection hidden by the search is not applied', (
    tester,
  ) async {
    await makeNote('Alpha note', 'alpha body');
    await makeNote('Beta note', 'beta body');
    await openCapture(tester);

    await tester.tap(find.text('Alpha note'));
    await tester.pumpAndSettle();
    expect(find.text('Appending to: Alpha note'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Beta');
    await tester.pumpAndSettle();
    expect(find.text('Appending to: Alpha note'), findsNothing);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final alpha = (await everything()).firstWhere(
      (note) => note.title == 'Alpha note',
    );
    expect(alpha.bodyMarkdown, 'alpha body');
    expect(await everything(), hasLength(3));
  });
  testWidgets('Save appends to the note as it is now, not as listed', (
    tester,
  ) async {
    final target = await makeNote('Target note', 'old body');
    await openCapture(tester);

    await tester.tap(find.text('Target note'));
    await tester.pumpAndSettle();
    // An autosave from an open editor changes the note while the dialog is up.
    await notes.update(
      target.id,
      bodyMarkdown: 'typed while the dialog was open',
      expectedRevision: target.revision,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final body = (await notes.noteById(target.id))!.bodyMarkdown;
    expect(body, contains('typed while the dialog was open'));
    expect(body, contains('1870.0'));
    expect(find.text('Saved to notes'), findsOneWidget);
  });

  testWidgets('a note deleted while the dialog was open gets a new note', (
    tester,
  ) async {
    final target = await makeNote('Doomed note', 'body');
    await openCapture(tester);

    await tester.tap(find.text('Doomed note'));
    await tester.pumpAndSettle();
    await notes.delete(target.id);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final all = await everything();
    expect(all, hasLength(1));
    expect(all.single.bodyMarkdown, contains('1870.0'));
  });
}
