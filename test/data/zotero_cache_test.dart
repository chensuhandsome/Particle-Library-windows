import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/data/zotero_cache.dart';

void main() {
  test('Zotero cache resolves recid, DOI and arXiv', () async {
    final temp = await Directory.systemTemp.createTemp('zotero-cache-');
    final file = File('${temp.path}/index.json');
    final index = ZoteroCacheIndex(
      builtAt: DateTime(2026, 10, 18, 12, 30),
      sourceItems: 10,
      indexedItems: 3,
      recidKeys: {'2778309': 'FLWSX2DD'},
      doiKeys: {'10.1007/jhep08(2024)130': 'FLWSX2DD'},
      arxivKeys: {'2404.11215': 'FLWSX2DD'},
      titles: {'FLWSX2DD': 'Predicting isovector charmonium-like states'},
    );
    await index.save(file: file);
    final loaded = await ZoteroCacheIndex.load(file: file);
    expect(loaded, isNotNull);
    expect(loaded!.indexedItems, 3);
    expect(loaded.findItemKey(recid: '2778309'), 'FLWSX2DD');
    expect(
      loaded.findItemKey(doi: 'https://doi.org/10.1007/JHEP08(2024)130'),
      'FLWSX2DD',
    );
    expect(loaded.findItemKey(arxivId: 'arXiv:2404.11215v2'), 'FLWSX2DD');
    expect(loaded.titleFor('FLWSX2DD'), contains('Predicting'));
    await temp.delete(recursive: true);
  });

  test('cache is stale only after the 24 hour refresh interval', () {
    ZoteroCacheIndex index(DateTime builtAt) => ZoteroCacheIndex(
      builtAt: builtAt,
      sourceItems: 0,
      indexedItems: 0,
      recidKeys: const {},
      doiKeys: const {},
      arxivKeys: const {},
      titles: const {},
    );

    expect(
      index(DateTime.now().subtract(const Duration(hours: 23))).isStale,
      isFalse,
    );
    expect(
      index(DateTime.now().subtract(const Duration(hours: 25))).isStale,
      isTrue,
    );
  });
}
