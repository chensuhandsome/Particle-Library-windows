import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/app/app_scope.dart';
import 'package:pdgapp/app/app_theme.dart';
import 'package:pdgapp/app/full_backup.dart';
import 'package:pdgapp/app/settings_controller.dart';
import 'package:pdgapp/core/contract.dart';
import 'package:pdgapp/data/pdg_database.dart';
import 'package:pdgapp/data/pdg_repository.dart';
import 'package:pdgapp/data/sql_executor.dart';
import 'package:pdgapp/features/common/import_types.dart';
import 'package:pdgapp/features/settings/settings_page.dart';
import 'package:pdgapp/notes/notes.dart';
import 'package:pdgapp/search/search_service.dart';
import 'package:pdgapp/user/user_store.dart';

const _pickerChannel = MethodChannel('plugins.flutter.io/file_selector');

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
    tempDir = await Directory.systemTemp.createTemp('pdgapp-backup-import-');
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

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pickerChannel, null);
  });

  void mockPicker(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pickerChannel, handler);
  }

  // The settings page keeps scheduling frames, so pumpAndSettle never returns.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // The import runs on real file I/O, so give it real time to finish.
  Future<void> waitForSnackBar(WidgetTester tester) async {
    for (var i = 0; i < 50 && find.byType(SnackBar).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpSettings(WidgetTester tester) async {
    // Another section of the page puts a ListTile inside a filled card, which
    // trips a debug-only ink-splash assertion that has nothing to do with the
    // backup buttons under test.
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('ListTile background color')) {
        return;
      }
      reportError?.call(details);
    };
    addTearDown(() => FlutterError.onError = reportError);
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppScope(services: services, child: const SettingsPage()),
        ),
      ),
    );
    await settle(tester);
  }

  Finder importButton() => find.text('Import full backup…');

  test('import pickers name their files in the form iOS requires', () {
    // The iOS picker throws, before anything is shown, for a type group that
    // has no uniform type identifiers; Android reads the MIME types.
    for (final group in [fullBackupImportType, notesJsonImportType]) {
      expect(group.uniformTypeIdentifiers, isNotEmpty, reason: group.label);
      expect(group.mimeTypes, isNotEmpty, reason: group.label);
      expect(group.extensions, isNotEmpty, reason: group.label);
    }
    expect(fullBackupImportType.extensions, containsAll(['zip', 'json']));
    expect(
      fullBackupImportType.uniformTypeIdentifiers,
      containsAll(['com.pkware.zip-archive', 'public.json']),
    );
  });

  testWidgets('the picker is asked with the full set of file types', (
    tester,
  ) async {
    Object? requested;
    mockPicker((call) async {
      requested = call.arguments;
      return null;
    });
    await pumpSettings(tester);

    await tester.tap(importButton());
    await settle(tester);

    final groups = (requested! as Map)['acceptedTypeGroups'] as List;
    expect(groups, hasLength(1));
    final group = groups.single as Map;
    expect(group['uniformTypeIdentifiers'], contains('com.pkware.zip-archive'));
    expect(group['extensions'], containsAll(['zip', 'json']));
    expect(group['mimeTypes'], contains('application/zip'));
  });

  testWidgets('a picker that fails is reported instead of ignored', (
    tester,
  ) async {
    mockPicker((call) async {
      throw PlatformException(code: 'picker_failed', message: 'no picker');
    });
    await pumpSettings(tester);

    await tester.tap(importButton());
    await settle(tester);

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Full backup operation failed'), findsOneWidget);
    // The buttons are usable again so the user can retry.
    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: importButton(),
        matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('cancelling the picker leaves the page quiet and usable', (
    tester,
  ) async {
    mockPicker((call) async => null);
    await pumpSettings(tester);

    await tester.tap(importButton());
    await settle(tester);

    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: importButton(),
        matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('a picked backup is confirmed, imported and reported', (
    tester,
  ) async {
    // Written by hand: FullBackup.export resolves platform directories whose
    // cached lookup, started inside an earlier widget test, never completes.
    final source = '${tempDir.path}/picked-backup.json';
    await tester.runAsync(
      () => File(source).writeAsString(
        jsonEncode({
          'format': FullBackup.format,
          'formatVersion': 2,
          'notes': {
            'schema': 'particle-library.notes.v2',
            'notes': [
              {
                'uuid': 'widget-test-note',
                'title': 'Backup import widget test',
                'bodyMarkdown': 'body',
                'anchors': <Object?>[],
                'tags': <Object?>[],
                'collections': <Object?>[],
              },
            ],
          },
        }),
      ),
    );
    mockPicker((call) async => [source]);
    await pumpSettings(tester);

    await tester.tap(importButton());
    await settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('OK'));
    await waitForSnackBar(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('Full backup imported'), findsOneWidget);
    final restored = await tester.runAsync(() => notes.recent());
    expect(
      restored!.map((item) => item.title),
      contains('Backup import widget test'),
    );
  });
}
