import 'dart:async';
import 'dart:io';

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
  group('talking to the local API', () {
    late HttpServer server;
    late Future<void> Function(HttpRequest request) handler;

    ZoteroBridge bridge() =>
        ZoteroBridge(baseUrl: 'http://127.0.0.1:${server.port}');

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.connectionsInfo();
      server.listen((request) async {
        request.response.done.whenComplete(() {});
        await handler(request);
      });
    });

    tearDown(() async => server.close(force: true));

    test('a Zotero with the local API switched off is "not available"', () async {
      handler = (request) async {
        request.response.statusCode = HttpStatus.forbidden;
        request.response.write('Local API is not enabled');
        await request.response.close();
      };
      expect(await bridge().isAvailable(), isFalse);
      // Its answer was read to the end and the client closed: nothing is left
      // open on the server side.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(server.connectionsInfo().total, 0);
    });

    test('a running Zotero is available', () async {
      handler = (request) async {
        request.response.write('[]');
        await request.response.close();
      };
      expect(await bridge().isAvailable(), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(server.connectionsInfo().total, 0);
    });

    test('an item is found by its INSPIRE recid', () async {
      handler = (request) async {
        request.response.write(
          '[{"key": "ABCD1234", "data": {"archive": "INSPIRE", '
          '"archiveLocation": "42"}}]',
        );
        await request.response.close();
      };
      expect(await bridge().findItemKey(recid: '42'), 'ABCD1234');
    });

    test('a server that never answers does not hang the lookup', () async {
      final stalled = Completer<void>();
      handler = (request) => stalled.future;
      final watch = Stopwatch()..start();
      expect(await bridge().isAvailable(), isFalse);
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
      stalled.complete();
    });
  });
}
