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
}
