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

  test('charge pairs become a readable plus-minus', () {
    expect(plainReferenceTitle('D_s()+-'), 'D_s()±');
  });
}
