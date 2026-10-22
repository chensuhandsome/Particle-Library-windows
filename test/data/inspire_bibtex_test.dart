import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/data/inspire_bibtex.dart';

void main() {
  test('BibTeX cite key is parsed from the entry', () {
    expect(
        InspireBibtexService.parseBibtexKey(
            '@article{ATLAS:2023jfq,\n title={X}}'),
        'ATLAS:2023jfq');
    expect(InspireBibtexService.parseBibtexKey('not bibtex'), isNull);
  });
  test('BibTeX endpoint prefers recid and falls back to DOI', () {
    expect(
        InspireBibtexService.bibtexUri(inspireId: '2704123', doi: '')
            .toString(),
        'https://inspirehep.net/api/literature/2704123?format=bibtex');
    final viaDoi = InspireBibtexService.bibtexUri(
        inspireId: '', doi: '10.1103/PhysRevLett.133.161804');
    expect(viaDoi?.path, '/api/literature');
    expect(viaDoi?.queryParameters['q'],
        'doi:10.1103/PhysRevLett.133.161804');
    expect(viaDoi?.queryParameters['format'], 'bibtex');
    expect(InspireBibtexService.canFetch(inspireId: '', doi: ''), isFalse);
  });
  group('a bad answer is an InspireBibtexException, nothing else', () {
    late HttpServer server;
    late Future<void> Function(HttpResponse response) respond;

    InspireBibtexService service() => InspireBibtexService(
      uriBuilder: ({required inspireId, required doi}) =>
          Uri.http('127.0.0.1:${server.port}', '/bibtex'),
    );

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) => respond(request.response));
    });

    tearDown(() async => server.close(force: true));

    test('a connection that drops mid-answer', () async {
      respond = (response) async {
        // Promise 5000 bytes, send 10, and close short: the server drops the
        // connection, which the client sees as a broken transfer.
        response.contentLength = 5000;
        response.add(List<int>.filled(10, 0x40));
        await response.flush();
        try {
          await response.close();
        } catch (_) {}
      };
      await expectLater(
        service().fetchBibtex(inspireId: '1', doi: ''),
        throwsA(isA<InspireBibtexException>()),
      );
      // The cite-key path turns it into "no key" instead of throwing.
      expect(await service().fetchCiteKey(inspireId: '1', doi: ''), isNull);
    });

    test('a body that is not valid UTF-8', () async {
      respond = (response) async {
        response.add(<int>[0x40, 0xff, 0xfe, 0x41]);
        await response.close();
      };
      await expectLater(
        service().fetchBibtex(inspireId: '2', doi: ''),
        throwsA(isA<InspireBibtexException>()),
      );
      expect(await service().fetchCiteKey(inspireId: '2', doi: ''), isNull);
    });

    test('a good answer is still returned', () async {
      respond = (response) async {
        response.write('@article{Key:2024abc,\n title={X}}');
        await response.close();
      };
      expect(
        await service().fetchCiteKey(inspireId: '3', doi: ''),
        'Key:2024abc',
      );
    });
  });
}
