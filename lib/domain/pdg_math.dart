/// Parser for the ASCII/TeX-like mathematics embedded in PDG text fields.
///
/// The PDG's listing text is not LaTeX. Two conventions matter and are easy to
/// get wrong:
///
/// * `**` starts a superscript whose operand is a whole atom. Thus
///   `g**nu_{e}` is `g^{\nu_e}`, not `g^{\nu}_{e}`; the underscore belongs to
///   the superscript operand.
/// * parentheses can be a subscript (`g(A)**e` -> `g_A^e`, `f(1)**L` ->
///   `f_1^L`, `K(S)0` -> `K_S^0`), a mass label (`D_1(2420)0`), or a function
///   argument (`mass(pi0)`). The parser only accepts a case when the role is
///   unambiguous; otherwise it returns `null` and the caller keeps the source
///   string verbatim.
///
/// The output is a LaTeX fragment for `flutter_math_fork`. It never drops an
/// unsupported character, and no partial conversion is allowed.
library;

const Set<String> _functionWords = {
  'mass',
  'meanlife',
  'Gamma',
  'G',
  'B',
  'A',
  'N',
  'R',
  'S',
  'T',
  'd',
  'sin',
  'cos',
  'tan',
  'sqrt',
  'log',
  'exp',
  'Sum',
  'sum',
  'Abs',
  'abs',
  'max',
  'min',
};

const Set<String> _couplingBases = {'g', 'f', 'h', 'kappa', 'lambda'};

const Map<String, String> _greekBases = {
  'pi': r'\pi',
  'Pi': r'\Pi',
  'eta': r'\eta',
  'rho': r'\rho',
  'omega': r'\omega',
  'phi': r'\phi',
  'chi': r'\chi',
  'psi': r'\psi',
  'tau': r'\tau',
  'mu': r'\mu',
  'nu': r'\nu',
  'gamma': r'\gamma',
  'Lambda': r'\Lambda',
  'Sigma': r'\Sigma',
  'Xi': r'\Xi',
  'Omega': r'\Omega',
  'Delta': r'\Delta',
  'Upsilon': r'\Upsilon',
  'Theta': r'\Theta',
  'alpha': r'\alpha',
  'beta': r'\beta',
  'lambda': r'\lambda',
  'sigma': r'\sigma',
  'kappa': r'\kappa',
  'epsilon': r'\epsilon',
  'zeta': r'\zeta',
  'theta': r'\theta',
  'iota': r'\iota',
  'xi': r'\xi',
  'upsilon': r'\upsilon',
  'ell': r'\ell',
  'chitilde': r'\tilde{\chi}',
  'nutilde': r'\tilde{\nu}',
  'lambdatilde': r'\tilde{\lambda}',
  'kappatilde': r'\tilde{\kappa}',
  'chiOdd': r'\chi_{c1-\mathrm{odd}}',
};

const Map<String, String> _unitBases = {
  'fb': r'\mathrm{fb}',
  'pb': r'\mathrm{pb}',
  'nb': r'\mathrm{nb}',
  'ab': r'\mathrm{ab}',
};

const Set<String> _particleSymbols = {
  'p',
  'n',
  'e',
  'g',
  'q',
  'W',
  'Z',
  'H',
  'K',
  'D',
  'B',
  'N',
  'X',
  'Y',
  'f',
  'm',
  'a',
  'h',
  'b',
  'c',
  's',
  'd',
  'u',
  't',
  'r',
  'R',
  'A',
  'V',
  'T',
  'J',
  'C',
  'S',
  'P',
  'U',
  'F',
  'M',
  'E',
  'Q',
  'I',
  'L',
};

const Set<String> _formulaTextWords = {
  'invisible',
  'visible',
  'hadrons',
  'anything',
  'at',
  'all',
  'anomalous',
  'non-prompt',
};

const Map<String, String> _functionLatex = {
  'mass': 'm',
  'meanlife': r'\mathrm{meanlife}',
  'Gamma': r'\Gamma',
  'G': r'\Gamma',
  'B': 'B',
  'A': 'A',
  'N': 'N',
  'R': 'R',
  'S': 'S',
  'T': 'T',
  'd': 'd',
  'sin': r'\sin',
  'cos': r'\cos',
  'tan': r'\tan',
  'sqrt': r'\sqrt',
  'log': r'\log',
  'exp': r'\exp',
  'Sum': r'\mathrm{Sum}',
  'sum': r'\mathrm{sum}',
  'Abs': r'\mathrm{Abs}',
  'abs': r'\mathrm{abs}',
  'max': r'\max',
  'min': r'\min',
};

