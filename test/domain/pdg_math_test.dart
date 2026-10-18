import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/domain/latex.dart';
import 'package:pdgapp/domain/pdg_math.dart';

void main() {
  test('PDG text scripts are right-associative', () {
    expect(
      convertPdgExpression(r'g**nu_{{{{\mathit \ell}}}}'),
      r'g^{\nu_{\ell}}',
    );
    expect(convertPdgExpression(r'g**nu_{{\mu}}'), r'g^{\nu_{\mu}}');
    expect(convertPdgExpression('g**nu_e'), r'g^{\nu_{e}}');
    expect(convertPdgExpression('g**nu'), r'g^{\nu}');
    expect(convertPdgExpression('q**2'), r'q^{2}');
  });

  test(
    'parentheses are subscripts, masses or arguments only when unambiguous',
    () {
      expect(convertPdgExpression('g(A)**e'), r'g_{A}^{e}');
      expect(convertPdgExpression('g(V)**e'), r'g_{V}^{e}');
      expect(convertPdgExpression('f(1)**L'), r'f_{1}^{L}');
      expect(convertPdgExpression('K(S)0'), r'K_{S}^{0}');
    expect(convertPdgExpression('K0S'), r'K_{S}^{0}');
    expect(convertPdgExpression('K0L'), r'K_{L}^{0}');
    expect(convertPdgExpression('D*+'), r'D^{*+}');
    expect(convertPdgExpression('D*0'), r'D^{*0}');
    expect(convertPdgExpression('D_s3*(2860)+-'),
        r'D_{s3}^{*}(2860)^{\pm}');
    expect(convertPdgExpression('D*(2010)+'), r'D^{*}(2010)^{+}');
    expect(
        convertPdgExpression(
            'G(D_s3*(2860)+- --> D*+ K0S)'),
        isNotNull);
    expect(convertPdgExpression('D_s3'), r'D_{s3}');
    expect(convertPdgExpression('D_{s3}'), r'D_{s3}');
    expect(convertPdgExpression('mbar'), r'\bar{m}');
    expect(convertPdgExpression('meanlife(pi+)'),
        r'\mathrm{meanlife}(\pi^{+})');
    expect(convertPdgExpression('meanlife(pi-)'),
        r'\mathrm{meanlife}(\pi^{-})');
    expect(convertPdgExpression('alpha(pi)'), r'\alpha_{\pi}');
    expect(convertPdgExpression('chi_c1-odd(3872)'),
        r'\chi_{c1-\mathrm{odd}}(3872)');
    expect(convertPdgExpression('fb**-1'), r'\mathrm{fb}^{-1}');
    expect(convertPdgExpression('chitilde_1()0'), r'\tilde{\chi}_{1}^{0}');
    expect(convertPdgExpression('G(mu- --> e- nu(e) nubar_mu)'),
        r'\Gamma(\mu^{-}\to e^{-}\nu_{e}\bar{\nu}_{\mu})');
    expect(convertPdgExpression('G(Z --> anomalous gamma + hadrons)'), isNotNull);
    expect(convertPdgExpression('G(B+ --> [ K- pi+ ]_D K+)'), isNotNull);
    expect(convertPdgExpression('(ex.K0)'), r'(\text{ex. }K^{0})');
    expect(convertPdgExpression('A(CP)'), r'A_{CP}');
    expect(convertPdgExpression('G(Z --> b-baryon X)'), isNotNull);
    expect(convertPdgExpression('q(r)**2'), r'q(r)^{2}');
    expect(convertPdgExpression('(1 + q(r)**2 R**2)'),
        r'(1+q(r)^{2}R^{2})');
    expect(convertPdgExpression('G(W+ --> hadrons)'),
        r'\Gamma(W^{+}\to \text{hadrons})');
    expect(convertPdgExpression('G(B+ --> [ K- pi+ ]_D K+)'), isNotNull);
    expect(convertPdgExpression('3pi0'), r'3\pi^{0}');
    expect(convertPdgExpression('D_sJ(2573)+-'),
        r'D_{sJ}(2573)^{\pm}');
    expect(convertPdgExpression('Upsilon(1,2,3S)'),
        r'\Upsilon(1,2,3S)');
    expect(
        convertPdgExpression('G(J/psi(1S) --> eta pi+ pi- 3pi0)'),
        r'\Gamma(J/\psi(1S)\to \eta \pi^{+}\pi^{-}3\pi^{0})');
    expect(convertPdgExpression("eta'"), r"\eta'");
    expect(
        convertPdgExpression(
            "G(J/psi(1S) --> gamma eta(2370) --> gamma K0S K0S eta')"),
        isNotNull);
      expect(convertPdgExpression('D_1(2420)0'), r'D_{1}(2420)^{0}');
      expect(convertPdgExpression('D_s()+-'), r'D_{s}^{\pm}');
      expect(convertPdgExpression(r'H_{{1}}()0'), r'H_{1}^{0}');
      expect(convertPdgExpression('mass**2(pi)'), r'm_{\pi}^{2}');
      expect(convertPdgExpression('mass(pi0)'), r'm_{\pi^{0}}');
      expect(convertPdgExpression('mass(e+ e-)'), r'm_{e^{+}e^{-}}');
      expect(convertPdgExpression('mass(pi+ pi-)'), r'm_{\pi^{+}\pi^{-}}');
    expect(convertPdgExpression('G(Z --> J/psi(1S) lepton+ lepton-)'),
        r'\Gamma(Z\to J/\psi(1S)\ell^{+}\ell^{-})');
    expect(
        convertPdgExpression(
            r'\Gamma(J/\psi(1S)\to \gammaA^{0}\to \gamma\gamma\gamma)'),
        r'\Gamma(J/\psi(1S)\to \gamma A^{0}\to \gamma \gamma \gamma)');
    expect(convertPdgExpression('G(total)'), r'\Gamma(\mathrm{total})');
    // Unsupported whole expression must return null, not recurse forever.
    expect(convertPdgExpression('G(B+ --> lepton+ nu_lepton X)/G(total)'),
        isNull);
    expect(textTokenToLatex('lepton+'), r'\ell^{+}');
    expect(convertPdgExpression('nu_lepton'), r'\nu_{\ell}');
    expect(convertPdgExpression('[mass(e+ e-)/mass(pi0)]**2'),
        r'[m_{e^{+}e^{-}}/m_{\pi^{0}}]^{2}');
    expect(convertPdgExpression('(1 - M^2/Lambda^2)**-2'),
        r'(1-M^{2}/\Lambda^{2})^{-2}');
      expect(convertPdgExpression('R(K)**-'), r'R(K)^{-}');
      expect(convertPdgExpression('10**-6'), r'10^{-6}');
      expect(convertPdgExpression('nubar_mu'), r'\bar{\nu}_{\mu}');
      expect(convertPdgExpression('B_s^0'), r'B_{s}^{0}');
      expect(convertPdgExpression('pi**0+'), isNull);
      expect(convertPdgExpression('pi**+0'), isNull);
      expect(convertPdgExpression('a_0(980)**+0'), isNull);
      expect(
        convertPdgExpression('sin**2(2theta(14))'),
        r'\sin^{2}(2\theta_{14})',
      );
      expect(convertPdgExpression('sqrt(W**2)'), r'\sqrt{W^{2}}');
      expect(convertPdgExpression('sqrt((mass**2(s)-mbar**2))'),
          r'\sqrt{(m_{s}^{2}-\bar{m}^{2})}');
      expect(convertPdgExpression('mbar**2'), r'\bar{m}^{2}');
      expect(convertPdgExpression('sqrt(unknownname**2)'), isNull);
    },
  );

  test('unsupported or ambiguous fragments are rejected whole', () {
    expect(convertPdgExpression('CLEO-c'), isNull);
    expect(convertPdgExpression('LHCb'), isNull);
    expect(convertPdgExpression('Deltam(21)**2'), isNull);
    expect(convertPdgExpression('D^**'), isNull);
    expect(convertPdgExpression('A(raw)**top-left'), isNull);
  });
}
