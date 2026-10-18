import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/app/app_strings.dart';
import 'package:pdgapp/domain/labels.dart';

void main() {
  test('visible product name is Particle Library in both languages', () {
    final zh = AppStrings(TextLang.zh);
    final en = AppStrings(TextLang.en);
    expect(zh.appName, 'Particle Library');
    expect(en.appName, 'Particle Library');
    expect(zh.settingsAboutText, startsWith('Particle Library'));
    expect(en.settingsAboutText, startsWith('Particle Library'));
    expect(zh.settingsAboutText, isNot(contains('Particle Desk')));
    expect(en.settingsAboutText, isNot(contains('Particle Desk')));
    expect(zh.appTagline, isNotEmpty);
    expect(en.appTagline, isNotEmpty);
  });

  test('PLACE tooltips distinguish L from B', () {
    final strings = AppStrings(TextLang.zh);
    expect(strings.measurementPlaceMeaning('U'), contains('候选'));
    expect(strings.measurementPlaceMeaning('N'), contains('不参与汇总'));
    expect(strings.measurementPlaceMeaning('L'), contains('RESULT SUMMARY'));
    expect(strings.measurementPlaceMeaning('B'), contains('不进入'));
  });
}