/// Converts one complete PDG text expression. Returns `null` if any part is
/// outside the supported grammar; the caller must then keep the original text.
String? convertPdgExpression(String source) {
  final normalized = _normalize(source);
  if (normalized == null || normalized.isEmpty) return null;
  final parser = _ExpressionParser(normalized);
  final result = parser.parse();
  if (result == null) return null;
  if (parser.index != normalized.length) return null;
  return result;
}

String? _normalize(String source) {
  var text = source.trim();
  if (text.isEmpty) return null;
  // A few PDG labels retain both MathML brace layers and \mathit:
  // K_{{{{\mathit \ell}}4}}. Remove the redundant layers before the generic
  // double-brace collapse would leave an unbalanced brace.
  text = text.replaceAllMapped(
    RegExp(r'\{+\\mathit\s*(\\[A-Za-z]+)\}+\s*([0-9]+)\}+'),
    (match) => '${match.group(1)}${match.group(2)}',
  );
  var changed = true;
  while (changed) {
    final before = text;
    text = text.replaceAll('{{', '{').replaceAll('}}', '}');
    changed = text != before;
  }
  text = text.replaceAll(RegExp(r'\\mathit\s*'), '');
  text = text.replaceAll(RegExp(r'\\\\rm\\s*'), '');
  // PDG source text sometimes concatenates a command and the next atom:
  // \\gammaA^{0} or \\gamma\\gamma. Insert an atom boundary; a command
  // followed by '(' (\\psi(1S)) is left untouched.
  text = text.replaceAllMapped(
    RegExp(
      r'\\(?:Gamma|gamma|psi|phi|pi|mu|nu|tau|ell|sigma|Lambda|Sigma|Xi|Omega|Delta|Upsilon|rho|eta|omega|chi|theta|beta|alpha|kappa|lambda|to|rightarrow|longrightarrow|pm|mp)(?=[A-Z\\])',
    ),
    (match) => '${match.group(0)} ',
  );
  text = text.replaceAll(RegExp(r'mathit\s*'), '');
  // Redundant brace layers around a simple command (K_{{{{\ell}}4}}).
  text = text.replaceAllMapped(
    RegExp(r'\{+(\\(?:ell|mu|tau|pi|gamma|nu))\}+'),
    (match) => match.group(1)!,
  );
  text = text.replaceAll('chi_c1-odd', 'chiOdd');
  // `non-phi` is a physics label: upright "non-" followed by an italic φ.
  text = text.replaceAll('non-phi', 'nonphi');
  text = text.replaceAll('c.c.', r'\text{c.c.}');
  text = text.replaceAll('b-baryon', r'\text{b-baryon}');
  // Flavour-tagging labels such as `[... ]_D` or `(... )_D*` keep the star
  // inside the subscript: `(... )_{D^*}`.
  text = text.replaceAllMapped(
    RegExp(r'([)\]]\s*_)([A-Za-z0-9]+)\*'),
    (match) => '${match[1]}{${match[2]}*}',
  );
  if (text.isEmpty) return null;
  // Reject unbalanced braces early.
  var depth = 0;
  for (final unit in text.codeUnits) {
    if (unit == 0x7B) depth++;
    if (unit == 0x7D) {
      depth--;
      if (depth < 0) return null;
    }
  }
  if (depth != 0) return null;
  return text;
}

class _Base {
  const _Base({required this.latex, required this.kind, this.name = ''});

  final String latex;
  final _BaseKind kind;
  final String name;

  bool get isFunction => kind == _BaseKind.function;
  bool get isParticle => kind == _BaseKind.particle;
  bool get isCoupling => kind == _BaseKind.coupling;
}

enum _BaseKind { particle, function, coupling, command, number, text }

const _neutralZeroBases = {'B', 'K', 'Xi', 'Lambda', 'Omega'};

class _ExpressionParser {
  _ExpressionParser(this.text);

  final String text;
  int index = 0;

  bool get atEnd => index >= text.length;
  String get current => atEnd ? '' : text[index];

