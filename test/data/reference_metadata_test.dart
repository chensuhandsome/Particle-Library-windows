import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/data/reference_metadata.dart';

void main() {
  test('DOI normalization and validation', () {
    expect(ReferenceMetadataService.normalizeDoi('https://doi.org/10.1103/PhysRevD.111.072008'),
        '10.1103/PhysRevD.111.072008');
    expect(ReferenceMetadataService.normalizeDoi('doi:10.1007/JHEP10(2025)081'),
        '10.1007/JHEP10(2025)081');
    expect(ReferenceMetadataService.isValidDoi('10.1103/PhysRevD.111.072008'), isTrue);
    expect(ReferenceMetadataService.isValidDoi('not a doi'), isFalse);
  });

  test('INSPIRE link prefers ID, then DOI, then title', () {
    expect(
        ReferenceMetadataService.inspireUri(
                inspireId: '12345', doi: '10.1/x', title: 'x')
            .toString(),
        'https://inspirehep.net/literature/12345');
    expect(
        ReferenceMetadataService.inspireUri(
                inspireId: '', doi: '10.1103/PhysRevD.111.072008', title: 'x')
            .toString(),
        contains('/search?p=doi%3A10.1103%2FPhysRevD.111.072008'));
    expect(
        ReferenceMetadataService.inspireUri(
                inspireId: '', doi: '', title: 'A title')
            .toString(),
        contains('/search?p=title'));
  });

  test('Crossref MathML title cleanup keeps readable text', () {
    const raw =
        'Study of <mml:math><mml:mi>η</mml:mi><mml:mo>→</mml:mo><mml:mi>π</mml:mi></mml:math> decays &amp; more';
    expect(ReferenceMetadataService.cleanTitle(raw), 'Study of η → π decays & more');
  });
}
