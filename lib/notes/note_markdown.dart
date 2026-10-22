/// Converts the Markdown accepted by the notes editor into a plain-text body
/// used for previews and substring search.
///
/// This is intentionally a small, dependency-free extractor, not a CommonMark
/// implementation: message text is never discarded, so CJK content survives
/// unchanged. For example `**轻子** [衰变](https://example.com)` becomes
/// `轻子 衰变`. Fenced code blocks keep their content (without the fences).
/// Inline single `*`/`_` characters are preserved to avoid mangling words such
/// as `body_plain`.
String plainTextFromMarkdown(String markdown) {
  if (markdown.isEmpty) return '';
  final lines = markdown
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  final buffer = StringBuffer();
  var inFence = false;
  for (final rawLine in lines) {
    final trimmedLeft = rawLine.trimLeft();
    if (trimmedLeft.startsWith('```') || trimmedLeft.startsWith('~~~')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) {
      // Fenced code is literal text; do not strip HTML, emphasis or links.
      buffer.writeln(rawLine);
      continue;
    }
    var line = rawLine;
    line = line.replaceFirst(RegExp(r'^\s{0,3}#{1,6}\s+'), '');
    if (RegExp(r'^\s{0,3}([-*_])(?:\s*\1){2,}\s*$').hasMatch(line)) {
      buffer.writeln();
      continue;
    }
    line = line.replaceFirst(RegExp(r'^\s{0,3}>\s?'), '');
    line = line.replaceFirst(RegExp(r'^\s{0,3}(?:[-*+]|\d+[.)])\s+'), '');
    line = _stripInlineMarkdown(line);
    buffer.writeln(line);
  }

  var text = buffer.toString();
  text = text.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  text = text.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return text.trim();
}

// A link destination may hold balanced parentheses, as a DOI does
// ("10.1016/0370-2693(93)90355-u"). The label and the tag exclude the opening
// delimiter, so a long run of "[" or "<" with no closer cannot make a match
// attempt scan to the end of the text from every start (quadratic time).
final RegExp _imagePattern = RegExp(
  r'!\[([^\[\]]*)\]\((?:[^()]|\([^()]*\))*\)',
);
final RegExp _linkPattern = RegExp(r'\[([^\[\]]*)\]\((?:[^()]|\([^()]*\))*\)');
final RegExp _tagPattern = RegExp(r'<[^<>]+>');

String _stripInlineMarkdown(String line) {
  var text = line.replaceAllMapped(_imagePattern, (match) => match[1] ?? '');
  text = text.replaceAllMapped(_linkPattern, (match) => match[1] ?? '');
  text = text.replaceAll('**', '');
  text = text.replaceAll('__', '');
  text = text.replaceAll('~~', '');
  text = text.replaceAll('`', '');
  text = text.replaceAll(_tagPattern, '');
  return text;
}
