import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/features/notes/note_capture.dart';

void main() {
  test('selection capture preserves source text as a Markdown quote', () {
    final block = selectedQuoteBlock('  D0 lifetime\nsecond line  ', 'D0 (S032M)');
    expect(block, '> D0 lifetime\n> second line\n\n**D0 (S032M)**');
  });

  test('empty selection lines stay quoted', () {
    expect(selectedQuoteBlock('a\n\nb', 'X'), '> a\n>\n> b\n\n**X**');
  });
}
