import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/data/zotero_inspire_api.dart';

void main() {
  test('parseWriteToken accepts a 43-character token only', () {
    final token = List<String>.filled(43, 'A').join();
    final prefs =
        'user_pref("extensions.zotero.inspiremeta.external_token", "$token");\n';
    expect(ZoteroInspireApi.parseWriteToken(prefs), token);
    expect(
      ZoteroInspireApi.parseWriteToken(
        'user_pref("extensions.zotero.inspiremeta.external_token", "short");',
      ),
      isNull,
    );
    expect(ZoteroInspireApi.parseWriteToken(''), isNull);
  });

  test('probe, picker and add_item flow', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final token = List<String>.filled(43, 'B').join();
    final addBodies = <Map<String, Object?>>[];
    var pickerPolls = 0;

    server.listen((request) async {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      final path = request.uri.path;
      request.response.headers.contentType = ContentType.json;
      if (path == '/connector/zinspireWrite') {
        if (body['op'] == 'ping') {
          request.response.write(
            jsonEncode({
              'ok': true,
              'op': 'ping',
              'version': '4.0.4',
              'capabilities': ['ping', 'add_item', 'pick_save_target'],
            }),
          );
        } else if (body['op'] == 'add_item') {
          addBodies.add(Map<String, Object?>.from(body));
          request.response.write(
            jsonEncode({
              'ok': true,
              'op': 'add_item',
              'status': 'added',
              'item_key': 'NEWITEM1',
              'item_id': 101,
              'library_id': 1,
            }),
          );
        } else {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write(jsonEncode({'ok': false}));
        }
      } else if (path == '/connector/zinspirePickSaveTarget') {
        if (body['requestID'] == null) {
          request.response.write(
            jsonEncode({'ok': true, 'requestID': 'REQ1', 'status': 'pending'}),
          );
        } else {
          pickerPolls++;
          request.response.write(
            jsonEncode({
              'ok': true,
              'requestID': 'REQ1',
              'status': 'done',
              'libraryID': 1,
              'collectionIDs': [7],
              'selectedPath': 'My Library / Collection',
              'tags': ['test'],
              'note': 'note',
            }),
          );
        }
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write(jsonEncode({'ok': false}));
      }
      await request.response.close();
    });

    final api = ZoteroInspireApi(
      baseUrl: 'http://127.0.0.1:${server.port}',
      tokenOverride: token,
      pollInterval: const Duration(milliseconds: 1),
    );
    final status = await api.probe();
    expect(status.available, isTrue);
    expect(status.canAdd, isTrue);
    expect(status.version, '4.0.4');

    final result = await api.addItemWithPicker('1234567');
    expect(result, isNotNull);
    expect(result!.itemKey, 'NEWITEM1');
    expect(result.existing, isFalse);
    expect(pickerPolls, 1);

    expect(addBodies, hasLength(1));
    expect(addBodies.single['recid'], '1234567');
    expect(addBodies.single['library_id'], 1);
    expect(addBodies.single['collection_ids'], [7]);
    expect(addBodies.single['tags'], ['test']);
    expect(addBodies.single['note'], 'note');
  });

  test('cancelled picker returns null', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final token = List<String>.filled(43, 'C').join();

    server.listen((request) async {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/connector/zinspireWrite') {
        request.response.write(
          jsonEncode({
            'ok': true,
            'capabilities': ['add_item', 'pick_save_target'],
          }),
        );
      } else {
        request.response.write(
          jsonEncode({
            'ok': true,
            'requestID': 'REQ2',
            'status': body['requestID'] == null ? 'pending' : 'cancelled',
          }),
        );
      }
      await request.response.close();
    });

    final api = ZoteroInspireApi(
      baseUrl: 'http://127.0.0.1:${server.port}',
      tokenOverride: token,
      pollInterval: const Duration(milliseconds: 1),
    );
    expect(await api.addItemWithPicker('1234567'), isNull);
  });
  test('the write token is never sent to a host that is not this computer', () async {
    final token = List<String>.filled(43, 'C').join();
    // A real listener on loopback stands in for "somewhere else": the request
    // is addressed by a name that is not a loopback name, so it must be refused
    // before any connection is made.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var requests = 0;
    server.listen((request) async {
      requests++;
      await request.response.close();
    });
    final api = ZoteroInspireApi(
      baseUrl: 'http://example.org:${server.port}',
      tokenOverride: token,
    );
    await expectLater(
      api.addItem(
        recid: '1',
        target: const ZoteroSaveTarget(
          libraryID: 1,
          collectionIDs: [],
          tags: [],
          note: '',
        ),
      ),
      throwsA(isA<ZoteroInspireException>()),
    );
    expect((await api.probe()).available, isFalse);
    expect(requests, 0);
  });

  test('loopback names are accepted', () async {
    final token = List<String>.filled(43, 'D').join();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'ok': true, 'capabilities': []}));
      await request.response.close();
    });
    for (final host in ['127.0.0.1', 'localhost']) {
      final api = ZoteroInspireApi(
        baseUrl: 'http://$host:${server.port}',
        tokenOverride: token,
      );
      expect((await api.probe()).available, isTrue, reason: host);
    }
    expect(requests, greaterThanOrEqualTo(2));
  });
}
