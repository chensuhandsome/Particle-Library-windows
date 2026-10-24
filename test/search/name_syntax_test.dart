import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/search/name_syntax.dart';

void main() {
  test('equivalent user spellings canonicalize together', () {
    expect(
      normalizeName('π⁰').toLowerCase(),
      normalizeName('pi0').toLowerCase(),
    );
    expect(
      normalizeName(r'\pi^0').toLowerCase(),
      normalizeName('pi0').toLowerCase(),
    );
    expect(
      normalizeName('B_s0').toLowerCase(),
      normalizeName('B_s()0').toLowerCase(),
    );
    expect(
      normalizeName('B_s^0').toLowerCase(),
      normalizeName('B_s0').toLowerCase(),
    );
    expect(
      normalizeName('Bₛ⁰').toLowerCase(),
      normalizeName('B_s0').toLowerCase(),
    );
    expect(
      normalizeName('J/ψ').toLowerCase(),
      normalizeName('J/psi').toLowerCase(),
    );
    expect(
      normalizeName(r'\bar{\Lambda}').toLowerCase(),
      normalizeName('Lambdabar').toLowerCase(),
    );
    expect(
      normalizeName('K_S0').toLowerCase(),
      normalizeName('K(S)0').toLowerCase(),
    );
    expect(
      normalizeName('K0S').toLowerCase(),
      isNot(normalizeName('K_S0').toLowerCase()),
    );
    expect(
      normalizeName('D_s^*()+').toLowerCase(),
      normalizeName('D_s^*+').toLowerCase(),
    );
  });

  test('Greek case is not silently merged', () {
    expect(normalizeName('Λ'), 'Lambda');
    expect(normalizeName('λ'), 'lambda');
    expect(normalizeName('Ω'), 'Omega');
    expect(normalizeName('ω'), 'omega');
  });

  test('anti-particle spellings become bar names', () {
    expect(normalizeName(r'\bar{p}').toLowerCase(), 'pbar');
    expect(normalizeName('p̄').toLowerCase(), 'pbar');
    expect(normalizeName('anti-D0').toLowerCase(), 'dbar0');
  });

  test('curated aliases expand to PDG names', () {
    expect(nameQueryKeys('proton'), contains('p'));
    expect(nameQueryKeys('反质子'), contains('pbar'));
    expect(nameQueryKeys('photon'), contains('gamma'));
    expect(nameQueryKeys('J/ψ'), contains('jpsi'));
    expect(nameQueryKeys('jpsi'), contains('jpsi'));
  });

  test('PDG identifier heuristic only accepts identifier-like strings', () {
    expect(looksLikePdgIdentifier('S032'), isTrue);
    expect(looksLikePdgIdentifier('M002.131'), isTrue);
    expect(looksLikePdgIdentifier('S016T22'), isTrue);
    expect(looksLikePdgIdentifier('pi0'), isFalse);
    expect(looksLikePdgIdentifier('proton'), isFalse);
  });
  group('typographic spellings of PDG names', () {
    test('prime marks equal the ASCII apostrophe', () {
      final ascii = normalizeName("eta'(958)").toLowerCase();
      expect(normalizeName('η′(958)').toLowerCase(), ascii);
      expect(normalizeName('eta\u2032(958)').toLowerCase(), ascii);
      expect(normalizeName('eta\u2019(958)').toLowerCase(), ascii);
      expect(
        normalizeName('f2\u2032(1525)').toLowerCase(),
        normalizeName("f2'(1525)").toLowerCase(),
      );
    });

    test('a double prime is two apostrophes', () {
      expect(
        normalizeName('rho\u2033(1700)').toLowerCase(),
        normalizeName("rho''(1700)").toLowerCase(),
      );
    });

    test('Upsilon with hook equals Upsilon', () {
      expect(
        normalizeName('ϒ(1S)').toLowerCase(),
        normalizeName('Upsilon(1S)').toLowerCase(),
      );
      expect(
        normalizeName('Υ(1S)').toLowerCase(),
        normalizeName('Upsilon(1S)').toLowerCase(),
      );
    });
  });

  test('identifiers that end in charge signs are recognised', () {
    expect(looksLikePdgIdentifier('B033M++'), isTrue);
    expect(looksLikePdgIdentifier('B043D-0'), isTrue);
    expect(looksLikePdgIdentifier('B033M'), isTrue);
    expect(looksLikePdgIdentifier('e+e-'), isFalse);
    expect(looksLikePdgIdentifier('K0S'), isFalse);
  });
}