  String? parse() {
    final base = _parseBase();
    if (base == null) return null;
    if (base.kind == _BaseKind.number &&
        !atEnd &&
        RegExp(r'[A-Za-z\\]').hasMatch(current)) {
      final restParser = _ExpressionParser(text.substring(index));
      final rest = restParser.parse();
      if (rest != null && restParser.index == text.length - index) {
        index = text.length;
        return '${base.latex}$rest';
      }
    }
    final buffer = StringBuffer(base.latex);
    final particleLike = base.isParticle || base.isCoupling;
    var hasSuperscript = false;
    var hasSubscript = false;
    while (!atEnd) {
      if (text.startsWith('()', index)) {
        if (base.isFunction || base.isParticle || base.isCoupling) {
          index += 2;
          continue;
        }
        return null;
      }
      if (current == '(') {
        final end = _matching(index, '(', ')');
        if (end < 0) return null;
        final content = text.substring(index + 1, end);
        final classification = _classifyParens(base, content);
        if (classification == null) return null;
        buffer.write(classification);
        index = end + 1;
        // A charge after a mass label is a superscript on the mass, not a
        // second superscript on the particle base (D_s3*(2860)+-).
        hasSuperscript = false;
        continue;
      }
      if (text.startsWith('**', index)) {
        if (hasSuperscript) return null;
        index += 2;
        final script = _parseScriptAtom(includeNested: true);
        if (script == null) return null;
        if (base.isParticle && RegExp(r'^\+[0-9]+$').hasMatch(script)) {
          return null;
        }
        hasSuperscript = true;
        buffer.write('^{');
        buffer.write(script);
        buffer.write('}');
        continue;
      }
      if (current == '_' || current == '^') {
        final operator = current;
        if (operator == '^' && hasSuperscript) return null;
        if (operator == '_' && hasSubscript) return null;
        index++;
        final script = _parseScriptAtom(
          allowNeutralZero: _neutralZeroBases.contains(base.name),
        );
        if (script == null) return null;
        if (operator == '^') {
          hasSuperscript = true;
        } else {
          hasSubscript = true;
        }
        buffer.write(operator == '^' ? '^{' : '_{');
        buffer.write(script);
        buffer.write('}');
        continue;
      }
      if (base.name == 'K' && text.startsWith('0S', index)) {
        buffer.write('_{S}^{0}');
        index += 2;
        continue;
      }
      if (base.name == 'K' && text.startsWith('0L', index)) {
        buffer.write('_{L}^{0}');
        index += 2;
        continue;
      }
      if (current == "'" || current == '′') {
        buffer.write("'");
        index++;
        continue;
      }
      if (current == '*' && particleLike && !base.isFunction) {
        index++;
        final charge = _chargeAt(index);
        if (charge != null) {
          buffer.write('^{*${_chargeLatex(charge)}}');
          index += charge.length;
        } else {
          buffer.write('^{*}');
        }
        hasSuperscript = true;
        continue;
      }
      final charge = _chargeAt(index);
      if (charge != null && particleLike && !base.isFunction) {
        if (hasSuperscript) return null;
        hasSuperscript = true;
        buffer.write('^{');
        buffer.write(_chargeLatex(charge));
        buffer.write('}');
        index += charge.length;
        continue;
      }
      return null;
    }
    var result = buffer.toString();
    if (result.isEmpty) return null;
    if (base.name == 'mass') result = _reorderMassScripts(result);
    return result;
  }

