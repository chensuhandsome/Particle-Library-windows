import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/domain/labels.dart';

void main() {
  test('verified experiment codes expand without guessing methods', () {
    expect(techniqueFullName('BELL'), 'Belle');
    expect(techniqueFullName('BABR'), 'BaBar');
    expect(techniqueFullName('BES3'), 'BES III');
    expect(techniqueFullName('CLE2'), 'CLEO II');
    expect(techniqueFullName('DPWA'), 'DPWA');
    expect(techniqueIsExpanded('BELL'), isTrue);
    expect(techniqueIsExpanded('DPWA'), isFalse);
  });
}
