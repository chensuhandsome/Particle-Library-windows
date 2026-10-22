import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/app/app_scope.dart';
import 'package:pdgapp/app/app_theme.dart';
import 'package:pdgapp/app/settings_controller.dart';
import 'package:pdgapp/core/contract.dart';
import 'package:pdgapp/data/inspire_literature_search.dart';
import 'package:pdgapp/data/pdg_database.dart';
import 'package:pdgapp/data/pdg_repository.dart';
import 'package:pdgapp/data/sql_executor.dart';
import 'package:pdgapp/features/reference/inspire_search_page.dart';
import 'package:pdgapp/search/search_service.dart';
import 'package:pdgapp/user/user_store.dart';

typedef _Call = ({String query, int page, int size, String sort});

class _FakeService extends InspireLiteratureSearchService {
  final List<_Call> calls = [];
  int total = 100;
  Object? failWith;

  @override
  Future<InspireLiteraturePage> searchPage(
    String rawQuery, {
    int page = 1,
    int size = 50,
    String sort = 'mostcited',
  }) async {
    calls.add((query: rawQuery.trim(), page: page, size: size, sort: sort));
    final failure = failWith;
    if (failure != null) throw failure;
    return InspireLiteraturePage(
      hits: [
        InspireLiteratureHit(
          recid: 1000 + page,
          title: 'Hit of ${rawQuery.trim()} page $page',
          authors: const ['Author, A.'],
          firstAuthor: 'Author, A.',
          authorCount: 1,
          collaborations: const [],
          doi: '',
          arxivId: '',
          year: 2020,
          journal: '',
          citationCount: 1,
        ),
      ],
      total: total,
    );
  }
}

void main() {
  test('INSPIRE serves at most 10000 results of a query', () {
    expect(inspireReachablePages(36071, 20), 500);
    expect(inspireReachablePages(10000, 20), 500);
    expect(inspireReachablePages(10001, 50), 200);
    expect(inspireReachablePages(95, 20), 5);
    expect(inspireReachablePages(0, 20), 1);
    expect(inspireReachablePages(5, 20), 1);
  });

  group('the page', () {
    late DirectSqlExecutor executor;
    late PdgDatabase db;
    late UserStore userStore;
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
      tempDir = await Directory.systemTemp.createTemp('pdgapp-inspire-page-');
      userStore = await UserStore.open(
        overridePath: '${tempDir.path}/user.json',
      );
      await userStore.setSettings(
        userStore.settings.copyWith(zoteroEnabled: false),
      );
      services = AppServices(
        database: db,
        repository: PdgRepository(db),
        search: SearchService(db),
        userStore: userStore,
        settings: SettingsController(
          userStore,
          systemLocale: const Locale('en'),
        ),
        snapshotHash: SnapshotContract.expectedSha256,
        snapshotPath: snapshot.path,
        copiedFromBundle: true,
      );
    });

    tearDownAll(() async {
      await executor.dispose();
      await tempDir.delete(recursive: true);
    });

    Future<void> pumpPage(WidgetTester tester, _FakeService service) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        AppScope(
          services: services,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(body: InspireSearchPage(service: service)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> search(WidgetTester tester, String query) async {
      await tester.enterText(find.byType(TextField).first, query);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
    }

    testWidgets('next page continues the query on screen, not the box', (
      tester,
    ) async {
      final service = _FakeService();
      await pumpPage(tester, service);
      await search(tester, 'alpha');
      expect(service.calls.last.query, 'alpha');
      expect(service.calls.last.page, 1);

      // Edit the box without pressing Enter, then ask for the next page.
      await tester.enterText(find.byType(TextField).first, 'beta');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(service.calls.last.query, 'alpha');
      expect(service.calls.last.page, 2);
    });

    testWidgets('the last reachable page is 500 for a huge result set', (
      tester,
    ) async {
      final service = _FakeService()..total = 36071;
      await pumpPage(tester, service);
      await search(tester, 'huge');
      expect(find.textContaining('1 / 500'), findsOneWidget);
    });

    testWidgets('results of an earlier query do not stay under an error', (
      tester,
    ) async {
      final service = _FakeService();
      await pumpPage(tester, service);
      await search(tester, 'first');
      expect(find.text('Hit of first page 1'), findsOneWidget);

      service.failWith = const InspireSearchException('offline');
      await search(tester, 'second');
      expect(find.text('Hit of first page 1'), findsNothing);
    });

    testWidgets('a failed next page keeps the results already shown', (
      tester,
    ) async {
      final service = _FakeService();
      await pumpPage(tester, service);
      await search(tester, 'steady');
      expect(find.text('Hit of steady page 1'), findsOneWidget);

      service.failWith = const InspireSearchException('offline');
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      // Same query: the page that was on screen is still there.
      expect(find.text('Hit of steady page 1'), findsOneWidget);
    });
  });
}