  _Base? _parseBase() {
    if (atEnd) return null;
    if (current == r'\') {
      final command = _readCommand();
      if (command == null) return null;
      // A command such as \bar{...} is accepted only as a complete atom.
      String? group;
      if (!atEnd && current == '{') {
        final end = _matching(index, '{', '}');
        if (end < 0) return null;
        group = text.substring(index + 1, end);
        index = end + 1;
      }
      final digits = RegExp(r'^[0-9]+').firstMatch(text.substring(index));
      final suffix = digits?.group(0) ?? '';
      if (digits != null) index += suffix.length;
      final latex =
          '${group == null ? command : '$command{${_safeGroup(group)}}'}$suffix';
      final function = _functionWords.contains(command.replaceFirst(r'\', ''));
      return _Base(
        latex: latex,
        kind: function ? _BaseKind.function : _BaseKind.command,
      );
    }
    if (current == '(' || current == '[') {
      final opener = current;
      final close = opener == '(' ? ')' : ']';
      final end = _matching(index, opener, close);
      if (end < 0) return null;
      final inner = text.substring(index + 1, end);
      final converted = _SequenceParser(inner).parse();
      if (converted != null) {
        index = end + 1;
        return _Base(latex: '$opener$converted$close', kind: _BaseKind.command);
      }
      final annotation = _parentheticalAnnotation(inner);
      if (annotation != null) {
        index = end + 1;
        return _Base(latex: annotation, kind: _BaseKind.command);
      }
      return null;
    }
    if (RegExp(r'[0-9]').hasMatch(current) ||
        current == '+' ||
        current == '-') {
      final match = RegExp(r'^[+\-]?[0-9]+(?:\.[0-9]+)?')
          .firstMatch(text.substring(index));
      if (match == null) return null;
      index += match.group(0)!.length;
      return _Base(latex: match.group(0)!, kind: _BaseKind.number);
    }
    if (RegExp(r'[A-Za-z]').hasMatch(current)) {
      final word = _readWord();
      if (word == null) return null;
      if (word == 'J' && !atEnd && current == '/') {
        final match = RegExp(r'^/psi').firstMatch(text.substring(index));
        if (match == null) return null;
        index += match.end;
        return _Base(latex: r'J/\psi', kind: _BaseKind.particle, name: 'J/psi');
      }
      if (!atEnd && current == '/') {
        return null; // other slash names unsupported
      }
      final function =
          _functionWords.contains(word) && _functionLatex.containsKey(word);
      final coupling = _couplingBases.contains(word);
      if (word == 'nonphi') {
        return const _Base(
          latex: r'\text{non-}\phi',
          kind: _BaseKind.particle,
          name: 'nonphi',
        );
      }
      final greek = _greekBases[word];
      final particle = _particleSymbols.contains(word) || greek != null;

      if (word == 'lepton') {
        return _Base(latex: r'\ell', kind: _BaseKind.particle, name: word);
      }
      if (word == 'total') {
        return _Base(
          latex: r'\mathrm{total}',
          kind: _BaseKind.command,
          name: word,
        );
      }
      if (greek != null) {
        return _Base(latex: greek, kind: _BaseKind.particle, name: word);
      }
      final unit = _unitBases[word];
      if (unit != null) {
        return _Base(latex: unit, kind: _BaseKind.command, name: word);
      }
      if (word.endsWith('bar') && word.length > 3) {
        final inner = word.substring(0, word.length - 3);
        final innerLatex =
            _greekBases[inner] ??
            (_particleSymbols.contains(inner) ? inner : null);
        if (innerLatex != null) {
          return _Base(
            latex: '\\bar{$innerLatex}',
            kind: _BaseKind.particle,
            name: word,
          );
        }
      }

      final nextParenthesis = _peekParenContent();
      final nextIsArgument =
          nextParenthesis != null &&
          !_isMassLabel(nextParenthesis) &&
          !(word == 'K' && (nextParenthesis == 'S' || nextParenthesis == 'L'));
      // Symbols that are both functions and particles (B, N, G, A, R, S, T,
      // d, ...) are treated as particles when followed by a charge/script or a
      // numeric mass, and as functions when followed by a non-numeric argument.
      if (function && particle) {
        if (nextIsArgument) {
          return _Base(
            latex: _functionLatex[word]!,
            kind: _BaseKind.function,
            name: word,
          );
        }
        return _Base(latex: word, kind: _BaseKind.particle, name: word);
      }
      if (function) {
        return _Base(
          latex: _functionLatex[word]!,
          kind: _BaseKind.function,
          name: word,
        );
      }
      if (coupling && particle) {
        // f and h are both particle symbols and coupling labels. A directly
        // following parenthesised symbol/number is a coupling subscript;
        // a following subscript/charge keeps the particle reading.
        if (nextParenthesis != null &&
            RegExp(r'^[A-Za-z0-9]{1,3}$').hasMatch(nextParenthesis)) {
          return _Base(latex: word, kind: _BaseKind.coupling, name: word);
        }
        return _Base(latex: word, kind: _BaseKind.particle, name: word);
      }
      if (coupling) {
        return _Base(latex: word, kind: _BaseKind.coupling, name: word);
      }
      if (particle) {
        // A single-letter particle symbol directly followed by a non-numeric
        // argument is a variable function in running text: q(r), p(x).
        // Numeric D_1(2420)-style labels and coupling subscripts are excluded.
        if (!function &&
            !coupling &&
            word.length == 1 &&
            nextParenthesis != null &&
            !_isMassLabel(nextParenthesis) &&
            !(word == 'K' &&
                (nextParenthesis == 'S' || nextParenthesis == 'L'))) {
          return _Base(latex: word, kind: _BaseKind.function, name: word);
        }
        return _Base(latex: word, kind: _BaseKind.particle, name: word);
      }
      if (_formulaTextWords.contains(word.toLowerCase())) {
        return _Base(
          latex: '\\text{${word.toLowerCase()}}',
          kind: _BaseKind.text,
          name: word,
        );
      }
      return null;
    }
    return null;
  }

  String? _classifyParens(_Base base, String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return null;
    if (const {'A', 'C', 'S', 'P'}.contains(base.name) &&
        RegExp(r'^[A-Z]{1,3}$').hasMatch(trimmed)) {
      return '_{$trimmed}';
    }
    if (base.isFunction) {
      final converted = _SequenceParser(trimmed).parse();
      if (converted == null) return null;
      if (base.name == 'sqrt') return '{$converted}';
      // PDG typesets mass(X) as m_X, not as a literal function call.
      if (base.name == 'mass') return '_{$converted}';
      return '($converted)';
    }
    if (base.name == 'K' && (trimmed == 'S' || trimmed == 'L')) {
      return '_{$trimmed}';
    }
    if (base.name == 'nu' && const {'e', 'mu', 'tau'}.contains(trimmed)) {
      return '_{$trimmed}';
    }
    if (base.name == 'alpha') {
      final converted = _SequenceParser(trimmed).parse();
      if (converted != null) return '_{$converted}';
    }
    if (const {'A', 'C', 'S', 'P'}.contains(base.name) &&
        RegExp(r'^[A-Z]{1,3}$').hasMatch(trimmed)) {
      return '_{$trimmed}';
    }
    if (base.name == 'theta' && RegExp(r'^[0-9]{1,2}$').hasMatch(trimmed)) {
      return '_{$trimmed}';
    }
    if (base.isCoupling && RegExp(r'^[A-Za-z0-9]{1,3}$').hasMatch(trimmed)) {
      final converted = _SequenceParser(trimmed).parse();
      if (converted == null) return null;
      return '_{$converted}';
    }
    final annotation = _parentheticalAnnotation(trimmed);
    if (annotation != null) return annotation;
    if (_isMassLabel(trimmed) ||
        RegExp(r'^[0-9][0-9A-Za-z,]*$').hasMatch(trimmed)) {
      return '(${_safeGroup(trimmed)})';
    }
    return null;
  }

  String? _parentheticalAnnotation(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('ex.')) {
      final rest = _SequenceParser(trimmed.substring(3).trim()).parse();
      if (rest != null) return '(\\text{ex. }$rest)';
    }
    // Bare parenthetical prose, e.g. "(shown rounded)", is not mathematics.
    return null;
  }

  String? _parseScriptAtom({
    bool includeNested = false,
    bool allowNeutralZero = false,
  }) {
    if (atEnd) return null;
    if (current == '{') {
      final end = _matching(index, '{', '}');
      if (end < 0) return null;
      var content = text.substring(index + 1, end);
      index = end + 1;
      // PDG decay names sometimes retain redundant brace layers
      // (K_{{{{\mathit \ell}}4}}). Unwrap them before parsing.
      while (content.length >= 2 &&
          content.startsWith('{') &&
          content.endsWith('}')) {
        var depth = 0;
        var wraps = true;
        for (var i = 0; i < content.length; i++) {
          if (content[i] == '{') depth++;
          if (content[i] == '}') depth--;
          if (depth == 0 && i != content.length - 1) {
            wraps = false;
            break;
          }
        }
        if (!wraps) break;
        content = content.substring(1, content.length - 1);
      }
      final parsed = _SequenceParser(content).parse();
      if (parsed != null) return parsed;
      // Simple subscripts such as D_{s3} are literal labels, not expressions.
      if (RegExp(r'^[A-Za-z0-9+\-]+$').hasMatch(content)) return content;
      return null;
    }
    if (current == r'\') {
      final command = _readCommand();
      if (command == null) return null;
      String? group;
      if (!atEnd && current == '{') {
        final end = _matching(index, '{', '}');
        if (end < 0) return null;
        group = text.substring(index + 1, end);
        index = end + 1;
      }
      final digits = RegExp(r'^[0-9]+').firstMatch(text.substring(index));
      final suffix = digits?.group(0) ?? '';
      if (digits != null) index += suffix.length;
      return '${group == null ? command : '$command{${_safeGroup(group)}}'}$suffix';
    }
    if (current == "'" || current == '′') {
      index++;
      return r'\prime';
    }
    if (current == '+' || current == '-') {
      final sign = current;
      index++;
      if (atEnd) return sign;
      final atom = _parseScriptAtom(includeNested: includeNested);
      if (atom == null) return sign;
      return '$sign$atom';
    }
    if (RegExp(r'[0-9]').hasMatch(current)) {
      final match = RegExp(r'^[0-9]+(?:\.[0-9]+)?')
          .firstMatch(text.substring(index));
      if (match == null) return null;
      index += match.group(0)!.length;
      return match.group(0);
    }
    if (RegExp(r'[A-Za-z]').hasMatch(current)) {
      final word = _readWord();
      if (word == null) return null;
      final base = _baseFromWord(word, allowBare: true);
      if (base == null) {
        // Short subscripts such as D_{sJ} are literal state labels.
        if (!includeNested && RegExp(r'^[A-Za-z]{1,2}$').hasMatch(word)) {
          return word;
        }
        return null;
      }
      final buffer = StringBuffer(base.latex);
      if (!includeNested) {
        final digits = RegExp(r'^[0-9]+').firstMatch(text.substring(index));
        if (digits != null) {
          // B_s0, Xi_c0, K_S0 and friends use a trailing 0 as the neutral
          // charge, not as part of the subscript. D_s0 is intentionally
          // excluded: there it is the scalar-meson state label.
          if (!allowNeutralZero || digits.group(0) != '0' || word.length != 1) {
            buffer.write(digits.group(0));
            index += digits.group(0)!.length;
          }
        }
      }
      // A subscript directly after the superscript's atom belongs to it:
      // g**nu_{e} -> g^{\nu_e}. At base level (B_s^0) it does not, so this
      // nesting is only enabled for a ** operand.
      if (includeNested) {
        while (!atEnd && (current == '_' || current == '^')) {
          final operator = current;
          index++;
          final nested = _parseScriptAtom(includeNested: true);
          if (nested == null) return null;
          buffer.write(operator == '^' ? '^{$nested}' : '_{$nested}');
        }
      }
      return buffer.toString();
    }
    return null;
  }

  _Base? _baseFromWord(String word, {required bool allowBare}) {
    if (word == 'lepton') {
      return _Base(latex: r'\ell', kind: _BaseKind.particle, name: word);
    }
    final greek = _greekBases[word];
    if (greek != null) {
      return _Base(
        latex: word.endsWith('bar') ? '\\bar{$greek}' : greek,
        kind: _BaseKind.particle,
        name: word,
      );
    }
    if (_functionWords.contains(word) && _functionLatex.containsKey(word)) {
      return _Base(
        latex: _functionLatex[word]!,
        kind: _BaseKind.function,
        name: word,
      );
    }
    if (_couplingBases.contains(word)) {
      return _Base(latex: word, kind: _BaseKind.coupling, name: word);
    }
    if (_particleSymbols.contains(word)) {
      return _Base(latex: word, kind: _BaseKind.particle, name: word);
    }
    if (word.endsWith('bar') && word.length > 3) {
      final inner = word.substring(0, word.length - 3);
      if (_greekBases.containsKey(inner) || _particleSymbols.contains(inner)) {
        return _Base(
          latex: '\\bar{${_greekBases[inner] ?? inner}}',
          kind: _BaseKind.particle,
          name: word,
        );
      }
    }
    return null;
  }

  String? _peekParenContent() {
    if (atEnd || current != '(') return null;
    final end = _matching(index, '(', ')');
    if (end < 0) return null;
    return text.substring(index + 1, end).trim();
  }

  String? _readWord() {
    final match = RegExp(r'^[A-Za-z]+').firstMatch(text.substring(index));
    if (match == null) return null;
    index += match.group(0)!.length;
    return match.group(0);
  }

  String? _readCommand() {
    final match = RegExp(r'^\\([A-Za-z]+)').firstMatch(text.substring(index));
    if (match == null) return null;
    index += match.group(0)!.length;
    return r'\' + match.group(1)!;
  }

  int _matching(int start, String open, String close) {
    var depth = 0;
    for (var i = start; i < text.length; i++) {
      if (text[i] == open) depth++;
      if (text[i] == close) {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }

  String? _chargeAt(int at) {
    for (final candidate in const ['++', '--', '+-', '-+', '+', '-', '0']) {
      if (text.startsWith(candidate, at)) return candidate;
    }
    return null;
  }

  String _chargeLatex(String charge) {
    return switch (charge) {
      '+-' => r'\pm',
      '-+' => r'\mp',
      _ => charge,
    };
  }

  bool _isMassLabel(String content) {
    return RegExp(r'^[0-9]+(?:\.[0-9]+)?[A-Za-z]?$').hasMatch(content) ||
        RegExp(r'^[0-9]+[SPDFG]$').hasMatch(content) ||
        RegExp(r'^[0-9]+(?:\.[0-9]+)?$').hasMatch(content);
  }
}

class _SequenceParser {
  _SequenceParser(this.text);

  final String text;

  String? parse() {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    // Space-separated factors, e.g. the invariant mass m(e+ e-) or
    // 2 theta(12). Each factor must be a complete expression.
    final whitespaceParts = _splitTopLevelWhitespace(trimmed);
    if (whitespaceParts.length > 1) {
      final converted = <String>[];
      var ok = true;
      for (final part in whitespaceParts) {
        final parser = _ExpressionParser(part);
        final latex = parser.parse();
        if (latex == null || parser.index != part.length) {
          ok = false;
          break;
        }
        converted.add(latex);
      }
      if (ok) return _joinAtoms(converted);
    }
    // A single expression is the common case (a script content or argument).
    final leadingNumber = RegExp(r'^([0-9]+(?:\.[0-9]+)?)\s*([A-Za-z\\].*)$')
        .firstMatch(trimmed);
    if (leadingNumber != null) {
      final rest = _SequenceParser(leadingNumber.group(2)!).parse();
      if (rest != null) return '${leadingNumber.group(1)}$rest';
    }
    final wholeParser = _ExpressionParser(trimmed);
    final whole = wholeParser.parse();
    if (whole != null && wholeParser.index == trimmed.length) return whole;
    if (whole != null && wholeParser.index < trimmed.length) {
      final rest = trimmed.substring(wholeParser.index);
      final convertedRest = _SequenceParser(rest).parse();
      if (convertedRest != null) return '$whole$convertedRest';
    }
    // Split simple products/sums at top level. Anything more complex is left
    // to the caller as raw text.
    final parts = _split(trimmed);
    if (parts == null) return null;
    final buffer = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.operator) {
        buffer.write(part.value);
        continue;
      }
      final value = part.value.trim();
      if (value.isEmpty) return null;
      final parser = _ExpressionParser(value);
      final converted = parser.parse();
      if (converted == null || parser.index != value.length) {
        // Do not recurse on an unchanged part: when _split produced a single
        // part equal to the whole input there is no progress to make.
        if (value == trimmed || !value.contains(RegExp(r'\s'))) return null;
        final nested = _SequenceParser(value).parse();
        if (nested == null) return null;
        buffer.write(nested);
        continue;
      }
      buffer.write(converted);
    }
    return buffer.toString();
  }

  List<_Part>? _split(String input) {
    final parts = <_Part>[];
    var depth = 0;
    var start = 0;
    void flush(int end) {
      if (end > start) parts.add(_Part(input.substring(start, end), false));
    }

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '{' || char == '(' || char == '[') depth++;
      if (char == '}' || char == ')' || char == ']') depth--;
      if (depth < 0) return null;
      if (depth == 0) {
        final arrow = _arrowLengthAt(input, i);
        if (arrow > 0) {
          flush(i);
          parts.add(const _Part(r'\to ', true));
          i += arrow - 1;
          start = i + 1;
          continue;
        }
        final commandArrow = _commandArrowLengthAt(input, i);
        if (commandArrow > 0) {
          flush(i);
          parts.add(const _Part(r'\to ', true));
          i += commandArrow - 1;
          start = i + 1;
          continue;
        }
      }
      if (char == '*' && i + 1 < input.length && input[i + 1] == '*') {
        i++;
        continue;
      }
      if (char == '*' && _isParticleStar(input, i)) {
        continue;
      }
      final plusMinus = char == '+' || char == '-';
      final plusMinusIsOperator =
          !plusMinus ||
          (!_isParticleChargeBoundary(input, i) &&
              _isPlusMinusOperatorBoundary(input, i));
      if (depth == 0 &&
          plusMinusIsOperator &&
          (char == '+' ||
              char == '-' ||
              char == '=' ||
              char == '/' ||
              char == '*' ||
              char == ',')) {
        if (char == '*' && i + 1 < input.length && input[i + 1] == '*') {
          i++;
          continue;
        }
        flush(i);
        parts.add(_Part(char == ',' ? ', ' : char, true));
        start = i + 1;
      }
    }
    flush(input.length);
    return depth == 0 ? parts : null;
  }
}

