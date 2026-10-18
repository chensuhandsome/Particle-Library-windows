import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/app/app_shell.dart';
import 'package:pdgapp/app/app_strings.dart';
import 'package:pdgapp/domain/labels.dart';

void main() {
  test('primary destinations are Search, Favorites, Notes, Settings', () {
    expect(AppTab.values.length, 4);
    expect(AppTab.values.map((tab) => tab.name).toList(), <String>[
      'search',
      'favorites',
      'notes',
      'settings',
    ]);
    expect(AppTab.notes.index, 2);
    expect(AppTab.settings.index, 3);
  });

  test('Notes navigation labels exist in both languages', () {
    const zh = AppStrings(TextLang.zh);
    const en = AppStrings(TextLang.en);
    expect(zh.navNotes, '笔记');
    expect(en.navNotes, 'Notes');
    expect(zh.notesTitle, isNotEmpty);
    expect(en.notesTitle, isNotEmpty);
    expect(zh.notesCount(2), '2 条笔记');
    expect(en.notesCount(1), '1 note');
    expect(en.notesCount(3), '3 notes');
  });
}
