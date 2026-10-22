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
import 'package:pdgapp/features/common/context_sidebar.dart';
import 'package:pdgapp/features/common/resize_handle.dart';
import 'package:pdgapp/search/search_service.dart';
import 'package:pdgapp/user/user_store.dart';

void main() {
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
    tempDir = await Directory.systemTemp.createTemp('pdgapp-context-sidebar-');
    userStore = await UserStore.open(overridePath: '${tempDir.path}/user.json');
    services = AppServices(
      database: db,
      repository: PdgRepository(db),
      search: SearchService(db),
      userStore: userStore,
      settings: SettingsController(userStore, systemLocale: const Locale('en')),
      snapshotHash: SnapshotContract.expectedSha256,
      snapshotPath: snapshot.path,
      copiedFromBundle: true,
    );
  });

  tearDownAll(() async {
    await executor.dispose();
    await tempDir.delete(recursive: true);
  });

  Future<void> pumpSidebar(WidgetTester tester) => tester.pumpWidget(
    AppScope(
      services: services,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Row(
            children: [
              Expanded(child: SizedBox()),
              ResizableContextSidebar(
                viewportWidth: 1400,
                child: SizedBox.expand(key: Key('sidebar-body')),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'dragging the handle left widens the sidebar without collapsing',
    (tester) async {
      await pumpSidebar(tester);
      final before = tester
          .getSize(find.byKey(const Key('sidebar-body')))
          .width;
      await tester.drag(
        find.byType(VerticalResizeHandle),
        const Offset(-60, 0),
      );
      await tester.pumpAndSettle();
      final after = tester.getSize(find.byKey(const Key('sidebar-body'))).width;
      expect(after, greaterThan(before));
      expect(services.settings.sidebarMode, isNot('off'));
    },
  );

  testWidgets('dragging the handle right past the minimum collapses it', (
    tester,
  ) async {
    await pumpSidebar(tester);
    await tester.drag(find.byType(VerticalResizeHandle), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(services.settings.sidebarMode, 'off');
  });
}