List<String> _splitTopLevelWhitespace(String input) {
  final parts = <String>[];
  final buffer = StringBuffer();
  var depth = 0;
  void flush() {
    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
      buffer.clear();
    }
  }

  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (char == '(' || char == '[' || char == '{') depth++;
    if (char == ')' || char == ']' || char == '}') depth--;
    if (depth == 0 && RegExp(r'\s').hasMatch(char)) {
      flush();
      continue;
    }
    buffer.write(char);
  }
  flush();
  return parts;
}

bool _isParticleChargeBoundary(String input, int index) {
  if (index <= 0) return false;
  var before = input.substring(0, index);
  // A charge pair D_s3*(2860)+- has its second sign immediately after the
  // first; inspect the mass label before the pair.
  if (before.endsWith('+') || before.endsWith('-')) {
    before = before.substring(0, before.length - 1);
  }
  final match = RegExp(r'([A-Za-z]+)(?:_[A-Za-z0-9]+)?\*?\([^()]*\)$')
      .firstMatch(before);
  if (match == null) return false;
  return _particleSymbols.contains(match.group(1));
}

bool _isParticleStar(String input, int index) {
  if (index <= 0) return false;
  final prefix = input.substring(0, index);
  final match = RegExp(r'([A-Za-z]+)(?:_[A-Za-z0-9]+)?$').firstMatch(prefix);
  if (match == null) return false;
  return _particleSymbols.contains(match.group(1));
}

