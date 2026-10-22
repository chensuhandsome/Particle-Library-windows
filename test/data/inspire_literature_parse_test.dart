import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/data/inspire_literature_search.dart';

Map<String, Object?> _hit({
  List<Map<String, Object?>> authors = const [],
  List<Map<String, Object?>> collaborations = const [],
  Map<String, Object?>? firstAuthor,
  int authorCount = 0,
}) => {
  'metadata': {
    'control_number': 3161743,
    'titles': [
      {'title': 'Elliptic Flow of Multi-strange Hadrons', 'source': 'arXiv'},
    ],
    'authors': authors,
    'first_author': ?firstAuthor,
    'author_count': authorCount,
    'collaborations': collaborations,
  },
};

void main() {
  test('collaboration-only records use the collaboration as the byline', () {
    final hit = parseInspireLiteratureHit(
      _hit(
        collaborations: [
          {'value': 'STAR'},
        ],
      ),
    );
    expect(hit, isNotNull);
    expect(hit!.authors, isEmpty);
    expect(hit.byline, 'STAR Collaboration');
    expect(hit.bylineShort, 'STAR Collaboration');
  });

  test(
    'a collaboration value that already ends with Collaboration is kept',
    () {
      final hit = parseInspireLiteratureHit(
        _hit(
          collaborations: [
            {'value': 'STAR Collaboration'},
          ],
        ),
      );
      expect(hit!.byline, 'STAR Collaboration');
    },
  );

  test('individual authors win and long lists are shortened', () {
    final hit = parseInspireLiteratureHit(
      _hit(
        authors: [
          for (var i = 0; i < 7; i++) {'full_name': 'Author $i'},
        ],
        collaborations: [
          {'value': 'STAR'},
        ],
      ),
    );
    expect(hit!.byline, startsWith('Author 0, Author 1'));
    expect(hit.bylineShort, endsWith('et al.'));
    expect(hit.bylineShort, contains('Author 4'));
    expect(hit.bylineShort, isNot(contains('Author 5')));
  });

  test('a record without the author array falls back to first_author', () {
    final hit = parseInspireLiteratureHit(
      _hit(firstAuthor: {'full_name': 'Jia, Jiangyong'}, authorCount: 1664),
    );
    expect(hit!.authors, isEmpty);
    expect(hit.byline, 'Jia, Jiangyong et al.');
    expect(hit.bylineShort, 'Jia, Jiangyong et al.');
  });

  test('records without authors or collaborations have an empty byline', () {
    final hit = parseInspireLiteratureHit(_hit());
    expect(hit!.byline, isEmpty);
    expect(hit.bylineShort, isEmpty);
  });
  group('the year of a record', () {
    Map<String, Object?> withMetadata(Map<String, Object?> extra) => {
      'metadata': {
        'control_number': 1,
        'titles': [
          {'title': 'A title'},
        ],
        ...extra,
      },
    };

    test('a published record uses its publication year', () {
      final hit = parseInspireLiteratureHit(
        withMetadata({
          'publication_info': [
            {'year': 2019, 'journal_title': 'Phys.Rev.D'},
          ],
          'earliest_date': '2018-11-02',
        }),
      );
      expect(hit!.year, 2019);
    });

    test('a preprint has the year of its earliest date', () {
      for (final date in ['2026-05-14', '2026-05', '2026']) {
        final hit = parseInspireLiteratureHit(
          withMetadata({'earliest_date': date}),
        );
        expect(hit!.year, 2026, reason: date);
      }
    });

    test('no date at all leaves the year empty', () {
      expect(parseInspireLiteratureHit(withMetadata({}))!.year, isNull);
      expect(
        parseInspireLiteratureHit(withMetadata({'earliest_date': 'n/a'}))!.year,
        isNull,
      );
    });
  });
}
