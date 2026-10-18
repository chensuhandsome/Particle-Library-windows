/// Name syntax used only for search and display aids.
///
/// The physics identity of a name is never changed here: the database rows are
/// untouched. Search keys are forgiving (Unicode Greek, super/subscripts, LaTeX,
/// anti-particle notation), while the original spelling is always shown.
library;

const Map<String, String> greekToAscii = {
  'Α': 'Alpha',
  'α': 'alpha',
  'Β': 'Beta',
  'β': 'beta',
  'Γ': 'Gamma',
  'γ': 'gamma',
  'Δ': 'Delta',
  'δ': 'delta',
  'Ε': 'Epsilon',
  'ε': 'epsilon',
  'ζ': 'zeta',
  'Η': 'Eta',
  'η': 'eta',
  'Θ': 'Theta',
  'θ': 'theta',
  'Ι': 'Iota',
  'ι': 'iota',
  'Κ': 'Kappa',
  'κ': 'kappa',
  'Λ': 'Lambda',
  'λ': 'lambda',
  'Μ': 'Mu',
  'μ': 'mu',
  'µ': 'mu',
  'Ν': 'Nu',
  'ν': 'nu',
  'Ξ': 'Xi',
  'ξ': 'xi',
  'Ο': 'Omicron',
  'ο': 'omicron',
  'Π': 'Pi',
  'π': 'pi',
  'Ρ': 'Rho',
  'ρ': 'rho',
  'Σ': 'Sigma',
  'σ': 'sigma',
  'ς': 'sigma',
  'Τ': 'Tau',
  'τ': 'tau',
  'Υ': 'Upsilon',
  'υ': 'upsilon',
  'Φ': 'Phi',
  'φ': 'phi',
  'ϕ': 'phi',
  'Χ': 'Chi',
  'χ': 'chi',
  'Ψ': 'Psi',
  'ψ': 'psi',
  'Ω': 'Omega',
  'ω': 'omega',
};

const Map<String, String> _latexGreek = {
  'alpha': 'alpha',
  'beta': 'beta',
  'gamma': 'gamma',
  'delta': 'delta',
  'epsilon': 'epsilon',
  'zeta': 'zeta',
  'eta': 'eta',
  'theta': 'theta',
  'iota': 'iota',
  'kappa': 'kappa',
  'lambda': 'lambda',
  'mu': 'mu',
  'nu': 'nu',
  'xi': 'xi',
  'omicron': 'omicron',
  'pi': 'pi',
  'rho': 'rho',
  'sigma': 'sigma',
  'varsigma': 'sigma',
  'tau': 'tau',
  'upsilon': 'upsilon',
  'phi': 'phi',
  'varphi': 'phi',
  'chi': 'chi',
  'psi': 'psi',
  'omega': 'omega',
  'Delta': 'Delta',
  'Gamma': 'Gamma',
  'Theta': 'Theta',
  'Lambda': 'Lambda',
  'Xi': 'Xi',
  'Pi': 'Pi',
  'Sigma': 'Sigma',
  'Upsilon': 'Upsilon',
  'Phi': 'Phi',
  'Psi': 'Psi',
  'Omega': 'Omega',
};

const Map<String, String> _superscripts = {
  '⁰': '0',
  '¹': '1',
  '²': '2',
  '³': '3',
  '⁴': '4',
  '⁵': '5',
  '⁶': '6',
  '⁷': '7',
  '⁸': '8',
  '⁹': '9',
  '⁺': '+',
  '⁻': '-',
  '⁼': '=',
  '⁽': '(',
  '⁾': ')',
  'ⁿ': 'n',
  'ⁱ': 'i',
};

const Map<String, String> _subscripts = {
  '₀': '0',
  '₁': '1',
  '₂': '2',
  '₃': '3',
  '₄': '4',
  '₅': '5',
  '₆': '6',
  '₇': '7',
  '₈': '8',
  '₉': '9',
  '₊': '+',
  '₋': '-',
  '₌': '=',
  '₍': '(',
  '₎': ')',
  'ₐ': 'a',
  'ₑ': 'e',
  'ₕ': 'h',
  'ᵢ': 'i',
  'ⱼ': 'j',
  'ₖ': 'k',
  'ₗ': 'l',
  'ₘ': 'm',
  'ₙ': 'n',
  'ₒ': 'o',
  'ₚ': 'p',
  'ᵣ': 'r',
  'ₛ': 's',
  'ₜ': 't',
  'ᵤ': 'u',
  'ᵥ': 'v',
  'ₓ': 'x',
};

/// Curated common-language aliases. These are not represented as PDG source
/// fields; the UI labels a hit through them as a common alias. Chinese entries
/// are a small maintained seed, not a claim of complete translation coverage.
const Map<String, String> curatedAliases = {
  'proton': 'p',
  'antiproton': 'pbar',
  'anti-proton': 'pbar',
  'neutron': 'n',
  'antineutron': 'nbar',
  'electron': 'e',
  'positron': 'e+',
  'muon': 'mu',
  'antimuon': 'mu+',
  'photon': 'gamma',
  'gluon': 'g',
  'higgs': 'H',
  'higgs boson': 'H',
  'w boson': 'W',
  'z boson': 'Z',
  'pion': 'pi',
  'pi meson': 'pi',
  'kaon': 'K',
  'rho meson': 'rho',
  'omega meson': 'omega',
  'eta meson': 'eta',
  'j/psi': 'J/psi',
  'jpsi': 'J/psi',
  'x(3872)': 'chi_c1(3872)',
  'upsilon': 'Upsilon',
  '质子': 'p',
  '反质子': 'pbar',
  '中子': 'n',
  '反中子': 'nbar',
  '电子': 'e',
  '正电子': 'e+',
  'μ子': 'mu',
  '缪子': 'mu',
  '光子': 'gamma',
  '胶子': 'g',
  '希格斯': 'H',
  '希格斯玻色子': 'H',
  'π介子': 'pi',
  'K介子': 'K',
  '中微子': 'nu',
  '上夸克': 'u',
  '下夸克': 'd',
  '粲夸克': 'c',
  '奇异夸克': 's',
  '顶夸克': 't',
  '底夸克': 'b',
};

