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
import 'package:pdgapp/features/common/ui.dart';
import 'package:pdgapp/features/help/help_page.dart';
import 'package:pdgapp/search/search_service.dart';
import 'package:pdgapp/user/user_store.dart';

void main() {
  late DirectSqlExecutor executor;
  late PdgDatabase db;
  late UserStore store;
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
    tempDir = await Directory.systemTemp.createTemp('pdgapp-help-page-');
    store = await UserStore.open(overridePath: '${tempDir.path}/user.json');
    services = AppServices(
      database: db,
      repository: PdgRepository(db),
      search: SearchService(db),
      userStore: store,
      settings: SettingsController(store, systemLocale: const Locale('en')),
      snapshotHash: SnapshotContract.expectedSha256,
      snapshotPath: snapshot.path,
      copiedFromBundle: true,
    );
  });

  tearDownAll(() async {
    await executor.dispose();
    await tempDir.delete(recursive: true);
  });

  testWidgets('help table of contents scrolls in the narrow layout', (
    tester,
  ) async {
    await verifyTocJump(tester, services: services, width: 600);
  });

  testWidgets('help table of contents scrolls in the wide layout', (
    tester,
  ) async {
    await verifyTocJump(tester, services: services, width: 1200);
  });
}

Future<void> verifyTocJump(
  WidgetTester tester, {
  required AppServices services,
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: AppScope(services: services, child: const HelpPage()),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('FAQ').first);
  await tester.pumpAndSettle();

  final contentScrollable = find
      .ancestor(
        of: find.byType(SectionCard).first,
        matching: find.byType(Scrollable),
      )
      .first;
  final scrollable = tester.state<ScrollableState>(contentScrollable);
  expect(scrollable.position.pixels, greaterThan(0));

  final faqHeading = find.descendant(
    of: find.byType(SectionCard),
    matching: find.text('FAQ'),
  );
  expect(faqHeading, findsOneWidget);
  final top = tester.getTopLeft(faqHeading).dy;
  expect(top, greaterThanOrEqualTo(0));
  expect(top, lessThan(1000));
}
