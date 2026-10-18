import 'models.dart';
import 'pdg_math.dart';

/// Conservative conversion of PDG's ASCII particle names into LaTeX.
///
/// The converter returns `null` whenever a name cannot be interpreted with
/// certainty; callers then fall back to the selectable raw text. It never drops
/// a character to make the output look clean.
String? particleNameToLatex(String source) {
  var name = source.trim();
  if (name.isEmpty) return null;
  if (name.contains(RegExp(r'[\s\[\]{}<>,;|\\%&$#]'))) return null;
  if (name == 'K0S') return r'K_{S}^{0}';
  if (name == 'K0L') return r'K_{L}^{0}';

  // Kaon short states use a parenthesised subscript in the source.
  name = name.replaceAll(RegExp(r'\(L\)'), '_L');
  name = name.replaceAll(RegExp(r'\(S\)'), '_S');

  // LaTeX-style charge annotation: B_s^0, D_s^+, B_s^{+-}. The database names
  // usually write the neutral charge after an empty mass placeholder instead;
  // both forms are accepted for display and text enrichment.
  String? caretCharge;
  final caretChargeMatch = RegExp(r'\^(?:\{([+\-0]{1,2})\}|([+\-0]{1,2}))$')
      .firstMatch(name);
  if (caretChargeMatch != null) {
    caretCharge = caretChargeMatch.group(1) ?? caretChargeMatch.group(2);
    name = name.substring(0, caretChargeMatch.start);
  }

  // Trailing charge.
  String? charge;
  final chargeMatch = RegExp(r'(\+\+|\-\-|\+\-|\-\+|\+|\-|0)$')
      .firstMatch(name);
  if (chargeMatch != null) {
    charge = chargeMatch.group(1);
    name = name.substring(0, name.length - charge!.length);
  }
  charge ??= caretCharge;

  // Empty mass placeholders such as `B_s()0` and `D_s^*()+`.
  name = name.replaceAll('()', '');

  // Mass label in parentheses.
  String? mass;
  final massMatch = RegExp(r'\(([^()]*)\)$').firstMatch(name);
  if (massMatch != null) {
    mass = massMatch.group(1);
    name = name.substring(0, name.length - mass!.length - 2);
  }

  // Prime/star superscript. The PDG writes both `D^*(...)` and `D*(...)`.
  String? sup;
  final supMatch = RegExp(r"\^([*'\u2032]+)$").firstMatch(name);
  if (supMatch != null) {
    sup = supMatch.group(1);
    name = name.substring(0, name.length - sup!.length - 1);
  } else {
    final bareSup = RegExp(r"([*'\u2032]+)$").firstMatch(name);
    if (bareSup != null) {
      sup = bareSup.group(1);
      name = name.substring(0, name.length - sup!.length);
    }
  }

  // Subscript.
  String? sub;
  final subMatch = RegExp(r'_([A-Za-z0-9]+)$').firstMatch(name);
  if (subMatch != null) {
    sub = subMatch.group(1);
    name = name.substring(0, name.length - sub!.length - 1);
  }

  if (name.isEmpty) return null;
  if (name.contains(RegExp(r'[^A-Za-z/]'))) return null;

  var anti = false;
  if (name.endsWith('bar') && name.length > 3) {
    anti = true;
    name = name.substring(0, name.length - 3);
  }

  final base = _baseLatex(name);
  if (base == null) return null;

  final buffer = StringBuffer();
  if (anti) buffer.write(r'\bar{');
  buffer.write(base);
  if (anti) buffer.write('}');
  if (sub != null && sub.isNotEmpty) {
    buffer.write('_{');
    buffer.write(_subLatex(sub));
    buffer.write('}');
  }

  final superscript = <String>[];
  if (sup != null && sup.isNotEmpty) {
    superscript.add(sup.replaceAll('\u2032', "'"));
  }
  final hasPrime = superscript.any((part) => part.contains("'"));
  final chargePart = <String>[];
  if (charge == '0') {
    chargePart.add('0');
  } else if (charge != null && charge.isNotEmpty) {
    chargePart.add(charge);
  }

  if (mass == null) {
    // No mass label: star and charge conventionally share one superscript.
    final combined = <String>[];
    for (final part in superscript) {
      combined.add(part == '*' ? '*' : part);
    }
    combined.addAll(chargePart);
    if (combined.isNotEmpty) {
      buffer.write('^{');
      for (final part in combined) {
        buffer.write(_supPartLatex(part));
      }
      buffer.write('}');
    }
  } else {
    // With a mass: star/prime first, then mass, then charge.
    if (superscript.isNotEmpty) {
      buffer.write('^{');
      for (final part in superscript) {
        buffer.write(_supPartLatex(part));
      }
      buffer.write('}');
    }
    buffer.write('(');
    buffer.write(mass.replaceAll(r'\', ''));
    buffer.write(')');
    if (chargePart.isNotEmpty) {
      buffer.write('^{');
      for (final part in chargePart) {
        buffer.write(_supPartLatex(part));
      }
      buffer.write('}');
    }
  }

  final latex = buffer.toString();
  if (latex.contains('\\bar{}')) return null;
  // A prime that was folded into a charge superscript would be wrong; this
  // guard catches malformed combinations.
  if (hasPrime && mass == null && chargePart.isNotEmpty) {
    // With no mass, PDG has no real name combining a prime and a charge in
    // this snapshot. Keep the raw text rather than inventing an ordering.
    return null;
  }
  return latex;
}

String _subLatex(String sub) {
  return switch (sub) {
    'tau' => r'\tau',
    'mu' => r'\mu',
    'e' => 'e',
    _ => sub,
  };
}

String _supPartLatex(String part) {
  if (part.contains("'")) return r"\prime";
  if (part == '+-') return r'\pm';
  if (part == '-+') return r'\mp';
  return part;
}

String? _baseLatex(String name) {
  const greek = {
    'alpha': r'\alpha',
    'beta': r'\beta',
    'gamma': r'\gamma',
    'delta': r'\delta',
    'epsilon': r'\epsilon',
    'zeta': r'\zeta',
    'eta': r'\eta',
    'theta': r'\theta',
    'iota': r'\iota',
    'kappa': r'\kappa',
    'lambda': r'\lambda',
    'mu': r'\mu',
    'nu': r'\nu',
    'xi': r'\xi',
    'pi': r'\pi',
    'rho': r'\rho',
    'sigma': r'\sigma',
    'tau': r'\tau',
    'upsilon': r'\upsilon',
    'phi': r'\phi',
    'chi': r'\chi',
    'psi': r'\psi',
    'omega': r'\omega',
    'Delta': r'\Delta',
    'Gamma': r'\Gamma',
    'Theta': r'\Theta',
    'Lambda': r'\Lambda',
    'Xi': r'\Xi',
    'Pi': r'\Pi',
    'Sigma': r'\Sigma',
    'Upsilon': r'\Upsilon',
    'Phi': r'\Phi',
    'Psi': r'\Psi',
    'Omega': r'\Omega',
    'chitilde': r'\tilde{\chi}',
    'nutilde': r'\tilde{\nu}',
    'lambdatilde': r'\tilde{\lambda}',
    'kappatilde': r'\tilde{\kappa}',
    'leptontilde': r'\tilde{\ell}',
    'qtilde': r'\tilde{q}',
    'ttilde': r'\tilde{t}',
    'btilde': r'\tilde{b}',
  };
  if (name == 'J/psi') return r'J/\psi';
  if (name == 'lepton') return r'\ell';
  if (name == 'KS') return r'K_{S}';
  if (name == 'KL') return r'K_{L}';
  final greekBase = greek[name];
  if (greekBase != null) return greekBase;
  const latin = {
    'p',
    'n',
    'e',
    'g',
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
  };
  if (latin.contains(name)) return name;
  if (RegExp(r'^[A-Za-z]{2,}$').hasMatch(name)) {
    return '\\mathrm{$name}';
  }
  return null;
}

String mathEscapeText(String source) {
  final buffer = StringBuffer();
  for (final char in source.split('')) {
    switch (char) {
      case '\u005c':
        buffer.write(r'\backslash ');
      case '{':
      case '}':
      case '%':
      case '&':
      case '#':
      case r'$':
      case '_':
      case '^':
        buffer.write('\\$char');
      case '~':
        buffer.write(r'\sim ');
      default:
        buffer.write(char);
    }
  }
  return buffer.toString();
}

/// LaTeX for the ordered source tokens of a decay. The sequence is displayed
/// exactly in source order: arrows that are T items become `\longrightarrow`,
/// and text fragments stay text. This is not a claim that every token belongs
/// to a resolved physical stage.
String decayTokensToLatex(List<DecayToken> tokens) {
  final buffer = StringBuffer();
  bool? previousOutgoing;
  var arrowEmitted = false;
  for (var i = 0; i < tokens.length; i++) {
    final token = tokens[i];
    final name = token.name.trim();
    final isArrow =
        name == '-->' ||
        name == r'\rightarrow' ||
        name == '→' ||
        name.contains('-->');
    if (isArrow) {
      buffer.write(r'\;\longrightarrow\;');
      arrowEmitted = true;
      continue;
    }
    // A single-stage mode stores no arrow token; the incoming -> outgoing
    // change is the stage boundary and is typeset exactly once.
    if (previousOutgoing == false && token.isOutgoing && !arrowEmitted) {
      buffer.write(r'\;\longrightarrow\;');
      arrowEmitted = true;
    }
    if (i > 0 && !buffer.toString().endsWith(r'\;\longrightarrow\;')) {
      buffer.write(r'\;');
    }
    if (token.multiplier > 1) {
      buffer.write('${token.multiplier},');
    }
    final latex = particleNameToLatex(name);
    if (latex != null && token.itemType != 'T') {
      buffer.write(latex);
    } else {
      buffer.write(r'\text{');
      buffer.write(mathEscapeText(name));
      buffer.write('}');
    }
    previousOutgoing = token.isOutgoing;
  }
  return buffer.toString();
}

/// Converts one bare token from a description or explanatory text into LaTeX.
///
/// This handles the two spellings that occur in the snapshot's text fields:
/// the database's `D_s()+-` style and the TeX-ish `D_{{s}}()+-` /
/// `g**nu_{{e}}` style. A token with no mathematical marker and no known
/// particle symbol is returned as `null` so that normal prose stays prose.
String? textTokenToLatex(String token) {
  final trimmed = token.trim();
  if (trimmed.isEmpty || trimmed.length > 40) return null;
  // Crossref titles sometimes run the two final-state particles together.
  if (trimmed == 'J/psieta') return r'J/\psi\eta';
  if (trimmed == 'non-phi') return r'\text{non-}\phi';
  final lepton = RegExp(r'^lepton([+-]{1,2})?$').firstMatch(trimmed);
  if (lepton != null) {
    final charge = lepton.group(1);
    if (charge == null || charge.isEmpty) return r'\ell';
    final latex = switch (charge) {
      '+-' => r'\pm',
      '-+' => r'\mp',
      _ => charge,
    };
    return '\\ell^{$latex}';
  }
  // Experimental collaborations are names, not particle formulas. In
  // particular CLEO-c is the CLEO-c collaboration, never CLEO^- + c.
  if (_isCollaborationName(trimmed)) return null;
  final hasScript = RegExp(r'[_^]|\*\*|\{\{').hasMatch(trimmed);
  final hasSymbol = RegExp(r'[0-9*+\-\u2032]').hasMatch(trimmed);
  if (!hasScript && !hasSymbol) {
    // A bare one-letter word is usually an article or a mathematical
    // variable, not a particle. Convert only the unambiguous particle names
    // (and let the expression parser handle anything with structure).
    if (!_bareNameWords.contains(trimmed) &&
        !_isAntiSymbol(trimmed) &&
        !trimmed.contains('/')) {
      return null;
    }
    final bare = particleNameToLatex(trimmed);
    if (bare != null) return bare;
    if (!_isSymbolWord(trimmed)) return null;
  }

  // A multi-letter prose word such as CLEO or LHCb must not be turned into a
  // charged particle merely because of a trailing hyphen. Only known particle
  // bases (Greek names, anti-particle names, etc.) are accepted.
  final base =
      RegExp(r'^([A-Za-z]+(?:bar)?)').firstMatch(trimmed)?.group(1) ?? '';
  const unitWords = {'fb', 'pb', 'nb', 'ab'};
  if (base.length > 1 &&
      !_symbolWords.contains(base) &&
      !_isAntiSymbol(base) &&
      !unitWords.contains(base)) {
    return null;
  }

  var normalized = trimmed;
  while (normalized.contains('{{') || normalized.contains('}}')) {
    normalized = normalized.replaceAll('{{', '{').replaceAll('}}', '}');
  }
  normalized = normalized.replaceAll('**', '^');

  final simplified = normalized.replaceAll(RegExp(r'[{}]'), '');
  final particle = particleNameToLatex(simplified);
  if (particle != null) return particle;
  if (!hasScript) return null;
  return convertPdgExpression(trimmed);
}

/// Converts the PDG's explanatory-text markup to LaTeX.
///
/// The actual grammar lives in [convertPdgExpression]; this wrapper keeps the
/// older call sites and tests explicit.
String? sourceExpressionToLatex(String source) => convertPdgExpression(source);

/// A run of PDG text: either literal prose or a converted LaTeX fragment.
class PdgTextSegment {
  const PdgTextSegment.plain(this.text) : latex = null;

  const PdgTextSegment.math(this.latex) : text = null;

  final String? text;
  final String? latex;
}

/// Splits PDG explanatory text into literal and math segments.
///
/// Candidate expressions are scanned as balanced units (spaces inside braces
/// and parentheses are allowed). A candidate is typeset only when the whole
/// candidate converts; otherwise the exact original substring is emitted as
/// literal text. This is what prevents a half-converted formula such as
/// `sin**2(2 theta(12))` from turning into a valid prefix plus a broken tail.
List<PdgTextSegment> segmentPdgText(String original) {
  final cached = _segmentCache[original];
  if (cached != null) return cached;
  final result = _segmentPdgTextUncached(original);
  if (_segmentCache.length >= _segmentCacheLimit) {
    _segmentCache.remove(_segmentCache.keys.first);
  }
  _segmentCache[original] = result;
  return result;
}

const int _segmentCacheLimit = 300;
final Map<String, List<PdgTextSegment>> _segmentCache = {};

List<PdgTextSegment> _segmentPdgTextUncached(String original) {
  var source = original.replaceAllMapped(
    RegExp(r'([_^])mathit\s+([A-Za-z]+)'),
    (match) => '${match.group(1)}${match.group(2)}',
  );
  source = source.replaceAll(RegExp(r'\\mathit\s+'), r'\mathit');

  final segments = <PdgTextSegment>[];
  var plainStart = 0;
  var index = 0;

  void flushPlain(int end) {
    if (end > plainStart) {
      _addPlain(segments, source.substring(plainStart, end));
    }
  }

  while (index < source.length) {
    if (source[index] == r'$') {
      final end = source.indexOf(r'$', index + 1);
      if (end > index) {
        flushPlain(index);
        final body = source.substring(index + 1, end);
        if (_looksLikeSafeLatex(body)) {
          segments.add(PdgTextSegment.math(body));
        } else {
          _addPlain(segments, source.substring(index, end + 1));
        }
        index = end + 1;
        plainStart = index;
        continue;
      }
    }
    final arrowLength = _arrowLength(source, index);
    if (arrowLength > 0) {
      flushPlain(index);
      segments.add(const PdgTextSegment.math(r'\longrightarrow'));
      index += arrowLength;
      plainStart = index;
      continue;
    }
    if (_canStartExpression(source[index])) {
      final end = _scanExpression(source, index);
      if (end > index) {
        final candidate = source.substring(index, end);
        if (_isCollaborationName(candidate)) {
          flushPlain(index);
          _addPlain(segments, candidate);
          index = end;
          plainStart = index;
          continue;
        }
        final prepared = _prepareCandidate(candidate);
        String? latex;
        if (_hasMathMarker(prepared)) {
          latex = convertPdgExpression(prepared);
          // Never paper over a parser rejection of a scripted expression with
          // the narrower token converter; that is how invalid double
          // superscripts such as pi**0+ used to slip through.
          if (latex == null &&
              !prepared.contains('**') &&
              !prepared.contains(r'\')) {
            latex = textTokenToLatex(prepared);
          }
        } else {
          latex = textTokenToLatex(prepared);
        }
        if (latex != null && _looksLikeSafeLatex(latex)) {
          flushPlain(index);
          segments.add(PdgTextSegment.math(latex));
          index = end;
          plainStart = index;
          continue;
        }
        // If the whole expression has no `**` script, fall back to complete
        // name tokens inside it (e.g. G(Z --> pi0 gamma)/G(total)). Tokens are
        // validated as whole units, so this cannot produce the broken
        // half-superscript that the whole-expression rule prevents.
        flushPlain(index);
        if (!candidate.contains('**') &&
            (_emitTopLevelSplit(segments, candidate) ||
                _emitTokenFallback(segments, candidate))) {
          index = end;
          plainStart = index;
          continue;
        }
        _addPlain(segments, candidate);
        index = end;
        plainStart = index;
        continue;
      }
    }
    index++;
  }
  flushPlain(source.length);
  return segments;
}

/// Converts complete subexpressions separated by top-level operators. This is
/// what turns `mass(pi+-)-mass(pi0)` into two typeset calls without touching
/// the hyphen in a detector name such as CLEO-c (both halves simply fail to
/// convert and are emitted verbatim).
bool _emitTopLevelSplit(List<PdgTextSegment> segments, String candidate) {
  final parts = <PdgTextSegment>[];
  var converted = false;
  var start = 0;
  var depth = 0;

  void addPart(int end) {
    if (end <= start) return;
    final part = candidate.substring(start, end);
    if (part.trim().isEmpty) {
      _addPlain(parts, part);
      return;
    }
    String? latex;
    if (_hasMathMarker(part)) latex = convertPdgExpression(part);
    latex ??= textTokenToLatex(part);
    if (latex != null && _looksLikeSafeLatex(latex)) {
      parts.add(PdgTextSegment.math(latex));
      converted = true;
    } else if (!_emitTokenFallback(parts, part)) {
      _addPlain(parts, part);
    } else {
      converted = true;
    }
  }

  for (var i = 0; i < candidate.length; i++) {
    final char = candidate[i];
    if (char == '(' || char == '[' || char == '{') depth++;
    if (char == ')' || char == ']' || char == '}') {
      depth--;
      if (depth < 0) return false;
    }
    if (depth != 0) continue;
    final arrow = _arrowLength(candidate, i);
    if (arrow > 0) {
      addPart(i);
      parts.add(const PdgTextSegment.math(r'\longrightarrow'));
      converted = true;
      i += arrow - 1;
      start = i + 1;
      continue;
    }
    if ('+-/*='.contains(char)) {
      addPart(i);
      _addPlain(parts, char);
      start = i + 1;
    }
  }
  addPart(candidate.length);
  if (!converted) return false;
  for (final part in parts) {
    if (part.text != null) {
      _addPlain(segments, part.text!);
    } else {
      segments.add(part);
    }
  }
  return true;
}

final RegExp _fallbackTokenPattern = RegExp(
  r"[A-Za-z]+(?:bar)?(?:(?:_|\^|\*\*)(?:\{\{[^{}]*\}\}|\{[^{}]*\}|[A-Za-z0-9+\-*'′]+))*(?:\([^()\s]*\))?(?:\^?[+\-0]{1,2})?",
);

/// Emits complete name tokens from a failed composite expression. Returns
/// `false` when nothing was converted, so the caller can keep one plain span.
bool _emitTokenFallback(List<PdgTextSegment> segments, String candidate) {
  final parts = <PdgTextSegment>[];
  var cursor = 0;
  var converted = false;
  void flush(int end) {
    if (end > cursor) _addPlain(parts, candidate.substring(cursor, end));
  }

  final combined = RegExp('(?:-->|->|→)|${_fallbackTokenPattern.pattern}');
  for (final match in combined.allMatches(candidate)) {
    if (!_fallbackBoundary(candidate, match.start, match.end)) continue;
    flush(match.start);
    final token = match.group(0)!;
    if (token == '-->' || token == '->' || token == '→') {
      parts.add(const PdgTextSegment.math(r'\longrightarrow'));
      converted = true;
      cursor = match.end;
      continue;
    }
    final latex = textTokenToLatex(token);
    if (latex != null && _looksLikeSafeLatex(latex)) {
      parts.add(PdgTextSegment.math(latex));
      converted = true;
    } else {
      _addPlain(parts, token);
    }
    cursor = match.end;
  }
  flush(candidate.length);
  if (!converted) return false;
  for (final part in parts) {
    if (part.text != null) {
      _addPlain(segments, part.text!);
    } else {
      segments.add(part);
    }
  }
  return true;
}

bool _fallbackBoundary(String text, int start, int end) {
  if (start > 0) {
    final previous = text.codeUnitAt(start - 1);
    if ((previous >= 65 && previous <= 90) ||
        (previous >= 97 && previous <= 122) ||
        previous == 45) {
      return false;
    }
  }
  if (end < text.length) {
    final next = text.codeUnitAt(end);
    if ((next >= 65 && next <= 90) || (next >= 97 && next <= 122)) {
      return false;
    }
  }
  return true;
}

void _addPlain(List<PdgTextSegment> segments, String text) {
  if (text.isEmpty) return;
  if (segments.isNotEmpty && segments.last.text != null) {
    final merged = '${segments.last.text}$text';
    segments[segments.length - 1] = PdgTextSegment.plain(merged);
  } else {
    segments.add(PdgTextSegment.plain(text));
  }
}

bool _canStartExpression(String char) {
  return RegExp(r'[A-Za-z0-9]').hasMatch(char) ||
      char == r'\' ||
      char == '(' ||
      char == '[';
}

int _arrowLength(String text, int index) {
  if (text.startsWith('-->', index)) return 3;
  if (text.startsWith('->', index)) return 2;
  if (text.startsWith('→', index)) return 1;
  return 0;
}

int _scanExpression(String text, int start) {
  var depth = 0;
  var index = start;
  while (index < text.length) {
    final char = text[index];
    if (char == r'$') break;
    if (depth == 0) {
      if (RegExp(r'\s').hasMatch(char)) break;
      if (',;:!?='.contains(char)) break;
      if (char == '|' || char == '<' || char == '>') break;
      if (char == '.' &&
          !(index > start &&
              index + 1 < text.length &&
              RegExp(r'[0-9]').hasMatch(text[index - 1]) &&
              RegExp(r'[0-9]').hasMatch(text[index + 1]))) {
        break;
      }
      if (_arrowLength(text, index) > 0) break;
    }
    if (char == '(' || char == '[' || char == '{') depth++;
    if (char == ')' || char == ']' || char == '}') {
      if (depth == 0) break;
      depth--;
    }
    index++;
  }
  return index;
}

String _prepareCandidate(String candidate) {
  return candidate.replaceAll(RegExp(r'\\mathit\s*'), '');
}

bool _hasMathMarker(String candidate) {
  return candidate.contains('_') ||
      candidate.contains('^') ||
      candidate.contains('**') ||
      candidate.contains(r'\') ||
      candidate.contains('(') ||
      candidate.contains('[');
}

bool _looksLikeSafeLatex(String latex) {
  if (latex.isEmpty) return false;
  if (latex.contains('**')) return false;
  if (latex.contains(r'\mathit')) return false;
  var depth = 0;
  for (final char in latex.split('')) {
    if (char == '{') depth++;
    if (char == '}') {
      depth--;
      if (depth < 0) return false;
    }
  }
  return depth == 0;
}

bool _isCollaborationName(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(' ', '');
  return _collaborationNames.contains(normalized);
}

/// Common experiment/collaboration names in PDG text. These are deliberately
/// kept literal even when they contain digits or a hyphen that could otherwise
/// look like a charge. D0 is intentionally not listed because it is also the
/// D0 meson; the parser handles that context separately.
const Set<String> _collaborationNames = {
  'cleo',
  'cleo-c',
  'cleoiii',
  'cleo-iii',
  'lhc',
  'lhcb',
  'atlas',
  'cms',
  'alice',
  'cdf',
  'd0collaboration',
  'ua1',
  'ua2',
  'babar',
  'belle',
  'belleii',
  'bes',
  'besiii',
  'bes-iii',
  'aleph',
  'delphi',
  'opal',
  'l3',
  'sld',
  'lep',
  'slc',
  'tevatron',
  'fermilab',
  'cern',
  'desy',
  'slac',
  'kek',
  'j-parc',
  'rhic',
  'hera',
  'zeus',
  'h1',
  'kloe',
  'kloe-2',
  'klev',
  'ktev',
  'na31',
  'na48',
  'na62',
  'meg',
  'megii',
  'pep',
  'pep-ii',
  'cesr',
  'cesr-c',
  'bepc',
  'bepcii',
  'kekb',
  'superkekb',
  'snd',
  'crystalball',
  'marki',
  'markii',
  'markiii',
  'pluto',
  'tasso',
  'jade',
  'mac',
  'tpc',
  'cush',
  'cusb',
  'argus',
  'nutev',
  'ccfr',
  'cdhs',
  'gargamelle',
  'bebc',
  'charm',
  'charmii',
  'charm-ii',
};

const Set<String> _bareNameWords = {
  'W',
  'Z',
  'H',
  'K',
  'D',
  'B',
  'N',
  'p',
  'n',
  'e',
  'g',
  'pi',
  'eta',
  'rho',
  'omega',
  'phi',
  'chi',
  'psi',
  'tau',
  'mu',
  'nu',
  'gamma',
  'Lambda',
  'Sigma',
  'Xi',
  'Omega',
  'Delta',
  'Upsilon',
  'theta',
  'lambda',
  'kappa',
  'chitilde',
  'nutilde',
  'lambdatilde',
  'kappatilde',
};

const Set<String> _symbolWords = {
  'pi',
  'Pi',
  'K',
  'D',
  'B',
  'p',
  'n',
  'e',
  'mu',
  'tau',
  'nu',
  'gamma',
  'g',
  'W',
  'Z',
  'H',
  'N',
  'X',
  'Y',
  'f',
  'a',
  'h',
  'm',
  'Lambda',
  'Sigma',
  'Xi',
  'Omega',
  'Delta',
  'Upsilon',
  'psi',
  'phi',
  'rho',
  'eta',
  'omega',
  'chi',
  'theta',
  'alpha',
  'beta',
  'lambda',
  'sigma',
  'kappa',
  'chitilde',
  'nutilde',
  'lambdatilde',
  'kappatilde',
};

bool _isSymbolWord(String token) => _symbolWords.contains(token);

bool _isAntiSymbol(String base) {
  if (!base.endsWith('bar') || base.length <= 3) return false;
  return _symbolWords.contains(base.substring(0, base.length - 3));
}
