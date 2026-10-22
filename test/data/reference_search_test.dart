import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/core/contract.dart';
import 'package:pdgapp/data/pdg_database.dart';
import 'package:pdgapp/data/sql_executor.dart';

void main() {
  late DirectSqlExecutor executor;

  setUpAll(() async {
    final snapshot = File('assets/pdgall-2026.0.sqlite');
    if (!snapshot.existsSync()) {
      fail(
        'Snapshot asset missing; this suite must run against the real pdgall file.',
      );
    }
    executor = await DirectSqlExecutor.open(snapshot.path);
  });

  tearDownAll(() async => executor.dispose());

  test('an author name finds that author\'s reference labels', () async {
    final db = await PdgDatabase.open(
      executor,
      snapshotHash: SnapshotContract.expectedSha256,
    );
    final all = await db.searchReferences('AAIJ', limit: 1000);
    // Only a handful of references were found by an exact label match before;
    // the data holds hundreds of AAIJ papers.
    expect(all.length, greaterThan(100));
    expect(
      all.every((reference) => reference.documentId.trim().startsWith('AAIJ')),
      isTrue,
      reason: 'the prefix match must not widen to other authors',
    );
    expect(await db.countSearchReferences('AAIJ'), greaterThan(100));

    // An exact label still finds exactly that reference first.
    final exact = await db.searchReferences(all.first.documentId.trim());
    expect(exact.first.documentId.trim(), all.first.documentId.trim());
  });
}
