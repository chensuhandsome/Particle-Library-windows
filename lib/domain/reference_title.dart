import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

/// Converts reference titles from Crossref/JATS/MathML into readable text.
///
/// The original title is never used as HTML; only text nodes survive. Common
/// MathML constructs are linearized (`msqrt` → `√`, `msub`/`msup` →
/// sub/superscripts, `mfrac` → `a/b`) so a title does not degrade to
/// `s=13 TeV` or leak tags.
String cleanReferenceTitle(String source) {
  if (source.isEmpty) return source;
  final fragment = html.parseFragment(_protectLiteralAngles(source));
  var text = _renderNodes(fragment.nodes);
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  // "+-" is the ASCII plus-minus, except before an arrow: in "mu+->e+gamma" it
  // is a charge sign followed by "->".
  return text.replaceAll(RegExp(r'\+-(?!>)'), '±');
}

String _renderNodes(Iterable<Node> nodes) => nodes.map(_renderNode).join();

String _renderMathNodes(Iterable<Node> nodes) => nodes
    .where((node) => !(node is Text && node.data.trim().isEmpty))
    .map(_renderNode)
    .join();

List<Element> _mathChildren(Element element) =>
    element.nodes.whereType<Element>().toList(growable: false);

/// HTML parsing treats `<G**4>` or `<sqrt(s)` as a tag and silently drops the
/// rest of the title. Protect only angle brackets that cannot start a real
/// tag; MathML/JATS tags continue to be parsed normally.
String _protectLiteralAngles(String source) {
  final tag = RegExp(r'</?[A-Za-z][A-Za-z0-9:_-]*(?:\s[^<>]*?)?/?>');
  final buffer = StringBuffer();
  var index = 0;
  while (index < source.length) {
    final char = source[index];
    if (char != '<') {
      buffer.write(char);
      index++;
      continue;
    }
    final match = tag.matchAsPrefix(source, index);
    if (match == null) {
      buffer.write('&lt;');
      index++;
    } else {
      buffer.write(match.group(0));
      index = match.end;
    }
  }
  return buffer.toString();
}

String _renderNode(Node node) {
  if (node is Text) return node.data;
  if (node is! Element) return '';
  final tag = (node.localName ?? '').split(':').last;
  // Rendered on first use, and each at most once. Rendering both for every
  // element made the cost double with each level of nesting: a title with 30
  // nested tags took minutes.
  late final children = _renderNodes(node.nodes);
  late final mathChildren = _renderMathNodes(node.nodes);
  switch (tag) {
    case 'script':
    case 'style':
    case 'annotation':
    case 'annotation-xml':
      return '';
    case 'math':
    case 'mrow':
      return mathChildren;
    case 'mi':
    case 'mn':
    case 'mtext':
    case 'semantics':
      return children;
    case 'mo':
      final op = children.trim();
      if (op == '=' ||
          op == '<' ||
          op == '>' ||
          op == '≤' ||
          op == '≥' ||
          op == '→' ||
          op == '←' ||
          op == '↔' ||
          op == '⟶') {
        return ' $op ';
      }
      return children;
    case 'msqrt':
      final value = mathChildren.trim();
      return value.length <= 1 ? '√$value' : '√($value)';
    case 'mroot':
      final parts = _mathChildren(node).map(_renderNode).toList();
      if (parts.length < 2) return '√($children)';
      return '√[${parts[1].trim()}]${_group(parts[0].trim())}';
    case 'mfrac':
      final parts = _mathChildren(node).map(_renderNode).toList();
      if (parts.length < 2) return children;
      return '${_group(parts[0].trim())}/${_group(parts[1].trim())}';
    case 'msup':
      final parts = _mathChildren(node).map(_renderNode).toList();
      if (parts.length < 2) return children;
      return '${parts[0]}${_superscript(parts[1].trim())}';
    case 'msub':
      final parts = _mathChildren(node).map(_renderNode).toList();
      if (parts.length < 2) return children;
      return '${parts[0]}${_subscript(parts[1].trim())}';
    case 'mover':
      final parts = _mathChildren(node).map(_renderNode).toList();
      if (parts.length < 2) return children;
      final over = parts[1].trim();
      if (over == '¯' || over == '‾' || over == '\u0304') {
        return '${parts[0]}\u0304';
      }
      if (over == '^' || over == 'ˆ') {
        return '${parts[0]}${_superscript(parts[0].trim())}';
      }
      return '${parts[0]}$over';
    case 'munder':
      final parts = _mathChildren(node).map(_renderNode).toList();
      if (parts.length < 2) return children;
      return '${parts[0]}${_subscript(parts[1].trim())}';
    case 'mfenced':
      return '($mathChildren)';
    case 'mtable':
      return node.nodes
          .whereType<Element>()
          .where((row) => row.localName == 'mtr')
          .map((row) {
            return row.nodes
                .whereType<Element>()
                .where((cell) => cell.localName == 'mtd')
                .map((cell) => _renderNodes(cell.nodes).trim())
                .join(' ');
          })
          .where((row) => row.isNotEmpty)
          .join('; ');
    case 'mtr':
      return node.nodes
          .whereType<Element>()
          .where((cell) => cell.localName == 'mtd')
          .map((cell) => _renderNodes(cell.nodes).trim())
          .join(' ');
    case 'mtd':
      return children;
    case 'sup':
      return _superscript(children.trim());
    case 'sub':
      return _subscript(children.trim());
    case 'br':
      return ' ';
    default:
      return children;
  }
}

