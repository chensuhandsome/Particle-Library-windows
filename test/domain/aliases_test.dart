import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/domain/aliases.dart';
import 'package:pdgapp/search/name_syntax.dart';

void main() {
  test('PDG alias X(3872) maps to the current listing', () {
    expect(aliasesForPdgid('M176'), ['X(3872)']);
    expect(nameQueryKeys('X(3872)'), contains('chic1(3872)'));
  });
}
