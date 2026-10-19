import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/features/reference/reference_page.dart';

void main() {
  test('MathML titles become readable text', () {
    const title =
        'Observation of <math display="inline"><mrow><mi>X</mi>'
        '<mo>(</mo><mn>3872</mn><mo>)</mo></mrow><mo>+</mo></math>'
        ' and <math><mi>ω</mi></math> X(3872)';
    final plain = plainReferenceTitle(title);
    expect(plain, isNot(contains('<')));
    expect(plain, contains('X'));
    expect(plain, contains('3872'));
    expect(plain, contains('ω'));
    expect(plain, isNot(contains('  ')));
  });

  test('MathML roots, fractions and JATS scripts become readable', () {
    expect(
      plainReferenceTitle(
        'at <math><msqrt><mi>s</mi></msqrt><mo>=</mo><mn>13</mn></math> TeV',
      ),
      'at √s = 13 TeV',
    );
    expect(plainReferenceTitle('B<sup>0</sup> and D<sub>s</sub>'), 'B⁰ and Dₛ');
    expect(
      plainReferenceTitle('<math><mfrac><mn>1</mn><mn>2</mn></mfrac></math>'),
      '1/2',
    );
  });

  test('pretty MathML whitespace and literal angle brackets survive', () {
    expect(
      plainReferenceTitle(
        '<math>\n  <msup>\n    <mi>π</mi>\n    <mo>+</mo>\n  </msup>\n'
        '  <msup>\n    <mi>π</mi>\n    <mo>-</mo>\n  </msup>\n</math>',
      ),
      'π⁺π⁻',
    );
    expect(
      plainReferenceTitle('Region 400<sqrt(s)< 1000 MeV'),
      'Region 400<sqrt(s)< 1000 MeV',
    );
    expect(plainReferenceTitle('and <G**4>'), 'and <G**4>');
  });

  test('charge pairs become a readable plus-minus', () {
    expect(plainReferenceTitle('D_s()+-'), 'D_s()±');
  });
}