final Map<String, List<String>> _aliasesByNormalizedKey = () {
  final map = <String, List<String>>{};
  for (final entry in curatedAliases.entries) {
    final key = _normalizeCore(entry.key).toLowerCase();
    map.putIfAbsent(key, () => []).add(entry.value);
  }
  return map;
}();

/// Canonical ASCII form used for matching. Case is preserved so that Λ/λ are
/// not silently identified; callers compare a lower-cased key and surface all
/// candidates when two distinct names collide.
String normalizeName(String input) => _normalizeCore(input);

String _normalizeCore(String input) {
  var s = input.trim();
  if (s.isEmpty) return '';
  // Strip math delimiters.
  s = s.replaceAll(RegExp(r'^\$+|\$+$'), '');
  s = s.replaceAll(r'\(', '').replaceAll(r'\)', '');
  s = s.replaceAll(r'\[', '').replaceAll(r'\]', '');

  // \mathrm{...}, \text{...}, \mbox{...} wrappers.
  s = s.replaceAllMapped(
    RegExp(r'\\(?:mathrm|text|mbox|rm)\s*\{([^{}]*)\}'),
    (m) => m.group(1) ?? '',
  );

  // Overbar commands: \bar{X}, \overline{X} -> Xbar.
  s = s.replaceAllMapped(
    RegExp(r'\\(?:bar|overline)\s*\{([^{}]*)\}'),
    (m) => '${m.group(1)}bar',
  );
  s = s.replaceAllMapped(
    RegExp(r'\\(?:bar|overline)\s*([A-Za-z])'),
    (m) => '${m.group(1)}bar',
  );

  // Remaining LaTeX commands: known Greek names become ASCII names; unknown
  // spacing commands are removed.
  s = s.replaceAllMapped(RegExp(r'\\([A-Za-z]+)'), (m) {
    final command = m.group(1)!;
    if (command == 'left' || command == 'right' || command == 'rm') return '';
    return _latexGreek[command] ?? command;
  });
  s = s.replaceAll(RegExp(r'\\[,;:! ]'), '');

  // Unicode Greek, superscripts, subscripts, micro sign.
  final buffer = StringBuffer();
  for (final rune in s.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(
      greekToAscii[char] ?? _superscripts[char] ?? _subscripts[char] ?? char,
    );
  }
  s = buffer.toString();

  // Combining macron after a letter: p̄ -> pbar, Λ̄ -> Lambdabar.
  s = s.replaceAllMapped(RegExp('([A-Za-z])\u0304'), (m) => '${m.group(1)}bar');
  s = s.replaceAllMapped(RegExp('([A-Za-z])\u0305'), (m) => '${m.group(1)}bar');

  // Anti-particle spelling: anti-D0 -> Dbar0, anti-Λ -> Lambdabar,
  // anti-nu_tau -> nubar_tau. Applied after Greek conversion so that both
  // Latin and Greek spellings work.
  s = s.replaceAllMapped(
    RegExp(r'^anti[-\s]?([A-Za-z]+)(.*)$', caseSensitive: false),
    (m) => '${m.group(1)}bar${m.group(2)}',
  );

  // Punctuation normalization. Slash is optional in common HEP spellings
  // (J/psi vs jpsi), so it is not part of the search identity.
  s = s.replaceAll('/', '');
  s = s.replaceAll('−', '-').replaceAll('–', '-').replaceAll('—', '-');
  s = s.replaceAll('±', '+-').replaceAll('∓', '-+');

  // Kaon short-state spelling used by the snapshot: K(L)0 / K(S)0.
  s = s.replaceAllMapped(
    RegExp(r'[Kk]\(([LSls])\)0'),
    (m) => 'K${m.group(1)!.toUpperCase()}0',
  );

  // Empty mass placeholders such as B_s()0 and D_s^*().
  while (s.contains('()')) {
    s = s.replaceAll('()', '');
  }

  // TeX sub/superscript delimiters and spacing are not part of the identity.
  s = s.replaceAll(RegExp(r'[\s~{}$\\^_]'), '');
  return s;
}

/// Keys to try for a user-entered name, including curated aliases.
List<String> nameQueryKeys(String input) {
  final keys = <String>[];
  void add(String value) {
    final normalized = normalizeName(value);
    if (normalized.isNotEmpty) keys.add(normalized.toLowerCase());
  }

  add(input);
  final baseKey = normalizeName(input).toLowerCase();
  for (final aliasTarget
      in _aliasesByNormalizedKey[baseKey] ?? const <String>[]) {
    add(aliasTarget);
  }
  // The alias table itself may contain a normalized form different from the
  // raw key (spaces, Unicode). Add a second pass over raw entries.
  final rawLower = input.trim().toLowerCase();
  for (final entry in curatedAliases.entries) {
    if (entry.key.toLowerCase() == rawLower) add(entry.value);
  }
  return keys.toSet().toList(growable: false);
}

/// Whether the input looks like a PDG identifier (`S032`, `S032.1`, `M002.131`,
/// `B185`, `Q123`, `S016T22`). It is only a routing hint; the exact entry lookup
/// decides whether the identifier exists.
bool looksLikePdgIdentifier(String input) {
  return RegExp(r'^[A-Za-z]\d{3}(\.[0-9]+)?[A-Za-z0-9]*$')
      .hasMatch(input.trim());
}
