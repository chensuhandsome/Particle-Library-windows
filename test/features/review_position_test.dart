import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/features/reviews/review_viewer_page.dart';

void main() {
  group('readingPositionToRestore', () {
    const saved = <String, Object?>{
      'page': 40,
      'zoom': 1.5,
      'scroll': [10.0, 2500.5],
    };

    test(
      'restores the saved position when nothing sends the reader elsewhere',
      () {
        final position = readingPositionToRestore(saved);
        expect(position.page, 40);
        expect(position.zoom, 1.5);
        expect(position.scroll, const Offset(10, 2500.5));
      },
    );

    test('a note link to an annotation beats the saved position', () {
      // The reader was last closed on page 40; the note points to page 7.
      final position = readingPositionToRestore(saved, explicitPage: 7);
      expect(position.page, isNull);
      expect(position.zoom, isNull);
      expect(position.scroll, isNull);
    });

    test('a link to page 1 is explicit too', () {
      final position = readingPositionToRestore(saved, explicitPage: 1);
      expect(position.page, isNull);
      expect(position.scroll, isNull);
    });

    test('unusable saved values are ignored', () {
      final position = readingPositionToRestore({
        'page': double.infinity,
        'zoom': -1,
        'scroll': [double.nan, 3],
      });
      expect(position.page, isNull);
      expect(position.zoom, isNull);
      expect(position.scroll, isNull);
      final empty = readingPositionToRestore(const <String, Object?>{});
      expect(empty.page, isNull);
    });
  });
}
