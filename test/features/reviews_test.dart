import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/features/reviews/review_index.dart';

void main() {
  test('PDG 2026 review index is complete and links are HTTPS PDFs', () {
    final entries = [for (final group in reviewGroups) ...group.entries];
    expect(entries, hasLength(115));
    expect(entries.map((entry) => entry.file).toSet(), hasLength(115));
    for (final entry in entries) {
      expect(entry.title, isNotEmpty);
      expect(entry.file, endsWith('.pdf'));
      expect(entry.url, startsWith('https://pdg.lbl.gov/2026/reviews/'));
    }
  });

  test('review groups are non-empty and have distinct categories', () {
    expect(reviewGroups, isNotEmpty);
    for (final group in reviewGroups) {
      expect(group.entries, isNotEmpty);
      expect(group.titleZh, isNotEmpty);
      expect(group.titleEn, isNotEmpty);
    }
  });
}
