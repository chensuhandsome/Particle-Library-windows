import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/data/zotero_bridge.dart';

void main() {
  test('extracts INSPIRE recids from the formats zotero-inspire writes', () {
    expect(
      ZoteroBridge.extractInspireRecid({
        'archive': 'INSPIRE',
        'archiveLocation': '2778309',
      }),
      '2778309',
    );
    expect(
      ZoteroBridge.extractInspireRecid({'extra': 'INSPIRE: 2778309'}),
      '2778309',
    );
    expect(
      ZoteroBridge.extractInspireRecid({
        'url': 'https://inspirehep.net/literature/2778309',
      }),
      '2778309',
    );
    expect(
      ZoteroBridge.extractInspireRecid({'callNumber': 'INSPIRE-2778309'}),
      '2778309',
    );
  });

  test('does not mistake an INSPIRE date line for a recid', () {
    expect(
      ZoteroBridge.extractInspireRecid({
        'extra': '35 citations (INSPIRE 2026/8/20)',
      }),
      isNull,
    );
  });
}
