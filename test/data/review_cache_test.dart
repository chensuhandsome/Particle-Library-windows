import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/data/review_cache.dart';

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
}
