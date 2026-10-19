import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/user/user_store.dart';

void main() {
  test('cached reference titles survive a reopen', () async {
    final dir = await Directory.systemTemp.createTemp('pdgapp-store-');
    final path = '${dir.path}/user_store.json';
    final store = await UserStore.open(overridePath: path);
    await store.cacheReferenceTitle('10.1103/ABC.123', 'A cached title');
    final reopened = await UserStore.open(overridePath: path);
    final cached = reopened.cachedReferenceTitle('10.1103/abc.123');
    expect(cached?.title, 'A cached title');
    expect(cached?.source, 'Crossref');
    await dir.delete(recursive: true);
  });

  test('individual recent searches can be removed', () async {
    final dir = await Directory.systemTemp.createTemp('pdgapp-store-');
    final path = '${dir.path}/user_store.json';
    final store = await UserStore.open(overridePath: path);
    await store.addRecent('D0 lifetime', 'all');
    await store.addRecent('BESIII', 'particles');
    await store.removeRecent('D0 lifetime', 'all');
    expect(store.recents.map((item) => item.query), ['BESIII']);
    final reopened = await UserStore.open(overridePath: path);
    expect(reopened.recents.map((item) => item.query), ['BESIII']);
    await dir.delete(recursive: true);
  });

  test('text scale supports five levels and clamps oversized values', () async {
    final dir = await Directory.systemTemp.createTemp('pdgapp-store-');
    final path = '${dir.path}/user_store.json';
    final store = await UserStore.open(overridePath: path);
    await store.setSettings(store.settings.copyWith(textScale: 1.2));
    final reopened = await UserStore.open(overridePath: path);
    expect(reopened.settings.textScale, 1.2);

    await store.setSettings(store.settings.copyWith(textScale: 2.0));
    final clamped = await UserStore.open(overridePath: path);
    expect(clamped.settings.textScale, 1.2);
    await dir.delete(recursive: true);
  });

  test('detailed mode persists with settings', () async {
    final dir = await Directory.systemTemp.createTemp('pdgapp-store-');
    final path = '${dir.path}/user_store.json';
    final store = await UserStore.open(overridePath: path);
    await store.setSettings(
      store.settings.copyWith(
        detailedMode: false,
        sidebarMode: 'always',
        noteLinkMode: 'sidebar',
      ),
    );
    final reopened = await UserStore.open(overridePath: path);
    expect(reopened.settings.detailedMode, isFalse);
    expect(reopened.settings.sidebarMode, 'always');
    expect(reopened.settings.noteLinkMode, 'sidebar');
    await dir.delete(recursive: true);
  });
}
