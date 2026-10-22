import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/data/review_cache.dart';

final utf8Html = '<html>not a pdf</html>'.codeUnits;
final header = '%PDF-1.7\n'.codeUnits;

void main() {
  test('cached files and byte counts are scoped to the cache directory', () async {
    final dir = await Directory.systemTemp.createTemp('pdgapp-reviews-');
    final cache = ReviewCache(dir);
    await File('${dir.path}/one.pdf').writeAsBytes([
      ...'%PDF-'.codeUnits,
      1, 2, 3,
    ]);
    await File('${dir.path}/two.pdf').writeAsBytes([
      ...'%PDF-'.codeUnits,
      4, 5,
    ]);
    final names = ['one.pdf', 'two.pdf', 'missing.pdf'];
    expect(await cache.cachedFiles(names), {'one.pdf', 'two.pdf'});
    expect(await cache.cachedBytes(names), 8 + 7);
    await cache.clear();
    expect(await cache.cachedFiles(names), isEmpty);
    await dir.delete(recursive: true);
  });

  test('removeFiles deletes only the selected reviews', () async {
    final dir = await Directory.systemTemp.createTemp('pdgapp-reviews-');
    final cache = ReviewCache(dir);
    for (final name in ['keep.pdf', 'remove.pdf', 'other.pdf']) {
      await File('${dir.path}/$name').writeAsBytes('%PDF-1'.codeUnits);
    }
    expect(await cache.removeFiles(['remove.pdf', 'missing.pdf']), 1);
    expect(
      await cache.cachedFiles(['keep.pdf', 'remove.pdf', 'other.pdf']),
      {'keep.pdf', 'other.pdf'},
    );
    await dir.delete(recursive: true);
  });

  test('safe file names cannot escape the cache directory', () {
    final cache = ReviewCache(Directory('/tmp/pdgapp-cache-test'));
    expect(cache.fileFor('../evil.pdf').path,
        '/tmp/pdgapp-cache-test/.._evil.pdf');
    expect(cache.fileFor('a/b.pdf').path, '/tmp/pdgapp-cache-test/a_b.pdf');
  });

  group('downloading a review', () {
    late Directory dir;
    late ReviewCache cache;
    late HttpServer server;
    var requests = 0;
    // Chunks the server sends and how long it waits between them.
    List<List<int>> chunks = [];
    int? declaredLength;
    var chunkDelay = Duration.zero;

    String urlFor(String name) => 'http://127.0.0.1:${server.port}/$name';

    setUp(() async {
      ReviewCache.allowLoopbackHttp = true;
      dir = await Directory.systemTemp.createTemp('pdgapp-download-');
      cache = ReviewCache(dir);
      requests = 0;
      chunkDelay = Duration.zero;
      declaredLength = null;
      chunks = [
        [...'%PDF-1.7\n'.codeUnits, ...List<int>.filled(1000, 7)],
        List<int>.filled(1000, 8),
      ];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        requests++;
        final length = declaredLength;
        if (length != null) request.response.contentLength = length;
        for (final chunk in chunks) {
          request.response.add(chunk);
          await request.response.flush();
          if (chunkDelay > Duration.zero) {
            await Future<void>.delayed(chunkDelay);
          }
        }
        try {
          await request.response.close();
        } catch (_) {
          // Closing short of the declared length makes the server drop the
          // connection, which is exactly what the client must cope with.
        }
      });
    });

    tearDown(() async {
      ReviewCache.allowLoopbackHttp = false;
      ReviewCache.maxBytes = 256 << 20;
      await server.close(force: true);
      await dir.delete(recursive: true);
    });

    test('two requests for one review share a single download', () async {
      chunkDelay = const Duration(milliseconds: 150);
      final first = cache.download(fileName: 'a.pdf', url: urlFor('a.pdf'));
      // A second tap while the first download is still running.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final second = cache.download(fileName: 'a.pdf', url: urlFor('a.pdf'));
      final files = await Future.wait([first, second]);

      expect(requests, 1);
      expect(files[0].path, files[1].path);
      // The cached file is the complete download, not a half-written one.
      expect(await files[0].length(), header.length + 1000 + 1000);
      expect(File('${files[0].path}.partial').existsSync(), isFalse);
    });

    test('a finished download can be repeated later', () async {
      await cache.download(fileName: 'b.pdf', url: urlFor('b.pdf'));
      await cache.removeFiles(['b.pdf']);
      await cache.download(fileName: 'b.pdf', url: urlFor('b.pdf'));
      expect(requests, 2);
      expect(File('${dir.path}/b.pdf').existsSync(), isTrue);
    });

    test('a failed download does not block the next attempt', () async {
      chunks = [utf8Html];
      await expectLater(
        cache.download(fileName: 'c.pdf', url: urlFor('c.pdf')),
        throwsA(isA<ReviewCacheException>()),
      );
      chunks = [
        [...'%PDF-1.7\n'.codeUnits, 1, 2, 3],
      ];
      final file = await cache.download(
        fileName: 'c.pdf',
        url: urlFor('c.pdf'),
      );
      expect(await file.length(), header.length + 3);
    });

    test('a response shorter than its declared length is not cached', () async {
      declaredLength = 5000;
      await expectLater(
        cache.download(fileName: 'd.pdf', url: urlFor('d.pdf')),
        throwsA(isA<ReviewCacheException>()),
      );
      expect(File('${dir.path}/d.pdf').existsSync(), isFalse);
      expect(File('${dir.path}/d.pdf.partial').existsSync(), isFalse);
    });

    test('a download larger than the limit is refused', () async {
      ReviewCache.maxBytes = 1500;
      await expectLater(
        cache.download(fileName: 'e.pdf', url: urlFor('e.pdf')),
        throwsA(isA<ReviewCacheException>()),
      );
      expect(File('${dir.path}/e.pdf').existsSync(), isFalse);
      expect(File('${dir.path}/e.pdf.partial').existsSync(), isFalse);
    });

    test('plain http is refused outside the test switch', () async {
      ReviewCache.allowLoopbackHttp = false;
      await expectLater(
        cache.download(fileName: 'f.pdf', url: urlFor('f.pdf')),
        throwsA(isA<ReviewCacheException>()),
      );
      expect(requests, 0);
    });
  });
}