String _group(String value) =>
    value.contains(RegExp(r'\s|[=<>]')) ? '($value)' : value;

const _superscripts = <String, String>{
  '0': '⁰',
  '1': '¹',
  '2': '²',
  '3': '³',
  '4': '⁴',
  '5': '⁵',
  '6': '⁶',
  '7': '⁷',
  '8': '⁸',
  '9': '⁹',
  '+': '⁺',
  '-': '⁻',
  '−': '⁻',
  '=': '⁼',
  '(': '⁽',
  ')': '⁾',
  'n': 'ⁿ',
  'i': 'ⁱ',
};

const _subscripts = <String, String>{
  '0': '₀',
  '1': '₁',
  '2': '₂',
  '3': '₃',
  '4': '₄',
  '5': '₅',
  '6': '₆',
  '7': '₇',
  '8': '₈',
  '9': '₉',
  '+': '₊',
  '-': '₋',
  '−': '₋',
  '=': '₌',
  '(': '₍',
  ')': '₎',
  'a': 'ₐ',
  'e': 'ₑ',
  'h': 'ₕ',
  'i': 'ᵢ',
  'j': 'ⱼ',
  'k': 'ₖ',
  'l': 'ₗ',
  'm': 'ₘ',
  'n': 'ₙ',
  'o': 'ₒ',
  'p': 'ₚ',
  'r': 'ᵣ',
  's': 'ₛ',
  't': 'ₜ',
  'u': 'ᵤ',
  'v': 'ᵥ',
  'x': 'ₓ',
};

String _superscript(String value) {
  final mapped = value.split('').map((c) => _superscripts[c]).toList();
  if (mapped.every((v) => v != null)) return mapped.join();
  return value.isEmpty ? '' : '^($value)';
}

String _subscript(String value) {
  final mapped = value.split('').map((c) => _subscripts[c]).toList();
  if (mapped.every((v) => v != null)) return mapped.join();
  return value.isEmpty ? '' : '_($value)';
}

/// Some snapshot titles are cut off mid-sentence (e.g. "... Analysis of").
/// This conservative check only flags endings that cannot be a complete title.
bool referenceTitleLooksTruncated(String title) {
  final value = title.trim();
  if (value.isEmpty || value.endsWith('…') || value.endsWith('...')) {
    return false;
  }
  if (RegExp(r'(?:->|-->|→|=)$').hasMatch(value)) return true;
  return RegExp(
    r'(?:^|\s)(?:of|the|in|on|for|and|to|with|at|from|by|as|a|an|or|via|'
    r'using|between|into|under|over)$',
    caseSensitive: false,
  ).hasMatch(value);
}
