import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/data/inspire_bibtex.dart';

void main() {
  test('BibTeX cite key is parsed from the entry', () {
    expect(
        InspireBibtexService.parseBibtexKey(
            '@article{ATLAS:2023jfq,\n title={X}}'),
        'ATLAS:2023jfq');
    expect(InspireBibtexService.parseBibtexKey('not bibtex'), isNull);
  });
  test('BibTeX endpoint prefers recid and falls back to DOI', () {
    expect(
        InspireBibtexService.bibtexUri(inspireId: '2704123', doi: '')
            .toString(),
        'https://inspirehep.net/api/literature/2704123?format=bibtex');
    final viaDoi = InspireBibtexService.bibtexUri(
        inspireId: '', doi: '10.1103/PhysRevLett.133.161804');
    expect(viaDoi?.path, '/api/literature');
    expect(viaDoi?.queryParameters['q'],
        'doi:10.1103/PhysRevLett.133.161804');
    expect(viaDoi?.queryParameters['format'], 'bibtex');
    expect(InspireBibtexService.canFetch(inspireId: '', doi: ''), isFalse);
  });
}
