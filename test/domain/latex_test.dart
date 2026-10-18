import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/domain/latex.dart';
import 'package:pdgapp/domain/models.dart';

void main() {
  test('typesets common PDG particle names', () {
    expect(particleNameToLatex('pi0'), r'\pi^{0}');
    expect(particleNameToLatex('K-'), r'K^{-}');
    expect(particleNameToLatex('B_s()0'), r'B_{s}^{0}');
    expect(particleNameToLatex('D_s^*()+'), r'D_{s}^{*+}');
    expect(particleNameToLatex('D*(2010)+'), r'D^{*}(2010)^{+}');
    expect(particleNameToLatex('K_0^*(1430)+'), r'K_{0}^{*}(1430)^{+}');
    expect(particleNameToLatex('f_2^\'(1525)0'), r'f_{2}^{\prime}(1525)^{0}');
    expect(particleNameToLatex('Lambdabar'), r'\bar{\Lambda}');
    expect(particleNameToLatex('mbar'), r'\bar{m}');
    expect(particleNameToLatex('lepton+'), r'\ell^{+}');
    expect(particleNameToLatex('KS0'), r'K_{S}^{0}');
    expect(particleNameToLatex('leptontilde'), r'\tilde{\ell}');
    expect(particleNameToLatex('chitilde_1()0'), r'\tilde{\chi}_{1}^{0}');
    expect(textTokenToLatex('fb**-1'), r'\mathrm{fb}^{-1}');
    expect(textTokenToLatex('J/psieta'), r'J/\psi\eta');
    expect(textTokenToLatex('chitilde_1()0'), r'\tilde{\chi}_{1}^{0}');
    expect(particleNameToLatex('nubar_tau'), r'\bar{\nu}_{\tau}');
    expect(particleNameToLatex('J/psi(1S)'), r'J/\psi(1S)');
    expect(particleNameToLatex('Omega_c0'), r'\Omega_{c}^{0}');
    expect(particleNameToLatex('B_s^0'), r'B_{s}^{0}');
    expect(particleNameToLatex('D_s^+'), r'D_{s}^{+}');
    expect(particleNameToLatex('T_c_c(3875)+'), r'T_{cc}(3875)^{+}');
    expect(particleNameToLatex('T_c_cbar(4050)+'), r'T_{c\,\bar{c}}(4050)^{+}');
    expect(
      particleNameToLatex('T_c_cbar_1(3900)+'),
      r'T_{c\,\bar{c}\,1}(3900)^{+}',
    );
    expect(
      particleNameToLatex('T_c c cbar cbar(6600)+'),
      r'T_{cc\,\bar{c}\,\bar{c}}(6600)^{+}',
    );
    expect(
      particleNameToLatex('T_b_bbar_1(10610)+'),
      r'T_{b\,\bar{b}\,1}(10610)^{+}',
    );
  });

  test('bare and TeX-ish source tokens become math', () {
    expect(textTokenToLatex('B_s^0'), r'B_{s}^{0}');
    expect(textTokenToLatex('D_{{s}}()+-'), isNotNull);
    expect(textTokenToLatex('H_{{1}}()0'), isNotNull);
    expect(textTokenToLatex('nubar_mu'), r'\bar{\nu}_{\mu}');
    expect(textTokenToLatex('mass'), isNull);
    expect(textTokenToLatex('total'), isNull);
    expect(textTokenToLatex('CLEO-c'), isNull);
    expect(textTokenToLatex('LHCb'), isNull);
    expect(textTokenToLatex('D_s()+-'), isNotNull);
  });

  test('PDG explanatory-text expressions convert as whole units', () {
    expect(
      sourceExpressionToLatex(r'g**nu_{{{{\mathit \ell}}}}'),
      r'g^{\nu_{\ell}}',
    );
    expect(sourceExpressionToLatex('g**nu_e'), r'g^{\nu_{e}}');
    expect(sourceExpressionToLatex('q**2'), r'q^{2}');
    expect(sourceExpressionToLatex('F_{{{V+A}}}'), r'F_{V+A}');
    expect(sourceExpressionToLatex('g**nu_mathit ell'), r'g^{\nu_{\ell}}');
    expect(sourceExpressionToLatex('CLEO-c'), isNull);
  });

  test('IG(JPC) shorthand becomes superscript mathematics', () {
    expect(
      quantumLineToLatex('X(360) IG(JPC) = ??(??+)'),
      r'X(360)\,I^{G}(J^{PC}) = ??(??^{+})',
    );
    expect(
      quantumLineToLatex('X(1110) IG(JPC) = 0+(even++)'),
      r'X(1110)\,I^{G}(J^{PC}) = 0^{+}(\mathrm{even}^{++})',
    );
    expect(segmentPdgText('X(360) IG(JPC) = ??(??+)').single.latex, isNotNull);
  });

  test('dollar-delimited title math is segmented', () {
    final segments = segmentPdgText(
      r'Measurement at $\sqrt{s}$ = 7 TeV with a $W$ boson',
    );
    expect(segments.any((segment) => segment.latex == r'\sqrt{s}'), isTrue);
    expect(segments.any((segment) => segment.latex == 'W'), isTrue);
    expect(segments.any((segment) => segment.text == r'$\sqrt{s}$'), isFalse);
  });

  test('a single-stage decay equation gets one arrow', () {
    final tokens = [
      DecayToken({
        'id': 1,
        'pdgid_id': 1,
        'pdgid': 'S032.1',
        'pdgitem_id': 1,
        'name': 'D0',
        'is_outgoing': 0,
        'multiplier': 1,
        'subdecay_id': null,
        'sort': 1,
        'item_type': 'P',
      }),
      DecayToken({
        'id': 2,
        'pdgid_id': 1,
        'pdgid': 'S032.1',
        'pdgitem_id': 2,
        'name': 'K-',
        'is_outgoing': 1,
        'multiplier': 1,
        'subdecay_id': null,
        'sort': 2,
        'item_type': 'P',
      }),
      DecayToken({
        'id': 3,
        'pdgid_id': 1,
        'pdgid': 'S032.1',
        'pdgitem_id': 3,
        'name': 'pi+',
        'is_outgoing': 1,
        'multiplier': 1,
        'subdecay_id': null,
        'sort': 3,
        'item_type': 'P',
      }),
    ];
    final latex = decayTokensToLatex(tokens);
    expect(latex.contains(r'\longrightarrow'), isTrue);
    expect(RegExp(r'\longrightarrow').allMatches(latex).length, 1);
  });

  test('does not invent a typeset form for non-name text', () {
    expect(particleNameToLatex('-->'), isNull);
    expect(particleNameToLatex('K- pi+'), isNull);
    expect(particleNameToLatex('ex.K0'), isNull);
  });
}