bool _isPlusMinusOperatorBoundary(String input, int index) {
  if (index == 0) return true;
  final previous = input[index - 1];
  if (RegExp(r'[\s\)\]\}]').hasMatch(previous)) return true;
  // A sum of single-letter symbols such as V+A / V-A. A charge attached to a
  // word (lepton+) or a name (CLEO-c) does not satisfy this.
  if (index + 1 < input.length &&
      RegExp(r'[A-Z]').hasMatch(previous) &&
      RegExp(r'[A-Z]').hasMatch(input[index + 1])) {
    return true;
  }
  return false;
}

String _joinAtoms(List<String> atoms) {
  final buffer = StringBuffer();
  for (final atom in atoms) {
    if (buffer.isNotEmpty &&
        RegExp(r'\\[A-Za-z]+$').hasMatch(buffer.toString()) &&
        RegExp(r'[A-Za-z\\]').hasMatch(atom[0])) {
      buffer.write(' ');
    }
    buffer.write(atom);
  }
  return buffer.toString();
}

int _arrowLengthAt(String text, int index) {
  if (text.startsWith('-->', index)) return 3;
  if (text.startsWith('->', index)) return 2;
  if (text.startsWith('→', index)) return 1;
  return 0;
}

int _commandArrowLengthAt(String text, int index) {
  for (final command in const [r'\longrightarrow', r'\rightarrow', r'\to']) {
    if (text.startsWith(command, index)) return command.length;
  }
  return 0;
}

class _Part {
  const _Part(this.value, this.operator);

  final String value;
  final bool operator;
}

/// PDG prints mass**2(pi) as m_pi^2. The parser naturally sees the
/// superscript before the parenthesised argument, so swap the two braced
/// scripts at the end when both are present.
String _reorderMassScripts(String value) {
  if (!value.startsWith('m^{')) return value;
  final supEnd = _closingBrace(value, 2);
  if (supEnd < 0) return value;
  final subStart = supEnd + 1;
  if (subStart + 1 >= value.length || !value.startsWith('_{', subStart)) {
    return value;
  }
  final subEnd = _closingBrace(value, subStart + 1);
  if (subEnd != value.length - 1) return value;
  final sup = value.substring(3, supEnd);
  final sub = value.substring(subStart + 2, subEnd);
  return 'm_{$sub}^{$sup}';
}

int _closingBrace(String value, int open) {
  var depth = 0;
  for (var i = open; i < value.length; i++) {
    if (value[i] == '{') depth++;
    if (value[i] == '}') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

String _safeGroup(String value) => value.replaceAll(r'\', '');

String? particleExpressionToLatex(String source) {
  final parser = _ExpressionParser(source);
  final result = parser.parse();
  return parser.index == source.length ? result : null;
}
